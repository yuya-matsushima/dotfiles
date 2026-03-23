local M = {}

--- URL を解析し、マッチすれば {label, url} を返す。マッチしなければ nil。
---@param url string
---@return {label: string, url: string}|nil
function M.format_url(url)
  url = vim.trim(url)

  -- GitHub Issue / Pull Request
  local num = url:match('https://github%.com/.+/issues/(%d+)')
    or url:match('https://github%.com/.+/pull/(%d+)')
  if num then
    return { label = '#' .. num, url = url }
  end

  -- Backlog
  local ticket = url:match('https://.+%.backlog%.com/view/([%w_]+-[%w_]+)')
  if ticket then
    return { label = ticket, url = url }
  end

  return nil
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
