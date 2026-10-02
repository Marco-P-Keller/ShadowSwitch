#!/usr/bin/env python3
from PIL import Image, ImageDraw, ImageFilter, ImageChops
import math, os
S = 2048
OUT = os.path.join(os.path.dirname(__file__), "..", "ShadowSwitch", "Resources", "Assets.xcassets", "AppIcon.appiconset", "icon-1024.png")

def vgrad(top, bottom):
    img = Image.new("RGB", (S, S))
    d = ImageDraw.Draw(img)
    for y in range(S):
        t = y / S
        d.line([(0, y), (S, y)], fill=tuple(int(top[i] + (bottom[i] - top[i]) * t) for i in range(3)))
    return img

real = vgrad((255, 150, 90), (255, 232, 190))
shadow = vgrad((16, 6, 40), (92, 34, 170))

# diagonal split (lightning-ish jag)
mask = Image.new("L", (S, S), 0)
md = ImageDraw.Draw(mask)
md.polygon([(S * 0.62, 0), (S, 0), (S, S), (S * 0.28, S), (S * 0.52, S * 0.55), (S * 0.40, S * 0.5)], fill=255)
mask = mask.filter(ImageFilter.GaussianBlur(2))
bg = Image.composite(shadow, real, mask)

# sun + stars
d = ImageDraw.Draw(bg)
d.ellipse([S*0.12, S*0.10, S*0.34, S*0.32], fill=(255, 244, 200))
import random; random.seed(7)
for _ in range(60):
    x, y = random.randint(int(S*0.55), S), random.randint(0, S)
    if mask.getpixel((min(x, S-1), y)) > 200:
        r = random.randint(3, 9); d.ellipse([x-r, y-r, x+r, y+r], fill=(255, 255, 255))

# ground line
gy = int(S * 0.80)
ground_real = Image.new("RGB", (S, S - gy), (244, 214, 160))
ground_shadow = Image.new("RGB", (S, S - gy), (22, 8, 48))
gm = mask.crop((0, gy, S, S))
bg.paste(Image.composite(ground_shadow, ground_real, gm), (0, gy))
neon = Image.new("RGB", (S, 14), (0, 240, 255)); nm = mask.crop((0, gy, S, gy + 14))
bg.paste(Image.composite(neon, Image.new("RGB", (S, 14), (212, 165, 95)), nm), (0, gy))

# figure (the "shade")
def figure(color, extra=None):
    layer = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    f = ImageDraw.Draw(layer)
    cx = S * 0.47
    # scarf
    f.polygon([(cx - 90, S*0.46), (cx - 520, S*0.40), (cx - 560, S*0.45), (cx - 90, S*0.53)], fill=color)
    # legs
    f.line([(cx - 60, gy - 170), (cx - 190, gy - 10)], fill=color, width=84)
    f.line([(cx + 70, gy - 170), (cx + 200, gy - 40)], fill=color, width=84)
    # body
    f.rounded_rectangle([cx - 250, S*0.32, cx + 250, gy - 120], radius=250, fill=color)
    # ears
    f.polygon([(cx - 230, S*0.37), (cx - 190, S*0.26), (cx - 60, S*0.335)], fill=color)
    f.polygon([(cx + 60, S*0.335), (cx + 190, S*0.26), (cx + 230, S*0.37)], fill=color)
    return layer

def eyes(color):
    layer = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    f = ImageDraw.Draw(layer); cx = S * 0.47
    for dx in (60, 190):
        f.ellipse([cx + dx - 34, S*0.455, cx + dx + 34, S*0.545], fill=color)
    return layer

dark = figure((27, 22, 51, 255))
glow_col = (232, 253, 255, 255)
light = figure(glow_col)
# glow for the shadow half
halo = light.filter(ImageFilter.GaussianBlur(60))
halo = Image.merge("RGBA", (halo.split()[0].point(lambda v: 0), halo.split()[1].point(lambda v: 240), halo.split()[2].point(lambda v: 255), halo.split()[3].point(lambda a: int(a * 0.9))))

fig_mask = mask
canvas = bg.convert("RGBA")
# dark figure only on real side
dk = Image.composite(dark, Image.new("RGBA", (S, S), (0, 0, 0, 0)), ImageChops.invert(fig_mask))
canvas = Image.alpha_composite(canvas, dk)
# glowing figure on shadow side
canvas = Image.alpha_composite(canvas, Image.composite(halo, Image.new("RGBA", (S, S), (0, 0, 0, 0)), fig_mask))
lt = Image.composite(light, Image.new("RGBA", (S, S), (0, 0, 0, 0)), fig_mask)
canvas = Image.alpha_composite(canvas, lt)
# eyes: white on dark half, dark on bright half
ey_w = Image.composite(eyes((255, 255, 255, 255)), Image.new("RGBA", (S, S), (0, 0, 0, 0)), ImageChops.invert(fig_mask))
ey_d = Image.composite(eyes((18, 8, 40, 255)), Image.new("RGBA", (S, S), (0, 0, 0, 0)), fig_mask)
canvas = Image.alpha_composite(Image.alpha_composite(canvas, ey_w), ey_d)

# subtle vignette
final = canvas.convert("RGB").resize((1024, 1024), Image.LANCZOS)
final.save(OUT, "PNG")
print("icon ->", os.path.abspath(OUT))
