"""Generate the little kid character used by the animation layer.

All poses share one 512x512 canvas and one design language so the character can
swap poses mid-scene without jumping around. Standing poses put the feet at
y=468 (the Character scene compensates with a Sprite2D offset).

Usage: python tools/gen_character.py
Outputs: assets/char/char_<pose>.png

WARNING: this overwrites all 11 poses in assets/char. Do not run it after
replacing the character with your own artwork. See docs/ASSET_GUIDE.md.
"""
from __future__ import annotations

import math
import os

from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "char")
os.makedirs(OUT, exist_ok=True)
S = 2

INK = (74, 74, 106, 255)
SKIN = (255, 217, 190, 255)
SKIN_D = (242, 191, 160, 255)
HAIR = (107, 74, 61, 255)
HAIR_L = (138, 98, 80, 255)
PJ = (191, 232, 245, 255)
PJ_D = (143, 208, 230, 255)
PANTS = (127, 169, 217, 255)
SHIRT = (255, 209, 102, 255)
SHIRT_D = (240, 176, 64, 255)
SHOE = (255, 138, 128, 255)
SHOE_D = (232, 104, 96, 255)
WHITE = (255, 255, 255, 255)


def canvas() -> Image.Image:
    return Image.new("RGBA", (512 * S, 512 * S), (0, 0, 0, 0))


def sc(v: float) -> int:
    return int(round(v * S))


def ell(d, cx, cy, rx, ry, fill=None, outline=None, width=0):
    d.ellipse([sc(cx - rx), sc(cy - ry), sc(cx + rx), sc(cy + ry)],
              fill=fill, outline=outline, width=sc(width) if width else 0)


def rrect(d, box, radius, fill=None, outline=None, width=0):
    x0, y0, x1, y1 = box
    d.rounded_rectangle([sc(x0), sc(y0), sc(x1), sc(y1)], radius=sc(radius),
                        fill=fill, outline=outline,
                        width=sc(width) if width else 0)


def poly(d, pts, fill=None, outline=None, width=0):
    points = [(sc(x), sc(y)) for x, y in pts]
    d.polygon(points, fill=fill)
    if outline and width:
        d.line(points + [points[0]], fill=outline, width=sc(width),
               joint="curve")


def line(d, pts, fill, width, joint="curve"):
    d.line([(sc(x), sc(y)) for x, y in pts], fill=fill,
           width=sc(width), joint=joint)


def arc(d, box, start, end, fill, width):
    d.arc([sc(box[0]), sc(box[1]), sc(box[2]), sc(box[3])], start, end,
          fill=fill, width=sc(width))


def capsule(d, x0, y0, x1, y1, r, fill, outline=None, width=0):
    if outline:
        d.line([(sc(x0), sc(y0)), (sc(x1), sc(y1))], fill=outline,
               width=sc(r * 2 + width * 2))
    d.line([(sc(x0), sc(y0)), (sc(x1), sc(y1))], fill=fill,
           width=sc(r * 2))
    ell(d, x0, y0, r, r, fill=fill, outline=outline, width=width)
    ell(d, x1, y1, r, r, fill=fill, outline=outline, width=width)


def sparkle(d, cx, cy, r, fill=WHITE):
    poly(d, [(cx, cy - r), (cx + r * 0.28, cy - r * 0.28), (cx + r, cy),
             (cx + r * 0.28, cy + r * 0.28), (cx, cy + r),
             (cx - r * 0.28, cy + r * 0.28), (cx - r, cy),
             (cx - r * 0.28, cy - r * 0.28)], fill=fill)


def shadow(d, cx=256, cy=472, rx=104, ry=15):
    ell(d, cx, cy, rx, ry, fill=(60, 50, 90, 45))


