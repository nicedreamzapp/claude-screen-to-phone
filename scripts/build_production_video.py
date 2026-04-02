#!/usr/bin/env python3
"""
Production video builder — UV Glass Jars clip
Nice Dreamz style — Pillow for text rendering, ffmpeg for video
"""
import subprocess, os, sys
from PIL import Image, ImageDraw, ImageFont, ImageFilter

FFMPEG  = "/opt/homebrew/bin/ffmpeg"
FFPROBE = "/opt/homebrew/bin/ffprobe"
INPUT   = "/Users/dtribe/Desktop/Screen Recordings/screen-20260402-012237.mp4"
LOGO    = "/Users/dtribe/Desktop/PROJECTS/Recording studio inside an apple logo.png"
TTS_URL = "http://localhost:8000/tts"
OUTPUT  = "/Users/dtribe/Desktop/Screen Recordings/uv-jars-nicedreamz-FINAL.mp4"
W, H    = 1920, 1080

NAVY    = (10, 10, 26)       # #0a0a1a
CYAN    = (0, 212, 255)      # #00d4ff
WHITE   = (255, 255, 255)
DIM     = (160, 160, 200)
RED_REC = (255, 59, 92)

FONT_SF      = "/System/Library/Fonts/SFNS.ttf"
FONT_SFROUND = "/System/Library/Fonts/SFNSRounded.ttf"
FONT_MONO    = "/System/Library/Fonts/SFNSMono.ttf"

def run(cmd, label="", capture=True):
    print(f"  $ {label or ' '.join(str(x) for x in cmd[:5])} ...")
    r = subprocess.run(cmd, capture_output=capture, text=True)
    if r.returncode != 0:
        print("FAILED stderr:", (r.stderr or "")[-600:])
        sys.exit(1)
    return r

def audio_dur(path):
    r = subprocess.run([FFPROBE,"-v","quiet","-show_entries","format=duration",
                        "-of","csv=p=0",path], capture_output=True, text=True)
    return float(r.stdout.strip())

