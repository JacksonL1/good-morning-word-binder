"""Generate the little kid character used by the animation layer.

Design rules:
  * one consistent 512x512 canvas, feet at y=468 for standing poses
  * long pajama pants are drawn separately, so the child is never "bottomless"
  * arms are drawn BEHIND the torso and there are no separate shoulder balls
  * toothbrush / cup / towel are drawn AFTER the head so they sit in front
  * the lying pose has a horizontal neck connecting head and torso

Usage: python tools/gen_character.py
Outputs: assets/char/char_<pose>.png

WARNING: overwrites all poses in assets/char. See docs/ASSET_GUIDE.md.
"""
from __future__ import annotations

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
PJ = (191, 232, 245, 255)
PJ_D = (143, 208, 230, 255)
PANTS = (108, 154, 208, 255)
PANTS_D = (78, 122, 176, 255)
SHIRT = (255, 209, 102, 255)
SHIRT_D = (240, 176, 64, 255)
SHOE = (255, 138, 128, 255)
SHOE_D = (232, 104, 96, 255)
WHITE = (255, 255, 255, 255)
TEAL = (96, 205, 196, 255)
TEAL_D = (62, 172, 168, 255)


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
    # outline first (slightly wider), then the fill
    if outline:
        d.line([(sc(x0), sc(y0)), (sc(x1), sc(y1))], fill=outline,
               width=sc(r * 2 + max(width, 4) * 2))
    d.line([(sc(x0), sc(y0)), (sc(x1), sc(y1))], fill=fill,
           width=sc(r * 2))
    ell(d, x0, y0, r, r, fill=fill, outline=outline, width=width)
    ell(d, x1, y1, r, r, fill=fill, outline=outline, width=width)


def capsule_outlined(d, x0, y0, x1, y1, r, fill, width=4):
    # draw a clean rounded outline around a capsule by stroking a wider line
    d.line([(sc(x0), sc(y0)), (sc(x1), sc(y1))], fill=INK,
           width=sc(r * 2 + width * 2))
    ell(d, x0, y0, r + width, r + width, fill=INK)
    ell(d, x1, y1, r + width, r + width, fill=INK)
    d.line([(sc(x0), sc(y0)), (sc(x1), sc(y1))], fill=fill,
           width=sc(r * 2))
    ell(d, x0, y0, r, r, fill=fill)
    ell(d, x1, y1, r, r, fill=fill)


def sparkle(d, cx, cy, r, fill=WHITE):
    poly(d, [(cx, cy - r), (cx + r * 0.28, cy - r * 0.28), (cx + r, cy),
             (cx + r * 0.28, cy + r * 0.28), (cx, cy + r),
             (cx - r * 0.28, cy + r * 0.28), (cx - r, cy),
             (cx - r * 0.28, cy - r * 0.28)], fill=fill)


def shadow(d, cx=256, cy=474, rx=100, ry=14):
    ell(d, cx, cy, rx, ry, fill=(60, 50, 90, 42))


def draw_head(d, cx, cy, eyes="open", mouth="smile", neck=True):
    if neck:
        rrect(d, (cx - 17, cy + 48, cx + 17, cy + 84), 8, fill=SKIN,
              outline=INK, width=4)
    ell(d, cx, cy - 6, 74, 72, fill=HAIR, outline=INK, width=4)
    ell(d, cx - 63, cy + 8, 13, 17, fill=SKIN, outline=INK, width=4)
    ell(d, cx + 63, cy + 8, 13, 17, fill=SKIN, outline=INK, width=4)
    ell(d, cx, cy, 62, 65, fill=SKIN, outline=INK, width=4)
    poly(d, [(cx - 60, cy - 16), (cx - 57, cy - 52), (cx - 30, cy - 64),
             (cx + 4, cy - 66), (cx + 40, cy - 56), (cx + 59, cy - 30),
             (cx + 61, cy - 12), (cx + 40, cy - 34), (cx + 12, cy - 42),
             (cx - 18, cy - 34), (cx - 40, cy - 22)],
         fill=HAIR, outline=INK, width=3)
    rrect(d, (cx - 70, cy - 34, cx - 50, cy + 30), 10, fill=HAIR,
          outline=INK, width=3)
    rrect(d, (cx + 50, cy - 34, cx + 70, cy + 30), 10, fill=HAIR,
          outline=INK, width=3)
    arc(d, (cx - 42, cy - 16, cx - 16, cy + 2), 200, 340, INK, 3)
    arc(d, (cx + 16, cy - 16, cx + 42, cy + 2), 200, 340, INK, 3)
    if eyes == "closed":
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
    ell(d, cx, cy + 24, 4, 3, fill=SKIN_D)
    if mouth == "open":
        ell(d, cx, cy + 38, 12, 9, fill=(120, 60, 70, 255))
        ell(d, cx, cy + 42, 7, 4, fill=(255, 140, 140, 255))
    elif mouth == "smile":
        arc(d, (cx - 17, cy + 18, cx + 17, cy + 46), 20, 160, INK, 4)
    else:
        line(d, [(cx - 10, cy + 36), (cx + 10, cy + 36)], INK, 3)
    ell(d, cx - 40, cy + 30, 12, 7, fill=(255, 168, 156, 120))
    ell(d, cx + 40, cy + 30, 12, 7, fill=(255, 168, 156, 120))


