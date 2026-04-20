#!/bin/bash
# Send an image via iMessage — navigates to correct conversation first
# ─────────────────────────────────────────────
CONFIG="$(dirname "$0")/../config.sh"
[ ! -f "$CONFIG" ] && CONFIG="$HOME/.claude/screen-to-phone-config.sh"
if [ ! -f "$CONFIG" ]; then echo "❌ config.sh not found. Run setup.sh first."; exit 1; fi
source "$CONFIG"

FILE="$1"

if [ -z "$FILE" ]; then echo "Usage: imessage-send-image.sh '/path/to/image'"; exit 1; fi
if [ ! -f "$FILE" ]; then echo "File not found: $FILE"; exit 1; fi

FILE=$(realpath "$FILE")
EXT=$(echo "${FILE##*.}" | tr '[:upper:]' '[:lower:]')

case "$EXT" in
    png)        FILETYPE="«class PNGf»" ;;
    jpg|jpeg)   FILETYPE="JPEG picture" ;;
    gif)        FILETYPE="«class GIFf»" ;;
    *)          FILETYPE="«class PNGf»" ;;
esac

osascript << APPLESCRIPT
set prevApp to path to frontmost application as text

-- Copy image to clipboard
set the clipboard to (read POSIX file "$FILE" as $FILETYPE)
delay 0.3

-- Pre-position: launch Messages hidden and move any existing window off-screen
tell application "Messages" to launch
delay 0.5
tell application "System Events"
    tell process "Messages"
        -- Move ALL windows off-screen before we do anything visible
        repeat with w in windows
            try
                set position of w to {-9999, -9999}
            end try
        end repeat
    end tell
end tell
delay 0.2

-- Now open the conversation — window is already off-screen
do shell script "open 'imessage://$BUDDY'"
delay 1.5

-- Make sure the new window is also off-screen
tell application "System Events"
    tell process "Messages"
        repeat with w in windows
            try
                set position of w to {-9999, -9999}
            end try
        end repeat
        set frontmost to true
        delay 0.2
        -- Paste and send
        keystroke "v" using command down
        delay 0.5
        key code 36
        delay 0.5
    end tell
end tell

-- Hide Messages (keeps windows off-screen, no animation) and switch back
tell application "System Events" to set visible of process "Messages" to false
delay 0.1
activate application prevApp
APPLESCRIPT

echo "Sent: $FILE"
