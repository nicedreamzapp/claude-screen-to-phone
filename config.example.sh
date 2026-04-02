#!/bin/bash
# ─────────────────────────────────────────────
#  Claude Screen to Phone — Configuration
#  Copy this file to config.sh and fill it in.
#  config.sh is gitignored — your info stays private.
# ─────────────────────────────────────────────

# Your iPhone number (include country code, e.g. +15551234567)
BUDDY="+1XXXXXXXXXX"

# Your Apple ID email (used as fallback chat identifier)
APPLE_ID_EMAIL="you@example.com"

# Path to ffmpeg (install with: brew install ffmpeg)
FFMPEG="/opt/homebrew/bin/ffmpeg"

# Where screen recordings get saved
RECORDINGS_DIR="$HOME/Desktop/Screen Recordings"

# Local TTS server (Voicebox or compatible)
TTS_URL="http://localhost:8000/tts"
