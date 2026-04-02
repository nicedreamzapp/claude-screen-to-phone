#!/usr/bin/env python3
"""Studio Record — Modern recording app with virtual backgrounds and sound control."""

import customtkinter as ctk
from PIL import Image, ImageTk, ImageDraw
import cv2
import numpy as np
import mediapipe as mp
from mediapipe.tasks.python import vision, BaseOptions
import subprocess
import sounddevice as sd
import wave
import threading
import time
import os
import glob
from flask import Flask, request, jsonify

# ── Theme — Liquid Glass ──────────────────────────────
ctk.set_appearance_mode('dark')
ctk.set_default_color_theme('dark-blue')

# Glass palette
GLASS_BG = '#0d0d1a'          # deep base
GLASS_PANEL = '#1a1a2e'       # panel fill (simulates frosted layer)
GLASS_SURFACE = '#22223a'     # elevated surface
GLASS_BORDER = '#3a3a5c'      # subtle edge
GLASS_HIGHLIGHT = '#4a4a70'   # hover / active edge
GLASS_TEXT = '#e8e8f4'        # primary text
GLASS_DIM = '#8888aa'         # secondary text
ACCENT = '#00b4d8'
ACCENT_HOVER = '#0090b0'
RED = '#ff3b5c'
GREEN = '#2dd85a'
SAVED = '#40e080'
DIM = '#8888aa'

FFMPEG = '/opt/homebrew/bin/ffmpeg'
BG_DIR = os.path.expanduser('~/Desktop/Screen Recordings/backgrounds')
OUT_DIR = os.path.expanduser('~/Desktop/Screen Recordings')
MODEL_PATH = os.path.expanduser('~/Desktop/Screen Recordings/selfie_segmenter.tflite')

MODE_FACE = 'face'
MODE_SCREEN = 'screen'
MODE_SCREEN_FACE = 'screen_face'


def _detect_devices():
    """Detect screen, mic (avfoundation), and mic (sounddevice) device indices.

    Returns (screen_idx, av_audio_idx, sd_audio_idx).
    Device indices change when displays/mics are connected/disconnected.
    """
    screen_idx = 0
    av_audio_idx = 0
    sd_audio_idx = None

    # Parse avfoundation devices
    try:
        r = subprocess.run(
            [FFMPEG, '-f', 'avfoundation', '-list_devices', 'true', '-i', ''],
            capture_output=True, text=True, timeout=5)
        in_video = False
        in_audio = False
        for line in r.stderr.split('\n'):
            if 'AVFoundation video devices' in line:
                in_video = True
                in_audio = False
                continue
            if 'AVFoundation audio devices' in line:
                in_audio = True
                in_video = False
                continue
            if '] [' not in line:
                continue
            idx_start = line.index('] [') + 3
            idx_end = line.index(']', idx_start)
            dev_idx = int(line[idx_start:idx_end])
            dev_name = line[idx_end + 2:].strip()

            if in_video and 'capture screen' in dev_name.lower():
                screen_idx = dev_idx
            if in_audio:
                nl = dev_name.lower()
                # Prefer USB mic > MacBook > anything else
                if 'usb' in nl or 'rode' in nl or 'yeti' in nl or 'shure' in nl:
                    av_audio_idx = dev_idx
                elif 'macbook' in nl and av_audio_idx == 0:
                    av_audio_idx = dev_idx
    except Exception:
        pass

    # Sounddevice mic index
    try:
        for i, d in enumerate(sd.query_devices()):
            if d['max_input_channels'] > 0:
                nl = d['name'].lower()
                if 'usb' in nl or 'rode' in nl or 'yeti' in nl or 'shure' in nl:
                    sd_audio_idx = i
                    break
        if sd_audio_idx is None:
            for i, d in enumerate(sd.query_devices()):
                if d['max_input_channels'] > 0 and 'macbook' in d['name'].lower():
                    sd_audio_idx = i
                    break
        if sd_audio_idx is None:
            sd_audio_idx = sd.default.device[0]
    except Exception:
        sd_audio_idx = None

    return screen_idx, av_audio_idx, sd_audio_idx


SCREEN_DEVICE, AV_AUDIO_DEVICE, SD_AUDIO_DEVICE = _detect_devices()


