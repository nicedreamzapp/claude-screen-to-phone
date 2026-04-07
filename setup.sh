#!/bin/bash
# ─────────────────────────────────────────────
#  Claude Screen to Phone — One-Time Setup
# ─────────────────────────────────────────────

set -e
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

echo ""
echo "📱 Claude Screen to Phone — Setup"
echo "──────────────────────────────────"

# 1. Create config.sh from example
if [ ! -f "$REPO_DIR/config.sh" ]; then
    cp "$REPO_DIR/config.example.sh" "$REPO_DIR/config.sh"
    echo "✅ Created config.sh from template"
    echo ""
    echo "⚠️  Open config.sh and fill in:"
    echo "   • Your iPhone number (BUDDY)"
    echo "   • Your Apple ID email (APPLE_ID_EMAIL)"
    echo "   • ffmpeg path (run: which ffmpeg)"
    echo ""
    echo "Then re-run this script to finish setup."
    exit 0
else
    echo "✅ config.sh already exists"
fi

# 2. Make all scripts executable
chmod +x "$REPO_DIR/scripts/"*.sh
echo "✅ Scripts marked executable"

# 3. Install scripts to ~/.claude/ so Claude Code can find them
CLAUDE_DIR="$HOME/.claude"
mkdir -p "$CLAUDE_DIR"

for script in imessage-send.sh imessage-send-image.sh imessage-send-video.sh \
              imessage-toggle.sh imessage-receive.sh imessage-ask.sh \
              imessage-agent.sh statusline.sh; do
    cp "$REPO_DIR/scripts/$script" "$CLAUDE_DIR/$script"
    chmod +x "$CLAUDE_DIR/$script"
done
echo "✅ Scripts installed to ~/.claude/"

# 3b. Wire statusline into Claude Code's settings.json (additive, preserves existing keys)
SETTINGS="$CLAUDE_DIR/settings.json"
if command -v jq >/dev/null 2>&1; then
    if [ -f "$SETTINGS" ]; then
        TMP=$(mktemp)
        jq '.statusLine = {"type":"command","command":"bash ~/.claude/statusline.sh"}' \
            "$SETTINGS" > "$TMP" && mv "$TMP" "$SETTINGS"
    else
        echo '{"statusLine":{"type":"command","command":"bash ~/.claude/statusline.sh"}}' \
            | jq . > "$SETTINGS"
    fi
    echo "✅ Statusline wired into ~/.claude/settings.json"
else
    echo "⚠️  jq not found — skipped settings.json update. Install with: brew install jq"
fi

# 4. Copy config to ~/.claude/ so scripts can find it
cp "$REPO_DIR/config.sh" "$CLAUDE_DIR/screen-to-phone-config.sh"
echo "✅ Config installed to ~/.claude/"

echo ""
echo "🎉 Setup complete!"
echo ""
echo "Try it:"
echo "  ~/.claude/imessage-send.sh 'Hello from Claude!'"
echo "  ~/.claude/imessage-send-image.sh /path/to/image.png"
echo "  ~/.claude/imessage-send-video.sh /path/to/video.mp4"
echo ""
echo "Add this to your Claude Code CLAUDE.md to enable phone control:"
echo ""
echo '  ## iMessage Agent'
echo '  bash ~/.claude/imessage-toggle.sh   # toggle on/off'
echo '  bash ~/.claude/imessage-send.sh "msg"'
echo '  bash ~/.claude/imessage-receive.sh  # wait for reply'
