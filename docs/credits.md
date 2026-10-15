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
| [Chrome DevTools Protocol](https://chromedevtools.github.io/devtools-protocol/) | Browser control in `browser-agent.py` | The Chromium team |
| [Brave Browser](https://brave.com/) | The browser the agent drives | Brave Software |
| [ffmpeg](https://ffmpeg.org/) | Video compression, screen capture, editing | FFmpeg developers |
| [SQLite](https://sqlite.org/) | Reading `chat.db` | SQLite developers |
| [jq](https://jqlang.github.io/jq/) | Statusline JSON and `settings.json` edits | jq developers |
| [websockets](https://github.com/python-websockets/websockets) | CDP connection | Aymeric Augustin and contributors |
| [MediaPipe](https://github.com/google-ai-edge/mediapipe) | `selfie_segmenter.tflite` model referenced by Studio Record | Google |
| [CustomTkinter](https://github.com/TomSchimansky/CustomTkinter) | Studio Record UI | Tom Schimansky |
| [Flask](https://flask.palletsprojects.com/) | Studio Record HTTP API | Pallets |
| [OpenCV](https://opencv.org/) | Camera capture and compositing | OpenCV team |
| [NumPy](https://numpy.org/) | Frame math | NumPy developers |
| [Pillow](https://python-pillow.org/) | Thumbnails and title cards | Pillow contributors |
| [sounddevice](https://github.com/spatialaudio/python-sounddevice) | Microphone capture | Matthias Geier and contributors |
| [PyObjC](https://github.com/ronaldoussoren/pyobjc) | Calling Apple Vision from Python | Ronald Oussoren and contributors |
| [MLX](https://github.com/ml-explore/mlx) | The README says the browser agent was built against a local model served through MLX | Apple machine learning research |
| Qwen 3.5 122B | Model named in the README for the browser agent | Alibaba Qwen team |
| [MkDocs](https://www.mkdocs.org/) and [Material for MkDocs](https://squidfunk.github.io/mkdocs-material/) | This documentation site | Tom Christie and contributors; Martin Donath |

The model server for the browser agent is not in this repo. TODO-VERIFY: the README calls it MLX-based; if it uses [mlx-lm](https://github.com/ml-explore/mlx-lm) or [mlx-vlm](https://github.com/Blaizzy/mlx-vlm), credit them here.

See also [`CREDITS.md`](https://github.com/nicedreamzapp/claude-screen-to-phone/blob/main/CREDITS.md) in the repo. If your work should be listed and isn't, [open an issue](https://github.com/nicedreamzapp/claude-screen-to-phone/issues).
