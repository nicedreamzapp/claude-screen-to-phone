#!/bin/bash
# Send an iMessage to the configured BUDDY. Routes through the SAME conversation path the
# image/video senders use ("imessage://BUDDY" URL scheme + clipboard paste)
# so text and media all land in one thread instead of splitting between
# email-handle and phone-number threads.
DIR="$(cd "$(dirname "$0")" && pwd)"
SENT_LOG="$DIR/imessage-sent-recent"
# Source config
CONFIG="$(dirname "$0")/../config.sh"
[ ! -f "$CONFIG" ] && CONFIG="$HOME/.claude/screen-to-phone-config.sh"
if [ ! -f "$CONFIG" ]; then echo "❌ config.sh not found. Run setup.sh first."; exit 1; fi
source "$CONFIG"
MSG="$1"

# Record this outbound message so imessage-listener.sh can skip its echo (iCloud-sync echoes)
printf '%s\t%s\n' "$(date +%s)" "$MSG" >> "$SENT_LOG"
if [ -f "$SENT_LOG" ]; then
    tail -n 50 "$SENT_LOG" > "${SENT_LOG}.tmp" 2>/dev/null && mv "${SENT_LOG}.tmp" "$SENT_LOG"
fi

osascript <<APPLESCRIPT
set msgText to "$MSG"
set prevApp to path to frontmost application as text
set the clipboard to msgText

tell application "Messages" to launch
delay 0.3
tell application "System Events"
    tell process "Messages"
        repeat with w in windows
            try
                set position of w to {-9999, -9999}
            end try
        end repeat
    end tell
end tell

do shell script "open 'imessage://$BUDDY'"
delay 1.2

tell application "System Events"
    tell process "Messages"
        repeat with w in windows
            try
                set position of w to {-9999, -9999}
            end try
        end repeat
        set frontmost to true
        delay 0.2
        keystroke "v" using command down
        delay 0.3
        key code 36
        delay 0.3
    end tell
    set visible of process "Messages" to false
end tell
delay 0.1
activate application prevApp
APPLESCRIPT
