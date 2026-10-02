#!/usr/bin/env python3
"""Composes App Store screenshots (2868x1320, iPhone 6.9" landscape) from raw simulator captures."""
from PIL import Image, ImageDraw, ImageFont, ImageFilter
import os
ROOT = os.path.join(os.path.dirname(__file__), "..", "marketing")
W, H = 2868, 1320
SHOTS = [
    ("play-real-shadow", "ONE TAP. ", "TWO WORLDS."),
    ("play-talk", "THE LONGER YOU LIVE, ", "THE WEIRDER IT GETS"),
    ("play-lava-shadow", "THE FLOOR IS ", "LAVA. SOMETIMES."),
    ("play-upside", "GRAVITY ", "QUIT MID-RUN"),
    ("daily", "A NEW TWIST ", "EVERY DAY"),
    ("dead", "SHARE YOUR ", "WEIRDEST DEATH"),
    ("skins", "COLLECT ", "WILD SKINS"),
    ("pass", "UNLOCK THE ", "SHADOW PASS"),
]
def font(size):
    f = ImageFont.truetype("/System/Library/Fonts/SFCompactRounded.ttf", size)
    try: f.set_variation_by_name("Black")
    except Exception:
        try: f.set_variation_by_name("Heavy")
        except Exception: pass
    return f
os.makedirs(os.path.join(ROOT, "store"), exist_ok=True)
for i, (raw, a, b) in enumerate(SHOTS, 1):
    bg = Image.new("RGB", (W, H), (11, 7, 32))
    px = bg.load()
    g = ImageDraw.Draw(bg)
    for y in range(H):
        t = y / H
        g.line([(0, y), (W, y)], fill=(int(24 + 40 * (1 - t)), int(10 + 8 * (1 - t)), int(60 + 70 * (1 - t))))
    shot = Image.open(os.path.join(ROOT, "raw", raw + ".png")).convert("RGB")
    tw = 2290; th = int(tw * shot.height / shot.width)
    shot = shot.resize((tw, th), Image.LANCZOS)
    mask = Image.new("L", shot.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, tw, th], radius=80, fill=255)
    x, y = (W - tw) // 2, H - th - 40
    glow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(glow).rounded_rectangle([x - 6, y - 6, x + tw + 6, y + th + 6], radius=86, fill=(139, 92, 246, 200))
    bg.paste(Image.alpha_composite(bg.convert("RGBA"), glow.filter(ImageFilter.GaussianBlur(30))).convert("RGB"))
    bg.paste(shot, (x, y), mask)
    d = ImageDraw.Draw(bg)
    f = font(112)
    wa = d.textlength(a, font=f); wb = d.textlength(b, font=f)
    sx = (W - (wa + wb)) / 2
    d.text((sx, 52), a, font=f, fill=(255, 255, 255))
    d.text((sx + wa, 52), b, font=f, fill=(34, 211, 238) if i % 2 else (255, 74, 220))
    out = os.path.join(ROOT, "store", f"{i:02d}_{raw}.png")
    bg.save(out)
    print(out)
