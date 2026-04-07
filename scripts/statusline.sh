#!/bin/bash
# Claude Code statusline:
#   [AGENT TAG] [context bar] [pct%]  [📱 Mobile Mode ON/OFF]
#
# - Reads $CLAUDE_SESSION_LABEL exported by your launcher to render an agent tag
#   (e.g. "Llama 70B · Local" → [LLAMA 70B]). Add your own mappings below.
# - Context bar color tiers: green <40%, cyan 40-69%, yellow 70-89%, red 90%+.
# - Mobile mode flag is the same file imessage-toggle.sh creates.

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
BOLD="\033[1m"

pct_int=$(printf "%.0f" "$used_pct")

if   awk "BEGIN { exit !($used_pct >= 90) }"; then CLR="$R"
elif awk "BEGIN { exit !($used_pct >= 70) }"; then CLR="$Y"
elif awk "BEGIN { exit !($used_pct >= 40) }"; then CLR="$C"
else                                                CLR="$G"
fi

# 10-char shaded bar
BAR_WIDTH=10
filled=$(awk "BEGIN { printf \"%.0f\", ($used_pct / 100) * $BAR_WIDTH }")
empty=$((BAR_WIDTH - filled))
bar=""
for ((i=0; i<filled; i++)); do bar+="█"; done
for ((i=0; i<empty; i++)); do bar+="░"; done

# Agent tag from CLAUDE_SESSION_LABEL — customize the case for your launchers
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
if [ -n "$AGENT" ]; then
    AGENT_TAG="${PURPLE}${BOLD}[${AGENT}]${RST} "
else
    AGENT_TAG=""
fi

# iMessage agent flag — same path imessage-toggle.sh writes
IBLUE="\033[38;2;0;122;255m"
IGRAY="\033[38;2;80;80;90m"
IM_FLAG="$HOME/.claude/imessage-agent-on"
if [ -f "$IM_FLAG" ]; then
    IM="${IBLUE}${BOLD}📱 Mobile Mode ON${RST}"
else
    IM="${IGRAY}📱 Mobile Mode OFF${RST}"
fi

printf "${AGENT_TAG}${CLR}${bar}${RST} ${DIM}${pct_int}%%${RST}  ${IM}"