def draw_head(d, cx, cy, eyes="open", mouth="smile", sleepy=False,
              cheeks=True):
    # neck
    rrect(d, (cx - 17, cy + 48, cx + 17, cy + 84), 8, fill=SKIN,
          outline=INK, width=4)
    # hair back
    ell(d, cx, cy - 6, 74, 72, fill=HAIR, outline=INK, width=4)
    # ears
    ell(d, cx - 63, cy + 8, 13, 17, fill=SKIN, outline=INK, width=4)
    ell(d, cx + 63, cy + 8, 13, 17, fill=SKIN, outline=INK, width=4)
    # face
    ell(d, cx, cy, 62, 65, fill=SKIN, outline=INK, width=4)
    # fringe
    poly(d, [(cx - 60, cy - 16), (cx - 57, cy - 52), (cx - 30, cy - 64),
             (cx + 4, cy - 66), (cx + 40, cy - 56), (cx + 59, cy - 30),
             (cx + 61, cy - 12), (cx + 40, cy - 34), (cx + 12, cy - 42),
             (cx - 18, cy - 34), (cx - 40, cy - 22)],
         fill=HAIR, outline=INK, width=3)
    # side hair
    rrect(d, (cx - 70, cy - 34, cx - 50, cy + 30), 10, fill=HAIR,
          outline=INK, width=3)
    rrect(d, (cx + 50, cy - 34, cx + 70, cy + 30), 10, fill=HAIR,
          outline=INK, width=3)
    # eyebrows
    arc(d, (cx - 42, cy - 16, cx - 16, cy + 2), 200, 340, INK, 3)
    arc(d, (cx + 16, cy - 16, cx + 42, cy + 2), 200, 340, INK, 3)
    # eyes
    if eyes == "closed" or sleepy:
        arc(d, (cx - 38, cy + 2, cx - 12, cy + 20), 200, 340, INK, 4)
        arc(d, (cx + 12, cy + 2, cx + 38, cy + 20), 200, 340, INK, 4)
    elif eyes == "happy":
        arc(d, (cx - 38, cy + 2, cx - 12, cy + 20), 20, 160, INK, 4)
        arc(d, (cx + 12, cy + 2, cx + 38, cy + 20), 20, 160, INK, 4)
    else:
        ell(d, cx - 24, cy + 8, 8, 10, fill=INK)
        ell(d, cx + 24, cy + 8, 8, 10, fill=INK)
        ell(d, cx - 26, cy + 5, 3, 3, fill=WHITE)
        ell(d, cx + 22, cy + 5, 3, 3, fill=WHITE)
    # nose
    ell(d, cx, cy + 24, 4, 3, fill=SKIN_D)
    # mouth
    if mouth == "open":
        ell(d, cx, cy + 38, 12, 9, fill=(120, 60, 70, 255))
        ell(d, cx, cy + 42, 7, 4, fill=(255, 140, 140, 255))
    elif mouth == "smile":
        arc(d, (cx - 17, cy + 18, cx + 17, cy + 46), 20, 160, INK, 4)
    else:
        line(d, [(cx - 10, cy + 36), (cx + 10, cy + 36)], INK, 3)
    if cheeks:
        ell(d, cx - 40, cy + 30, 12, 7, fill=(255, 168, 156, 120))
        ell(d, cx + 40, cy + 30, 12, 7, fill=(255, 168, 156, 120))


def draw_torso(d, top=196, bottom=352, color=PJ, outline=INK,
               collar=False, stars=True):
    rrect(d, (206, top, 306, bottom), 38, fill=color, outline=outline, width=5)
    if collar:
        poly(d, [(232, top + 2), (256, top + 34), (280, top + 2)], fill=WHITE,
             outline=outline, width=3)
    if stars:
        sparkle(d, 230, top + 50, 9, (255, 250, 205, 200))
        sparkle(d, 282, top + 96, 7, (255, 250, 205, 170))
        sparkle(d, 244, top + 126, 6, (255, 250, 205, 150))
    # buttons
    for y in (top + 40, top + 70):
        ell(d, 256, y, 5, 5, fill=WHITE, outline=outline, width=2)


def draw_sleeve(d, shoulder, hand, color=PJ):
    capsule(d, shoulder[0], shoulder[1], hand[0], hand[1], 16, SKIN, INK, 4)
    # short sleeve cap
    ex = shoulder[0] + (hand[0] - shoulder[0]) * 0.28
    ey = shoulder[1] + (hand[1] - shoulder[1]) * 0.28
    capsule(d, shoulder[0], shoulder[1], ex, ey, 18, color, INK, 4)
    ell(d, hand[0], hand[1], 15, 15, fill=SKIN, outline=INK, width=4)


