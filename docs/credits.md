---
title: Credits and upstream projects
description: The upstream projects Claude Screen to Phone is built on - Anthropic Claude Code, Apple Messages and AppleScript, Chrome DevTools Protocol, ffmpeg, MediaPipe, CustomTkinter, Flask, OpenCV and more.
---

# Credits

The scripts in this repo were written by Matt Macosko ([@nicedreamzapp](https://github.com/nicedreamzapp)) and are MIT licensed. They are glue around a lot of other people's work. None of the projects below are part of this repo or written by its author.

| Project | Used for | By |
|---|---|---|
| [Claude Code](https://claude.ai/code) | The agent the whole thing is built around | Anthropic |
| Messages, AppleScript, System Events | Transport and UI automation | Apple |
| Vision framework | Person segmentation in Studio Record | Apple |
| [ffmpeg](https://ffmpeg.org/) | Video compression, screen capture, editing | FFmpeg developers |
| [SQLite](https://sqlite.org/) | Reading `chat.db` | SQLite developers |
| [jq](https://jqlang.github.io/jq/) | Statusline JSON and `settings.json` edits (the installer falls back to macOS `plutil`) | jq developers |
| [MediaPipe](https://github.com/google-ai-edge/mediapipe) | `selfie_segmenter.tflite` model referenced by Studio Record | Google |
| [CustomTkinter](https://github.com/TomSchimansky/CustomTkinter) | Studio Record UI | Tom Schimansky |
| [Flask](https://flask.palletsprojects.com/) | Studio Record HTTP API | Pallets |
| [OpenCV](https://opencv.org/) | Camera capture and compositing | OpenCV team |
| [NumPy](https://numpy.org/) | Frame math | NumPy developers |
| [Pillow](https://python-pillow.org/) | Thumbnails and title cards | Pillow contributors |
| [sounddevice](https://github.com/spatialaudio/python-sounddevice) | Microphone capture | Matthias Geier and contributors |
| [PyObjC](https://github.com/ronaldoussoren/pyobjc) | Calling Apple Vision from Python | Ronald Oussoren and contributors |
| [MkDocs](https://www.mkdocs.org/) and [Material for MkDocs](https://squidfunk.github.io/mkdocs-material/) | This documentation site | Tom Christie and contributors; Martin Donath |

The browser agent moved to [browser-agent](https://github.com/nicedreamzapp/browser-agent); its credits (Chrome DevTools Protocol, websockets, MLX) are listed there.

See also [`CREDITS.md`](https://github.com/nicedreamzapp/claude-screen-to-phone/blob/main/CREDITS.md) in the repo. If your work should be listed and isn't, [open an issue](https://github.com/nicedreamzapp/claude-screen-to-phone/issues).
