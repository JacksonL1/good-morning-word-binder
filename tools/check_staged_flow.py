"""Numeric verification of the new staged flow screenshots (no vision needed)."""
from __future__ import annotations

import glob
import os

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SHOTS = os.path.join(ROOT, "shots")

HAIR = (107, 74, 61)
PANTS = (108, 154, 208)
SHIRT = (255, 209, 102)
CORAL = (255, 138, 128)
TEAL = (96, 205, 196)


def count(img, color, tol=14, box=None):
    px = img.load()
    x0, y0, x1, y1 = box or (0, 0, img.size[0], img.size[1])
    n = 0
    minx, miny, maxx, maxy = x1, y1, x0, y0
    for y in range(y0, y1, 2):
        for x in range(x0, x1, 2):
            r, g, b = px[x, y][:3]
            if all(abs((r, g, b)[i] - color[i]) <= tol for i in range(3)):
                n += 1
                minx = min(minx, x)
                maxx = max(maxx, x)
                miny = min(miny, y)
                maxy = max(maxy, y)
    return n, (minx, miny, maxx, maxy)


def mean(img, box):
    return tuple(int(v) for v in img.crop(box).resize((1, 1), Image.BOX).getpixel((0, 0)))


def main() -> int:
    if not os.path.isdir(SHOTS):
        print("no shots")
        return 1
    files = sorted(os.path.basename(p) for p in glob.glob(os.path.join(SHOTS, "*.png")))
    print("shots:", len(files))

    rooms = {
        "02_step_1_wake.png": "bedroom",
        "lvl_03_drink.png": "living",
        "lvl_05_brush.png": "bathroom",
        "lvl_12_shoes.png": "entrance",
    }
    print("\n-- room backgrounds (top-left wall colour) --")
    for name, label in rooms.items():
        path = os.path.join(SHOTS, name)
        if not os.path.exists(path):
            print("  MISSING", name)
            continue
        img = Image.open(path).convert("RGB")
        print(f"  {label:9s} {name:22s} wall={mean(img, (0, 0, 120, 90))} "
              f"floor={mean(img, (0, 640, 160, 715))}")

    print("\n-- character presence (hair pixels) --")
    for name, expect_x in [("02_step_1_wake.png", 620), ("lvl_03_drink.png", 930),
                           ("lvl_05_brush.png", 930), ("lvl_09_shirt.png", 930),
                           ("lvl_10_pants.png", 930), ("lvl_12_shoes.png", 1000)]:
        path = os.path.join(SHOTS, name)
        if not os.path.exists(path):
            print("  MISSING", name)
            continue
        img = Image.open(path).convert("RGB")
        n, bb = count(img, HAIR, 26)
        cx = (bb[0] + bb[2]) // 2
        ok = n > 100
        print(f"  {'OK ' if ok else 'FAIL'} {name:22s} hair_px={n:5d} centre_x={cx} "
              f"expected~{expect_x}")

    print("\n-- clothing / props --")
    pairs = [("lvl_09_shirt.png", SHIRT, "character shirt"),
             ("lvl_10_pants.png", PANTS, "pants prop"),
             ("lvl_12_shoes.png", CORAL, "shoe props")]
    for name, color, label in pairs:
        path = os.path.join(SHOTS, name)
        if not os.path.exists(path):
            continue
        img = Image.open(path).convert("RGB")
        n, bb = count(img, color, 14)
        print(f"  {name:22s} {label:16s} px={n:5d} bbox={bb}")

    print("\n-- panes --")
    for name in ["08_checklist.png", "09_finale.png", "cut_goto_living.png",
                 "cut_brush_video.png"]:
        path = os.path.join(SHOTS, name)
        if not os.path.exists(path):
            print("  MISSING", name)
            continue
        img = Image.open(path).convert("RGB")
        print(f"  {name:24s} centre={img.getpixel((640, 360))} "
              f"corner={img.getpixel((6, 6))}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
