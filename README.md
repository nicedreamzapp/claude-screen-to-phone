# 📱 Claude Screen to Phone

> **Control Claude Code from your iPhone. Get screenshots, screen recordings, and videos sent straight to your Messages app — automatically.**

Built with love on a Mac. Powered by Claude Code + iMessage + AppleScript magic. 🧠✨

---

## 🤯 What This Does

You text Claude. Claude does things on your computer. Claude texts you back — with **receipts**.

| You say 📲 | Claude does 💻 | You get 📥 |
|---|---|---|
| "grab me that article image" | Screenshots the image | 📸 Photo in iMessage |
| "screen record what you're doing" | Records the screen | 🎥 Video in iMessage |
| "summarize that YouTube video" | Watches + summarizes | 📝 Text reply |
| "make me a highlight reel" | Edits + compresses | 🎬 Produced video |
| "go find X and send it to me" | Browses + captures | 📦 Whatever you asked for |

---

## 🏗️ How It Works

```
Your iPhone 📲
     │
     ▼  iMessage
Your Mac 💻 (Claude Code running)
     │
     ├── reads your message from Messages SQLite DB
     ├── executes the task (browse, record, screenshot, edit)
     └── sends result back → text / image / video
```

Claude reads incoming messages directly from `~/Library/Messages/chat.db` — no server, no API, no internet middleman. 100% local. 🔒

---

## ⚡ Quick Start

