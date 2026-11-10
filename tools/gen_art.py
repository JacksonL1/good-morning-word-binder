"""Generate flat-cartoon art for the 'Morning Routine' MVP.

Everything is drawn procedurally with Pillow at 2x and downsampled, so the
repository stays self-contained (no external art dependencies).

Usage: python tools/gen_art.py
Outputs into assets/bgs, assets/props, assets/ui.

WARNING: this script overwrites every PNG in assets/bgs, assets/props and
assets/ui. If you have replaced the placeholder art with your own, do NOT run
it again (or back up your assets first). See docs/ASSET_GUIDE.md.
"""
from __future__ import annotations

import math
import os

from PIL import Image, ImageDraw, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BG_DIR = os.path.join(ROOT, "assets", "bgs")
PROP_DIR = os.path.join(ROOT, "assets", "props")
UI_DIR = os.path.join(ROOT, "assets", "ui")
for d in (BG_DIR, PROP_DIR, UI_DIR):
    os.makedirs(d, exist_ok=True)

S = 2  # supersampling factor

# ---------------------------------------------------------------- palette ----
INK = (74, 74, 106, 255)
WALL = (255, 244, 228, 255)
WALL_2 = (250, 233, 210, 255)
WOOD = (222, 168, 110, 255)
WOOD_D = (198, 140, 86, 255)
WOOD_L = (240, 196, 148, 255)
TEAL = (96, 205, 196, 255)
TEAL_D = (62, 172, 168, 255)
BLUE = (110, 198, 255, 255)
BLUE_D = (74, 166, 230, 255)
YELLOW = (255, 209, 102, 255)
YELLOW_D = (240, 176, 64, 255)
CORAL = (255, 138, 128, 255)
CORAL_D = (232, 104, 96, 255)
GREEN = (127, 209, 174, 255)
PURPLE = (179, 157, 219, 255)
WHITE = (255, 255, 255, 255)
CREAM = (255, 250, 240, 255)


def canvas(w: int, h: int) -> Image.Image:
    return Image.new("RGBA", (w * S, h * S), (0, 0, 0, 0))


def finish(img: Image.Image, w: int, h: int, path: str) -> None:
    img = img.resize((w, h), Image.LANCZOS)
    img.save(path, "PNG")
    print("wrote", os.path.relpath(path, ROOT))


def sc(v: float) -> int:
    return int(round(v * S))


def ell(d: ImageDraw.ImageDraw, cx, cy, rx, ry, fill=None, outline=None, width=0):
    d.ellipse([sc(cx - rx), sc(cy - ry), sc(cx + rx), sc(cy + ry)],
              fill=fill, outline=outline, width=sc(width) if width else 0)


def rrect(d: ImageDraw.ImageDraw, box, radius, fill=None, outline=None, width=0):
    x0, y0, x1, y1 = box
    d.rounded_rectangle([sc(x0), sc(y0), sc(x1), sc(y1)], radius=sc(radius),
                        fill=fill, outline=outline,
                        width=sc(width) if width else 0)


def poly(d: ImageDraw.ImageDraw, pts, fill=None, outline=None, width=0):
    pts = [(sc(x), sc(y)) for x, y in pts]
    d.polygon(pts, fill=fill)
    if outline and width:
        pts2 = pts + [pts[0]]
        d.line(pts2, fill=outline, width=sc(width), joint="curve")


def line(d: ImageDraw.ImageDraw, pts, fill, width, joint="curve"):
    d.line([(sc(x), sc(y)) for x, y in pts], fill=fill,
           width=sc(width), joint=joint)


def arc(d: ImageDraw.ImageDraw, box, start, end, fill, width):
    d.arc([sc(box[0]), sc(box[1]), sc(box[2]), sc(box[3])], start, end,
          fill=fill, width=sc(width))


def capsule(d, x0, y0, x1, y1, r, fill, outline=None, width=0):
    d.line([(sc(x0), sc(y0)), (sc(x1), sc(y1))], fill=outline or fill,
           width=sc(r * 2 + (width * 2 if outline else 0)))
    if outline:
        d.line([(sc(x0), sc(y0)), (sc(x1), sc(y1))], fill=fill,
               width=sc(r * 2))
    ell(d, x0, y0, r, r, fill=fill)
    ell(d, x1, y1, r, r, fill=fill)


def soft_shadow(d: ImageDraw.ImageDraw, cx, cy, rx, ry, alpha=60):
    d.ellipse([sc(cx - rx), sc(cy - ry), sc(cx + rx), sc(cy + ry)],
              fill=(60, 50, 90, alpha))