def draw_legs(d, shoe_color=None, barefoot=True):
    capsule(d, 230, 326, 224, 440, 19, SKIN, INK, 4)
    capsule(d, 282, 326, 288, 440, 19, SKIN, INK, 4)
    if shoe_color:
        for x in (224, 288):
            rrect(d, (x - 30, 432, x + 30, 462), 16, fill=shoe_color,
                  outline=SHOE_D, width=4)
            rrect(d, (x - 30, 448, x + 30, 462), 8, fill=WHITE,
                  outline=(210, 214, 226, 255), width=2)
    else:
        ell(d, 220, 450, 28, 14, fill=SKIN, outline=INK, width=4)
        ell(d, 292, 450, 28, 14, fill=SKIN, outline=INK, width=4)


def base_standing(shoe_color=None):
    img = canvas()
    d = ImageDraw.Draw(img)
    shadow(d)
    draw_legs(d, shoe_color=shoe_color)
    draw_torso(d)
    # short pajama shorts
    rrect(d, (208, 318, 304, 364), 22, fill=PJ_D, outline=INK, width=4)
    return img, d


def finish(img: Image.Image, pose: str) -> None:
    img = img.resize((512, 512), Image.LANCZOS)
    path = os.path.join(OUT, f"char_{pose}.png")
    img.save(path, "PNG")
    print("wrote", os.path.relpath(path, ROOT), img.getbbox())


def pose_stand(pose="stand", shoe_color=None, happy=False):
    img, d = base_standing(shoe_color=shoe_color)
    if happy:
        draw_sleeve(d, (212, 220), (150, 92))
        draw_sleeve(d, (300, 220), (362, 92))
        draw_head(d, 256, 132, eyes="happy", mouth="open")
        sparkle(d, 120, 130, 12, (255, 235, 140, 230))
        sparkle(d, 394, 120, 10, (255, 235, 140, 230))
    else:
        draw_sleeve(d, (212, 220), (186, 328))
        draw_sleeve(d, (300, 220), (326, 328))
        draw_head(d, 256, 132, mouth="smile")
    return img


def pose_sit():
    img = canvas()
    d = ImageDraw.Draw(img)
    shadow(d, cy=474, rx=92)
    # bent legs forward, feet on the floor
    capsule(d, 226, 350, 210, 452, 19, SKIN, INK, 4)
    capsule(d, 286, 350, 302, 452, 19, SKIN, INK, 4)
    ell(d, 206, 458, 27, 14, fill=SKIN, outline=INK, width=4)
    ell(d, 306, 458, 27, 14, fill=SKIN, outline=INK, width=4)
    draw_torso(d, top=232, bottom=372)
    rrect(d, (208, 354, 304, 392), 20, fill=PJ_D, outline=INK, width=4)
    draw_sleeve(d, (212, 250), (178, 340))
    draw_sleeve(d, (300, 250), (334, 340))
    draw_head(d, 256, 172, mouth="smile")
    return img


def pose_drink():
    img, d = base_standing()
    draw_sleeve(d, (212, 220), (180, 328))
    # right arm bent up to the mouth
    capsule(d, 300, 220, 328, 262, 16, SKIN, INK, 4)
    capsule(d, 328, 262, 300, 190, 15, SKIN, INK, 4)
    ell(d, 300, 188, 15, 15, fill=SKIN, outline=INK, width=4)
    # cup
    rrect(d, (274, 140, 326, 198), 12, fill=(139, 208, 240, 235),
          outline=(74, 166, 230, 255), width=4)
    rrect(d, (270, 136, 330, 150), 8, fill=WHITE, outline=(74, 166, 230, 255),
          width=3)
    line(d, [(310, 140), (342, 112)], (255, 138, 128, 255), 7)
    ell(d, 288, 168, 4, 4, fill=WHITE)
    ell(d, 276, 158, 3, 3, fill=WHITE)
    draw_head(d, 256, 132, mouth="open")
    return img