class StudioRecordApp:
    def __init__(self, root):
        self.root = root
        self.root.title('Studio Record')
        self.root.resizable(True, True)
        self.root.configure(fg_color=GLASS_BG)
        self.root.minsize(200, 200)

        # State
        self.running = True
        self.recording = False
        self.mode = MODE_FACE
        self.current_bg_path = None
        self.current_bg_image = None
        self.segmentor = None
        self.ffmpeg_proc = None
        self._audio_stream = None
        self._audio_chunks = []
        self._temp_video = None
        self._temp_audio = None
        self.record_start = None
        self.outpath = None
        self.photo = None
        self.bg_items = []
        self.bg_buttons = []
        self.selected_idx = 0
        self.audio_enabled = True
        self._saved_input_vol = None

        # Threading: background captures + processes, main thread displays
        self._latest_frame = None
        self._frame_lock = threading.Lock()
        self._capture_thread = None

        # API server
        threading.Thread(target=self._run_api, daemon=True).start()

        # PiP
        self.pip_window = None
        self.pip_canvas = None
        self.pip_photo = None
        self._pip_drag_x = 0
        self._pip_drag_y = 0

        # Camera — compact preview (1/3 bigger than 240x135)
        self.cap = None
        self.cam_w = 1280
        self.cam_h = 720
        self.disp_w = 320
        self.disp_h = 180
        self.pip_w = 200
        self.pip_h = 112

        self._build_ui()
        self._load_backgrounds()
        # Only open camera if mode needs it (Face or Screen+Face)
        if self.mode != MODE_SCREEN:
            self.root.after(500, self._open_camera)

    # ────────────────────────────────────────────────────
    #  UI
    # ────────────────────────────────────────────────────
    def _build_ui(self):
        p = 4  # tight padding

        # Everything in one fixed-width column so nothing stretches
        self._main = ctk.CTkFrame(self.root, fg_color='transparent')
        self._main.pack(padx=p, pady=p)

        # ── Header: title + timer ──
        top = ctk.CTkFrame(self._main, fg_color='transparent')
        top.pack(fill='x', pady=(0, 2))

        ctk.CTkLabel(top, text='\u0950 Studio Record',
                     font=ctk.CTkFont(size=11, weight='bold'),
                     text_color=GLASS_TEXT).pack(side='left')

        self.timer_lbl = ctk.CTkLabel(top, text='',
                                       font=ctk.CTkFont(family='Menlo', size=9),
                                       text_color=GLASS_DIM)
        self.timer_lbl.pack(side='right')

        # ── Mode selector ──
        mode_frame = ctk.CTkFrame(self._main, corner_radius=10,
                                   fg_color=GLASS_PANEL, border_width=1,
                                   border_color=GLASS_BORDER)
        mode_frame.pack(fill='x', pady=(0, 2))

        self.mode_seg = ctk.CTkSegmentedButton(
            mode_frame,
            values=['Screen', 'Screen + Face', 'Face Only'],
            command=self._on_mode_change,
            font=ctk.CTkFont(size=9, weight='bold'),
            corner_radius=10,
            selected_color=ACCENT,
            selected_hover_color=ACCENT_HOVER,
            unselected_color=GLASS_SURFACE,
            unselected_hover_color=GLASS_HIGHLIGHT,
            height=22)
        self.mode_seg.pack(fill='x', padx=2, pady=2)
        self.mode_seg.set('Face Only')

        # ── Video preview ──
        vid_frame = ctk.CTkFrame(self._main, corner_radius=10, border_width=1,
                                  border_color=GLASS_BORDER, fg_color=GLASS_PANEL)
        vid_frame.pack(fill='x', pady=(0, 2))

        self.canvas = ctk.CTkCanvas(vid_frame, width=self.disp_w, height=self.disp_h,
                                     bg='#080810', highlightthickness=0)
        self.canvas.pack(padx=2, pady=2)
        self.screen_info_visible = False

        # ── Controls row: BG toggle + sound + record ──
        controls = ctk.CTkFrame(self._main, fg_color='transparent')
        controls.pack(fill='x', pady=(0, 2))

        # BG picker toggle — small palette button
        self.bg_open = False
        self.bg_toggle_btn = ctk.CTkButton(
            controls, text='\U0001f3a8', width=28, height=22,
            font=ctk.CTkFont(size=12),
            fg_color=GLASS_PANEL, hover_color=GLASS_SURFACE,
            border_width=1, border_color=GLASS_BORDER,
            corner_radius=11,
            command=self._toggle_bg_panel)
        self.bg_toggle_btn.pack(side='left', padx=(0, 2))

        # Sound toggle
        self.sound_btn = ctk.CTkButton(
            controls, text='\U0001f50a', width=28, height=22,
            font=ctk.CTkFont(size=12),
            fg_color=GLASS_PANEL, hover_color=GLASS_SURFACE,
            border_width=1, border_color=GLASS_BORDER,
            text_color=GREEN, corner_radius=11,
            command=self._toggle_audio)
        self.sound_btn.pack(side='left', padx=(0, 2))

        # Record button
        self.rec_btn = ctk.CTkButton(
            controls, text='\u25cf  Record',
            font=ctk.CTkFont(size=10, weight='bold'),
            fg_color=GREEN, hover_color='#24cc50',
            text_color='white', corner_radius=11, height=22,
            command=self._toggle_recording)
        self.rec_btn.pack(side='left', fill='x', expand=True)

        # ── Collapsible BG panel (hidden by default) ──
        self.bg_panel = ctk.CTkFrame(self._main, corner_radius=10, border_width=1,
                                      border_color=GLASS_BORDER, fg_color=GLASS_PANEL)
        # Starts hidden — not packed

        self.bg_strip = ctk.CTkFrame(self.bg_panel, fg_color='transparent')
        self.bg_strip.pack(padx=3, pady=3)

        # ── Status line ──
        self.status_lbl = ctk.CTkLabel(self._main, text='Ready',
                                        font=ctk.CTkFont(size=9),
                                        text_color=GLASS_DIM, anchor='w')
        self.status_lbl.pack(fill='x', pady=(1, 0))

    def _toggle_bg_panel(self):
        """Show/hide the background picker grid."""
        self.bg_open = not self.bg_open
        if self.bg_open:
            # Insert below controls, above status
            self.bg_panel.pack(fill='x', pady=(0, 2),
                               before=self.status_lbl)
            self.bg_toggle_btn.configure(border_color=ACCENT)
        else:
            self.bg_panel.pack_forget()
            self.bg_toggle_btn.configure(border_color=GLASS_BORDER)

    # ────────────────────────────────────────────────────
    #  Mode Switching
    # ────────────────────────────────────────────────────
    def _on_mode_change(self, value):
        mode_map = {'Screen': MODE_SCREEN, 'Screen + Face': MODE_SCREEN_FACE,
                     'Face Only': MODE_FACE}
        self._set_mode(mode_map.get(value, MODE_FACE))

    def _set_mode(self, mode):
        if self.recording:
            rev = {MODE_SCREEN: 'Screen', MODE_SCREEN_FACE: 'Screen + Face',
                   MODE_FACE: 'Face Only'}
            self.mode_seg.set(rev[self.mode])
            return

        old_mode = getattr(self, 'mode', None)
        self.mode = mode

        # Release camera when switching to Screen mode
        if mode == MODE_SCREEN and self.cap and self.cap.isOpened():
            # Stop capture thread before releasing camera to avoid race condition
            old_cap = self.cap
            self.cap = None
            time.sleep(0.05)
            old_cap.release()

        # Open camera when switching to a mode that needs it
        if mode != MODE_SCREEN and (self.cap is None or not self.cap.isOpened()):
            self._open_camera()

        if mode == MODE_SCREEN:
            for btn in self.bg_buttons:
                btn.configure(state='disabled')
        else:
            for btn in self.bg_buttons:
                btn.configure(state='normal')
            self._highlight_bg(self.selected_idx)

        if mode != MODE_SCREEN_FACE:
            self._close_pip()
        else:
            self._open_pip()

        rev = {MODE_SCREEN: 'Screen', MODE_SCREEN_FACE: 'Screen + Face', MODE_FACE: 'Face Only'}
        self.mode_seg.set(rev[mode])

        msgs = {
            MODE_SCREEN: ('Screen mode — entire display recorded', DIM),
            MODE_SCREEN_FACE: ('Drag the floating face cam to position it', ACCENT),
            MODE_FACE: ('Ready — pick a background', DIM),
        }
        text, color = msgs[mode]
        self.status_lbl.configure(text=text, text_color=color)

    # ────────────────────────────────────────────────────
    #  Sound Toggle
    # ────────────────────────────────────────────────────
    def _toggle_audio(self):
        self.audio_enabled = not self.audio_enabled
        if self.audio_enabled:
            self.sound_btn.configure(text='\U0001f50a', text_color=GREEN,
                                     border_color=GLASS_BORDER)
            if self.recording:
                self._unmute_mic()
        else:
            self.sound_btn.configure(text='\U0001f507', text_color=RED,
                                     border_color=RED)
            if self.recording:
                self._mute_mic()

    def _mute_mic(self):
        try:
            r = subprocess.run(
                ['osascript', '-e', 'input volume of (get volume settings)'],
                capture_output=True, text=True, timeout=3)
            self._saved_input_vol = r.stdout.strip()
            subprocess.run(
                ['osascript', '-e', 'set volume input volume 0'], timeout=3)
        except Exception:
            pass

    def _unmute_mic(self):
        vol = self._saved_input_vol or '75'
        try:
            subprocess.run(
                ['osascript', '-e', f'set volume input volume {vol}'], timeout=3)
        except Exception:
            pass
        self._saved_input_vol = None

    # ────────────────────────────────────────────────────
    #  PiP Window
    # ────────────────────────────────────────────────────
    def _open_pip(self):
        if self.pip_window is not None:
            return

        import tkinter as tk
        self.pip_window = tk.Toplevel(self.root)
        self.pip_window.overrideredirect(True)
        self.pip_window.attributes('-topmost', True)
        self.pip_window.configure(bg='black')

        sw = self.root.winfo_screenwidth()
        sh = self.root.winfo_screenheight()
        x = sw - self.pip_w - 40
        y = sh - self.pip_h - 80
        self.pip_window.geometry(f'{self.pip_w}x{self.pip_h}+{x}+{y}')

        self.pip_canvas = tk.Canvas(self.pip_window, width=self.pip_w, height=self.pip_h,
                                    bg='black', highlightthickness=0, cursor='fleur')
        self.pip_canvas.pack()

        self.pip_canvas.bind('<Button-1>', self._pip_start_drag)
        self.pip_canvas.bind('<B1-Motion>', self._pip_do_drag)
        self.pip_window.protocol('WM_DELETE_WINDOW', self._close_pip)

    def _close_pip(self):
        if self.pip_window:
            self.pip_window.destroy()
            self.pip_window = None
            self.pip_canvas = None
            self.pip_photo = None

    def _pip_start_drag(self, event):
        self._pip_drag_x = event.x
        self._pip_drag_y = event.y

    def _pip_do_drag(self, event):
        if self.pip_window:
            x = self.pip_window.winfo_x() + (event.x - self._pip_drag_x)
            y = self.pip_window.winfo_y() + (event.y - self._pip_drag_y)
            self.pip_window.geometry(f'+{x}+{y}')

    # ────────────────────────────────────────────────────
    #  Background Loading
    # ────────────────────────────────────────────────────
    def _load_backgrounds(self):
        os.makedirs(BG_DIR, exist_ok=True)

        files = []
        for ext in ('*.jpg', '*.jpeg', '*.png', '*.webp', '*.bmp'):
            files.extend(glob.glob(os.path.join(BG_DIR, ext)))
        files.sort()

        self.bg_items = [(None, 'None')]
        for f in files:
            name = os.path.splitext(os.path.basename(f))[0]
            name = name.replace('-', ' ').replace('_', ' ').title()
            self.bg_items.append((f, name))

        thumb_s = 16
        cols = 8  # 8 per row — fits within 320px easily
        for i, (path, name) in enumerate(self.bg_items):
            if path is None:
                img = Image.new('RGB', (thumb_s, thumb_s), (40, 40, 60))
                draw = ImageDraw.Draw(img)
                draw.line([(3, 3), (thumb_s - 3, thumb_s - 3)], fill=(120, 120, 160), width=1)
                draw.line([(thumb_s - 3, 3), (3, thumb_s - 3)], fill=(120, 120, 160), width=1)
            else:
                img = Image.open(path)
                w, h = img.size
                side = min(w, h)
                left = (w - side) // 2
                top_c = (h - side) // 2
                img = img.crop((left, top_c, left + side, top_c + side))
                img = img.resize((thumb_s, thumb_s), Image.LANCZOS)

            ctk_img = ctk.CTkImage(light_image=img, dark_image=img,
                                    size=(thumb_s, thumb_s))

            row, col = divmod(i, cols)
            btn = ctk.CTkButton(
                self.bg_strip, image=ctk_img, text='',
                width=thumb_s + 2, height=thumb_s + 2,
                corner_radius=thumb_s,  # fully round
                border_width=2,
                border_color=ACCENT if i == 0 else GLASS_BORDER,
                fg_color=GLASS_SURFACE, hover_color=GLASS_HIGHLIGHT,
                command=lambda idx=i: self._select_bg(idx))
            btn.grid(row=row, column=col, padx=1, pady=1)
            btn._ctk_img = ctk_img
            self.bg_buttons.append(btn)

    def _highlight_bg(self, index):
        for i, btn in enumerate(self.bg_buttons):
            btn.configure(border_color=ACCENT if i == index else GLASS_BORDER)

    def _select_bg(self, index):
        if self.mode == MODE_SCREEN:
            return

        self.selected_idx = index
        self._highlight_bg(index)

        path, name = self.bg_items[index]
        self.current_bg_path = path

        if path:
            bg = cv2.imread(path)
            if bg is not None:
                self.current_bg_image = cv2.resize(bg, (self.cam_w, self.cam_h))
                self.status_lbl.configure(text=f'Background: {name} (Apple Vision)',
                                          text_color='#e4e4f0')
        else:
            self.current_bg_image = None
            self.status_lbl.configure(text='Background off', text_color=DIM)

    # ────────────────────────────────────────────────────
    #  Camera + Background Thread
    # ────────────────────────────────────────────────────
    def _open_camera(self):
        self.status_lbl.configure(text='Opening camera...', text_color=ACCENT)
        self.root.update()

        self.cap = cv2.VideoCapture(0)
        if not self.cap.isOpened():
            self.status_lbl.configure(
                text='Camera unavailable — check Privacy settings',
                text_color=RED)
            self._update_display()
            return

        self.cap.set(cv2.CAP_PROP_FRAME_WIDTH, 1280)
        self.cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 720)
        self.cap.set(cv2.CAP_PROP_FPS, 30)
        self.cam_w = int(self.cap.get(cv2.CAP_PROP_FRAME_WIDTH))
        self.cam_h = int(self.cap.get(cv2.CAP_PROP_FRAME_HEIGHT))

        self.disp_h = int(self.disp_w * self.cam_h / self.cam_w)
        self.pip_h = int(self.pip_w * self.cam_h / self.cam_w)
        self.canvas.configure(height=self.disp_h)

        if self.current_bg_path:
            bg = cv2.imread(self.current_bg_path)
            if bg is not None:
                self.current_bg_image = cv2.resize(bg, (self.cam_w, self.cam_h))

        self.status_lbl.configure(text='Ready', text_color=DIM)

        # Start background capture/processing thread
        self._capture_thread = threading.Thread(target=self._capture_loop, daemon=True)
        self._capture_thread.start()

        # Start display loop (runs in main/UI thread at ~30fps)
        self._update_display()

    def _init_apple_vision(self):
        """One-time init of Apple Vision segmentation + CoreVideo helpers."""
        if getattr(self, '_vn_ready', False):
            return
        try:
            import Vision as VN
            import ctypes
            from ctypes import c_void_p, c_size_t
            import objc

            self._VN = VN
            self._objc = objc
            cv = ctypes.CDLL('/System/Library/Frameworks/CoreVideo.framework/CoreVideo')
            cv.CVPixelBufferLockBaseAddress.argtypes = [c_void_p, ctypes.c_uint64]
            cv.CVPixelBufferUnlockBaseAddress.argtypes = [c_void_p, ctypes.c_uint64]
            cv.CVPixelBufferGetBaseAddress.restype = c_void_p
            cv.CVPixelBufferGetBaseAddress.argtypes = [c_void_p]
            cv.CVPixelBufferGetBytesPerRow.restype = c_size_t
            cv.CVPixelBufferGetBytesPerRow.argtypes = [c_void_p]
            cv.CVPixelBufferGetWidth.restype = c_size_t
            cv.CVPixelBufferGetWidth.argtypes = [c_void_p]
            cv.CVPixelBufferGetHeight.restype = c_size_t
            cv.CVPixelBufferGetHeight.argtypes = [c_void_p]
            self._cv = cv
            self._vn_ready = True
        except Exception:
            self._vn_ready = False

    def _apple_vision_mask(self, frame):
        """Run Apple Vision person segmentation in-memory (no file I/O).
        Uses Balanced quality — 14ms/frame on M-series, 69fps capable.
        """
        from Foundation import NSData
        import ctypes

        # Encode frame to JPEG in memory
        _, jpg = cv2.imencode('.jpg', frame, [cv2.IMWRITE_JPEG_QUALITY, 60])
        ns_data = NSData.dataWithBytes_length_(jpg.tobytes(), len(jpg))

        req = self._VN.VNGeneratePersonSegmentationRequest.alloc().initWithCompletionHandler_(None)
        req.setQualityLevel_(self._VN.VNGeneratePersonSegmentationRequestQualityLevelBalanced)

        handler = self._VN.VNImageRequestHandler.alloc().initWithData_options_(ns_data, None)
        success, error = handler.performRequests_error_([req], None)

        if not success or not req.results() or len(req.results()) == 0:
            return None

        pb = req.results()[0].pixelBuffer()
        pb_ptr = self._objc.pyobjc_id(pb)

        self._cv.CVPixelBufferLockBaseAddress(pb_ptr, 0)
        base = self._cv.CVPixelBufferGetBaseAddress(pb_ptr)
        bpr = self._cv.CVPixelBufferGetBytesPerRow(pb_ptr)
        mw = self._cv.CVPixelBufferGetWidth(pb_ptr)
        mh = self._cv.CVPixelBufferGetHeight(pb_ptr)

        buf = (ctypes.c_uint8 * (bpr * mh)).from_address(base)
        mask_raw = np.frombuffer(buf, dtype=np.uint8).reshape((mh, bpr))[:, :mw].copy()
        self._cv.CVPixelBufferUnlockBaseAddress(pb_ptr, 0)

        mask = cv2.resize(mask_raw, (frame.shape[1], frame.shape[0])).astype(np.float32) / 255.0
        mask = cv2.GaussianBlur(mask, (5, 5), 0)
        return mask

    def _process_frame(self, frame):
        """Apply virtual background using Apple Vision (Neural Engine) with
        MediaPipe fallback. Caches mask every 3rd frame for smooth performance.
        """
        if self.current_bg_image is not None:
            self._seg_count = getattr(self, '_seg_count', 0) + 1
            cached_mask = getattr(self, '_cached_mask', None)

            if cached_mask is None or self._seg_count % 3 == 0:
                self._init_apple_vision()

                if self._vn_ready:
                    mask = self._apple_vision_mask(frame)
                    if mask is not None:
                        self._cached_mask = np.stack((mask,) * 3, axis=-1)
                elif self.segmentor:
                    # MediaPipe fallback
                    rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
                    mp_img = mp.Image(image_format=mp.ImageFormat.SRGB, data=rgb)
                    result = self.segmentor.segment(mp_img)
                    mask = result.confidence_masks[0].numpy_view()
                    if mask.ndim == 3:
                        mask = mask[:, :, 0]
                    mask = cv2.GaussianBlur(mask, (7, 7), 0)
                    self._cached_mask = np.stack((mask,) * 3, axis=-1)

            if self._cached_mask is not None:
                frame = (self._cached_mask * frame +
                         (1 - self._cached_mask) * self.current_bg_image).astype(np.uint8)
        return frame

    def _capture_loop(self):
        """Background thread: read camera + apply virtual background.

        Yields CPU between frames so audio capture doesn't get starved.
        """
        while self.running and self.cap and self.cap.isOpened():
            try:
                cap = self.cap
                if cap is None or not cap.isOpened():
                    break
                ret, frame = cap.read()
            except Exception:
                break
            if not ret:
                time.sleep(0.01)
                continue

            if self.mode != MODE_SCREEN:
                frame = self._process_frame(frame)

            with self._frame_lock:
                self._latest_frame = frame

            # Yield CPU to audio capture process
            time.sleep(0.002)

    def _update_display(self):
        """Main/UI thread: display latest frame + write to recorder at ~30fps."""
        if not self.running:
            return

        # Grab latest processed frame from background thread
        with self._frame_lock:
            frame = self._latest_frame

        if frame is None:
            self.root.after(33, self._update_display)
            return

        # Write frame to video recorder (face mode only)
        if self.recording and self.mode == MODE_FACE and self.ffmpeg_proc and self.ffmpeg_proc.stdin:
            try:
                rec = cv2.resize(frame, (1920, 1080)) if (frame.shape[1] != 1920 or frame.shape[0] != 1080) else frame
                self.ffmpeg_proc.stdin.write(rec.tobytes())
                if self._first_frame_written is None:
                    self._first_frame_written = time.time()
            except (BrokenPipeError, OSError):
                pass

        # Update main preview
        if self.mode == MODE_SCREEN:
            if not self.screen_info_visible:
                self.canvas.delete('all')
                self.canvas.create_rectangle(0, 0, self.disp_w, self.disp_h,
                                             fill='#0a0a14', outline='')
                cy = self.disp_h // 2
                self.canvas.create_text(self.disp_w // 2, cy - 14,
                                        text='Screen Recording',
                                        fill=GLASS_TEXT,
                                        font=('Helvetica Neue', 11, 'bold'))
                self.canvas.create_text(self.disp_w // 2, cy + 4,
                                        text='Entire display captured',
                                        fill=GLASS_DIM, font=('Helvetica Neue', 9))
                if self.recording:
                    blink = int(time.time() * 2) % 2
                    if blink:
                        self.canvas.create_oval(self.disp_w // 2 - 4, cy + 18,
                                                self.disp_w // 2 + 4, cy + 26,
                                                fill=RED, outline='')
                    self.canvas.create_text(self.disp_w // 2 + 10, cy + 22,
                                            text='REC', fill=RED,
                                            font=('Helvetica Neue', 8, 'bold'),
                                            anchor='w')
                    self.screen_info_visible = False
                else:
                    self.screen_info_visible = True
        else:
            self.screen_info_visible = False
            display = cv2.resize(frame, (self.disp_w, self.disp_h))
            display = cv2.cvtColor(display, cv2.COLOR_BGR2RGB)

            if self.recording:
                blink = int(time.time() * 2) % 2
                if blink:
                    cv2.circle(display, (self.disp_w - 28, 28), 9, (255, 59, 92), -1)
                cv2.putText(display, 'REC', (self.disp_w - 72, 33),
                            cv2.FONT_HERSHEY_SIMPLEX, 0.55, (255, 59, 92), 2,
                            cv2.LINE_AA)

            img = Image.fromarray(display)
            self.photo = ImageTk.PhotoImage(img)
            self.canvas.delete('all')
            self.canvas.create_image(0, 0, anchor='nw', image=self.photo)

        # Update PiP
        if self.pip_window and self.pip_canvas and self.mode == MODE_SCREEN_FACE:
            pip_display = cv2.resize(frame, (self.pip_w, self.pip_h))
            pip_display = cv2.cvtColor(pip_display, cv2.COLOR_BGR2RGB)
            pip_img = Image.fromarray(pip_display)
            self.pip_photo = ImageTk.PhotoImage(pip_img)
            self.pip_canvas.delete('all')
            self.pip_canvas.create_image(0, 0, anchor='nw', image=self.pip_photo)

        # Timer
        if self.recording and self.record_start:
            elapsed = int(time.time() - self.record_start)
            m, s = divmod(elapsed, 60)
            h, m = divmod(m, 60)
            t = f'{h}:{m:02d}:{s:02d}' if h else f'{m:02d}:{s:02d}'
            self.timer_lbl.configure(text=t, text_color=RED)

        self.root.after(33, self._update_display)

    # ────────────────────────────────────────────────────
    #  Recording
    # ────────────────────────────────────────────────────
    def _toggle_recording(self):
        if self.recording:
            self._stop_recording()
        else:
            self._start_recording()

    def _start_recording(self):
        os.makedirs(OUT_DIR, exist_ok=True)
        ts = time.strftime('%Y%m%d-%H%M%S')

        if not self.audio_enabled:
            self._mute_mic()

        if self.mode == MODE_FACE:
            tag = 'facecam-bg' if self.current_bg_path else 'facecam'
            self.outpath = os.path.join(OUT_DIR, f'{tag}-{ts}.mp4')
            self._start_face_recording()
        elif self.mode == MODE_SCREEN:
            self.outpath = os.path.join(OUT_DIR, f'screen-{ts}.mp4')
            self._start_screen_recording()
        elif self.mode == MODE_SCREEN_FACE:
            tag = 'screen-facecam-bg' if self.current_bg_path else 'screen-facecam'
            self.outpath = os.path.join(OUT_DIR, f'{tag}-{ts}.mp4')
            if not self.pip_window:
                self._open_pip()
            self._start_screen_recording()

        self.recording = True
        self.record_start = time.time()
        self._first_frame_written = None  # timestamp of first video frame
        self._audio_start_time = time.time()
        self.rec_btn.configure(text='\u25a0  Stop', fg_color=RED,
                               hover_color='#d0303e')
        self.status_lbl.configure(text='Recording...', text_color=RED)
        self.screen_info_visible = False
        self.root.lift()
        self.root.attributes('-topmost', True)
        self.root.after(3000, lambda: self.root.attributes('-topmost', False))

    def _start_face_recording(self):
        """Face-only: video via pipe, audio captured separately, muxed on stop."""
        self._temp_video = self.outpath.replace('.mp4', '-vtmp.mp4')
        self._temp_audio = self.outpath.replace('.mp4', '-atmp.m4a')

        # Video: pipe processed frames at 30fps (no audio)
        vid_cmd = [
            FFMPEG, '-y',
            '-f', 'rawvideo', '-pixel_format', 'bgr24',
            '-video_size', '1920x1080', '-framerate', '30',
            '-i', 'pipe:0',
            '-c:v', 'h264_videotoolbox', '-b:v', '10M',
            self._temp_video
        ]
        self.ffmpeg_proc = subprocess.Popen(
            vid_cmd, stdin=subprocess.PIPE,
            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

        # Audio: capture via sounddevice (real-time priority thread, no drops)
        self._audio_chunks = []

        def _audio_cb(indata, frames, time_info, status):
            self._audio_chunks.append(indata.copy())

        self._audio_stream = sd.InputStream(
            samplerate=48000, channels=1, dtype='int16',
            device=SD_AUDIO_DEVICE, callback=_audio_cb, blocksize=2048)
        self._audio_stream.start()

    def _start_screen_recording(self):
        """Screen (and screen+face): FFmpeg captures display, sounddevice captures mic."""
        self._temp_video = self.outpath.replace('.mp4', '-vtmp.mp4')
        self._temp_audio = self.outpath.replace('.mp4', '-atmp.m4a')

        # Video: FFmpeg captures screen only (no audio)
        cmd = [
            FFMPEG, '-y',
            '-f', 'avfoundation',
            '-framerate', '30',
            '-capture_cursor', '1', '-capture_mouse_clicks', '1',
            '-i', f'{SCREEN_DEVICE}:none',
            '-c:v', 'h264_videotoolbox', '-b:v', '10M', '-realtime', 'true',
            self._temp_video
        ]
        self.ffmpeg_proc = subprocess.Popen(
            cmd, stdin=subprocess.PIPE,
            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        self._first_frame_written = time.time()  # FFmpeg starts capturing immediately

        # Audio: sounddevice (same crystal clear capture as face mode)
        self._audio_chunks = []

        def _audio_cb(indata, frames, time_info, status):
            self._audio_chunks.append(indata.copy())

        self._audio_stream = sd.InputStream(
            samplerate=48000, channels=1, dtype='int16',
            device=SD_AUDIO_DEVICE, callback=_audio_cb, blocksize=2048)
        self._audio_stream.start()

    def _stop_recording(self):
        self.recording = False
        self.record_start = None

        if self._saved_input_vol is not None:
            self._unmute_mic()

        if self.mode == MODE_FACE:
            self._stop_face_recording()
        else:
            self._stop_screen_recording()

        self.rec_btn.configure(text='\u25cf  Record', fg_color=GREEN,
                               hover_color='#24cc50')
        self.timer_lbl.configure(text='', text_color=DIM)
        self.screen_info_visible = False

        if self.outpath and os.path.exists(self.outpath):
            mb = os.path.getsize(self.outpath) / (1024 * 1024)
            name = os.path.basename(self.outpath)
            self.status_lbl.configure(text=f'Saved: {name} ({mb:.1f} MB)',
                                       text_color=SAVED)
        else:
            self.status_lbl.configure(text='Ready', text_color=DIM)

    def _stop_face_recording(self):
        """Stop face recording: close both processes then mux video + audio."""
        self.status_lbl.configure(text='Saving...', text_color=ACCENT)
        self.root.update()

        # Close video pipe
        if self.ffmpeg_proc:
            try:
                self.ffmpeg_proc.stdin.close()
            except OSError:
                pass
            try:
                self.ffmpeg_proc.wait(timeout=15)
            except subprocess.TimeoutExpired:
                self.ffmpeg_proc.kill()
            self.ffmpeg_proc = None

        # Stop audio capture and save to WAV then convert to AAC
        if self._audio_stream:
            self._audio_stream.stop()
            self._audio_stream.close()
            self._audio_stream = None

        if self._audio_chunks:
            audio_data = np.concatenate(self._audio_chunks)

            # Trim audio to align with video start
            # Audio started at self._audio_start_time, video at self._first_frame_written
            if self._first_frame_written and self._audio_start_time:
                offset = self._first_frame_written - self._audio_start_time
                if offset > 0:
                    skip_samples = int(offset * 48000)
                    if skip_samples < len(audio_data):
                        audio_data = audio_data[skip_samples:]

            temp_wav = self._temp_audio.replace('.m4a', '.wav')
            with wave.open(temp_wav, 'w') as wf:
                wf.setnchannels(1)
                wf.setsampwidth(2)
                wf.setframerate(48000)
                wf.writeframes(audio_data.tobytes())
            # Convert WAV to AAC (upmix to stereo)
            subprocess.run([
                FFMPEG, '-y', '-i', temp_wav,
                '-af', ','.join([
                    'highpass=f=60',
                    'afftdn=nf=-25',
                    'acompressor=threshold=-20dB:ratio=3:attack=5:release=100:makeup=8dB',
                    'equalizer=f=3000:t=q:w=1.5:g=3',
                    'equalizer=f=6000:t=q:w=2:g=2',
                    'agate=threshold=-45dB:attack=10:release=200',
                    'loudnorm=I=-16:TP=-1.5:LRA=11',
                ]),
                '-ac', '2', '-c:a', 'aac', '-b:a', '256k',
                self._temp_audio
            ], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=30)
            try:
                os.remove(temp_wav)
            except OSError:
                pass
            self._audio_chunks = []

        # Log temp file status
        v_exists = self._temp_video and os.path.exists(self._temp_video)
        a_exists = self._temp_audio and os.path.exists(self._temp_audio)
        with open('/tmp/studio-save.log', 'w') as log:
            log.write(f'temp_video: {self._temp_video} exists={v_exists}\n')
            log.write(f'temp_audio: {self._temp_audio} exists={a_exists}\n')
            if v_exists:
                log.write(f'  video size: {os.path.getsize(self._temp_video)}\n')
            if a_exists:
                log.write(f'  audio size: {os.path.getsize(self._temp_audio)}\n')

        # Mux video + audio into final file
        if v_exists and a_exists:
            mux_cmd = [
                FFMPEG, '-y',
                '-i', self._temp_video,
                '-i', self._temp_audio,
                '-c:v', 'copy', '-c:a', 'copy',
                '-shortest',
                self.outpath
            ]
            result = subprocess.run(mux_cmd, timeout=30,
                                    capture_output=True, text=True)
            with open('/tmp/studio-save.log', 'a') as log:
                log.write(f'mux returncode: {result.returncode}\n')
                log.write(f'mux stderr: {result.stderr[-500:]}\n')

            if os.path.exists(self.outpath) and os.path.getsize(self.outpath) > 0:
                # Success — clean up temp files
                try:
                    os.remove(self._temp_video)
                except OSError:
                    pass
                try:
                    os.remove(self._temp_audio)
                except OSError:
                    pass
            else:
                # Mux failed — keep temp files, use video-only as fallback
                with open('/tmp/studio-save.log', 'a') as log:
                    log.write('MUX FAILED — keeping temp files\n')
                if v_exists:
                    import shutil
                    shutil.copy2(self._temp_video, self.outpath)
        elif v_exists:
            # No audio, just use video
            import shutil
            shutil.copy2(self._temp_video, self.outpath)

        self._temp_video = None
        self._temp_audio = None

    def _stop_screen_recording(self):
        """Stop screen recording: stop FFmpeg video + sounddevice audio, then mux."""
        self.status_lbl.configure(text='Saving...', text_color=ACCENT)
        self.root.update()

        # Stop video capture — SIGTERM lets FFmpeg finalize the file properly
        if self.ffmpeg_proc:
            try:
                self.ffmpeg_proc.stdin.close()
            except OSError:
                pass
            try:
                self.ffmpeg_proc.terminate()
            except OSError:
                pass
            try:
                self.ffmpeg_proc.wait(timeout=10)
            except subprocess.TimeoutExpired:
                self.ffmpeg_proc.kill()
            self.ffmpeg_proc = None

        # Stop audio capture and save
        if self._audio_stream:
            self._audio_stream.stop()
            self._audio_stream.close()
            self._audio_stream = None

        if self._audio_chunks:
            audio_data = np.concatenate(self._audio_chunks)

            # Trim audio to align with video start
            if self._first_frame_written and self._audio_start_time:
                offset = self._first_frame_written - self._audio_start_time
                if offset > 0:
                    skip_samples = int(offset * 48000)
                    if skip_samples < len(audio_data):
                        audio_data = audio_data[skip_samples:]

            temp_wav = self._temp_audio.replace('.m4a', '.wav')
            with wave.open(temp_wav, 'w') as wf:
                wf.setnchannels(1)
                wf.setsampwidth(2)
                wf.setframerate(48000)
                wf.writeframes(audio_data.tobytes())
            subprocess.run([
                FFMPEG, '-y', '-i', temp_wav,
                '-af', ','.join([
                    'highpass=f=60',
                    'afftdn=nf=-25',
                    'acompressor=threshold=-20dB:ratio=3:attack=5:release=100:makeup=8dB',
                    'equalizer=f=3000:t=q:w=1.5:g=3',
                    'equalizer=f=6000:t=q:w=2:g=2',
                    'agate=threshold=-45dB:attack=10:release=200',
                    'loudnorm=I=-16:TP=-1.5:LRA=11',
                ]),
                '-ac', '2', '-c:a', 'aac', '-b:a', '256k',
                self._temp_audio
            ], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=30)
            try:
                os.remove(temp_wav)
            except OSError:
                pass
            self._audio_chunks = []

        # Mux video + audio
        v_exists = self._temp_video and os.path.exists(self._temp_video)
        a_exists = self._temp_audio and os.path.exists(self._temp_audio)

        if v_exists and a_exists:
            subprocess.run([
                FFMPEG, '-y',
                '-i', self._temp_video,
                '-i', self._temp_audio,
                '-c:v', 'copy', '-c:a', 'copy',
                '-shortest',
                self.outpath
            ], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=60)

            if os.path.exists(self.outpath) and os.path.getsize(self.outpath) > 0:
                try:
                    os.remove(self._temp_video)
                except OSError:
                    pass
                try:
                    os.remove(self._temp_audio)
                except OSError:
                    pass
            elif v_exists:
                import shutil
                shutil.copy2(self._temp_video, self.outpath)
        elif v_exists:
            import shutil
            shutil.copy2(self._temp_video, self.outpath)

        self._temp_video = None
        self._temp_audio = None

    # ────────────────────────────────────────────────────
    #  HTTP API  (http://127.0.0.1:17494)
    # ────────────────────────────────────────────────────
    def _run_api(self):
        api = Flask('studio_record_api')
        import logging
        log = logging.getLogger('werkzeug')
        log.setLevel(logging.ERROR)

        @api.route('/start', methods=['POST'])
        def api_start():
            mode = request.args.get('mode', 'screen')
            mode_map = {'screen': MODE_SCREEN, 'screen_face': MODE_SCREEN_FACE, 'face': MODE_FACE}
            m = mode_map.get(mode, MODE_SCREEN)
            done = threading.Event()
            def do_it():
                self._set_mode(m)
                if not self.recording:
                    self._start_recording()
                done.set()
            self.root.after(0, do_it)
            done.wait(timeout=5)
            return jsonify({'status': 'recording', 'outpath': self.outpath, 'mode': mode})

        @api.route('/stop', methods=['POST'])
        def api_stop():
            outpath = self.outpath
            done = threading.Event()
            def do_it():
                if self.recording:
                    self._stop_recording()
                done.set()
            self.root.after(0, do_it)
            done.wait(timeout=5)
            for _ in range(60):
                if outpath and os.path.exists(outpath) and os.path.getsize(outpath) > 0:
                    break
                time.sleep(0.5)
            return jsonify({'status': 'stopped', 'outpath': outpath})

        @api.route('/status', methods=['GET'])
        def api_status():
            return jsonify({
                'recording': self.recording,
                'outpath': self.outpath,
                'mode': self.mode,
                'duration': round(time.time() - self.record_start, 1) if self.recording and self.record_start else 0
            })

        api.run(host='127.0.0.1', port=17494, debug=False, use_reloader=False)

    # ────────────────────────────────────────────────────
    #  Cleanup
    # ────────────────────────────────────────────────────
    def on_close(self):
        self.running = False
        if self.recording:
            self._stop_recording()
        if self._audio_stream:
            self._audio_stream.stop()
            self._audio_stream.close()
            self._audio_stream = None
        if self._saved_input_vol is not None:
            self._unmute_mic()
        self._close_pip()
        if self.cap:
            old_cap = self.cap
            self.cap = None
            time.sleep(0.05)
            old_cap.release()
        if self.segmentor:
            self.segmentor.close()
        self.root.destroy()


def main():
    root = ctk.CTk()
    app = StudioRecordApp(root)
    root.protocol('WM_DELETE_WINDOW', app.on_close)

    root.update_idletasks()
    sw = root.winfo_screenwidth()
    sh = root.winfo_screenheight()
    ww = root.winfo_width()
    wh = root.winfo_height()
    root.geometry(f'+{(sw - ww) // 2}+{(sh - wh) // 3}')

    root.lift()
    root.attributes('-topmost', True)
    root.after(100, lambda: root.attributes('-topmost', False))
    root.focus_force()

    root.mainloop()


if __name__ == '__main__':
    main()
