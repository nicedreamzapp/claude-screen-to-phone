<p align="center">
  <h1 align="center">📱⚡ Claude Screen to Phone</h1>
  <p align="center">
    <strong>Your iPhone is now a keyboard for your Mac.<br>
    Text a command. The AI builds it. iMessage delivers the receipts.</strong>
  </p>
  <p align="center">
    <a href="https://github.com/nicedreamzapp/claude-screen-to-phone/stargazers"><img src="https://img.shields.io/github/stars/nicedreamzapp/claude-screen-to-phone?style=for-the-badge&logo=github&color=f5c542&labelColor=1f2328" alt="GitHub stars"></a>
    <a href="#-what-this-does"><img src="https://img.shields.io/badge/📱_iMessage-Native-25D366?style=for-the-badge" alt="iMessage Native"></a>
    <a href="#-how-it-works"><img src="https://img.shields.io/badge/🔒_Privacy-100%25_Local-success?style=for-the-badge" alt="100% Local"></a>
    <a href="#-what-this-does"><img src="https://img.shields.io/badge/📸_Sends-Text_·_Images_·_Video-blue?style=for-the-badge" alt="Text · Images · Video"></a>
    <a href="#-mobile-mode--your-phone-is-the-keyboard"><img src="https://img.shields.io/badge/🎤_Mobile_Mode-Remote_Control-purple?style=for-the-badge" alt="Mobile Mode"></a>
    <a href="#-quick-start"><img src="https://img.shields.io/badge/⚡_Setup-60_seconds-orange?style=for-the-badge" alt="60-second setup"></a>
    <a href="LICENSE"><img src="https://img.shields.io/badge/📜_License-MIT-yellow?style=for-the-badge" alt="MIT"></a>
  </p>
  <p align="center">
    <em>Built by <a href="https://x.com/divinetribevape">Matt Macosko</a> in Arcata, CA. Off the screen, still getting work done.</em>
  </p>
  <p align="center">
    <a href="#-the-big-claim">💥 The Claim</a> ·
    <a href="#-what-this-does">🤯 What It Does</a> ·
    <a href="#-how-it-works">🏗️ How</a> ·
    <a href="#-mobile-mode--your-phone-is-the-keyboard">📱 Mobile Mode</a> ·
    <a href="#-quick-start">⚡ Setup</a> ·
    <a href="#-the-complete-stack">🧩 The Stack</a>
  </p>
</p>

---

> ## 💥 The Big Claim
>
> **You are not chained to your desk anymore.**
>
> Text `"pull the latest, run tests, send me a screenshot of the dashboard"` from a Jacuzzi. The Mac does it — locally, privately, with a real AI driving. A minute later your phone buzzes with the results in Messages. No Telegram bot. No $20/mo SaaS. No cloud API reading your commands. Just iMessage, AppleScript, and a bash daemon that turns your iPhone into a full remote for Claude Code.
>
> **Free yourself from the chair. Your phone is now the keyboard.** 🛋️📱→💻

---

