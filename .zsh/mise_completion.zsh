# mise completion for zsh
# Note: This file provides completion setup for mise-managed tools

# Check if mise is available
if ! (( $+commands[mise] )); then
  return
fi

(( $+commands[aws_completer] )) && complete -C aws_completer aws
(( $+commands[terraform] )) && complete -C terraform terraform

# Special handling for gcloud (suppress all output)
if (( $+commands[gcloud] )); then
  {
    local gcloud_path
    gcloud_path=$(mise where gcloud 2>/dev/null)

    if [[ -n "$gcloud_path" ]]; then
      [[ -f "$gcloud_path/path.zsh.inc" ]] && source "$gcloud_path/path.zsh.inc"
      [[ -f "$gcloud_path/completion.zsh.inc" ]] && source "$gcloud_path/completion.zsh.inc"
    fi
  } >/dev/null 2>&1
fi
