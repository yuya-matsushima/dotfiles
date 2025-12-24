# Yazi configuration

# Shell wrapper function for changing directory on exit
# Official recommended function from yazi documentation
function y() {
  local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
  yazi "$@" --cwd-file="$tmp"
  IFS= read -r -d '' cwd < "$tmp"
  [ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
  rm -f -- "$tmp"
}

# Alternative: Use yy as an alias if preferred (commented out by default)
# alias yy='y'
