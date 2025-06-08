# less configuration - colorized man pages and improved paging
# Only configure if less command is available
if (( $+commands[less] )); then
  # less options:
  # -F: quit if entire file fits on first screen
  # -X: don't use termcap init/deinit strings
  # -R: output "raw" control characters
  export LESS='-F -X -R'

  # Only set color termcaps if terminal supports colors
  if [[ "$TERM" != "dumb" ]] && { (( $+termcap )) 2>/dev/null || [[ -n "$COLORTERM" ]]; }; then
    export LESS_TERMCAP_mb=$'\E[01;31m'     # begin blinking (red)
    export LESS_TERMCAP_md=$'\E[01;34m'     # begin bold (blue)
    export LESS_TERMCAP_me=$'\E[0m'         # end mode
    export LESS_TERMCAP_se=$'\E[0m'         # end standout-mode
    export LESS_TERMCAP_so=$'\E[01;44;33m'  # begin standout-mode (yellow on blue)
    export LESS_TERMCAP_ue=$'\E[0m'         # end underline
    export LESS_TERMCAP_us=$'\E[01;32m'     # begin underline (green)
  fi
fi
