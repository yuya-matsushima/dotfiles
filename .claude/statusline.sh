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

# Read current effort level from Claude Code settings.
# The statusline JSON payload does not expose effortLevel, so we read it
# directly from the user's settings file (updated by /effort).
SETTINGS_PATH="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/settings.json"
if [ -f "$SETTINGS_PATH" ]; then
    EFFORT=$(jq -r '.effortLevel // "default"' "$SETTINGS_PATH" 2>/dev/null || echo "default")
else
    EFFORT="default"
fi

# Advisor tool status.
# The statusline JSON payload does not expose the advisor, so we resolve it
# ourselves (highest priority first):
#   1. CLAUDE_CODE_DISABLE_ADVISOR_TOOL env -> off
#   2. --advisor <model> on the claude process (found by walking up ps)
#   3. advisorModel in settings (project local > project > user)
# This shows what is *configured*, not whether the server actually enabled it.
find_advisor_flag() {
    pid=$PPID
    for _ in 1 2 3 4 5 6; do
        [ -z "$pid" ] || [ "$pid" -le 1 ] && return
        args=$(ps -o args= -p "$pid" 2>/dev/null)
        # Only inspect the claude process itself (first word is .../claude),
        # so shells whose command text merely mentions --advisor are ignored.
        case "${args%% *}" in
            claude|*/claude)
                case "$args" in
                    *--advisor=*)
                        echo "$args" | sed -E 's/.*--advisor=([^ ]+).*/\1/' ;;
                    *--advisor\ *)
                        echo "$args" | sed -E 's/.*--advisor +([^ ]+).*/\1/' ;;
                esac
                return ;;
        esac
        pid=$(ps -o ppid= -p "$pid" 2>/dev/null | tr -d ' ')
    done
}

read_advisor_setting() {
    [ -f "$1" ] && jq -r '.advisorModel // empty' "$1" 2>/dev/null
}

# Capability rank per model family (from Claude Code 2.1.317 model table).
# The advisor only activates when its rank >= the main model's rank.
model_rank() {
    case "$1" in
        *fable*)  echo 9 ;;
        *opus*)   echo 7 ;;
        *sonnet*) echo 6 ;;
        *haiku*)  echo 4 ;;
        *)        echo "" ;;
    esac
}

if [ -n "$CLAUDE_CODE_DISABLE_ADVISOR_TOOL" ]; then
    ADVISOR="off"
else
    ADVISOR=$(find_advisor_flag)
    if [ -z "$ADVISOR" ]; then
        PROJECT_DIR=$(echo "$input" | jq -r '.workspace.project_dir // .workspace.current_dir // empty')
        for f in "$PROJECT_DIR/.claude/settings.local.json" \
                 "$PROJECT_DIR/.claude/settings.json" \
                 "$SETTINGS_PATH"; do
            [ -n "$PROJECT_DIR" ] || [ "$f" = "$SETTINGS_PATH" ] || continue
            ADVISOR=$(read_advisor_setting "$f")
            [ -n "$ADVISOR" ] && break
        done
    fi
fi

# ANSI color codes
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
NC='\033[0m'

# Color based on context usage
if [ "${CONTEXT_USED}" -gt 80 ]; then
    CTX_COLOR=$RED
elif [ "${CONTEXT_USED}" -gt 60 ]; then
    CTX_COLOR=$YELLOW
else
    CTX_COLOR=$GREEN
fi

# Color based on effort level
case "$EFFORT" in
    high)   EFFORT_COLOR=$RED ;;
    medium) EFFORT_COLOR=$YELLOW ;;
    low)    EFFORT_COLOR=$GREEN ;;
    *)      EFFORT_COLOR=$CYAN ;;
esac

# Advisor segment: cyan when it can activate, gray when unset, off or outranked.
ADVISOR_SEG=$(printf " | adv:%b-%b" "$GRAY" "$NC")
if [ -n "$ADVISOR" ]; then
    ADVISOR_COLOR=$CYAN
    if [ "$ADVISOR" = "off" ]; then
        ADVISOR_COLOR=$GRAY
    elif [ -z "$CLAUDE_CODE_ENABLE_EXPERIMENTAL_ADVISOR_TOOL" ]; then
        MAIN_RANK=$(model_rank "$(echo "$input" | jq -r '.model.id // empty')")
        ADV_RANK=$(model_rank "$ADVISOR")
        if [ -n "$MAIN_RANK" ] && [ -n "$ADV_RANK" ] && [ "$ADV_RANK" -lt "$MAIN_RANK" ]; then
            ADVISOR_COLOR=$GRAY
        fi
    fi
    ADVISOR_SEG=$(printf " | adv:%b%s%b" "$ADVISOR_COLOR" "$ADVISOR" "$NC")
fi

printf "%b%s%b | \$%s | ⚡%b%s%b%s | IN:%s OUT:%s | %b%s%%%b\n" \
    "$CYAN" "$MODEL" "$NC" \
    "$COST" \
    "$EFFORT_COLOR" "$EFFORT" "$NC" "$ADVISOR_SEG" \
    "$INPUT_TOKENS" "$OUTPUT_TOKENS" \
    "$CTX_COLOR" "$CONTEXT_USED" "$NC"
