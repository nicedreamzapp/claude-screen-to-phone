#!/bin/bash
# Compact statusline: ctx bar + iMessage agent

input=$(cat)
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // 0' 2>/dev/null)
[[ "$used_pct" =~ ^[0-9]+(\.[0-9]+)?$ ]] || used_pct=0

# Colors
R="\033[0;31m"
G="\033[0;32m"
Y="\033[0;33m"
C="\033[0;36m"
DIM="\033[2m"
RST="\033[0m"

pct_int=$(printf "%.0f" "$used_pct")

# Color based on usage
if awk "BEGIN { exit !($used_pct >= 90) }"; then CLR="$R"
elif awk "BEGIN { exit !($used_pct >= 70) }"; then CLR="$Y"
elif awk "BEGIN { exit !($used_pct >= 40) }"; then CLR="$C"
else CLR="$G"
fi

# Compact bar: 10 chars wide, shaded fill
BAR_WIDTH=10
filled=$(awk "BEGIN { printf \"%.0f\", ($used_pct / 100) * $BAR_WIDTH }")
empty=$((BAR_WIDTH - filled))
bar=""
for ((i=0; i<filled; i++)); do bar+="█"; done
for ((i=0; i<empty; i++)); do bar+="░"; done

# Agent label from CLAUDE_SESSION_LABEL exported by desktop launchers
case "$CLAUDE_SESSION_LABEL" in
    "Llama 70B"*)        AGENT="LLAMA 70B"     ;;
    "Gemma 4 Browser"*)  AGENT="GEMMA BROWSER" ;;
    "Gemma 4"*)          AGENT="GEMMA CODE"    ;;
    "Browser Agent"*)    AGENT="BROWSER AGENT" ;;
    "Claude Code"*)      AGENT="CLAUDE CODE"   ;;
    "NarrativeClaude"*)  AGENT="NARRATE"       ;;
    "")                  AGENT=""              ;;
    *)                   AGENT="$CLAUDE_SESSION_LABEL" ;;
esac

PURPLE="\033[38;2;175;130;255m"
BOLD="\033[1m"
if [ -n "$AGENT" ]; then
    AGENT_TAG="${PURPLE}${BOLD}[${AGENT}]${RST} "
else
    AGENT_TAG=""
fi

# iMessage Agent status — iMessage green (#34C759) / blue (#007AFF)
IBLUE="\033[38;2;0;122;255m"
IGREEN="\033[38;2;52;199;89m"
IGRAY="\033[38;2;80;80;90m"

IM_FLAG="$HOME/.claude/imessage-agent-on"
IM_PID_FILE="$HOME/.claude/imessage-listener.pid"
YESALL_FLAG="$HOME/.claude/imessage-yesall"

# Mobile mode is only truly ON if BOTH the flag exists AND the listener daemon
# is alive. A stale flag from a crashed/ended session shouldn't lie to us.
IM_ON=0
if [ -f "$IM_FLAG" ] && [ -f "$IM_PID_FILE" ]; then
    LISTENER_PID=$(cat "$IM_PID_FILE" 2>/dev/null)
    if [ -n "$LISTENER_PID" ] && kill -0 "$LISTENER_PID" 2>/dev/null; then
        IM_ON=1
    fi
fi

if [ "$IM_ON" = "1" ]; then
    IM="${IBLUE}${BOLD}📱 Mobile Mode ON${RST}"
else
    IM="${IGRAY}📱 Mobile Mode OFF${RST}"
fi

printf "${AGENT_TAG}${CLR}${bar}${RST} ${DIM}${pct_int}%%${RST}  ${IM}"
