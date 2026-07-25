#!/usr/bin/env python
import argparse
import numpy as np
from PIL import Image

SIZES = {"platform": (521, 165), "icon": (36, 36)}


def fit(img, w, h):
    img = img.convert("L")
    if img.size == (w, h):
        return img
    bg = img.getpixel((0, 0))
    src = img.copy()
    src.thumbnail((w, h), Image.LANCZOS)
    canvas = Image.new("L", (w, h), bg)
    canvas.paste(src, ((w - src.width) // 2, (h - src.height) // 2))
    return canvas


def encode(img, w, h):
    disp = np.asarray(fit(img, w, h), dtype=np.uint8)
    stored = np.rot90(disp, 1)
    flat = stored.reshape(-1)
    out = np.zeros((flat.size, 2), np.uint8)
    out[:, 0] = flat
    return out.reshape(-1).tobytes()


def decode(data, w, h):
    raw = np.frombuffer(data, dtype=np.uint8).reshape(-1, 2)
    gray = raw[:, 0].reshape(w, h)
    return Image.fromarray(np.rot90(gray, -1), "L")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("mode", choices=["encode", "decode"])
    ap.add_argument("src")
    ap.add_argument("dst")
    ap.add_argument("--size", choices=SIZES, default="platform")
    a = ap.parse_args()
    w, h = SIZES[a.size]
    if a.mode == "encode":
        open(a.dst, "wb").write(encode(Image.open(a.src), w, h))
    else:
        decode(open(a.src, "rb").read(), w, h).save(a.dst)
    print(f"{a.mode} {a.size} {w}x{h} -> {a.dst}")


if __name__ == "__main__":
    main()