def pose_brush(which="a"):
    img, d = base_standing()
    draw_sleeve(d, (212, 220), (180, 328))
    if which == "a":
        capsule(d, 300, 220, 326, 250, 16, SKIN, INK, 4)
        capsule(d, 326, 250, 292, 184, 15, SKIN, INK, 4)
        ell(d, 292, 184, 15, 15, fill=SKIN, outline=INK, width=4)
        # toothbrush angled up-left
        line(d, [(300, 196), (258, 150)], (255, 255, 255, 255), 9)
        line(d, [(258, 150), (248, 138)], (126, 205, 240, 255), 11)
        ell(d, 246, 134, 7, 7, fill=(226, 246, 255, 255))
        draw_head(d, 252, 136, mouth="open")
        sparkle(d, 320, 130, 8, (255, 255, 255, 210))
    else:
        capsule(d, 300, 220, 334, 258, 16, SKIN, INK, 4)
        capsule(d, 334, 258, 300, 196, 15, SKIN, INK, 4)
        ell(d, 300, 196, 15, 15, fill=SKIN, outline=INK, width=4)
        line(d, [(306, 206), (268, 166)], (255, 255, 255, 255), 9)
        line(d, [(268, 166), (256, 152)], (126, 205, 240, 255), 11)
        ell(d, 254, 148, 7, 7, fill=(226, 246, 255, 255))
        draw_head(d, 260, 140, mouth="open")
        sparkle(d, 214, 128, 8, (255, 255, 255, 210))
    return img


def pose_wash():
    img, d = base_standing()
    # both arms up, towel on the face
    capsule(d, 212, 220, 222, 176, 15, SKIN, INK, 4)
    capsule(d, 300, 220, 290, 176, 15, SKIN, INK, 4)
    ell(d, 222, 174, 14, 14, fill=SKIN, outline=INK, width=4)
    ell(d, 290, 174, 14, 14, fill=SKIN, outline=INK, width=4)
    draw_head(d, 256, 140, eyes="closed", mouth="smile")
    # towel
    rrect(d, (204, 150, 308, 204), 22, fill=WHITE, outline=(180, 212, 226, 255),
          width=4)
    for x in range(216, 300, 16):
        line(d, [(x, 154), (x, 200)], (255, 190, 120, 255), 3)
    for cx, cy, r in [(200, 128, 12), (316, 136, 9), (330, 168, 7)]:
        ell(d, cx, cy, r, r, fill=(180, 230, 250, 190),
            outline=(255, 255, 255, 240), width=3)
        ell(d, cx - r * 0.3, cy - r * 0.3, r * 0.28, r * 0.28, fill=WHITE)
    return img


def pose_shirt():
    img = canvas()
    d = ImageDraw.Draw(img)
    shadow(d)
    draw_legs(d)
    draw_torso(d, top=196, bottom=352, color=SHIRT, collar=True, stars=False)
    rrect(d, (208, 318, 304, 364), 22, fill=(127, 169, 217, 255), outline=INK,
          width=4)
    # short sleeves + arms out
    capsule(d, 212, 220, 178, 300, 16, SKIN, INK, 4)
    capsule(d, 300, 220, 334, 300, 16, SKIN, INK, 4)
    capsule(d, 212, 220, 190, 254, 19, SHIRT, INK, 4)
    capsule(d, 300, 220, 322, 254, 19, SHIRT, INK, 4)
    ell(d, 176, 306, 15, 15, fill=SKIN, outline=INK, width=4)
    ell(d, 336, 306, 15, 15, fill=SKIN, outline=INK, width=4)
    # collar
    poly(d, [(230, 198), (256, 228), (282, 198)], fill=WHITE, outline=INK,
         width=3)
    for y in (248, 278):
        ell(d, 256, y, 5, 5, fill=WHITE, outline=INK, width=2)
    draw_head(d, 256, 132, mouth="smile")
    sparkle(d, 160, 180, 10, (255, 240, 160, 220))
    return img