def sparkle(d, cx, cy, r, fill=WHITE):
    poly(d, [(cx, cy - r), (cx + r * 0.28, cy - r * 0.28), (cx + r, cy),
             (cx + r * 0.28, cy + r * 0.28), (cx, cy + r),
             (cx - r * 0.28, cy + r * 0.28), (cx - r, cy),
             (cx - r * 0.28, cy - r * 0.28)], fill=fill)


# ------------------------------------------------------------ backgrounds ----
def bg_bedroom(path: str) -> None:
    W, H = 1280, 720
    img = canvas(W, H)
    d = ImageDraw.Draw(img)

    # wall + floor
    d.rectangle([0, 0, sc(W), sc(470)], fill=WALL)
    d.rectangle([0, sc(470), sc(W), sc(H)], fill=(238, 205, 168, 255))
    for x in range(0, 1281, 120):
        line(d, [(x, 470), (x - 30, H)], (226, 188, 148, 255), 3)
    # baseboard
    d.rectangle([0, sc(452), sc(W), sc(478)], fill=(255, 252, 244, 255))
    line(d, [(0, 478), (W, 478)], (222, 186, 148, 255), 4)

    # window
    rrect(d, (110, 70, 460, 340), 26, fill=(255, 255, 255, 255))
    rrect(d, (126, 86, 444, 324), 18, fill=(168, 221, 240, 255))
    ell(d, 180, 150, 42, 42, fill=(255, 224, 138, 255))  # sun
    for cx, cy, r in [(250, 190, 30), (330, 150, 38), (395, 205, 28),
                      (220, 260, 26), (340, 250, 32), (410, 280, 22)]:
        ell(d, cx, cy, r, r * 0.78, fill=(255, 255, 255, 210))
    line(d, [(285, 86), (285, 324)], (255, 255, 255, 255), 8)
    line(d, [(126, 205), (444, 205)], (255, 255, 255, 255), 8)
    # curtains
    rrect(d, (70, 60, 130, 360), 26, fill=(255, 176, 160, 255))
    rrect(d, (440, 60, 500, 360), 26, fill=(255, 176, 160, 255))
    line(d, [(100, 80), (100, 340)], (255, 205, 195, 255), 6)
    line(d, [(470, 80), (470, 340)], (255, 205, 195, 255), 6)

    # rug under the stage
    d.ellipse([sc(300), sc(486), sc(1000), sc(640)], fill=(255, 220, 180, 255))
    d.ellipse([sc(330), sc(500), sc(970), sc(620)], fill=(255, 236, 208, 255))
    d.ellipse([sc(360), sc(514), sc(940), sc(606)], fill=(255, 246, 228, 255))

    # wall shelf with toys
    rrect(d, (960, 150, 1200, 178), 10, fill=WOOD, outline=WOOD_D, width=3)
    for x, col in [(990, CORAL), (1040, TEAL), (1090, YELLOW), (1140, PURPLE)]:
        rrect(d, (x, 100, x + 38, 150), 8, fill=col, outline=INK, width=3)
        ell(d, x + 19, 100, 9, 9, fill=(255, 255, 255, 160))
    # framed picture of a moon and stars
    rrect(d, (1000, 250, 1180, 390), 14, fill=(255, 255, 255, 255),
          outline=WOOD_D, width=4)
    rrect(d, (1016, 266, 1164, 374), 8, fill=(120, 144, 210, 255))
    ell(d, 1120, 300, 24, 24, fill=(255, 231, 150, 255))
    for x, y, r in [(1050, 300, 7), (1068, 340, 5), (1110, 345, 6),
                    (1140, 335, 4)]:
        sparkle(d, x, y, r, (255, 250, 205, 255))

    # plant
    poly(d, [(1150, 650), (1210, 650), (1195, 560), (1165, 560)], fill=WOOD,
         outline=WOOD_D, width=3)
    for ang in (-70, -40, -10, 20, 50):
        rad = math.radians(ang)
        line(d, [(1180, 560), (1180 + 70 * math.sin(rad), 560 - 70 * math.cos(rad))],
             GREEN, 10)
        ell(d, 1180 + 70 * math.sin(rad), 560 - 70 * math.cos(rad), 14, 20,
            fill=GREEN)

    # little floating dust/sparkles for warmth
    for x, y, r, a in [(560, 120, 7, 130), (760, 90, 5, 100), (880, 220, 6, 110),
                       (640, 270, 4, 80)]:
        sparkle(d, x, y, r, (255, 255, 255, a))
    finish(img, W, H, path)