def draw_arm(d, shoulder, elbow, hand, r=14, with_hand=True):
    """Arm behind the torso; only the lower part is visible."""
    capsule_outlined(d, shoulder[0], shoulder[1], elbow[0], elbow[1], r, SKIN)
    capsule_outlined(d, elbow[0], elbow[1], hand[0], hand[1], r, SKIN)
    if with_hand:
        ell(d, hand[0], hand[1], r + 2, r + 2, fill=SKIN, outline=INK, width=4)


def draw_short_sleeves(d, color, left=True, right=True, drop=0):
    """Sleeve wedges that reach deep inside the torso, so the silhouette and the
    body are always ONE solid shape (no floating 'second shoulder')."""
    if left:
        poly(d, [(258, 198 + drop), (196, 212 + drop), (186, 258 + drop),
                 (258, 270 + drop)], fill=color, outline=INK, width=4)
    if right:
        poly(d, [(254, 198 + drop), (316, 212 + drop), (326, 258 + drop),
                 (254, 270 + drop)], fill=color, outline=INK, width=4)


def draw_torso(d, top=196, bottom=340, color=PJ, collar=False):
    rrect(d, (204, top, 308, bottom), 36, fill=color, outline=INK, width=5)
    if collar:
        poly(d, [(228, top + 2), (256, top + 34), (284, top + 2)], fill=WHITE,
             outline=INK, width=3)
    if color == SHIRT:
        for y in (top + 50, top + 82):
            ell(d, 256, y, 5, 5, fill=WHITE, outline=INK, width=2)
    else:
        sparkle(d, 228, top + 52, 9, (255, 250, 205, 200))
        sparkle(d, 284, top + 98, 7, (255, 250, 205, 170))
        for y in (top + 44, top + 74):
            ell(d, 256, y, 5, 5, fill=WHITE, outline=INK, width=2)


def draw_shoe(d, x, y, color=SHOE):
    rrect(d, (x - 32, y - 22, x + 32, y + 10), 15, fill=color,
          outline=SHOE_D, width=4)
    rrect(d, (x - 32, y - 2, x + 32, y + 10), 7, fill=WHITE,
          outline=(210, 214, 226, 255), width=2)


def draw_feet(d, y=456, shoe_color=None):
    if shoe_color:
        draw_shoe(d, 220, y, shoe_color)
        draw_shoe(d, 292, y, shoe_color)
    else:
        ell(d, 220, y, 28, 13, fill=SKIN, outline=INK, width=4)
        ell(d, 292, y, 28, 13, fill=SKIN, outline=INK, width=4)


def draw_pants_stand(d, shoe_color=None):
    # long pajama pants: clearly visible below the top
    rrect(d, (206, 322, 306, 366), 18, fill=PANTS, outline=INK, width=4)
    capsule_outlined(d, 228, 348, 222, 438, 21, PANTS)
    capsule_outlined(d, 284, 348, 290, 438, 21, PANTS)
    rrect(d, (200, 428, 252, 456), 12, fill=PANTS_D, outline=INK, width=3)
    rrect(d, (260, 428, 312, 456), 12, fill=PANTS_D, outline=INK, width=3)
    draw_feet(d, 458, shoe_color)


def draw_pants_sit(d):
    rrect(d, (206, 340, 306, 382), 18, fill=PANTS, outline=INK, width=4)
    capsule_outlined(d, 230, 362, 206, 424, 21, PANTS)
    capsule_outlined(d, 282, 362, 306, 424, 21, PANTS)
    rrect(d, (184, 414, 236, 442), 12, fill=PANTS_D, outline=INK, width=3)
    rrect(d, (276, 414, 328, 442), 12, fill=PANTS_D, outline=INK, width=3)
    draw_feet(d, 458)