def pose_crouch_shoes():
    img = canvas()
    d = ImageDraw.Draw(img)
    shadow(d, cy=476, rx=112)
    # crouched body
    rrect(d, (210, 300, 302, 410), 34, fill=PJ, outline=INK, width=5)
    rrect(d, (206, 386, 306, 424), 18, fill=PJ_D, outline=INK, width=4)
    # legs folded, shoes at the front
    capsule(d, 232, 410, 214, 452, 18, SKIN, INK, 4)
    capsule(d, 284, 410, 300, 452, 18, SKIN, INK, 4)
    for x in (210, 302):
        rrect(d, (x - 32, 442, x + 32, 472), 16, fill=SHOE, outline=SHOE_D,
              width=4)
        rrect(d, (x - 32, 458, x + 32, 472), 8, fill=WHITE, outline=(210, 214, 226, 255), width=2)
    # arms reaching down
    capsule(d, 214, 330, 208, 430, 15, SKIN, INK, 4)
    capsule(d, 298, 330, 304, 430, 15, SKIN, INK, 4)
    ell(d, 206, 432, 15, 15, fill=SKIN, outline=INK, width=4)
    ell(d, 306, 432, 15, 15, fill=SKIN, outline=INK, width=4)
    draw_head(d, 256, 252, mouth="smile")
    return img


def pose_lying():
    img = canvas()
    d = ImageDraw.Draw(img)
    # body horizontal, head on the pillow (left)
    rrect(d, (196, 208, 372, 304), 34, fill=PJ, outline=INK, width=5)
    # legs to the right
    capsule(d, 356, 268, 442, 268, 20, SKIN, INK, 4)
    capsule(d, 372, 232, 448, 232, 18, SKIN, INK, 4)
    ell(d, 454, 232, 18, 26, fill=SKIN, outline=INK, width=4)
    ell(d, 454, 270, 18, 26, fill=SKIN, outline=INK, width=4)
    # pajama shorts
    rrect(d, (330, 214, 382, 300), 16, fill=PJ_D, outline=INK, width=4)
    # arm resting on the blanket
    capsule(d, 250, 292, 330, 316, 14, SKIN, INK, 4)
    ell(d, 336, 318, 14, 14, fill=SKIN, outline=INK, width=4)
    # head
    draw_head(d, 156, 250, eyes="closed", mouth="sleep", cheeks=True)
    # blanket edge over the legs
    rrect(d, (300, 290, 430, 314), 10, fill=(96, 205, 196, 255),
          outline=(62, 172, 168, 255), width=3)
    # zzz
    for (x, y, s) in [(210, 150, 9), (232, 128, 7), (250, 110, 5)]:
        sparkle(d, x, y, s, (255, 255, 255, 200))
    return img


def main() -> None:
    poses = {
        "stand": pose_stand(),
        "happy": pose_stand(happy=True),
        "drink": pose_drink(),
        "brush_a": pose_brush("a"),
        "brush_b": pose_brush("b"),
        "wash": pose_wash(),
        "shirt": pose_shirt(),
        "stand_shoes": pose_stand(shoe_color=SHOE),
        "sit": pose_sit(),
        "shoes": pose_crouch_shoes(),
        "lying": pose_lying(),
    }
    for name, img in poses.items():
        finish(img, name)

    # tiny bubble used for washing particles
    b = Image.new("RGBA", (64 * S, 64 * S), (0, 0, 0, 0))
    bd = ImageDraw.Draw(b)
    for cx, cy, r in [(32, 34, 20), (20, 20, 9), (46, 42, 7)]:
        ell(bd, cx, cy, r, r, fill=(190, 235, 250, 200),
            outline=(255, 255, 255, 240), width=2)
        ell(bd, cx - r * 0.3, cy - r * 0.3, r * 0.28, r * 0.28,
            fill=(255, 255, 255, 245))
    b = b.resize((64, 64), Image.LANCZOS)
    b.save(os.path.join(ROOT, "assets", "ui", "bubble.png"), "PNG")
    print("wrote assets/ui/bubble.png")


if __name__ == "__main__":
    main()