def bg_bathroom(path: str) -> None:
    W, H = 1280, 720
    img = canvas(W, H)
    d = ImageDraw.Draw(img)

    d.rectangle([0, 0, sc(W), sc(480)], fill=(214, 240, 244, 255))
    # tiles
    for x in range(0, W + 1, 100):
        line(d, [(x, 0), (x, 480)], (196, 228, 236, 255), 4)
    for y in range(0, 481, 100):
        line(d, [(0, y), (W, y)], (196, 228, 236, 255), 4)
    # floor
    d.rectangle([0, sc(480), sc(W), sc(H)], fill=(228, 236, 240, 255))
    d.rectangle([0, sc(456), sc(W), sc(486)], fill=(255, 255, 255, 255))
    line(d, [(0, 486), (W, 486)], (200, 216, 224, 255), 4)
    for x in range(0, W, 160):
        line(d, [(x, 486), (x - 40, H)], (214, 226, 232, 255), 3)

    # mirror
    rrect(d, (90, 80, 360, 330), 40, fill=(255, 255, 255, 255),
          outline=(173, 211, 222, 255), width=10)
    rrect(d, (114, 104, 336, 306), 30, fill=(190, 224, 238, 255))
    line(d, [(150, 260), (230, 150)], (255, 255, 255, 130), 12)
    line(d, [(190, 285), (290, 160)], (255, 255, 255, 90), 7)

    # sink counter (decor only, sits to the left)
    rrect(d, (50, 400, 400, 470), 18, fill=(255, 255, 255, 255))
    rrect(d, (70, 470, 380, 520), 12, fill=(219, 231, 237, 255))

    # bath bubbles
    for cx, cy, r in [(470, 140, 22), (505, 110, 15), (540, 155, 26),
                      (580, 120, 12), (760, 90, 18), (800, 120, 11),
                      (1050, 360, 16), (1085, 335, 10)]:
        ell(d, cx, cy, r, r, fill=(255, 255, 255, 150),
            outline=(255, 255, 255, 210), width=2)
        ell(d, cx - r * 0.3, cy - r * 0.35, r * 0.25, r * 0.25,
            fill=(255, 255, 255, 220))

    # towel hooks on right wall
    for y in (150, 250):
        rrect(d, (1080, y, 1160, y + 14), 7, fill=(174, 205, 217, 255))
        ell(d, 1088, y + 7, 9, 9, fill=(140, 180, 196, 255))

    # bath mat
    rrect(d, (470, 540, 830, 640), 44, fill=(255, 224, 160, 255))
    rrect(d, (500, 560, 800, 620), 30, fill=(255, 238, 196, 255))
    for x in range(515, 790, 34):
        line(d, [(x, 568), (x, 612)], (255, 214, 140, 255), 3)

    # rubber ducky
    ell(d, 940, 620, 46, 34, fill=YELLOW, outline=YELLOW_D, width=3)
    ell(d, 968, 580, 22, 20, fill=YELLOW, outline=YELLOW_D, width=3)
    poly(d, [(986, 580), (1012, 588), (986, 596)], fill=(255, 150, 90, 255))
    ell(d, 976, 576, 4, 4, fill=INK)
    # plant
    rrect(d, (1170, 600, 1250, 690), 16, fill=(255, 255, 255, 255))
    for ang in (-60, -25, 10):
        rad = math.radians(ang)
        line(d, [(1210, 600), (1210 + 55 * math.sin(rad), 600 - 55 * math.cos(rad))],
             GREEN, 10)
        ell(d, 1210 + 55 * math.sin(rad), 600 - 55 * math.cos(rad), 14, 20,
            fill=GREEN)

    # soft window light
    d.polygon([(sc(620), 0), (sc(760), 0), (sc(980), sc(520)),
               (sc(800), sc(520))], fill=(255, 255, 255, 22))
    finish(img, W, H, path)


# ------------------------------------------------------------------ props ----
def prop_bed(path: str) -> None:
    W = H = 512
    img = canvas(W, H)
    d = ImageDraw.Draw(img)
    soft_shadow(d, 256, 452, 190, 26, 55)

    # legs
    rrect(d, (92, 400, 126, 462), 10, fill=WOOD_D)
    rrect(d, (386, 400, 420, 462), 10, fill=WOOD_D)
    # headboard
    rrect(d, (66, 116, 122, 420), 24, fill=WOOD, outline=WOOD_D, width=5)
    ell(d, 94, 160, 18, 18, fill=WOOD_L)
    # base frame
    rrect(d, (74, 300, 438, 410), 22, fill=WOOD, outline=WOOD_D, width=5)
    # mattress
    rrect(d, (94, 244, 424, 330), 24, fill=CREAM, outline=INK, width=4)
    # blanket
    rrect(d, (94, 286, 424, 372), 26, fill=TEAL, outline=TEAL_D, width=5)
    rrect(d, (94, 350, 424, 392), 18, fill=TEAL_D)
    # blanket stripes + stars
    for x in (150, 230, 310, 390):
        line(d, [(x, 300), (x, 352)], (255, 255, 255, 60), 8)
    for x, y in [(156, 322), (250, 330), (344, 316)]:
        sparkle(d, x, y, 11, (255, 250, 210, 230))
    # pillow
    rrect(d, (112, 214, 246, 296), 34, fill=(255, 255, 255, 255),
          outline=INK, width=4)
    rrect(d, (132, 234, 226, 276), 20, fill=(255, 243, 226, 255))
    # headboard decoration
    ell(d, 94, 250, 12, 12, fill=YELLOW)
    finish(img, W, H, path)