### Requirements
- 🍎 Mac (macOS 12+)
- 📱 iPhone with iMessage
- 🤖 [Claude Code](https://claude.ai/code) installed
- 🍺 `ffmpeg` — `brew install ffmpeg`
- 🐍 Python 3 + deps — `pip install -r studio-record/requirements.txt`
- ✅ Messages app signed into your Apple ID

### Setup (60 seconds)

```bash
# 1. Clone the repo
git clone https://github.com/nicedreamzapp/claude-screen-to-phone
cd claude-screen-to-phone

# 2. Run setup — creates config.sh template
bash setup.sh

# 3. Fill in your details
nano config.sh
#   → Set BUDDY to your iPhone number (+15551234567)
#   → Set APPLE_ID_EMAIL to your Apple ID

# 4. Run setup again to install
bash setup.sh

# 5. Test it
~/.claude/imessage-send.sh "Hello from Claude! 👋"
```

---

## 📂 What's Inside

```
📁 scripts/
   📜 imessage-send.sh          — send a text message to your phone
   📜 imessage-send-image.sh    — send an image (PNG/JPG/GIF)
   📜 imessage-send-video.sh    — send a video (auto-compresses if >95MB)
   📜 imessage-toggle.sh        — toggle mobile mode on/off
   📜 imessage-receive.sh       — wait for your reply (polls Messages DB)
   🐍 build_production_video.py — full video editor: silence cut + title card + subtitles

🌐 browser-agent.py              — autonomous browser agent (CDP + MLX/Claude)

📁 studio-record/
   🎬 studio_record.py          — recording app (screen / webcam / PiP)
   📄 requirements.txt          — Python deps
   📄 README.md                 — setup + API docs
   🖼️  backgrounds/              — 32 virtual backgrounds included

📁 examples/
   🎬 uv-jars-example-output.mp4 — produced with this exact pipeline

📄 config.example.sh            — your personal settings template
📄 setup.sh                     — one-command installer
```

---

## 🎬 The Video Pipeline

Claude can build **fully produced videos** from raw screen recordings and send them to your phone:

```
Raw screen recording
       │
       ▼
✂️  Silence cut (keeps only the good parts)
       │
       ▼
🎨  Title card rendered (Pillow — Navy + Cyan style)
       │
       ▼
📝  Subtitles overlaid (timed to speech)
       │
       ▼
🏁  End card added
       │
       ▼
🗜️  Compressed to <95MB for iMessage
       │
       ▼
📲  Sent to your iPhone
```

See `scripts/build_production_video.py` for the full script. Customize title/end cards, branding, subtitle timing — it's all in there.

---

## 🌐 Browser Agent

Autonomous browser agent — Claude controls **Brave** directly via Chrome DevTools Protocol to grab anything from the web before sending it to your phone.

```bash
# Prerequisites: Brave with remote debugging + MLX server running
open -a "Brave Browser" --args --remote-debugging-port=9222
python ~/.local/mlx-native-server/server.py &   # or use cloud Claude

# Run it
python browser-agent.py "Find a cool article about X and screenshot it"
```

**Why it's different from normal browser automation:**

Most tools (Playwright, Selenium, MCP) break on news sites because comment widgets and embedded content live inside cross-origin iframes + Shadow DOM. This agent uses raw CDP primitives that bypass all of that:

```
DOM.getDocument(pierce: true)   → sees through iframes + Shadow DOM
DOM.focus(nodeId)               → focuses any element regardless of origin
Input.insertText(text)          → types into anything
```

**Works with both local AI (Qwen 3.5 122B via MLX) and Claude cloud** — just point it at the right server.

---

## 🎬 Studio Record

The repo includes **Studio Record** — a full dark-glass recording app with a built-in HTTP API so Claude can control it autonomously.

```bash
# Install deps
cd studio-record && pip install -r requirements.txt

# Download the ML model for background removal
curl -L -o studio-record/selfie_segmenter.tflite \
  "https://storage.googleapis.com/mediapipe-models/image_segmenter/selfie_segmenter/float16/latest/selfie_segmenter.tflite"

# Launch it
python studio-record/studio_record.py
```

Once running, Claude can control it:
```bash
curl -X POST http://127.0.0.1:17494/start?mode=screen   # 🔴 start recording
curl -X POST http://127.0.0.1:17494/stop                 # ⏹️  stop + save
curl http://127.0.0.1:17494/status                       # 📊 check status
```

**Recording modes:** `screen` | `face` | `screen_face` (PiP)
**32 virtual backgrounds** included — swap live in the UI 🌅

---

## 🔧 Permissions You'll Need

Grant these in **System Settings → Privacy & Security**:

| Permission | Why |
|---|---|
| 📂 **Full Disk Access** → Terminal/Claude | Read `~/Library/Messages/chat.db` |
| ♿ **Accessibility** → Terminal/Claude | Control Messages app to send |
| 🎬 **Screen Recording** → Terminal/Claude | Capture your screen |

---

## 🤖 Wiring Into Claude Code

Add this to your `~/.claude/CLAUDE.md` so Claude knows how to use the pipeline:

```markdown
## 📱 iMessage Agent

Send/receive iMessages to control Claude from your phone.

### Send a message:
bash ~/.claude/imessage-send.sh "Your message"

### Send an image:
bash ~/.claude/imessage-send-image.sh /path/to/image.png

### Send a video:
bash ~/.claude/imessage-send-video.sh /path/to/video.mp4

### Wait for reply:
bash ~/.claude/imessage-receive.sh

### Toggle mobile mode:
bash ~/.claude/imessage-toggle.sh
```

---

## 💡 Pro Tips

- 🔄 **Loop it** — Claude can run in a send → wait → reply loop indefinitely. Text "stop" to end it.
- 📹 **Screen recordings** — Claude uses the Studio Record API (`http://127.0.0.1:17494`) to start/stop recordings programmatically.
- 🗜️ **Video compression** — `imessage-send-video.sh` auto-compresses anything over 95MB using Apple's hardware encoder (`h264_videotoolbox`) — fast and quality.
- 🔒 **`config.sh` is gitignored** — your phone number and email never leave your machine.

---

## 🐛 Troubleshooting

**Messages won't send?**
→ Check Accessibility permissions for Terminal in System Settings.

**Video not arriving on phone?**
→ The Finder clipboard trick is required — direct AppleScript file sends fail silently on iMessage. The script handles this automatically.

**`chat.db` permission denied?**
→ Grant Full Disk Access to Terminal (or your Claude Code app).

**Receive script times out immediately?**
→ Double-check `BUDDY` and `APPLE_ID_EMAIL` in `config.sh` match what's in your Messages conversations.

---

## 🙌 Credit

Built by **[@nicedreamzapps](https://github.com/nicedreamzapp)** using Claude Code.

> *"I built this because I wanted Claude to be my assistant even when I'm away from my computer — and I wanted receipts."* 📲

---

⭐ Star this if it helped you | 🐛 [Open an issue](../../issues) if something's broken | 🍴 Fork it and make it yours
