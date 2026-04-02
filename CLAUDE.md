# Claude Screen to Phone — Instructions

## 📱 iMessage Agent

Send and receive iMessages to control Claude from your iPhone and send back text, images, and video.

### Setup (first time)
Run `bash setup.sh` and fill in `config.sh` with your phone number before using any of these.

### Send a text message
```bash
bash ~/.claude/imessage-send.sh "Your message here"
```

### Send an image
```bash
bash ~/.claude/imessage-send-image.sh /path/to/image.png
```

### Send a video (auto-compresses if over 95MB)
```bash
bash ~/.claude/imessage-send-video.sh /path/to/video.mp4
```

### Toggle mobile mode on/off
```bash
bash ~/.claude/imessage-toggle.sh
```

### Wait for a reply from the phone (polls up to 5 minutes)
```bash
bash ~/.claude/imessage-receive.sh
```

### Full send → wait → reply loop
1. Send a message
2. Immediately run `imessage-receive.sh` to wait for the reply
3. Process the reply and respond
4. Repeat until user says "stop" or "quit"

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

## 🌐 Browser Agent

Autonomous browser control via Chrome DevTools Protocol. Use this to grab content from the web before sending to phone.

```bash
# Brave must be running with remote debugging
open -a "Brave Browser" --args --remote-debugging-port=9222

# Run a task
python browser-agent.py "Find an article about X and screenshot it"
```

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