def prop_cup(path: str) -> None:
    W = H = 512
    img = canvas(W, H)
    d = ImageDraw.Draw(img)
    soft_shadow(d, 256, 442, 120, 20, 55)

    # handle
    arc(d, (302, 190, 424, 330), -80, 85, (255, 255, 255, 255), 26)
    arc(d, (302, 190, 424, 330), -80, 85, (196, 231, 246, 255), 10)
    # glass body
    poly(d, [(150, 160), (330, 160), (306, 420), (174, 420)],
         fill=(238, 250, 255, 255), outline=(150, 205, 226, 255), width=6)
    poly(d, [(170, 250), (310, 250), (296, 406), (186, 406)],
         fill=(139, 208, 240, 230))
    # water surface
    ell(d, 240, 254, 70, 13, fill=(176, 226, 250, 255))
    # highlights
    line(d, [(180, 280), (194, 380)], (255, 255, 255, 170), 12)
    line(d, [(206, 280), (212, 350)], (255, 255, 255, 110), 6)
    # rim
    rrect(d, (146, 150, 334, 180), 14, fill=(255, 255, 255, 255),
          outline=(150, 205, 226, 255), width=6)
    # straw
    line(d, [(286, 176), (330, 66)], CORAL, 22)
    line(d, [(286, 176), (330, 66)], CORAL_D, 22)
    line(d, [(282, 172), (326, 66)], (255, 255, 255, 160), 6)
    # bubbles
    for cx, cy, r in [(214, 320, 9), (252, 352, 6), (270, 300, 7)]:
        ell(d, cx, cy, r, r, fill=(255, 255, 255, 150))
    finish(img, W, H, path)


def prop_brush(path: str) -> None:
    W, H = 512, 512
    img = canvas(W, H)
    d = ImageDraw.Draw(img)
    soft_shadow(d, 256, 420, 160, 20, 55)

    # rotate a brush drawn horizontally
    layer = Image.new("RGBA", (W * S, H * S), (0, 0, 0, 0))
    bd = ImageDraw.Draw(layer)
    # handle
    capsule(bd, 96, 292, 330, 292, 21, TEAL, TEAL_D, 5)
    rrect(bd, (70, 268, 120, 316), 16, fill=TEAL_D)
    line(bd, [(110, 280), (300, 280)], (255, 255, 255, 90), 7)
    # neck + head
    capsule(bd, 320, 292, 386, 268, 17, WHITE, INK, 4)
    rrect(bd, (356, 224, 454, 292), 24, fill=WHITE, outline=INK, width=5)
    # bristles
    for i in range(7):
        x = 368 + i * 12
        line(bd, [(x, 230), (x, 210)], (126, 205, 240, 255), 9)
        ell(bd, x, 208, 5, 5, fill=(226, 246, 255, 255))
    # toothpaste blob
    ell(bd, 408, 258, 16, 12, fill=(255, 255, 255, 255))
    ell(bd, 398, 250, 10, 8, fill=(178, 232, 205, 255))
    ell(bd, 420, 250, 8, 7, fill=(255, 184, 190, 255))
    bd.ellipse([sc(120), sc(282), sc(140), sc(302)], fill=(255, 255, 255, 120))

    layer = layer.rotate(-18, resample=Image.BICUBIC, center=(256 * S, 256 * S))
    img.alpha_composite(layer)
    finish(img, W, H, path)


