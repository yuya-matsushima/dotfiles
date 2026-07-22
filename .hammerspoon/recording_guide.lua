-- OBS 録画用 1920x1080 ガイドオーバーレイ
-- 4K ディスプレイ全体をキャプチャし、本モジュールが示す領域だけをクロップして録画する用途

local M = {}

-- hs.reload() 時の二重登録防止: 既存インスタンスをクリーンアップ
if _G.__recording_guide_state then
	local prev = _G.__recording_guide_state
	if prev.canvas then prev.canvas:delete() end
	if prev.menubar then prev.menubar:delete() end
end

local SETTINGS_PREFIX = "recording_guide."
local DEFAULTS = {
	outputWidth = 1920,
	outputHeight = 1080,
	dimOpacity = 0.2,
	borderWidth = 3,
	dimOutside = true,
}

local state = {
	canvas = nil,
	menubar = nil,
	visible = false,
	dimOutside = DEFAULTS.dimOutside,
}
_G.__recording_guide_state = state
-- 過去バージョンで永続化された dimOutside を破棄し、常に default から始める
hs.settings.clear(SETTINGS_PREFIX .. "dimOutside")

local function getSetting(key)
	local v = hs.settings.get(SETTINGS_PREFIX .. key)
	if v == nil then return DEFAULTS[key] end
	return v
end

local function setSetting(key, value)
	hs.settings.set(SETTINGS_PREFIX .. key, value)
end

-- 対象ディスプレイを解決する。ユーザーが選んだ画面を優先し、
-- なければ物理ピクセル数が最大のもの (通常は 4K 外部) を採用する。
local function getTargetScreen()
	local savedName = hs.settings.get(SETTINGS_PREFIX .. "targetScreenName")
	local screens = hs.screen.allScreens()
	if savedName then
		for _, s in ipairs(screens) do
			if s:name() == savedName then return s end
		end
	end
	local best, bestPixels = nil, 0
	for _, s in ipairs(screens) do
		local mode = s:currentMode()
		local p = (mode.w or 0) * (mode.h or 0)
		if p > bestPixels then
			bestPixels = p
			best = s
		end
	end
	return best or hs.screen.mainScreen()
end

-- fullFrame() を使う。OBS の Display Capture はメニューバー含む全画面を対象にするため
local function computeGuide(screen)
	local frame = screen:fullFrame()
	local mode = screen:currentMode()
	local scaleX = mode.w / frame.w
	local scaleY = mode.h / frame.h
	local outW = getSetting("outputWidth")
	local outH = getSetting("outputHeight")
	local guideWpt = outW / scaleX
	local guideHpt = outH / scaleY
	-- ディスプレイに収まらない場合はプレビュー用に 16:9 維持したまま縮小
	local previewScale = 1
	if guideWpt > frame.w or guideHpt > frame.h then
		-- 16:9 のまま画面いっぱいまで拡大。border stroke は端で若干クリップされるが視認性優先
		previewScale = math.min(frame.w / guideWpt, frame.h / guideHpt)
		guideWpt = guideWpt * previewScale
		guideHpt = guideHpt * previewScale
	end
	return {
		screenFrame = frame,
		modeW = mode.w,
		modeH = mode.h,
		scaleX = scaleX,
		scaleY = scaleY,
		previewScale = previewScale,
		x = frame.x + (frame.w - guideWpt) / 2,
		y = frame.y + (frame.h - guideHpt) / 2,
		w = guideWpt,
		h = guideHpt,
	}
end