def make_card_image(text_lines, sub_lines=None, logo_path=None, fps=30):
    """Render a 1920x1080 title/end card PNG using Pillow."""
    img = Image.new("RGB", (W, H), NAVY)
    draw = ImageDraw.Draw(img)

    # Cyan accent bar on left edge
    draw.rectangle([0, 0, 6, H], fill=CYAN)

    # Logo
    logo_x = 140
    if logo_path:
        logo = Image.open(logo_path).convert("RGBA")
        logo_size = 300
        logo = logo.resize((logo_size, logo_size), Image.LANCZOS)
        # Glow behind logo
        glow = Image.new("RGBA", (logo_size+40, logo_size+40), (0,0,0,0))
        glow_draw = ImageDraw.Draw(glow)
        glow_draw.ellipse([0,0,logo_size+40,logo_size+40], fill=(0,180,220,60))
        img.paste(glow.convert("RGB"), (logo_x-20, (H-logo_size)//2-20), glow)
        img.paste(logo, (logo_x, (H-logo_size)//2), logo)

    # Text block
    tx = logo_x + 340 if logo_path else 160
    ty = 280

    try:
        font_big   = ImageFont.truetype(FONT_SFROUND, 80)
        font_med   = ImageFont.truetype(FONT_SF, 44)
        font_small = ImageFont.truetype(FONT_SF, 28)
        font_tag   = ImageFont.truetype(FONT_MONO, 22)
    except:
        font_big = font_med = font_small = font_tag = ImageFont.load_default()

    # Main title lines
    y = ty
    for i, (text, color, font) in enumerate(text_lines):
        draw.text((tx, y), text, font=font, fill=color)
        bbox = draw.textbbox((tx, y), text, font=font)
        y += (bbox[3] - bbox[1]) + 14

    # Cyan divider
    if text_lines:
        draw.rectangle([tx, y+10, tx+400, y+13], fill=CYAN)
        y += 30

    # Sub-lines
    if sub_lines:
        for text, color, font in sub_lines:
            draw.text((tx, y), text, font=font, fill=color)
            bbox = draw.textbbox((tx, y), text, font=font)
            y += (bbox[3] - bbox[1]) + 10

    return img

def img_to_video(img, duration, audio_path, out_path):
    """Convert a PIL image to a video clip with audio."""
    tmp_img = "/tmp/nda_card_frame.png"
    img.save(tmp_img)
    cmd = [
        FFMPEG, "-y",
        "-loop", "1", "-i", tmp_img,
        "-i", audio_path,
        "-c:v", "h264_videotoolbox", "-b:v", "3M",
        "-c:a", "aac", "-b:a", "192k",
        "-t", str(duration),
        "-pix_fmt", "yuv420p",
        "-r", "30",
        out_path
    ]
    run(cmd, f"img_to_video → {os.path.basename(out_path)}")

def silent_audio(duration, out_path):
    run([FFMPEG,"-y","-f","lavfi","-i",
         f"anullsrc=r=48000:cl=stereo:d={duration}",
         "-c:a","aac","-b:a","128k","-t",str(duration), out_path],
        f"silent audio {duration}s")

# ──────────────────────────────────────────────────────────────
print("\n[1/7] Generating intro voiceover...")
intro_text = ("What's up — welcome to Nice Dreamz. "
              "In this clip we're on DivineTribe.com checking out their complete guide "
              "to UV glass jars for cannabis and rosin storage, "
              "and why UV glass is the gold standard for keeping your concentrates fresh.")
intro_wav = "/tmp/nda_intro_vo.wav"
run(["curl","-s","-X","POST", TTS_URL, "-F", f"text={intro_text}", "--output", intro_wav],
    "TTS intro VO")
intro_dur  = audio_dur(intro_wav)
title_dur  = intro_dur + 0.8
print(f"   VO: {intro_dur:.1f}s  →  title card: {title_dur:.1f}s")

# ──────────────────────────────────────────────────────────────
print("\n[2/7] Rendering title card image...")
try:
    f_big   = ImageFont.truetype(FONT_SFROUND, 80)
    f_med   = ImageFont.truetype(FONT_SF, 44)
    f_small = ImageFont.truetype(FONT_SF, 30)
    f_tag   = ImageFont.truetype(FONT_MONO, 22)
except:
    f_big = f_med = f_small = f_tag = ImageFont.load_default()

title_img = make_card_image(
    text_lines=[
        ("NICE DREAMZ",    CYAN,  f_big),
        ("presents",       DIM,   f_small),
    ],
    sub_lines=[
        ("UV Glass Jars for Cannabis",      WHITE, f_med),
        ("& Rosin Storage",                 WHITE, f_med),
        ("DivineTribe.com  |  @nicedreamzapps", (120,180,220), f_tag),
    ],
    logo_path=LOGO
)
title_img.save("/tmp/nda_title_card.png")
print("   Saved title card PNG")

title_card_mp4 = "/tmp/nda_title.mp4"
img_to_video(title_img, title_dur, intro_wav, title_card_mp4)

# ──────────────────────────────────────────────────────────────
print("\n[3/7] Cutting silence from main recording...")
segs = [
    (0.0,   10.48),
    (10.93, 22.37),
    (23.10, 24.58),
    (25.74, 43.49),
]
parts, lv, la = [], [], []
for i, (s, e) in enumerate(segs):
    parts.append(
        f"[0:v]trim=start={s}:end={e},setpts=PTS-STARTPTS,"
        f"crop={W}:{H}:(iw-{W})/2:(ih-{H})/2,scale={W}:{H}[v{i}];"
    )
    parts.append(f"[0:a]atrim=start={s}:end={e},asetpts=PTS-STARTPTS[a{i}];")
    lv.append(f"[v{i}]"); la.append(f"[a{i}]")
fc = "".join(parts)
fc += f"{''.join(lv)}concat=n={len(segs)}:v=1:a=0[vcat];"
fc += f"{''.join(la)}concat=n={len(segs)}:v=0:a=1[acat]"

main_cut = "/tmp/nda_main_cut.mp4"
run([FFMPEG,"-y","-i",INPUT,
     "-filter_complex", fc,
     "-map","[vcat]","-map","[acat]",
     "-c:v","h264_videotoolbox","-b:v","8M",
     "-c:a","aac","-b:a","192k","-r","30", main_cut],
    "silence cut + scale")
main_dur = audio_dur(main_cut)
print(f"   Main: {main_dur:.1f}s  (was 48.2s)")

# ──────────────────────────────────────────────────────────────
print("\n[4/7] Adding subtitle overlays via Pillow frame compositing...")
# Build individual subtitle images (transparent PNG) for each sentence
# Then use ffmpeg overlay to composite onto video at timed intervals
# Since drawtext unavailable, use the simpler approach:
# overlay a semi-transparent PNG for each subtitle window

subtitle_data = [
    (0.5,  10.2,  "UV glass blocks all visible light — the #1 enemy of terpenes"),
    (10.5, 21.8,  "Clear glass, silicone & plastic all fail in different ways"),
    (21.9, 29.0,  "Silicone absorbs your terpenes right out of the product"),
    (29.0, 36.5,  "Rosin is the most delicate concentrate — UV glass is critical"),
    (36.5, 41.0,  "UV glass keeps your product fresh from day 1 to day 30"),
]

# Generate subtitle PNG strips
sub_pngs = []
try:
    f_sub = ImageFont.truetype(FONT_SF, 34)
except:
    f_sub = ImageFont.load_default()

for i, (t_in, t_out, text) in enumerate(subtitle_data):
    strip = Image.new("RGBA", (W, 70), (0, 0, 0, 0))
    d = ImageDraw.Draw(strip)
    d.rectangle([0, 0, W, 70], fill=(0, 0, 0, 170))
    bbox = d.textbbox((0,0), text, font=f_sub)
    tw = bbox[2] - bbox[0]
    tx = (W - tw) // 2
    d.text((tx+2, 18+2), text, font=f_sub, fill=(0,0,0,120))  # shadow
    d.text((tx,   18),   text, font=f_sub, fill=WHITE)
    path = f"/tmp/nda_sub_{i}.png"
    strip.save(path)
    sub_pngs.append((t_in, t_out, path))

# Also build watermark PNG
wm = Image.new("RGBA", (260, 36), (0,0,0,0))
wm_d = ImageDraw.Draw(wm)
try:
    f_wm = ImageFont.truetype(FONT_MONO, 20)
except:
    f_wm = ImageFont.load_default()
wm_d.text((0, 4), "NICE DREAMZ", font=f_wm, fill=(200,200,255,140))
wm.save("/tmp/nda_watermark.png")

# Build ffmpeg overlay filter with proper -i flags and enable expressions
n_subs = len(sub_pngs)
cmd = [FFMPEG, "-y", "-i", main_cut, "-i", "/tmp/nda_watermark.png"]
for _, _, p in sub_pngs:
    cmd += ["-i", p]

# filter_complex: watermark first, then each subtitle strip with time window
fc_parts = [f"[0:v][1:v]overlay=x=24:y=24[layer1]"]
for i, (t_in, t_out, _) in enumerate(sub_pngs):
    in_lbl  = f"layer{i+1}"
    out_lbl = "final" if i == n_subs - 1 else f"layer{i+2}"
    fc_parts.append(
        f"[{in_lbl}][{i+2}:v]overlay=x=0:y={H-70}"
        f":enable='between(t,{t_in},{t_out})'[{out_lbl}]"
    )
fc_overlay = ";".join(fc_parts)

main_sub = "/tmp/nda_main_sub.mp4"
cmd += ["-filter_complex", fc_overlay,
        "-map", "[final]", "-map", "0:a",
        "-c:v", "h264_videotoolbox", "-b:v", "8M",
        "-c:a", "copy", main_sub]
run(cmd, "subtitle overlay")
print("   Subtitles applied")

# ──────────────────────────────────────────────────────────────
print("\n[5/7] Rendering end card...")
try:
    f_big2  = ImageFont.truetype(FONT_SFROUND, 64)
    f_med2  = ImageFont.truetype(FONT_SF, 40)
    f_tag2  = ImageFont.truetype(FONT_MONO, 24)
except:
    f_big2 = f_med2 = f_tag2 = ImageFont.load_default()

end_img = make_card_image(
    text_lines=[
        ("Shop UV Glass Jars", WHITE, f_big2),
    ],
    sub_lines=[
        ("DivineTribe.com",         CYAN,  f_med2),
        ("@nicedreamzapps",         DIM,   f_tag2),
    ],
    logo_path=LOGO
)
end_img.save("/tmp/nda_end_card.png")
end_dur  = 3.5
end_sil  = "/tmp/nda_end_silence.m4a"
silent_audio(end_dur, end_sil)
end_card = "/tmp/nda_end.mp4"
img_to_video(end_img, end_dur, end_sil, end_card)
print(f"   End card: {end_dur}s")

# ──────────────────────────────────────────────────────────────
print("\n[6/7] Concatenating title + main + end...")
concat_txt = "/tmp/nda_concat.txt"
with open(concat_txt, "w") as f:
    for part in [title_card_mp4, main_sub, end_card]:
        f.write(f"file '{part}'\n")

run([FFMPEG, "-y",
     "-f", "concat", "-safe", "0", "-i", concat_txt,
     "-c:v", "h264_videotoolbox", "-b:v", "8M",
     "-c:a", "aac", "-b:a", "192k",
     "-movflags", "+faststart",
     OUTPUT], "final concat")

final_dur  = audio_dur(OUTPUT)
final_size = os.path.getsize(OUTPUT) // 1024 // 1024
print(f"\n[7/7] Done!")
print(f"   {OUTPUT}")
print(f"   Duration: {final_dur:.1f}s  |  Size: {final_size}MB")
