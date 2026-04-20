# Claude Screen to Phone — Instructions

## 📱 iMessage Agent

Send and receive iMessages to control Claude from your iPhone and send back text, images, and video.

### Setup (first time)
Run `bash setup.sh` and fill in `config.sh` with your phone number before using any of these.

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

`setup.sh` installs it to `~/.claude/statusline.sh` and wires it into `~/.claude/settings.json` automatically.

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

## 🌐 Browser Agent (general-purpose remote agent)

Autonomous agent backed by a local MLX model + Chrome DevTools Protocol. Originally browser-only; now has a much broader tool set so it can be driven from the phone as a real remote-building agent.

```bash
# Brave must be running with remote debugging
open -a "Brave Browser" --args --remote-debugging-port=9222
python browser-agent.py "Find an article about X and screenshot it"
```

### Browser tools
- `navigate(url)`, `snapshot()`, `click(uid)`, `type_text(uid, text)`, `scroll(direction)`, `js(code)`

### System tools (picked FIRST for code/file/deploy work — don't open a browser for shell tasks)
- `shell(cmd, timeout?)` — bash in `$HOME`; stdout+stderr returned (truncated)
- `read_file(path)` — read a text file or list a directory
- `write_file(path, content)` — overwrite a file (creates parent dirs)

### Phone/media tools (require mobile mode on)
- `screenshot()` — current Brave tab as PNG, texted to phone
- `fullscreen_shot()` — full macOS desktop via `screencapture`, texted
- `send_image(url)` — download + text any image URL (rejects `gstatic` thumbnails + dedupes)
- `send_video(url)` — same for video
- `record_start(mode)` / `record_stop()` / `record_status()` — drives Studio Record, auto-texts the `.mp4`

### Auto-notify the phone on task events
When `~/.claude/imessage-agent-on` exists, `done()`, max-steps, and task failures each send a one-line `imessage-send.sh` update to the phone, so you don't need to watch the terminal.

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