def prop_towel(path: str) -> None:
    W = H = 512
    img = canvas(W, H)
    d = ImageDraw.Draw(img)
    soft_shadow(d, 256, 430, 150, 20, 55)

    # hanging loop
    arc(d, (222, 88, 292, 156), 190, 350, (255, 255, 255, 255), 16)
    # folded towel body
    rrect(d, (108, 130, 404, 400), 34, fill=(255, 255, 255, 255),
          outline=(180, 212, 226, 255), width=6)
    rrect(d, (108, 130, 404, 214), 34, fill=(255, 255, 255, 255))
    # colored band
    rrect(d, (108, 208, 404, 258), 0, fill=(255, 190, 120, 255))
    rrect(d, (108, 300, 404, 344), 0, fill=(255, 190, 120, 255))
    for x in range(126, 396, 26):
        line(d, [(x, 214), (x, 254)], (255, 214, 160, 255), 4)
    # fold shadow lines
    line(d, [(130, 268), (382, 268)], (232, 242, 246, 255), 4)
    line(d, [(130, 360), (382, 360)], (232, 242, 246, 255), 4)
    # fringe
    for x in range(120, 400, 16):
        line(d, [(x, 396), (x, 416)], (240, 218, 190, 255), 6)
    # bubbles = washing
    for cx, cy, r in [(356, 336, 20), (390, 306, 12), (330, 300, 10)]:
        ell(d, cx, cy, r, r, fill=(180, 230, 250, 170),
            outline=(255, 255, 255, 230), width=3)
        ell(d, cx - r * 0.3, cy - r * 0.35, r * 0.28, r * 0.28,
            fill=(255, 255, 255, 240))
    finish(img, W, H, path)


def prop_shirt(path: str) -> None:
    W = H = 512
    img = canvas(W, H)
    d = ImageDraw.Draw(img)
    soft_shadow(d, 256, 442, 150, 18, 55)

    # body
    poly(d, [(166, 128), (346, 128), (346, 414), (166, 414)],
         fill=YELLOW, outline=YELLOW_D, width=6)
    # sleeves
    poly(d, [(166, 132), (86, 190), (118, 262), (166, 240)],
         fill=YELLOW, outline=YELLOW_D, width=6)
    poly(d, [(346, 132), (426, 190), (394, 262), (346, 240)],
         fill=YELLOW, outline=YELLOW_D, width=6)
    # sleeve cuffs
    line(d, [(94, 196), (124, 258)], (255, 255, 255, 190), 12)
    line(d, [(418, 196), (388, 258)], (255, 255, 255, 190), 12)
    # collar
    ell(d, 256, 132, 44, 28, fill=(255, 244, 220, 255),
        outline=YELLOW_D, width=5)
    poly(d, [(212, 124), (256, 168), (300, 124)], fill=(255, 244, 220, 255),
         outline=YELLOW_D, width=5)
    # buttons
    for y in (212, 268, 324):
        ell(d, 256, y, 10, 10, fill=(255, 255, 255, 255),
            outline=YELLOW_D, width=3)
    # pocket
    rrect(d, (298, 214, 334, 254), 8, fill=(255, 224, 140, 255),
          outline=YELLOW_D, width=4)
    line(d, [(174, 150), (174, 396)], (255, 255, 255, 80), 8)
    # decorative star
    sparkle(d, 212, 330, 22, (255, 255, 255, 200))
    finish(img, W, H, path)


def prop_shoes(path: str) -> None:
    W, H = 512, 512
    img = canvas(W, H)
    d = ImageDraw.Draw(img)
    soft_shadow(d, 256, 430, 180, 20, 55)

    # back shoe
    rrect(d, (252, 214, 438, 336), 52, fill=(110, 198, 255, 255),
          outline=(74, 166, 230, 255), width=6)
    rrect(d, (252, 300, 450, 360), 24, fill=(255, 255, 255, 255),
          outline=(200, 220, 232, 255), width=4)
    line(d, [(278, 250), (392, 250)], (255, 255, 255, 160), 10)
    # front shoe
    rrect(d, (76, 284, 320, 414), 56, fill=CORAL, outline=CORAL_D, width=6)
    rrect(d, (76, 368, 330, 432), 30, fill=(255, 255, 255, 255),
          outline=(212, 218, 228, 255), width=4)
    # toe cap
    arc(d, (78, 286, 240, 408), 200, 340, (255, 176, 168, 255), 8)
    # laces
    for y in (310, 332, 354):
        line(d, [(196, y), (268, y + 8)], (255, 255, 255, 255), 9)
    # eyelets
    for x in (192, 266):
        for y in (308, 330, 352):
            ell(d, x, y, 4, 4, fill=(220, 90, 82, 255))
    # sole tread
    for x in range(100, 320, 24):
        line(d, [(x, 398), (x, 414)], (222, 228, 238, 255), 4)
    # star patch
    sparkle(d, 132, 330, 18, (255, 255, 255, 210))
    finish(img, W, H, path)