def draw_pants_crouch(d):
    rrect(d, (210, 366, 302, 414), 18, fill=PANTS, outline=INK, width=4)
    capsule_outlined(d, 232, 396, 206, 438, 20, PANTS)
    capsule_outlined(d, 280, 396, 306, 438, 20, PANTS)
    rrect(d, (182, 428, 234, 456), 12, fill=PANTS_D, outline=INK, width=3)
    rrect(d, (278, 428, 330, 456), 12, fill=PANTS_D, outline=INK, width=3)
    draw_feet(d, 458, SHOE)


def draw_body_standing(d, color=PJ, shoe_color=None, collar=False,
                       sleeves=True):
    draw_pants_stand(d, shoe_color)
    draw_arm(d, (222, 238), (196, 292), (190, 336))
    draw_arm(d, (290, 238), (316, 292), (322, 336))
    if sleeves:
        draw_short_sleeves(d, color)
    draw_torso(d, color=color, collar=collar)
    draw_head(d, 256, 132)
    # hands in front of the pants
    ell(d, 190, 336, 16, 16, fill=SKIN, outline=INK, width=4)
    ell(d, 322, 336, 16, 16, fill=SKIN, outline=INK, width=4)


def base_stand(color=PJ, shoe_color=None, collar=False) -> Image.Image:
    img = canvas()
    d = ImageDraw.Draw(img)
    shadow(d)
    draw_body_standing(d, color=color, shoe_color=shoe_color, collar=collar)
    return img


def pose_stand() -> Image.Image:
    return base_stand()


def pose_happy() -> Image.Image:
    img = canvas()
    d = ImageDraw.Draw(img)
    shadow(d)
    draw_pants_stand(d)
    draw_arm(d, (222, 238), (186, 162), (160, 92))
    draw_arm(d, (290, 238), (326, 162), (352, 92))
    draw_short_sleeves(d, PJ)
    draw_torso(d)
    draw_head(d, 256, 132, eyes="happy", mouth="open")
    ell(d, 160, 92, 16, 16, fill=SKIN, outline=INK, width=4)
    ell(d, 352, 92, 16, 16, fill=SKIN, outline=INK, width=4)
    sparkle(d, 118, 126, 11, (255, 235, 140, 230))
    sparkle(d, 394, 118, 9, (255, 235, 140, 230))
    return img


def pose_shirt() -> Image.Image:
    img = canvas()
    d = ImageDraw.Draw(img)
    shadow(d)
    draw_pants_stand(d)
    draw_arm(d, (222, 238), (190, 292), (184, 336))
    draw_arm(d, (290, 238), (322, 292), (328, 336))
    draw_short_sleeves(d, SHIRT)
    draw_torso(d, color=SHIRT, collar=True)
    draw_head(d, 256, 132)
    ell(d, 184, 336, 16, 16, fill=SKIN, outline=INK, width=4)
    ell(d, 328, 336, 16, 16, fill=SKIN, outline=INK, width=4)
    sparkle(d, 160, 180, 10, (255, 240, 160, 220))
    return img


def pose_sit() -> Image.Image:
    img = canvas()
    d = ImageDraw.Draw(img)
    shadow(d, cy=476, rx=92)
    draw_pants_sit(d)
    draw_arm(d, (222, 272), (180, 320), (174, 358))
    draw_arm(d, (290, 272), (332, 320), (338, 358))
    draw_short_sleeves(d, PJ)
    draw_torso(d, top=240, bottom=378)
    draw_head(d, 256, 172)
    ell(d, 174, 358, 15, 15, fill=SKIN, outline=INK, width=4)
    ell(d, 338, 358, 15, 15, fill=SKIN, outline=INK, width=4)
    return img


def pose_drink() -> Image.Image:
    """Head tipped back, cup held up to the mouth by a clearly visible arm."""
    img = canvas()
    d = ImageDraw.Draw(img)
    shadow(d)
    draw_pants_stand(d)
    # left arm relaxed at the side
    draw_arm(d, (222, 238), (194, 292), (188, 336))
    # right arm: upper arm down-out, forearm up to the mouth (elbow bend)
    capsule_outlined(d, 290, 240, 330, 286, 14, SKIN)
    capsule_outlined(d, 330, 286, 312, 214, 14, SKIN)
    draw_short_sleeves(d, PJ)
    draw_torso(d)
    # head slightly tilted back
    draw_head(d, 254, 138, mouth="open")
    # cup, mouth edge at the lips
    rrect(d, (272, 118, 320, 176), 11, fill=(139, 208, 240, 240),
          outline=(74, 166, 230, 255), width=4)
    rrect(d, (268, 114, 324, 132), 8, fill=WHITE,
          outline=(74, 166, 230, 255), width=3)
    ell(d, 286, 150, 5, 5, fill=WHITE)
    ell(d, 302, 138, 4, 4, fill=WHITE)
    # hand wraps the cup
    ell(d, 312, 214, 17, 17, fill=SKIN, outline=INK, width=4)
    line(d, [(306, 206), (300, 196)], INK, 3)
    ell(d, 188, 336, 16, 16, fill=SKIN, outline=INK, width=4)
    return img


