# Lazygit configuration

# Alias for quick access
alias lg='lazygit'

# Function to open lazygit in a specific repo
# Usage: lgg [path]
function lgg() {
  local repo_path="${1:-.}"
  if [[ ! -d "$repo_path/.git" ]]; then
    echo "Error: Not a git repository: $repo_path" >&2
    return 1
  fi
  lazygit -p "$repo_path"
}

# Integration with fz function for repo selection
# Usage: lgf
function lgf() {
  if ! (( $+commands[fzf] )) || ! (( $+commands[fd] )); then
    echo "Error: fzf and fd are required for lgf" >&2
    return 1
  fi

  local repo
  repo=$(fd -H -t d '^\.git$' --max-depth 5 --exec dirname {} \; | fzf \
    --preview 'cd {} && git log --oneline --graph --all -20 2>/dev/null || echo "No git history"' \
    --header "Select git repository")

  if [[ -n "$repo" ]]; then
    lazygit -p "$repo"
  fi
}