def icon_wake(path: str) -> None:
    W = H = 256
    img = canvas(W, H)
    d = ImageDraw.Draw(img)
    # rays
    for i in range(12):
        ang = math.radians(i * 30)
        x0 = 128 + 58 * math.cos(ang)
        y0 = 122 + 58 * math.sin(ang)
        x1 = 128 + 78 * math.cos(ang)
        y1 = 122 + 78 * math.sin(ang)
        line(d, [(x0, y0), (x1, y1)], (255, 205, 96, 255), 9)
    ell(d, 128, 122, 52, 52, fill=YELLOW, outline=YELLOW_D, width=5)
    # sleepy happy face
    arc(d, (104, 110, 122, 130), 200, 340, INK, 4)
    arc(d, (134, 110, 152, 130), 200, 340, INK, 4)
    arc(d, (114, 134, 142, 154), 20, 160, INK, 4)
    ell(d, 100, 136, 6, 4, fill=(255, 180, 160, 180))
    ell(d, 156, 136, 6, 4, fill=(255, 180, 160, 180))
    # horizon cloud
    ell(d, 128, 196, 66, 18, fill=(255, 255, 255, 255))
    ell(d, 96, 190, 22, 16, fill=(255, 255, 255, 255))
    ell(d, 166, 188, 26, 18, fill=(255, 255, 255, 255))
    finish(img, W, H, path)


def icon_drink(path: str) -> None:
    W = H = 256
    img = canvas(W, H)
    d = ImageDraw.Draw(img)
    # glass
    poly(d, [(76, 62), (180, 62), (168, 208), (88, 208)],
         fill=(238, 250, 255, 255), outline=(150, 205, 226, 255), width=5)
    poly(d, [(88, 112), (168, 112), (160, 198), (96, 198)],
         fill=(139, 208, 240, 235))
    ell(d, 128, 114, 38, 8, fill=(176, 226, 250, 255))
    rrect(d, (72, 54, 184, 74), 10, fill=WHITE, outline=(150, 205, 226, 255),
          width=5)
    line(d, [(160, 68), (190, 22)], CORAL, 10)
    line(d, [(100, 130), (106, 186)], (255, 255, 255, 180), 6)
    for cx, cy, r in [(118, 150, 4), (140, 170, 3)]:
        ell(d, cx, cy, r, r, fill=(255, 255, 255, 170))
    finish(img, W, H, path)


def icon_brush(path: str) -> None:
    W = H = 256
    img = canvas(W, H)
    d = ImageDraw.Draw(img)
    capsule(d, 34, 158, 140, 158, 11, TEAL, TEAL_D, 3)
    rrect(d, (128, 132, 222, 158), 10, fill=WHITE, outline=INK, width=4)
    for i in range(6):
        x = 138 + i * 13
        line(d, [(x, 136), (x, 120)], (126, 205, 240, 255), 6)
        ell(d, x, 118, 4, 4, fill=(226, 246, 255, 255))
    ell(d, 200, 148, 8, 6, fill=(178, 232, 205, 255))
    finish(img, W, H, path)


def icon_wash(path: str) -> None:
    W = H = 256
    img = canvas(W, H)
    d = ImageDraw.Draw(img)
    # towel
    rrect(d, (58, 86, 198, 206), 18, fill=WHITE, outline=(180, 212, 226, 255),
          width=5)
    rrect(d, (58, 130, 198, 158), 0, fill=(255, 190, 120, 255))
    for x in range(70, 190, 18):
        line(d, [(x, 202), (x, 216)], (240, 218, 190, 255), 5)
    # bubbles
    for cx, cy, r in [(176, 60, 24), (208, 92, 15), (146, 46, 11),
                      (210, 46, 9)]:
        ell(d, cx, cy, r, r, fill=(180, 230, 250, 190),
            outline=(255, 255, 255, 240), width=3)
        ell(d, cx - r * 0.3, cy - r * 0.35, r * 0.3, r * 0.3, fill=WHITE)
    finish(img, W, H, path)


def icon_shirt(path: str) -> None:
    W = H = 256
    img = canvas(W, H)
    d = ImageDraw.Draw(img)
    poly(d, [(88, 44), (168, 44), (168, 212), (88, 212)], fill=YELLOW,
         outline=YELLOW_D, width=5)
    poly(d, [(88, 46), (36, 76), (54, 116), (88, 100)], fill=YELLOW,
         outline=YELLOW_D, width=5)
    poly(d, [(168, 46), (220, 76), (202, 116), (168, 100)], fill=YELLOW,
         outline=YELLOW_D, width=5)
    ell(d, 128, 46, 24, 14, fill=(255, 244, 220, 255), outline=YELLOW_D,
        width=4)
    for y in (100, 138, 176):
        ell(d, 128, y, 6, 6, fill=WHITE, outline=YELLOW_D, width=2)
    finish(img, W, H, path)


