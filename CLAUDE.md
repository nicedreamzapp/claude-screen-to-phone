# Claude Screen to Phone — Instructions

## 📱 iMessage Agent

Send and receive iMessages to control Claude from your iPhone and send back text, images, and video.

### Setup (first time)
Install with `curl -fsSL https://raw.githubusercontent.com/nicedreamzapp/claude-screen-to-phone/main/install.sh | bash`, then fill in `~/.claude/screen-to-phone-config.sh` with your phone number before using any of these.

### Trigger phrases — toggle mobile mode ON if the user says any of these:
"turn on imessage", "imessage mode", "text mode", "phone mode", "message mode",
"mobile mode", "remote mode", "go mobile", "text me", "send to phone", "imessage on"

### Toggle mobile mode on/off
```bash
bash ~/.claude/imessage-toggle.sh
```
Sends a confirmation iMessage and writes/removes `~/.claude/imessage-agent-on` (the flag the statusline reads).

### Send a text message (no reply needed)
```bash
bash ~/.claude/imessage-send.sh "Done deploying the new code"
```

### Send an image
```bash
bash ~/.claude/imessage-send-image.sh /path/to/image.png
```

### Send a video (auto-compresses if over 95MB)
```bash
bash ~/.claude/imessage-send-video.sh /path/to/video.mp4
```

### Ask a Yes / No / Yes-to-All question (waits for reply)
```bash
bash ~/.claude/imessage-ask.sh "Deploy to prod" "All tests pass"
```
Sends a clean two-line message with `→ Yes / Yes to All / No`. Returns one of:
`YES`, `NO`, `YES_TO_ALL`, `TIMEOUT`, or the user's free-form text reply.
Once the user replies "Yes to All", a flag file is created and all future
`imessage-ask.sh` calls auto-return `YES` until you delete `~/.claude/imessage-yesall`.

### Ask an open-ended question and wait for reply
```bash
bash ~/.claude/imessage-agent.sh "Which color do you want?"
```
Same return semantics as `imessage-ask.sh` (yes/no detection + free-form fallback).

### Wait for a reply from the phone without sending anything
```bash
bash ~/.claude/imessage-receive.sh         # default timeout 5 min
bash ~/.claude/imessage-receive.sh 60      # wait up to 60 seconds
```

### Full send → wait → reply loop
1. Send a message
2. Immediately run `imessage-receive.sh` to wait for the reply
3. Process the reply and respond
4. Repeat until user says "stop" or "quit"

### 🎤 Mobile Mode — remote-control the Terminal from the phone
`imessage-toggle.sh` now spawns a background daemon (`imessage-listener.sh`) that polls `chat.db` every 2 seconds and **pastes incoming texts directly into the captured Terminal tab** via AppleScript. That means: you double-click a launcher, walk away, and from that point on your phone is the keyboard.

- Toggle: `bash ~/.claude/imessage-toggle.sh` (captures the current Terminal's TTY, starts the daemon)
- The daemon honors:
  - `imessage-startup-lock` — buffer (don't forward) while the launcher's app is still starting up
  - `imessage-ask-active` — consume the next reply inside `imessage-ask.sh` instead of forwarding it
- Phone texts "stop" → daemon exits + mobile mode off
- Icon-based launchers (`📱 Claude Phone.command`, `📱 Gemma Phone.command`) in `launchers/` show the pattern: clean state → capture TTY → start listener → `caffeinate -w $$` → exec the app.

### 🚨 CRITICAL — Phone replies must be SHORT (2-3 lines, max 3 sentences)
When mobile mode is ON, messages sent back to the phone MUST be scannable at a glance:
- Hard cap: 3 sentences / 2–3 short lines. No bullet lists, no multi-paragraph output, no code blocks.
- Templates: `"Done — <one line>. Need anything else?"` / `"Couldn't do X — <reason>. Try Y?"`
- Long reasoning stays in the Terminal transcript; only the summary ships to the phone.

## 📊 Statusline (context bar + agent tag + mobile flag)

`scripts/statusline.sh` is a Claude Code statusline that renders, at the bottom of every session:

```
[NARRATE] █████░░░░░ 47%  📱 Mobile Mode OFF
```

- **Agent tag** comes from the `CLAUDE_SESSION_LABEL` env var. Export this from each
  desktop launcher (e.g. `export CLAUDE_SESSION_LABEL='Llama 70B · Local'`) and add a
  matching `case` entry in `statusline.sh` to map it to a short tag.
- **Context bar** is color-tiered: green <40%, cyan 40–69%, yellow 70–89%, red 90%+.
- **Mobile flag** mirrors the file `imessage-toggle.sh` writes — blue when on, gray when off.

The installer copies it to `~/.claude/statusline.sh` and wires it into `~/.claude/settings.json` when no statusLine is set yet.

## 🎬 Studio Record (screen recording)

```bash
# Launch the app
python studio-record/studio_record.py &

# Start recording
curl -X POST http://127.0.0.1:17494/start?mode=screen

# Stop recording (saves to ~/Desktop/Screen Recordings/)
curl -X POST http://127.0.0.1:17494/stop

# Check status
curl http://127.0.0.1:17494/status
```

Recording modes: `screen` | `face` | `screen_face` (picture-in-picture)

## 🌐 Browser Agent (separate repo)

The browser and shell agent lives in [browser-agent](https://github.com/nicedreamzapp/browser-agent). Its broker owns port 9222 as a proxy in front of the real browser and leases each agent its own background tab, so never launch Brave with a debug port from here.

```bash
# one-time: install the broker (clones to ~/.browser-agent)
curl -fsSL https://raw.githubusercontent.com/nicedreamzapp/browser-agent/main/broker/get.sh | bash
# run a task (needs the MLX server from claude-code-local)
python ~/.browser-agent/agent.py "Find an article about X and screenshot it"
```

When `~/.claude/imessage-agent-on` exists, the agent texts results, screenshots and media through `~/.claude/imessage-send*.sh` from this repo.

## 🎥 Full Pipeline Example

When asked to "find something online and send me a video of it":

1. Start Studio Record: `curl -X POST http://127.0.0.1:17494/start?mode=screen`
2. Use browser agent or Brave to navigate and show the content
3. Narrate using `~/.local/bin/speak "..."` if voice is available
4. Stop recording: `curl -X POST http://127.0.0.1:17494/stop`
5. Find the output file in `~/Desktop/Screen Recordings/`
6. Send it: `bash ~/.claude/imessage-send-video.sh /path/to/recording.mp4`

## Voice / Narration

Use `~/.local/bin/speak "text"` to narrate in the user's cloned voice (Voicebox, port 17493).
