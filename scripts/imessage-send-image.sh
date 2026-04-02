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
set the clipboard to (read POSIX file "$FILE" as $FILETYPE)
delay 0.5
do shell script "open 'imessage://$BUDDY'"
delay 2
tell application "System Events"
    tell process "Messages"
        keystroke "v" using command down
        delay 0.5
        key code 36
        delay 0.5
        keystroke "m" using command down
    end tell
end tell
delay 0.3
tell application "Brave Browser" to activate
APPLESCRIPT

echo "Sent: $FILE"