def icon_shoes(path: str) -> None:
    W = H = 256
    img = canvas(W, H)
    d = ImageDraw.Draw(img)
    rrect(d, (32, 116, 200, 196), 34, fill=CORAL, outline=CORAL_D, width=5)
    rrect(d, (32, 170, 206, 206), 18, fill=WHITE, outline=(212, 218, 228, 255),
          width=4)
    for y in (132, 150):
        line(d, [(100, y), (164, y + 5)], WHITE, 6)
    sparkle(d, 68, 146, 12, (255, 255, 255, 210))
    finish(img, W, H, path)


def icon_coat(path: str) -> None:
    """Heavy winter coat: the decoy for the sunny-day shirt level."""
    W = H = 256
    img = canvas(W, H)
    d = ImageDraw.Draw(img)
    brown = (176, 132, 96, 255)
    brown_d = (140, 100, 70, 255)
    fur = (245, 236, 220, 255)
    # sleeves
    poly(d, [(80, 60), (36, 86), (52, 164), (84, 150)], fill=brown,
         outline=brown_d, width=5)
    poly(d, [(176, 60), (220, 86), (204, 164), (172, 150)], fill=brown,
         outline=brown_d, width=5)
    # body
    rrect(d, (82, 54, 174, 214), 20, fill=brown, outline=brown_d, width=5)
    # fur collar
    ell(d, 128, 56, 58, 20, fill=fur, outline=(214, 202, 184, 255), width=4)
    # zipper and pockets
    line(d, [(128, 76), (128, 206)], (245, 236, 220, 255), 5)
    rrect(d, (98, 150, 126, 180), 8, fill=(150, 108, 78, 255),
          outline=brown_d, width=3)
    rrect(d, (130, 150, 158, 180), 8, fill=(150, 108, 78, 255),
          outline=brown_d, width=3)
    for y in (104, 132):
        ell(d, 128, y, 5, 5, fill=(255, 240, 200, 255))
    # cuffs
    line(d, [(44, 154), (82, 144)], fur, 7)
    line(d, [(212, 154), (174, 144)], fur, 7)
    finish(img, W, H, path)


# -------------------------------------------------------------------- UI -----
def ui_ghost_hand(path: str) -> None:
    """Ghost hand with the index finger pointing DOWN (taps the word card)."""
    W, H = 180, 220
    img = canvas(W, H)
    d = ImageDraw.Draw(img)
    # soft glow
    for i, a in enumerate((30, 50)):
        rrect(d, (44 - i * 6, 54 - i * 6, 148 + i * 6, 196 + i * 6),
              42 + i * 6, fill=(140, 200, 255, a))

    # cuff (wrist at the top)
    rrect(d, (42, 8, 150, 44), 13, fill=(150, 205, 250, 220),
          outline=(120, 186, 245, 255), width=4)
    # palm
    rrect(d, (52, 40, 140, 140), 30, fill=(255, 255, 255, 250),
          outline=(120, 186, 245, 255), width=5)
    # curled fingers (knuckles)
    for x in (60, 84, 108, 128):
        rrect(d, (x, 44, x + 20, 84), 10, fill=(255, 255, 255, 250),
              outline=(120, 186, 245, 255), width=4)
    # thumb
    rrect(d, (32, 74, 60, 128), 14, fill=(255, 255, 255, 250),
          outline=(120, 186, 245, 255), width=4)
    # index finger pointing down
    rrect(d, (74, 122, 104, 200), 15, fill=(255, 255, 255, 255),
          outline=(120, 186, 245, 255), width=5)
    ell(d, 89, 198, 15, 15, fill=(255, 255, 255, 255),
        outline=(120, 186, 245, 255), width=5)
    # fingertip pad
    ell(d, 89, 199, 7, 6, fill=(235, 246, 255, 220))
    # highlight
    line(d, [(60, 56), (60, 124)], (225, 243, 255, 220), 6)
    finish(img, W, H, path)


def ui_star(path: str) -> None:
    W = H = 128
    img = canvas(W, H)
    d = ImageDraw.Draw(img)
    pts = []
    for i in range(10):
        ang = math.radians(-90 + i * 36)
        r = 54 if i % 2 == 0 else 24
        pts.append((64 + r * math.cos(ang), 66 + r * math.sin(ang)))
    poly(d, pts, fill=YELLOW, outline=(250, 186, 70, 255), width=5)
    ell(d, 50, 50, 8, 5, fill=(255, 255, 255, 170))
    finish(img, W, H, path)