def _brush_pose(which: str) -> Image.Image:
    """Toothbrush held vertically at the mouth; 'a' and 'b' shift it left/right."""
    img = canvas()
    d = ImageDraw.Draw(img)
    shadow(d)
    draw_pants_stand(d)
    draw_arm(d, (222, 238), (194, 292), (188, 336))
    # forearm up beside the cheek
    capsule_outlined(d, 290, 240, 328, 284, 14, SKIN)
    hand_y = 214 if which == "a" else 222
    capsule_outlined(d, 328, 284, 306, hand_y + 14, 14, SKIN)
    draw_short_sleeves(d, PJ)
    draw_torso(d)
    draw_head(d, 256, 132, mouth="open")

    # brush: handle from the hand up to the teeth, head of the brush at the lips
    shift = -6 if which == "a" else 6
    hand = (306, hand_y + 14)
    tip = (250 + shift, 158)
    line(d, [hand, (272 + shift, 186)], WHITE, 9)
    line(d, [hand, (272 + shift, 186)], (236, 240, 250, 255), 9)
    # bristle head
    rrect(d, (tip[0] - 16, tip[1] - 12, tip[0] + 6, tip[1] + 12), 8,
          fill=(236, 246, 255, 255), outline=INK, width=3)
    for i in range(3):
        line(d, [(tip[0] - 12 + i * 6, tip[1] - 12),
                 (tip[0] - 12 + i * 6, tip[1] - 22)],
             (170, 216, 240, 255), 4)
    # hand gripping the handle
    ell(d, hand[0], hand[1], 16, 16, fill=SKIN, outline=INK, width=4)
    ell(d, 188, 336, 16, 16, fill=SKIN, outline=INK, width=4)
    sparkle(d, 340 - shift, 150, 7, (255, 255, 255, 200))
    return img


def pose_brush_a() -> Image.Image:
    return _brush_pose("a")


def pose_brush_b() -> Image.Image:
    return _brush_pose("b")


def pose_wash() -> Image.Image:
    img = canvas()
    d = ImageDraw.Draw(img)
    shadow(d)
    draw_pants_stand(d)
    draw_arm(d, (222, 238), (206, 190), (222, 166), with_hand=False)
    draw_arm(d, (290, 238), (306, 190), (290, 166), with_hand=False)
    draw_short_sleeves(d, PJ)
    draw_torso(d)
    draw_head(d, 256, 140, eyes="closed", mouth="smile")
    # towel in front of the lower face
    rrect(d, (202, 150, 310, 208), 22, fill=WHITE,
          outline=(180, 212, 226, 255), width=4)
    for x in range(214, 300, 16):
        line(d, [(x, 154), (x, 204)], (255, 190, 120, 255), 3)
    ell(d, 218, 166, 16, 16, fill=SKIN, outline=INK, width=4)
    ell(d, 294, 166, 16, 16, fill=SKIN, outline=INK, width=4)
    for cx, cy, r in [(196, 126, 11), (318, 134, 9), (330, 166, 7)]:
        ell(d, cx, cy, r, r, fill=(180, 230, 250, 190),
            outline=(255, 255, 255, 240), width=3)
        ell(d, cx - r * 0.3, cy - r * 0.3, r * 0.28, r * 0.28, fill=WHITE)
    return img


def pose_shoes() -> Image.Image:
    img = canvas()
    d = ImageDraw.Draw(img)
    shadow(d, cy=476, rx=112)
    draw_pants_crouch(d)
    draw_arm(d, (216, 330), (204, 390), (202, 430), with_hand=False)
    draw_arm(d, (296, 330), (308, 390), (310, 430), with_hand=False)
    draw_short_sleeves(d, PJ)
    draw_torso(d, top=300, bottom=404)
    draw_head(d, 256, 250)
    ell(d, 202, 432, 15, 15, fill=SKIN, outline=INK, width=4)
    ell(d, 310, 432, 15, 15, fill=SKIN, outline=INK, width=4)
    return img


