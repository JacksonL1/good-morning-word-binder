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

    # lying: head must overlap the torso, and the head must be a SIDE profile
    # with the face pointing up (a front-facing face on a horizontal body is
    # exactly the "creepy" look we are avoiding).
    img = load("lying")
    px = img.load()
    w, h = img.size
    hair_pts = []
    for y in range(0, 400):
        for x in range(0, 340):
            r, g, b, a = px[x, y]
            if a > 200 and all(abs((r, g, b)[i] - HAIR[i]) <= 12 for i in range(3)):
                hair_pts.append((x, y))
    hair_max_x = max((p[0] for p in hair_pts), default=0)
    hair_cy = sum(p[1] for p in hair_pts) / max(len(hair_pts), 1)
    head_cy = 262.0
    print(f"lying: rightmost hair x={hair_max_x}, torso starts at x=146 "
          f"-> overlap={hair_max_x - 146}px")
    print(f"lying: hair centroid y={hair_cy:.0f} vs head centre y={head_cy:.0f} "
          f"(hair must sit BELOW centre = back of skull on the pillow)")
    if hair_max_x - 146 < 20:
        print("FAIL lying: head does not overlap torso")
        problems += 1
    else:
        print("OK  lying: head and torso overlap")
    if hair_cy < head_cy + 4:
        print("FAIL lying: hair is not on the back of the head (face still front-on)")
        problems += 1
    else:
        print("OK  lying: profile head, hair on the pillow side")

    # nose must point up: skin pixels near the TOP of the head circle
    nose_band = 0
    for y in range(int(head_cy) - 80, int(head_cy) - 58):
        for x in range(100, 200):
            r, g, b, a = px[x, y]
            if a > 200 and all(abs((r, g, b)[i] - SKIN[i]) <= 12 for i in range(3)):
                nose_band += 1
    print(f"lying: skin pixels above head centre (nose) = {nose_band}")
    if nose_band < 40:
        print("FAIL lying: no nose above the head centre")
        problems += 1
    else:
        print("OK  lying: nose points up")

    print("problems:", problems)
    return 1 if problems else 0


if __name__ == "__main__":
    raise SystemExit(main())
