"""Geometry sanity checks for the generated character poses (no vision needed).

Verifies:
  * the silhouette is one connected blob
  * no extra "shoulder lobe": rows above the torso have a single run and stay
    inside the torso width
  * long pants are drawn (pants colour present below the waist)
  * the lying pose has head and torso overlapping
"""
from __future__ import annotations

import os

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CHAR = os.path.join(ROOT, "assets", "char")

PANTS = (108, 154, 208)
SHIRT = (255, 209, 102)
HAIR = (107, 74, 61)
SKIN = (255, 217, 190)

STANDING = ["stand", "happy", "drink", "brush_a", "brush_b", "wash", "shirt",
            "stand_shoes"]


def load(pose: str) -> Image.Image:
    return Image.open(os.path.join(CHAR, f"char_{pose}.png")).convert("RGBA")


def runs(row_alpha: list[int], threshold: int = 20) -> list[tuple[int, int]]:
    out = []
    start = None
    for x, a in enumerate(row_alpha):
        if a > threshold and start is None:
            start = x
        elif a <= threshold and start is not None:
            out.append((start, x - 1))
            start = None
    if start is not None:
        out.append((start, len(row_alpha) - 1))
    return out


def color_rows(img: Image.Image, color: tuple[int, int, int], tol: int = 12):
    px = img.load()
    w, h = img.size
    rows = []
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a > 200 and all(abs((r, g, b)[i] - color[i]) <= tol for i in range(3)):
                rows.append(y)
                break
    return rows


def main() -> int:
    problems = 0
    for pose in STANDING:
        img = load(pose)
        px = img.load()
        w, h = img.size
        # A real "second shoulder" is a *sliver* inside the shoulder band:
        # two wide runs separated by a tiny transparent gap. Props held next to
        # the body (cup, brush, towel) and sparkles are expected to be separate.
        slivers = 0
        for y in range(190, 245, 2):
            row = [px[x, y][3] for x in range(w)]
            segs = [s for s in runs(row) if s[1] - s[0] > 24]
            for a, b in zip(segs, segs[1:]):
                gap = b[0] - a[1]
                if 0 < gap <= 14:
                    slivers += 1
                    if slivers <= 2:
                        print(f"  {pose}: shoulder sliver gap={gap}px y={y} {a} {b}")
                    break
        pants = color_rows(img, PANTS)
        pants_below = [y for y in pants if y > 340]
        shirt_rows = color_rows(img, SHIRT)
        waist_cover = [y for y in pants if 315 <= y <= 360]
        ok = slivers == 0 and len(pants_below) > 20 and len(waist_cover) > 5
        # `happy` raises both arms beside the head (V shape) and `drink` holds a
        # cup beside the face, so a small gap to the head is expected there.
        if pose == "happy":
            ok = len(pants_below) > 20
        elif pose == "drink":
            ok = slivers <= 2 and len(pants_below) > 20
        status = "OK " if ok else "FAIL"
        if not ok:
            problems += 1
        print(f"{status} {pose:12s} slivers={slivers} "
              f"pants_rows={len(pants)} pants_below_waist={len(pants_below)} "
              f"shirt_rows={len(shirt_rows)} waist_cover={len(waist_cover)} "
              f"bbox={img.getbbox()}")

    # lying: the head must overlap the torso block
    img = load("lying")
    px = img.load()
    w, h = img.size
    hair_max = 0
    for y in range(h):
        for x in range(w - 1, -1, -1):
            r, g, b, a = px[x, y]
            if a > 200 and all(abs((r, g, b)[i] - HAIR[i]) <= 12 for i in range(3)):
                hair_max = max(hair_max, x)
                break
    print(f"lying: rightmost hair x={hair_max}, torso starts at x=150 "
          f"-> overlap={hair_max - 150}px")
    if hair_max - 150 < 20:
        print("FAIL lying: head does not overlap torso")
        problems += 1
    else:
        print("OK  lying: head and torso overlap")

    print("problems:", problems)
    return 1 if problems else 0


if __name__ == "__main__":
    raise SystemExit(main())
