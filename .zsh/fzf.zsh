# fzf configuration

# 基本設定
export FZF_DEFAULT_COMMAND="fd --type f --type d --hidden --exclude .git"
export FZF_DEFAULT_OPTS='
  --height 50%
  --reverse
  --border
  --preview-window=right:50%
  --prompt="❯ "
  --pointer="▶"
  --marker="✓"
  --bind "P:preview-up,N:preview-down"'

# プレビューコマンド (Shift+N/P でプレビュー内をスクロール)
export FZF_PREVIEW_COMMAND='
  if [[ -d {} ]]; then
    if command -v erd >/dev/null 2>&1; then
      erd --color=auto {} | head -100
    elif command -v eza >/dev/null 2>&1; then
      eza --tree --color=always {} | head -100
    else
      tree -C {} | head -100
    fi
  elif [[ -f {} ]]; then
    case {} in
      *.jpg|*.jpeg|*.png|*.gif|*.webp) echo "Image: {}" ;;
      *.pdf) echo "PDF: {}" ;;
      *.zip|*.tar|*.gz|*.7z) echo "Archive: {}" ;;
      *) bat --style=numbers --color=always --line-range=:100 {} 2>/dev/null || cat {} ;;
    esac
  fi
'

export FZF_COMPLETION_OPTS="--preview '${FZF_PREVIEW_COMMAND}'"

# Ctrl+R: コマンド履歴検索
export FZF_CTRL_R_OPTS="
  --preview 'echo {} | sed \"s/^ *[0-9]* *//\" | head -1'
  --preview-window=down:3:wrap
  --bind 'ctrl-y:execute-silent(echo -n {2..} | pbcopy)+abort'
  --color header:italic
  --header 'Press CTRL-Y to copy command into clipboard'"

# Ctrl+T: ファイル検索
export FZF_CTRL_T_OPTS="
  --preview '${FZF_PREVIEW_COMMAND}'
  --bind 'ctrl-/:change-preview-window(down|hidden|)'"

# Alt+C support for Mac
bindkey "ç" fzf-cd-widget
