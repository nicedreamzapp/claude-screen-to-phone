# 🎬 Studio Record

**A beautiful dark-glass recording app for Mac — screen, webcam, or both. Controllable via HTTP API so Claude can start/stop recordings automatically.**

---

## ✨ Features

- 🖥️ **Screen recording** — capture your full display
- 🎥 **Webcam recording** — with virtual background support
- 🖥️🎥 **Screen + Face** — picture-in-picture mode
- 🌅 **32 virtual backgrounds** — included in `/backgrounds/`
- 🔇 **Background removal** — MediaPipe ML segmentation
- 🤖 **HTTP API** — Claude can control it remotely on port `17494`

---

## ⚡ Setup

### 1. Install Python deps
```bash
cd studio-record
pip install -r requirements.txt
```

### 2. Download the MediaPipe model (required for background removal)
```bash
curl -L -o selfie_segmenter.tflite \
  "https://storage.googleapis.com/mediapipe-models/image_segmenter/selfie_segmenter/float16/latest/selfie_segmenter.tflite"
```
> Place `selfie_segmenter.tflite` in the same folder as `studio_record.py`

### 3. Install ffmpeg
```bash
brew install ffmpeg
```

### 4. Run it
```bash
python studio_record.py
```

Recordings save to `~/Desktop/Screen Recordings/` by default.

---

## 🤖 HTTP API (for Claude Code)

Once running, Studio Record exposes a local API on `http://127.0.0.1:17494`:

```bash
# Start a screen recording
curl -X POST http://127.0.0.1:17494/start?mode=screen

# Start webcam recording
curl -X POST http://127.0.0.1:17494/start?mode=face

# Start screen + face (PiP)
curl -X POST http://127.0.0.1:17494/start?mode=screen_face

# Stop recording
curl -X POST http://127.0.0.1:17494/stop

# Check status
curl http://127.0.0.1:17494/status
```

Claude uses this to autonomously record, stop, then send the video to your phone.

---

## 🎨 Virtual Backgrounds

32 backgrounds included in `backgrounds/` — swap them live in the UI. Add your own JPG/PNG and they'll appear automatically.

---

## 📦 Dependencies

| Package | Purpose |
|---|---|
| `customtkinter` | Modern dark UI framework |
| `Pillow` | Image processing |
| `opencv-python` | Webcam capture |
| `mediapipe` | Background segmentation ML |
| `sounddevice` | Audio capture |
| `flask` | HTTP control API |
| `ffmpeg` (system) | Video encoding |
