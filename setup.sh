#!/bin/bash
# ─────────────────────────────────────────────
#  Claude Screen to Phone — Setup
#  Installs every script into ~/.claude/, creates your config the first time,
#  and wires the statusline into ~/.claude/settings.json if you have none.
#  Safe to run again: it never overwrites a filled-in config or your statusLine.
# ─────────────────────────────────────────────

set -euo pipefail
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
CONFIG_DEST="$CLAUDE_DIR/screen-to-phone-config.sh"
MANIFEST="$CLAUDE_DIR/.screen-to-phone-installed"
SETTINGS="$CLAUDE_DIR/settings.json"
STATUSLINE_CMD='bash ~/.claude/statusline.sh'

SCRIPTS=(
    imessage-send.sh imessage-send-image.sh imessage-send-video.sh
    imessage-toggle.sh imessage-receive.sh imessage-listener.sh
    imessage-ask.sh imessage-agent.sh statusline.sh
)

echo ""
echo "📱 Claude Screen to Phone — Setup"
echo "──────────────────────────────────"

mkdir -p "$CLAUDE_DIR"

# 1. Install the scripts the toggle, ask and statusline need
for script in "${SCRIPTS[@]}"; do
    cp "$REPO_DIR/scripts/$script" "$CLAUDE_DIR/$script"
    chmod +x "$CLAUDE_DIR/$script"
done
# The manifest tells uninstall.sh exactly what to remove
SETTINGS_MARK=""
if [ -f "$MANIFEST" ] && grep -qx '#settings-created' "$MANIFEST"; then
    SETTINGS_MARK='#settings-created'
fi
printf '%s\n' "${SCRIPTS[@]}" > "$MANIFEST"
if [ -n "$SETTINGS_MARK" ]; then echo "$SETTINGS_MARK" >> "$MANIFEST"; fi
echo "✅ Scripts installed to ~/.claude/"

# 2. Config: create it once, never overwrite one that is already there
NEW_CONFIG=0
if [ ! -f "$CONFIG_DEST" ]; then
    if [ -f "$REPO_DIR/config.sh" ]; then
        cp "$REPO_DIR/config.sh" "$CONFIG_DEST"
    else
        cp "$REPO_DIR/config.example.sh" "$CONFIG_DEST"
    fi
    chmod 600 "$CONFIG_DEST"
    NEW_CONFIG=1
    echo "✅ Created ~/.claude/screen-to-phone-config.sh"
else
    echo "✅ Kept your existing ~/.claude/screen-to-phone-config.sh"
fi

# 3. Statusline: only if settings.json has no statusLine yet (jq if present, else plutil)
has_statusline() {
    [ -f "$SETTINGS" ] || return 1
    if command -v jq >/dev/null 2>&1; then
        jq -e 'has("statusLine")' "$SETTINGS" >/dev/null 2>&1
    else
        plutil -extract statusLine json -o - "$SETTINGS" >/dev/null 2>&1
    fi
}

if [ ! -f "$SETTINGS" ]; then
    printf '{\n  "statusLine": {\n    "type": "command",\n    "command": "%s"\n  }\n}\n' "$STATUSLINE_CMD" > "$SETTINGS"
    if ! grep -qx '#settings-created' "$MANIFEST"; then echo '#settings-created' >> "$MANIFEST"; fi
    echo "✅ Statusline wired into ~/.claude/settings.json"
elif has_statusline; then
    echo "✅ You already have a statusLine in ~/.claude/settings.json, left it alone"
else
    TMP=$(mktemp)
    OK=0
    if command -v jq >/dev/null 2>&1; then
        jq --arg c "$STATUSLINE_CMD" '.statusLine = {"type":"command","command":$c}' "$SETTINGS" > "$TMP" 2>/dev/null && OK=1
    else
        cp "$SETTINGS" "$TMP"
        plutil -insert statusLine -json "{\"type\":\"command\",\"command\":\"$STATUSLINE_CMD\"}" "$TMP" 2>/dev/null && OK=1
    fi
    if [ "$OK" = "1" ]; then
        cat "$TMP" > "$SETTINGS"
        echo "✅ Statusline wired into ~/.claude/settings.json"
    else
        echo "⚠️  Could not read ~/.claude/settings.json, left it alone. Add the statusLine by hand: $STATUSLINE_CMD"
    fi
    rm -f "$TMP"
fi

echo ""
echo "🎉 Setup complete!"
if [ "$NEW_CONFIG" = "1" ]; then
    echo ""
    echo "⚠️  Next: open ~/.claude/screen-to-phone-config.sh and fill in"
    echo "   • BUDDY: your iPhone number, with country code"
    echo "   • APPLE_ID_EMAIL: your Apple ID"
    echo "   • FFMPEG: the path from: which ffmpeg"
fi
echo ""
echo "Try it:"
echo "  ~/.claude/imessage-send.sh 'Hello from Claude!'"
echo "  bash ~/.claude/imessage-toggle.sh   # Mobile Mode on/off"