local function rebuildCanvas()
	if state.canvas then
		state.canvas:delete()
		state.canvas = nil
	end

	local screen = getTargetScreen()
	local g = computeGuide(screen)
	local frame = g.screenFrame

	local canvas = hs.canvas.new({ x = frame.x, y = frame.y, w = frame.w, h = frame.h })
	canvas:level(hs.canvas.windowLevels.overlay)
	canvas:behavior({
		hs.canvas.windowBehaviors.canJoinAllSpaces,
		hs.canvas.windowBehaviors.stationary,
		hs.canvas.windowBehaviors.fullScreenAuxiliary,
	})
	-- 全マウスイベントを透過
	canvas:canvasMouseEvents(false, false, false, false)

	-- canvas 内座標系は左上原点 (frame ローカル)
	local localX = g.x - frame.x
	local localY = g.y - frame.y

	-- 暗幕: 4 枠で録画領域外だけを塗る (compositeRule より単純で確実)
	if state.dimOutside then
		local dim = { red = 0, green = 0, blue = 0, alpha = getSetting("dimOpacity") }
		-- Top
		canvas[#canvas + 1] = {
			type = "rectangle", action = "fill", fillColor = dim,
			frame = { x = 0, y = 0, w = frame.w, h = localY },
		}
		-- Bottom
		canvas[#canvas + 1] = {
			type = "rectangle", action = "fill", fillColor = dim,
			frame = { x = 0, y = localY + g.h, w = frame.w, h = frame.h - (localY + g.h) },
		}
		-- Left
		canvas[#canvas + 1] = {
			type = "rectangle", action = "fill", fillColor = dim,
			frame = { x = 0, y = localY, w = localX, h = g.h },
		}
		-- Right
		canvas[#canvas + 1] = {
			type = "rectangle", action = "fill", fillColor = dim,
			frame = { x = localX + g.w, y = localY, w = frame.w - (localX + g.w), h = g.h },
		}
	end

	-- 境界線
	canvas[#canvas + 1] = {
		type = "rectangle",
		action = "stroke",
		strokeColor = { red = 1, green = 0.2, blue = 0.2, alpha = 1 },
		strokeWidth = getSetting("borderWidth"),
		frame = { x = localX, y = localY, w = g.w, h = g.h },
	}

	state.canvas = canvas
	if state.visible then canvas:show() end
end

function M.show()
	state.visible = true
	if not state.canvas then rebuildCanvas() end
	state.canvas:show()
end

function M.hide()
	state.visible = false
	if state.canvas then state.canvas:hide() end
end

function M.toggle()
	if state.visible then M.hide() else M.show() end
end

function M.center()
	rebuildCanvas()
end

function M.toggleDimming()
	state.dimOutside = not state.dimOutside
	rebuildCanvas()
end

function M.copyCrop()
	local screen = getTargetScreen()
	local g = computeGuide(screen)
	if g.previewScale < 1 then
		hs.alert.show("Preview mode: OBS crop values not accurate on this display")
		return
	end
	local outW = getSetting("outputWidth")
	local outH = getSetting("outputHeight")
	local left = math.floor((g.x - g.screenFrame.x) * g.scaleX + 0.5)
	local top = math.floor((g.y - g.screenFrame.y) * g.scaleY + 0.5)
	local right = g.modeW - left - outW
	local bottom = g.modeH - top - outH
	local text = string.format(
		"OBS Crop\nLeft: %d\nTop: %d\nRight: %d\nBottom: %d\nOutput: %dx%d",
		left, top, right, bottom, outW, outH
	)
	hs.pasteboard.setContents(text)
	hs.alert.show("Copied OBS crop values")
end

local function targetDisplaySubmenu()
	local items = {}
	local activeScreen = getTargetScreen()
	local savedName = hs.settings.get(SETTINGS_PREFIX .. "targetScreenName")
	for _, s in ipairs(hs.screen.allScreens()) do
		local mode = s:currentMode()
		local name = s:name() or "Unknown"
		local screen = s
		table.insert(items, {
			title = string.format("%s (%dx%d)", name, mode.w or 0, mode.h or 0),
			checked = screen:id() == activeScreen:id(),
			fn = function()
				hs.settings.set(SETTINGS_PREFIX .. "targetScreenName", screen:name())
				rebuildCanvas()
			end,
		})
	end
	if savedName then
		table.insert(items, { title = "-" })
		table.insert(items, {
			title = "Auto (Largest Display)",
			fn = function()
				hs.settings.set(SETTINGS_PREFIX .. "targetScreenName", nil)
				rebuildCanvas()
			end,
		})
	end
	return items
end

local function buildMenubar()
	local mb = hs.menubar.new()
	if mb == nil then return nil end
	mb:setTitle("REC")
	mb:setTooltip("Recording Guide")
	mb:setMenu(function()
		return {
			{ title = state.visible and "Hide Guide" or "Show Guide", fn = M.toggle },
			{ title = "Center Guide", fn = M.center },
			{ title = "-" },
			{ title = "Toggle Outside Dimming", fn = M.toggleDimming, checked = state.dimOutside },
			{ title = "Target Display", menu = targetDisplaySubmenu() },
			{ title = "-" },
			{ title = "Copy OBS Crop Values", fn = M.copyCrop },
		}
	end)
	return mb
end

state.menubar = buildMenubar()

return M
