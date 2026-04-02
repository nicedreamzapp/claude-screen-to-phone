#!/bin/bash
# Toggle iMessage / Mobile Mode on or off
# ─────────────────────────────────────────────
FLAG="$HOME/.claude/imessage-agent-on"

if [ -f "$FLAG" ]; then
    rm "$FLAG"
    echo "📱 Mobile Mode OFF"
else
    touch "$FLAG"
    echo "📱 Mobile Mode ON"
fi
