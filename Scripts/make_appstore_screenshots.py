#!/usr/bin/env python3
"""Composite raw device screenshots into 6.9" App Store marketing images.

Usage: python3 Scripts/make_appstore_screenshots.py
Reads from screenshots/, writes to screenshots/appstore/.
"""

from PIL import Image, ImageDraw, ImageFont

CANVAS_W, CANVAS_H = 1320, 2868
BG_TOP = (101, 121, 247)      # sampled from app nav bar
BG_BOTTOM = (10, 10, 18)
CORNER_RADIUS = 64
FONT_BOLD = "/System/Library/Fonts/Supplemental/Arial Bold.ttf"

SHOTS = [
    # (filename, caption, crop_bottom) — crop_bottom picked from a sampled pixel gap
    # between card sections, so the cut lands in dead space, not mid-content.
    ("appScreenshot_2026.07.21_12.PNG", "Real pose photos guide\nyou through every round", 2532),
    ("appScreenshot_2026.07.21_10.PNG", "Every skill, broken into\nclear progressive steps", 2532),
    ("appScreenshot_2026.07.21_13.PNG", "Score technique, effort,\nand discomfort — every set", 2532),
    ("appScreenshot_2026.07.21_4.PNG", "Track completion across\nevery skill family", 2050),
    ("appScreenshot_2026.07.21_2.PNG", "Watch your rate climb,\nsession after session", 2310),
    ("appScreenshot_2026.07.21_6.PNG", "See exactly how much\nyou're training", 2080),
    ("appScreenshot_2026.07.21_1.PNG", "Every session logged,\nautomatically", 2150),
]


def gradient_bg():
    bg = Image.new("RGB", (CANVAS_W, CANVAS_H))
    draw = ImageDraw.Draw(bg)
    for y in range(CANVAS_H):
        t = y / CANVAS_H
        r = int(BG_TOP[0] + (BG_BOTTOM[0] - BG_TOP[0]) * t)
        g = int(BG_TOP[1] + (BG_BOTTOM[1] - BG_TOP[1]) * t)
        b = int(BG_TOP[2] + (BG_BOTTOM[2] - BG_TOP[2]) * t)
        draw.line([(0, y), (CANVAS_W, y)], fill=(r, g, b))
    return bg


def rounded_mask(size, radius):
    mask = Image.new("L", size, 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle([(0, 0), (size[0] - 1, size[1] - 1)], radius=radius, fill=255)
    return mask


def make_shot(filename, caption, crop_bottom, out_path):
    canvas = gradient_bg()
    draw = ImageDraw.Draw(canvas)

    font = ImageFont.truetype(FONT_BOLD, 92)
    lines = caption.split("\n")
    line_heights = [draw.textbbox((0, 0), l, font=font)[3] for l in lines]
    total_h = sum(line_heights) + (len(lines) - 1) * 20
    y = 140
    for line, lh in zip(lines, line_heights):
        w = draw.textbbox((0, 0), line, font=font)[2]
        draw.text(((CANVAS_W - w) / 2, y), line, font=font, fill=(255, 255, 255))
        y += lh + 20

    shot = Image.open(f"screenshots/{filename}").convert("RGB")
    shot = shot.crop((0, 0, shot.width, crop_bottom))
    shot_y = total_h + 260
    box_w = CANVAS_W - 160
    box_h = CANVAS_H - 40 - shot_y
    scale = min(box_w / shot.width, box_h / shot.height)
    shot = shot.resize((int(shot.width * scale), int(shot.height * scale)), Image.LANCZOS)

    mask = rounded_mask(shot.size, CORNER_RADIUS)
    shot_x = (CANVAS_W - shot.width) // 2
    shot_y += (box_h - shot.height) // 2

    shadow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(shadow)
    shadow_draw.rounded_rectangle(
        [(shot_x + 12, shot_y + 24), (shot_x + shot.width + 12, shot_y + shot.height + 24)],
        radius=CORNER_RADIUS, fill=(0, 0, 0, 90),
    )
    shadow = shadow.filter(__import__("PIL.ImageFilter", fromlist=["ImageFilter"]).GaussianBlur(24))
    canvas.paste(shadow, (0, 0), shadow)

    canvas.paste(shot, (shot_x, shot_y), mask)
    canvas.save(out_path)
    print(f"wrote {out_path}")


if __name__ == "__main__":
    import os
    out_dir = "screenshots/appstore"
    os.makedirs(out_dir, exist_ok=True)
    for i, (filename, caption, crop_bottom) in enumerate(SHOTS, start=1):
        make_shot(filename, caption, crop_bottom, f"{out_dir}/{i:02d}.png")