> 🧩 **Part of a 4-repo local-first ambient-computing stack.** Runs great standalone; wired up with the BRAIN ([`claude-code-local`](https://github.com/nicedreamzapp/claude-code-local)) you get Claude Code with local AI driven from your phone — fully on-device, zero cloud.

---

## 💬 iMessage — No Extra Apps Required

If you have a Mac and an iPhone, you already have iMessage. It's built in, encrypted, and the app you use every day. This project is a documented, working method for sending text, images, and video from your Mac to your iPhone using nothing but iMessage — no Telegram, no Discord, no third-party services required.

### 📎 How file sending actually works

Sending file attachments via AppleScript on macOS Sequoia is unreliable with the standard approach. The `send file to buddy` command fails silently — it returns success but the attachment never arrives on the phone.

**The method that works:**

```
1. Finder selects the file and copies it  (Cmd+C)
   → creates the correct clipboard type Messages accepts
2. open imessage://+1XXXXXXXXXX
   → opens/focuses the conversation
3. Cmd+V paste → Enter to send
   → delivered ✅
```

This works for images and video files. Video files over 95MB are automatically compressed first using Apple's hardware encoder so they fit within iMessage limits.

That's it. No extra apps. No accounts. No monthly fees. 🍎

---

## 🤯 What This Does

You text Claude. Claude does things on your computer. Claude texts you back — with **receipts**.

| You say 📲 | Claude does 💻 | You get 📥 |
|---|---|---|
| "grab me that article image" | Screenshots the image | 📸 Photo in iMessage |
| "screen record what you're doing" | Records the screen | 🎥 Video in iMessage |
| "summarize that YouTube video" | Watches + summarizes | 📝 Text reply |
| "make me a highlight reel" | Edits + compresses | 🎬 Produced video |
| "pull the repo and run tests" | Shell + git + reports | 💬 Pass/fail summary |
| "go find X and send it to me" | Browses + captures | 📦 Whatever you asked for |

---

## 📱 Mobile Mode — Your Phone Is the Keyboard

**This is the part that flips the whole thing around.** Toggle mobile mode on and a background daemon (`imessage-listener.sh`) starts watching `~/Library/Messages/chat.db` every two seconds. When a text arrives from your phone, it gets pasted **directly into the Terminal tab** where Claude Code (or the browser agent) is running — as if you typed it yourself. Claude replies? A short summary comes back to your phone via `imessage-send.sh`.

```
        🛋️  COUCH / JACUZZI / ANYWHERE                🖥️  DESK (ASLEEP BEHIND YOU)
                      │                                         │
                      │  "commit the changes and push"          │
                      ▼                                         │
              📱 iPhone iMessage   ───────────────────────►  💻 Mac (awake — caffeinated)
                      ▲                                         │
                      │                                         ├── listener.sh reads chat.db
                      │                                         ├── pastes into Claude Code
                      │                                         ├── Claude runs git add/commit/push
                      │                                         │   + shell + edit + MCP tools
                      │  "✅ pushed to main (7 files)"          ├── texts the summary back
                      └─────────────────────────────────────────┘
```

**Short-reply contract:** phone replies are capped at 3 sentences so you can read them at a glance. The Terminal keeps the long transcript.

**Turn it on, walk away:**
```bash
bash ~/.claude/imessage-toggle.sh        # captures THIS Terminal tab as the target
# from here: your phone is the keyboard. text "stop" from the phone to turn it off.
```

Pre-built launchers (`📱 Claude Phone.command`, `📱 Gemma Phone.command`) do the whole dance in one double-click: clear stale state → capture TTY → start listener → `caffeinate -w $$` so the Mac won't sleep → exec Claude Code (or the browser agent) with `--dangerously-skip-permissions` so no trust prompts block remote use.

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

### Toggle mobile mode (starts the background listener):
bash ~/.claude/imessage-toggle.sh
```

### 🎤 Mobile Mode — phone becomes the keyboard

`imessage-toggle.sh` starts a background daemon (`imessage-listener.sh`) that polls `~/Library/Messages/chat.db` every 2 seconds and pastes incoming texts directly into the captured Terminal tab. Double-click a launcher, walk away, text commands from the couch.

- `imessage-startup-lock` — daemon buffers texts until the app finishes starting (no more half-pasted messages)
- `imessage-ask-active` — `imessage-ask.sh` consumes the next reply for its Y/N prompts instead of the daemon forwarding it
- Text "stop" from the phone → daemon exits cleanly

### 🧰 Remote building from the phone

The browser agent now has **general-purpose tools** (`shell`, `read_file`, `write_file`) alongside browser + media tools, so you can text it build instructions — "pull my repo and run tests," "restart the server," "show me what's in `~/Desktop/Screen Recordings`" — and it actually executes them and texts the result back.

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

## 🧩 The Complete Stack

`claude-screen-to-phone` is the **phone piece**. Pairs with three sibling repos for the full ambient-computing setup — each stands alone, no mouse-scroll table needed:

#### 📱 claude-screen-to-phone — **Remote** *(you are here)*
Your iPhone becomes a full Claude Code terminal. Text any command — git ops, shell, file edits, deploys, web scraping, anything Claude can do — and get results back in Messages. Text, screenshots, screen recordings, produced videos, all of it.

#### 🤖 [claude-code-local](https://github.com/nicedreamzapp/claude-code-local) — **Brain**
Claude Code running on local AI (Gemma 31B / Llama 70B / Qwen 122B). Zero cloud, 65 tok/s on Apple Silicon.

#### 🎤 [NarrateClaude](https://github.com/nicedreamzapp/NarrateClaude) — **Ears + Mouth**
Talk to Claude, hear replies in your cloned voice. Fully on-device hands-free loop.

#### 🌐 [browser-agent](https://github.com/nicedreamzapp/browser-agent) — **Hands**
Drives Brave via Chrome DevTools Protocol. Handles iframes, Shadow DOM, ProseMirror.

**Pair this repo with the brain** ([`claude-code-local`](https://github.com/nicedreamzapp/claude-code-local)) and you get local-AI Claude Code driven from your phone — fully on-device, zero cloud latency, zero API fees.

---

## 🙌 Credit

Built by **[@nicedreamzapps](https://github.com/nicedreamzapp)** using Claude Code.

> *"I built this because I wanted Claude to be my assistant even when I'm away from my computer — and I wanted receipts."* 📲

---

⭐ Star this if it helped you | 🐛 [Open an issue](../../issues) if something's broken | 🍴 Fork it and make it yours
