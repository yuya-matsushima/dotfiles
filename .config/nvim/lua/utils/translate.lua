-- 任意のテキストを日本語に翻訳するユーティリティ。Gemini API を使用する。
--
-- 必要な環境変数:
--   GEMINI_API_KEY  : Google AI Studio (https://aistudio.google.com/app/apikey) で発行する API キー
--   GEMINI_MODEL    : 任意。デフォルトは gemini-2.5-flash
--
-- 公開 API:
--   M.translate(line1, line2)  : 行範囲を翻訳。引数なしならバッファ全体
--   M.translate_buffer()       : バッファ全体を翻訳
--   M.translate_range(l1, l2)  : 行範囲を翻訳

local M = {}

local DEFAULT_MODEL = 'gemini-2.5-flash'

local PROMPT = [[以下のテキストを自然な日本語に翻訳してください。

制約:
- 元のフォーマット (Markdown 構文, インデント, 改行, 箇条書き, テーブル, コードブロック等) を保持する
- コードブロックやインラインコード内のコード本体は翻訳せず, コメントや文字列のうち訳すべき部分のみ翻訳する
- 固有名詞, コマンド名, ライブラリ名, ファイルパス, URL, 技術用語は原文を尊重する
- 翻訳結果のみを出力し, 前置き・後書き・コードフェンスでの全体囲みは付けない

----
]]

local function get_api_key()
  local key = vim.env.GEMINI_API_KEY
  if not key or key == '' then
    vim.notify('GEMINI_API_KEY is not set', vim.log.levels.ERROR)
    return nil
  end
  return key
end

local function open_result_split(text, source_ft)
  vim.cmd('vsplit')
  vim.cmd('enew')
  local buf = vim.api.nvim_get_current_buf()
  vim.bo[buf].buftype = 'nofile'
  vim.bo[buf].bufhidden = 'wipe'
  vim.bo[buf].swapfile = false
  if source_ft and source_ft ~= '' then
    vim.bo[buf].filetype = source_ft
  end
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(text, '\n', { plain = true }))
end

local function call_gemini(text, source_ft, on_done)
  local api_key = get_api_key()
  if not api_key then
    return
  end

  local model = vim.env.GEMINI_MODEL or DEFAULT_MODEL
  local url = string.format(
    'https://generativelanguage.googleapis.com/v1beta/models/%s:generateContent?key=%s',
    model,
    api_key
  )

  local body = vim.json.encode({
    contents = {
      { parts = { { text = PROMPT .. text } } },
    },
    generationConfig = {
      temperature = 0.2,
    },
  })

  vim.notify('Translating with ' .. model .. '...', vim.log.levels.INFO)

  vim.system(
    { 'curl', '-sS', '-X', 'POST', '-H', 'Content-Type: application/json', '--data-binary', '@-', url },
    { stdin = body, text = true },
    function(result)
      vim.schedule(function()
        if result.code ~= 0 then
          vim.notify('curl failed (exit ' .. result.code .. '): ' .. (result.stderr or ''), vim.log.levels.ERROR)
          return
        end

        local ok, decoded = pcall(vim.json.decode, result.stdout)
        if not ok then
          vim.notify('Failed to decode response: ' .. result.stdout, vim.log.levels.ERROR)
          return
        end

        if decoded.error then
          local msg = (decoded.error and decoded.error.message) or vim.inspect(decoded.error)
          vim.notify('Gemini error: ' .. msg, vim.log.levels.ERROR)
          return
        end

        local candidate = decoded.candidates and decoded.candidates[1]
        local parts = candidate and candidate.content and candidate.content.parts or {}
        local text_out = parts[1] and parts[1].text or ''

        if text_out == '' then
          vim.notify('Empty translation: ' .. vim.inspect(decoded), vim.log.levels.WARN)
          return
        end

        on_done(text_out, source_ft)
      end)
    end
  )
end

--- 行範囲 [line1, line2] (1-based, inclusive) を翻訳して別ウィンドウに表示する。
---@param line1 integer
---@param line2 integer
function M.translate_range(line1, line2)
  local lines = vim.api.nvim_buf_get_lines(0, line1 - 1, line2, false)
  local text = table.concat(lines, '\n')
  if vim.trim(text) == '' then
    vim.notify('Selection is empty', vim.log.levels.WARN)
    return
  end
  local source_ft = vim.bo.filetype
  call_gemini(text, source_ft, open_result_split)
end

--- バッファ全体を翻訳して別ウィンドウに表示する。
function M.translate_buffer()
  local last = vim.api.nvim_buf_line_count(0)
  M.translate_range(1, last)
end

--- ユーザーコマンド/キーマップから呼ぶエントリポイント。
--- 引数が無い場合はバッファ全体を翻訳する。
---@param line1 integer|nil
---@param line2 integer|nil
function M.translate(line1, line2)
  if line1 and line2 then
    M.translate_range(line1, line2)
  else
    M.translate_buffer()
  end
end

return M
