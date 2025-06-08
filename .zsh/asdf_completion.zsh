# asdf completion for zsh
# Note: This file provides completion setup for asdf-managed tools

# Check if asdf is available
if ! (( $+commands[asdf] )); then
  echo "Warning: asdf not found. Install with: brew install asdf" >&2
  return
fi

# Helper function to setup completion for asdf tools
setup_asdf_completion() {
  local tool="$1"
  local completion_cmd="$2"

  if (( $+commands[$tool] )) && [[ "$(command -v $tool)" == *".asdf/shims/$tool"* ]]; then
    eval "$completion_cmd"
  fi
}

# Setup completions for specific tools
setup_asdf_completion "aws" "complete -C aws_completer aws"
setup_asdf_completion "terraform" "complete -C terraform terraform"

# Special handling for gcloud (suppress all output)
if (( $+commands[gcloud] )) && [[ "$(command -v gcloud)" == *".asdf/shims/gcloud"* ]]; then
  {
    local gcloud_version
    gcloud_version=$(asdf current gcloud | grep -v Version | awk '{print $2}')

    if [[ -n "$gcloud_version" ]]; then
      local gcloud_path="$HOME/.asdf/installs/gcloud/$gcloud_version"
      [[ -f "$gcloud_path/path.zsh.inc" ]] && source "$gcloud_path/path.zsh.inc"
      [[ -f "$gcloud_path/completion.zsh.inc" ]] && source "$gcloud_path/completion.zsh.inc"
    fi
  } >/dev/null 2>&1
fi
