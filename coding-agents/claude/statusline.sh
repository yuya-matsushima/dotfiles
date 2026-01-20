#!/bin/bash
# Claude Code statusline script
# Shows cost, input/output tokens, and context usage percentage
#
# Setup:
#   Add the following to ~/.claude/settings.json:
#
#   {
#     "statusLine": {
#       "type": "command",
#       "command": "/bin/sh /path/to/this/statusline.sh"
#     }
#   }
#
# Requirements:
#   - jq (brew install jq)

input=$(cat)

MODEL=$(echo "$input" | jq -r '.model.display_name // "Unknown"')
COST=$(echo "$input" | jq -r '.cost.total_cost_usd // 0' | xargs printf "%.2f")
# Format number with k/M suffix
format_tokens() {
    awk '{
        if ($1 >= 1000000) printf "%.1fM", $1/1000000
        else if ($1 >= 1000) printf "%.1fk", $1/1000
        else printf "%d", $1
    }'
}

INPUT_TOKENS=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0' | format_tokens)
OUTPUT_TOKENS=$(echo "$input" | jq -r '.context_window.total_output_tokens // 0' | format_tokens)
CONTEXT_USED=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | xargs printf "%.0f")

# ANSI color codes
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

# Color based on context usage
if [ "${CONTEXT_USED}" -gt 80 ]; then
    CTX_COLOR=$RED
elif [ "${CONTEXT_USED}" -gt 60 ]; then
    CTX_COLOR=$YELLOW
else
    CTX_COLOR=$GREEN
fi

printf "%b%s%b | \$%s | IN:%s OUT:%s | %b%s%%%b\n" \
    "$CYAN" "$MODEL" "$NC" \
    "$COST" "$INPUT_TOKENS" "$OUTPUT_TOKENS" \
    "$CTX_COLOR" "$CONTEXT_USED" "$NC"
