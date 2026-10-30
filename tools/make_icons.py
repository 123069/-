"""生成「清账」的 App 图标（iOS / Android / Web）。

只用标准库 + Pillow + numpy。用法：
    python tools/make_icons.py
"""

from __future__ import annotations

import os

import numpy as np
from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FONT = r"C:\Windows\Fonts\msyhbd.ttc"

TOP = (75, 107, 255)      # #4B6BFF
BOTTOM = (106, 70, 240)   # #6A46F0
SIZE = 1024


def gradient(size: int) -> Image.Image:
    y, x = np.mgrid[0:size, 0:size]
    t = ((x + y) / (2.0 * (size - 1))).clip(0, 1)
    t = t[..., None]
    top = np.array(TOP, dtype=float)
    bottom = np.array(BOTTOM, dtype=float)
    rgb = top + (bottom - top) * t
    return Image.fromarray(rgb.astype(np.uint8), mode="RGB")


def master() -> Image.Image:
    img = gradient(SIZE).convert("RGBA")

    # 右上角柔光
    glow = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    gd.ellipse(
        [SIZE * 0.55, -SIZE * 0.30, SIZE * 1.35, SIZE * 0.50],
        fill=(255, 255, 255, 26),
    )
    img = Image.alpha_composite(img, glow)

    # 「清」
    font = ImageFont.truetype(FONT, int(SIZE * 0.50))
    text = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    td = ImageDraw.Draw(text)
    box = td.textbbox((0, 0), "清", font=font)
    width = box[2] - box[0]
    height = box[3] - box[1]
    td.text(
        ((SIZE - width) / 2 - box[0], (SIZE - height) / 2 - box[1] - SIZE * 0.042),
        "清",
        font=font,
        fill=(255, 255, 255, 255),
    )
    img = Image.alpha_composite(img, text)

    # 底部一条“账目线”，像一笔刚记好的账
    line = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    ld = ImageDraw.Draw(line)
    bar_w = SIZE * 0.16
    bar_h = SIZE * 0.026
    x0 = (SIZE - bar_w) / 2
    y0 = SIZE * 0.805
    ld.rounded_rectangle(
        [x0, y0, x0 + bar_w, y0 + bar_h],
        radius=bar_h / 2,
        fill=(255, 255, 255, 170),
    )
    img = Image.alpha_composite(img, line)
    return img


def rounded(img: Image.Image, radius_ratio: float = 0.22) -> Image.Image:
    size = img.size[0]
    mask = Image.new("L", (size, size), 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        [0, 0, size - 1, size - 1],
        radius=int(size * radius_ratio),
        fill=255,
    )
    out = img.copy()
    out.putalpha(mask)
    return out


def save(img: Image.Image, path: str, size: int, flip: bool = False) -> None:
    os.makedirs(os.path.dirname(path), exist_ok=True)
    target = img.resize((size, size), Image.LANCZOS)
    if flip:
        target = rounded(target)
    target.save(path, optimize=True)


def main() -> None:
    base = master()
    ios = base.convert("RGB")

    ios_sizes = {
        "Icon-App-20x20@1x.png": 20,
        "Icon-App-20x20@2x.png": 40,
        "Icon-App-20x20@3x.png": 60,
        "Icon-App-29x29@1x.png": 29,
        "Icon-App-29x29@2x.png": 58,
        "Icon-App-29x29@3x.png": 87,
        "Icon-App-40x40@1x.png": 40,
        "Icon-App-40x40@2x.png": 80,
        "Icon-App-40x40@3x.png": 120,
        "Icon-App-60x60@2x.png": 120,
        "Icon-App-60x60@3x.png": 180,
        "Icon-App-76x76@1x.png": 76,
        "Icon-App-76x76@2x.png": 152,
        "Icon-App-83.5x83.5@2x.png": 167,
        "Icon-App-1024x1024@1x.png": 1024,
    }
    ios_dir = os.path.join(ROOT, "ios", "Runner", "Assets.xcassets", "AppIcon.appiconset")
    for name, size in ios_sizes.items():
        save(ios, os.path.join(ios_dir, name), size)

    android = {
        "mipmap-mdpi": 48,
        "mipmap-hdpi": 72,
        "mipmap-xhdpi": 96,
        "mipmap-xxhdpi": 144,
        "mipmap-xxxhdpi": 192,
    }
    for folder, size in android.items():
        path = os.path.join(
            ROOT, "android", "app", "src", "main", "res", folder, "ic_launcher.png"
        )
        save(base, path, size, flip=True)

    web_dir = os.path.join(ROOT, "web")
    save(base, os.path.join(web_dir, "favicon.png"), 32, flip=True)
    save(base, os.path.join(web_dir, "icons", "Icon-192.png"), 192, flip=True)
    save(base, os.path.join(web_dir, "icons", "Icon-512.png"), 512, flip=True)
    save(base, os.path.join(web_dir, "icons", "Icon-maskable-192.png"), 192)
    save(base, os.path.join(web_dir, "icons", "Icon-maskable-512.png"), 512)

    preview = os.path.join(ROOT, "docs", "shots", "icon-preview.png")
    save(base, preview, 1024)
    print("icons done:", preview)


if __name__ == "__main__":
    main()