def draw_head_profile_up(d, cx, cy, r=62):
    """Head seen from the side, lying on the back: the face points UP (towards
    the ceiling), so the nose is at the top, the forehead to the LEFT (towards
    the head of the bed) and the chin towards the RIGHT (towards the feet).
    Hair covers the back of the skull, i.e. the lower half resting on the pillow.
    """
    # skull
    ell(d, cx, cy, r, r, fill=SKIN, outline=INK, width=4)
    # back of the skull / hair: lower + left part of the circle
    poly(d, [(cx - r + 2, cy - 6), (cx - r + 8, cy + 34), (cx - 20, cy + r - 2),
             (cx + 26, cy + r - 4), (cx + 52, cy + 30), (cx + 46, cy + 6),
             (cx + 20, cy + 16), (cx - 14, cy + 18), (cx - 40, cy + 6)],
         fill=HAIR, outline=INK, width=3)
    # a couple of hair strands
    line(d, [(cx - 34, cy + 34), (cx + 4, cy + 44)], (138, 98, 80, 255), 3)
    line(d, [(cx - 40, cy + 16), (cx - 4, cy + 24)], (138, 98, 80, 255), 3)
    # ear (side of the head, slightly towards the feet side)
    ell(d, cx + 26, cy + 2, 13, 17, fill=SKIN, outline=INK, width=3)
    arc(d, (cx + 20, cy - 6, cx + 32, cy + 10), 40, 200, INK, 2)
    # nose pointing up
    poly(d, [(cx - 14, cy - 52), (cx - 20, cy - 74), (cx + 4, cy - 58)],
         fill=SKIN, outline=INK, width=3)
    # closed eye
    arc(d, (cx - 44, cy - 48, cx - 18, cy - 26), 200, 340, INK, 4)
    # mouth / chin line, towards the feet side
    arc(d, (cx + 16, cy - 46, cx + 38, cy - 24), 20, 150, INK, 3)
    # blush
    ell(d, cx - 30, cy - 16, 12, 7, fill=(255, 168, 156, 120))
    # ear-side highlight
    ell(d, cx + 50, cy - 20, 8, 5, fill=(255, 168, 156, 90))


def pose_lying() -> Image.Image:
    """On his back in bed: ONE continuous body block with a side-profile head
    whose face points up, so it never reads as a face stuck on a lying body."""
    img = canvas()
    d = ImageDraw.Draw(img)
    head_x, head_y = 150, 262
    # torso block starts UNDER the head, so the join is solid
    rrect(d, (146, 220, 374, 310), 40, fill=PJ, outline=INK, width=5)
    line(d, [(214, 232), (214, 298)], (150, 205, 225, 255), 3)
    # long pajama pants, legs to the right
    rrect(d, (346, 226, 398, 304), 16, fill=PANTS, outline=INK, width=4)
    capsule_outlined(d, 386, 266, 446, 266, 24, PANTS)
    rrect(d, (430, 240, 462, 292), 12, fill=PANTS_D, outline=INK, width=3)
    # bare feet
    ell(d, 470, 266, 18, 24, fill=SKIN, outline=INK, width=4)
    # arm resting along the blanket
    capsule_outlined(d, 252, 302, 332, 326, 14, SKIN)
    ell(d, 340, 328, 14, 14, fill=SKIN, outline=INK, width=4)
    # blanket edge over the hips
    rrect(d, (312, 294, 424, 320), 10, fill=TEAL, outline=TEAL_D, width=3)
    # profile head, drawn last so it sits on top of the torso
    draw_head_profile_up(d, head_x, head_y)
    for (x, y, s) in [(214, 156, 9), (236, 134, 7), (254, 116, 5)]:
        sparkle(d, x, y, s, (255, 255, 255, 200))
    return img


def finish(img: Image.Image, pose: str) -> None:
    img = img.resize((512, 512), Image.LANCZOS)
    path = os.path.join(OUT, f"char_{pose}.png")
    img.save(path, "PNG")
    print("wrote", os.path.relpath(path, ROOT), img.getbbox())


def main() -> None:
    poses = {
        "stand": pose_stand(),
        "happy": pose_happy(),
        "drink": pose_drink(),
        "brush_a": pose_brush_a(),
        "brush_b": pose_brush_b(),
        "wash": pose_wash(),
        "shirt": pose_shirt(),
        "stand_shoes": base_stand(shoe_color=SHOE),
        "sit": pose_sit(),
        "shoes": pose_shoes(),
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
