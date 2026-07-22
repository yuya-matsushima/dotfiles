-- OBS 録画用 1920x1080 ガイドオーバーレイ
-- 4K ディスプレイ全体をキャプチャし、本モジュールが示す領域だけをクロップして録画する用途

local M = {}

-- hs.reload() 時の二重登録防止: 既存インスタンスをクリーンアップ
if _G.__recording_guide_state then
	local prev = _G.__recording_guide_state
	if prev.canvas then prev.canvas:delete() end
	if prev.menubar then prev.menubar:delete() end
	if prev.recordingTask and prev.recordingTask:isRunning() then
		local pid = prev.recordingTask:pid()
		if pid then hs.execute("kill -INT " .. pid) end
	end
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
	recordingTask = nil,
	recordingPath = nil,
}
_G.__recording_guide_state = state

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
-- 同型モニタ複数接続でも一意に識別できるよう UUID を保存 key に使う。
local function getTargetScreen()
	local savedUUID = hs.settings.get(SETTINGS_PREFIX .. "targetScreenUUID")
	local screens = hs.screen.allScreens()
	if savedUUID then
		for _, s in ipairs(screens) do
			if s:getUUID() == savedUUID then return s end
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
	-- currentMode().w/h は POINT のため、物理ピクセルには mode.scale を掛ける必要がある
	local scaleFactor = mode.scale or 1
	local modePxW = mode.w * scaleFactor
	local modePxH = mode.h * scaleFactor
	local scaleX = modePxW / frame.w
	local scaleY = modePxH / frame.h
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
		modeW = modePxW,
		modeH = modePxH,
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
	-- 録画中はガイドを再表示しない (border/暗幕が録画に混入するため)
	if state.visible and not state.recordingTask then canvas:show() end
end

local function updateMenubarTitle()
	if not state.menubar then return end
	local font = { name = ".AppleSystemUIFont", size = 13 }
	if state.recordingTask then
		state.menubar:setTitle(hs.styledtext.new(" ● REC ", {
			color = { white = 1, alpha = 1 },
			backgroundColor = { red = 0.85, green = 0.15, blue = 0.15, alpha = 1 },
			font = font,
		}))
	elseif state.visible then
		state.menubar:setTitle(hs.styledtext.new(" REC ", {
			color = { white = 1, alpha = 1 },
			backgroundColor = { white = 0.4, alpha = 1 },
			font = font,
		}))
	else
		state.menubar:setTitle("REC")
	end
end

function M.show()
	state.visible = true
	if not state.canvas then rebuildCanvas() end
	state.canvas:show()
	updateMenubarTitle()
end

function M.hide()
	state.visible = false
	if state.canvas then state.canvas:hide() end
	updateMenubarTitle()
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

function M.startRecording()
	if state.recordingTask then
		return
	end
	local screen = getTargetScreen()
	local g = computeGuide(screen)
	if g.previewScale < 1 then
		hs.alert.show("Preview mode: recording at scaled size, not 1920x1080")
	end
	local ts = os.date("%Y%m%d-%H%M%S")
	local path = string.format("%s/Movies/recording-guide-%s.mov", os.getenv("HOME"), ts)
	local rect = string.format("%.0f,%.0f,%.0f,%.0f", g.x, g.y, g.w, g.h)
	state.recordingPath = path
	-- ガイドの border が録画に混入するため一時的に非表示 (状態は wasVisibleBeforeRecording に保持)
	state.wasVisibleBeforeRecording = state.visible
	if state.canvas and state.visible then state.canvas:hide() end
	state.recordingTask = hs.task.new(
		"/usr/sbin/screencapture",
		function(_exitCode, _stdout, _stderr)
			state.recordingTask = nil
			-- screencapture プロセスが実際に終了したここで canvas を復元。
			-- stopRecording 経由でも外部シグナル終了でも共通で復元される。
			if state.wasVisibleBeforeRecording and state.canvas then
				state.canvas:show()
			end
			state.wasVisibleBeforeRecording = nil
			updateMenubarTitle()
		end,
		{ "-v", "-g", "-R", rect, path }
	)
	state.recordingTask:start()
	updateMenubarTitle()
end

function M.stopRecording()
	if not state.recordingTask then
		return
	end
	local pid = state.recordingTask:pid()
	if pid then
		hs.execute("kill -INT " .. pid)
	end
	local path = state.recordingPath
	state.recordingPath = nil
	-- canvas 復元は task 完了 callback で行う (プロセス終了完了後)
	-- ファイル確定を待って Finder で表示
	if path then
		hs.timer.doAfter(1.2, function()
			hs.execute(string.format("open -R %q", path))
		end)
	end
end

function M.toggleRecording()
	if state.recordingTask then M.stopRecording() else M.startRecording() end
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
	local savedUUID = hs.settings.get(SETTINGS_PREFIX .. "targetScreenUUID")
	for _, s in ipairs(hs.screen.allScreens()) do
		local mode = s:currentMode()
		local name = s:name() or "Unknown"
		local screen = s
		table.insert(items, {
			title = string.format("%s (%dx%d)", name, mode.w or 0, mode.h or 0),
			checked = screen:id() == activeScreen:id(),
			fn = function()
				hs.settings.set(SETTINGS_PREFIX .. "targetScreenUUID", screen:getUUID())
				rebuildCanvas()
			end,
		})
	end
	if savedUUID then
		table.insert(items, { title = "-" })
		table.insert(items, {
			title = "Auto (Largest Display)",
			fn = function()
				hs.settings.set(SETTINGS_PREFIX .. "targetScreenUUID", nil)
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
			{ title = state.recordingTask and "Stop Recording" or "Start Recording (mic on)", fn = M.toggleRecording },
			{ title = "-" },
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
