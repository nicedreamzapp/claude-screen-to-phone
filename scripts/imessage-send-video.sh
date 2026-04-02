#!/bin/bash
# Send a video via iMessage — auto-compresses if over 95MB
# ─────────────────────────────────────────────
CONFIG="$(dirname "$0")/../config.sh"
[ ! -f "$CONFIG" ] && CONFIG="$HOME/.claude/screen-to-phone-config.sh"
if [ ! -f "$CONFIG" ]; then echo "❌ config.sh not found. Run setup.sh first."; exit 1; fi
source "$CONFIG"

FILE="$1"
MAX_MB=95

if [ -z "$FILE" ]; then echo "Usage: imessage-send-video.sh '/path/to/video.mp4'"; exit 1; fi
if [ ! -f "$FILE" ]; then echo "File not found: $FILE"; exit 1; fi

FILE=$(realpath "$FILE")
SIZE_MB=$(du -m "$FILE" | cut -f1)
echo "Video: $FILE (${SIZE_MB}MB)"

if [ "$SIZE_MB" -gt "$MAX_MB" ]; then
    echo "Compressing to fit iMessage limit..."
    COMPRESSED="/tmp/imessage-video-compressed.mp4"
    DURATION=$(ffprobe -v quiet -show_entries format=duration -of csv=p=0 "$FILE" 2>/dev/null)
    TARGET_KBPS=$(echo "$DURATION $MAX_MB" | awk '{printf "%d", ($2 * 8192) / $1 * 0.85}')
    "$FFMPEG" -y -i "$FILE" \
        -c:v h264_videotoolbox -b:v "${TARGET_KBPS}k" \
        -c:a aac -b:a 128k \
        -movflags +faststart \
        "$COMPRESSED" 2>/dev/null
    if [ $? -ne 0 ]; then echo "Compression failed"; exit 1; fi
    SEND_FILE="$COMPRESSED"
    echo "Compressed to $(du -m "$SEND_FILE" | cut -f1)MB"
else
    SEND_FILE="$FILE"
fi

SEND_FILE=$(realpath "$SEND_FILE")
echo "Sending via iMessage..."

osascript << APPLESCRIPT
tell application "Finder"
    activate
    set theFile to (POSIX file "$SEND_FILE") as alias
    select theFile
    delay 0.3
end tell
tell application "System Events"
    tell process "Finder"
        keystroke "c" using command down
    end tell
end tell
delay 0.5
do shell script "open 'imessage://$BUDDY'"
delay 3
tell application "System Events"
    tell process "Messages"
        set frontmost to true
        delay 0.5
        keystroke "v" using command down
        delay 2
        key code 36
    end tell
end tell
APPLESCRIPT

[ $? -eq 0 ] && echo "Sent: $SEND_FILE" || { echo "Send failed — check Messages app permissions"; exit 1; }
