# Recent directory tracking with cdr
# Configuration - easily editable values
local CDR_MAX_DIRS=100
local CDR_CLEANUP_THRESHOLD=120
local CDR_KEEP_DIRS=100

# Ensure cache directory exists
local cache_dir="${ZDOTDIR:-$HOME}/.zsh/caches"
[[ ! -d "$cache_dir" ]] && mkdir -p "$cache_dir"

# Load cdr functions if available
if autoload -Uz chpwd_recent_dirs cdr add-zsh-hook 2>/dev/null; then
  add-zsh-hook chpwd chpwd_recent_dirs
  
  # Configure recent directories
  zstyle ':completion:*' recent-dirs-insert both
  zstyle ':chpwd:*' recent-dirs-default true
  zstyle ':chpwd:*' recent-dirs-max $CDR_MAX_DIRS
  zstyle ':chpwd:*' recent-dirs-file "$cache_dir/recent-dirs"
  
  # Cleanup function for old entries
  cdr_cleanup() {
    local recent_dirs_file="$cache_dir/recent-dirs"
    if [[ -f "$recent_dirs_file" ]] && (( $(wc -l < "$recent_dirs_file") > $CDR_CLEANUP_THRESHOLD )); then
      # Keep only the most recent entries when file grows too large
      tail -$CDR_KEEP_DIRS "$recent_dirs_file" > "$recent_dirs_file.tmp" && \
        mv "$recent_dirs_file.tmp" "$recent_dirs_file"
    fi
  }
  
  # Run cleanup occasionally (every 50th shell startup)
  (( RANDOM % 50 == 0 )) && cdr_cleanup
else
  echo "Warning: cdr module not available. Install zsh-completions or check zsh installation." >&2
fi