def ui_sparkle(path: str) -> None:
    W = H = 128
    img = canvas(W, H)
    d = ImageDraw.Draw(img)
    for dx, dy, s in [(0, 0, 52), (-34, -30, 18), (36, 28, 14)]:
        sparkle(d, 64 + dx, 64 + dy, s, (255, 255, 255, 235))
    finish(img, W, H, path)


def ui_panel(path: str) -> None:
    """Wooden-ish word binder board, 9-slice friendly rounded panel."""
    W, H = 512, 256
    img = canvas(W, H)
    d = ImageDraw.Draw(img)
    rrect(d, (2, 2, 510, 254), 40, fill=(255, 249, 238, 255),
          outline=(222, 178, 128, 255), width=6)
    rrect(d, (18, 18, 494, 238), 30, fill=(255, 242, 222, 255))
    # dotted stitch border
    for x in range(36, 480, 26):
        ell(d, x, 28, 3, 3, fill=(240, 205, 165, 255))
        ell(d, x, 228, 3, 3, fill=(240, 205, 165, 255))
    finish(img, W, H, path)


def ui_card(path: str) -> None:
    """Word card background with a subtle top highlight."""
    W, H = 256, 256
    img = canvas(W, H)
    d = ImageDraw.Draw(img)
    rrect(d, (4, 4, 252, 252), 36, fill=(255, 255, 255, 255),
          outline=(150, 196, 226, 255), width=5)
    rrect(d, (18, 18, 238, 238), 28, fill=(250, 253, 255, 255))
    finish(img, W, H, path)


def ui_glow(path: str) -> None:
    W = H = 256
    img = canvas(W, H)
    d = ImageDraw.Draw(img)
    for r, a in [(120, 20), (100, 26), (80, 34)]:
        ell(d, 128, 128, r, r, fill=(255, 235, 150, a))
    finish(img, W, H, path)


def ui_sound(path: str, muted: bool = False) -> None:
    W = H = 64
    img = canvas(W, H)
    d = ImageDraw.Draw(img)
    color = (74, 74, 106, 255)
    # speaker body
    poly(d, [(10, 25), (21, 25), (34, 13), (34, 51), (21, 39), (10, 39)],
         fill=color)
    if muted:
        line(d, [(42, 24), (56, 40)], (232, 104, 96, 255), 5)
        line(d, [(56, 24), (42, 40)], (232, 104, 96, 255), 5)
    else:
        arc(d, (30, 18, 50, 46), -55, 55, color, 5)
        arc(d, (26, 10, 62, 54), -55, 55, color, 5)
    finish(img, W, H, path)


if __name__ == "__main__":
    bg_bedroom(os.path.join(BG_DIR, "bg_bedroom.png"))
    bg_bathroom(os.path.join(BG_DIR, "bg_bathroom.png"))
    prop_bed(os.path.join(PROP_DIR, "prop_bed.png"))
    prop_cup(os.path.join(PROP_DIR, "prop_cup.png"))
    prop_brush(os.path.join(PROP_DIR, "prop_brush.png"))
    prop_towel(os.path.join(PROP_DIR, "prop_towel.png"))
    prop_shirt(os.path.join(PROP_DIR, "prop_shirt.png"))
    prop_shoes(os.path.join(PROP_DIR, "prop_shoes.png"))
    icon_wake(os.path.join(PROP_DIR, "icon_wake.png"))
    icon_drink(os.path.join(PROP_DIR, "icon_drink.png"))
    icon_brush(os.path.join(PROP_DIR, "icon_brush.png"))
    icon_wash(os.path.join(PROP_DIR, "icon_wash.png"))
    icon_shirt(os.path.join(PROP_DIR, "icon_shirt.png"))
    icon_shoes(os.path.join(PROP_DIR, "icon_shoes.png"))
    icon_coat(os.path.join(PROP_DIR, "icon_coat.png"))
    ui_ghost_hand(os.path.join(UI_DIR, "ghost_hand.png"))
    ui_star(os.path.join(UI_DIR, "star.png"))
    ui_sparkle(os.path.join(UI_DIR, "sparkle.png"))
    ui_panel(os.path.join(UI_DIR, "panel.png"))
    ui_card(os.path.join(UI_DIR, "card.png"))
    ui_glow(os.path.join(UI_DIR, "glow.png"))
    ui_sound(os.path.join(UI_DIR, "sound_on.png"), muted=False)
    ui_sound(os.path.join(UI_DIR, "sound_off.png"), muted=True)
