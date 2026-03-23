local M = {}

--- URL またはパスの末尾セグメントを取得する。
---@param str string
---@return string|nil
local function last_segment(str)
  -- クエリパラメータやフラグメントを除去してからパス末尾を取得
  local path = str:match('^([^?#]*)') or str
  -- 末尾のスラッシュを除去してから最後のセグメントを取得
  path = path:gsub('/+$', '')
  return path:match('([^/]+)$')
end

--- URL またはパスを解析し、{label, url} を返す。変換不可なら nil。
--- 末尾パスセグメントが数字のみの場合は #number 形式にする。
---@param url string
---@return {label: string, url: string}|nil
function M.format_url(url)
  url = vim.trim(url)

  -- URL または相対パス（スラッシュを含む）が対象
  if not (url:match('^https?://') or url:match('/')) then
    return nil
  end

  local seg = last_segment(url)
  if not seg then
    return nil
  end

  -- 末尾が数字のみ → #number (GitHub, GitLab, Redmine 等)
  local label = seg:match('^%d+$') and '#' .. seg or seg
  return { label = label, url = url }
end

--- クリップボードの URL を Markdown リンク形式でペーストする。
--- カーソル下に URL があればそちらを優先して変換する。
function M.paste_as_link()
  -- カーソル下の WORD を先にチェック
  local cword = vim.fn.expand('<cWORD>')
  local result = M.format_url(cword)
  if result then
    -- カーソル下の URL をその場で置換（WORD の範囲を取得して直接置換）
    local link = string.format('[%s](%s)', result.label, result.url)
    local line = vim.api.nvim_get_current_line()
    local col = vim.fn.col('.')
    -- cWORD の開始・終了位置を特定
    local s, e = col, col
    while s > 1 and line:sub(s - 1, s - 1):match('%S') do s = s - 1 end
    while e < #line and line:sub(e + 1, e + 1):match('%S') do e = e + 1 end
    local new_line = line:sub(1, s - 1) .. link .. line:sub(e + 1)
    vim.api.nvim_set_current_line(new_line)
    return
  end

  -- クリップボードから取得
  local clipboard = vim.fn.getreg('+')
  result = M.format_url(clipboard)
  if result then
    local link = string.format('[%s](%s)', result.label, result.url)
    vim.api.nvim_put({ link }, 'c', true, true)
  else
    -- 通常ペースト
    vim.cmd('normal! "+p')
  end
end

return M
