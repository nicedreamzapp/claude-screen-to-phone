#!/bin/bash
# Send an image via iMessage — navigates to correct conversation first
# ─────────────────────────────────────────────
CONFIG="${STP_CONFIG:-$HOME/.claude/screen-to-phone-config.sh}"
[ ! -f "$CONFIG" ] && CONFIG="$(dirname "$0")/../config.sh"
if [ ! -f "$CONFIG" ]; then echo "❌ config.sh not found. Run setup.sh first."; exit 1; fi
# shellcheck disable=SC1090
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

# The file path and buddy id come in as ARGUMENTS so a quote in either cannot
# close an AppleScript string and run code. The heredoc stays unquoted only so
# $FILETYPE expands - that value is a fixed AppleScript class literal chosen by
# the `case` statement above, never user input.
osascript - "$FILE" "$BUDDY" << APPLESCRIPT
on run argv
set filePath to item 1 of argv
set buddyID to item 2 of argv
set prevApp to path to frontmost application as text

-- Copy image to clipboard
set the clipboard to (read POSIX file filePath as $FILETYPE)
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
do shell script "open " & quoted form of ("imessage://" & buddyID)
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
end run
APPLESCRIPT

echo "Sent: $FILE"
