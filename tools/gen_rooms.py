"""Generate the extra rooms, clothing and shoe props for the staged story.

New this round:
  assets/bgs/bg_living.png       客厅
  assets/bgs/bg_entrance.png     玄关
  assets/props/prop_pants.png    裤子
  assets/props/prop_shoe_l.png   左脚鞋（朝右）
  assets/props/prop_shoe_r.png   右脚鞋（朝左）
  assets/props/icon_pants.png    卡片图标
  assets/props/icon_shoe_l.png
  assets/props/icon_shoe_r.png

Usage: python tools/gen_rooms.py
WARNING: overwrites only the files listed above.
"""
from __future__ import annotations

import math
import os

from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BG = os.path.join(ROOT, "assets", "bgs")
PROP = os.path.join(ROOT, "assets", "props")
S = 2

INK = (74, 74, 106, 255)
WALL = (255, 244, 228, 255)
WOOD = (222, 168, 110, 255)
WOOD_D = (198, 140, 86, 255)
WOOD_L = (240, 196, 148, 255)
TEAL = (96, 205, 196, 255)
TEAL_D = (62, 172, 168, 255)
CORAL = (255, 138, 128, 255)
CORAL_D = (232, 104, 96, 255)
YELLOW = (255, 209, 102, 255)
YELLOW_D = (240, 176, 64, 255)
GREEN = (127, 209, 174, 255)
WHITE = (255, 255, 255, 255)
BLUE = (110, 198, 255, 255)
BLUE_D = (74, 166, 230, 255)
CREAM = (255, 250, 240, 255)


def canvas(w, h):
    return Image.new("RGBA", (w * S, h * S), (0, 0, 0, 0))


def sc(v):
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
        d.line(points + [points[0]], fill=outline, width=sc(width), joint="curve")


def line(d, pts, fill, width):
    d.line([(sc(x), sc(y)) for x, y in pts], fill=fill, width=sc(width),
           joint="curve")


def arc(d, box, start, end, fill, width):
    d.arc([sc(box[0]), sc(box[1]), sc(box[2]), sc(box[3])], start, end,
          fill=fill, width=sc(width))


def sparkle(d, cx, cy, r, fill=WHITE):
    poly(d, [(cx, cy - r), (cx + r * 0.28, cy - r * 0.28), (cx + r, cy),
             (cx + r * 0.28, cy + r * 0.28), (cx, cy + r),
             (cx - r * 0.28, cy + r * 0.28), (cx - r, cy),
             (cx - r * 0.28, cy - r * 0.28)], fill=fill)


def finish(img, w, h, path):
    img = img.resize((w, h), Image.LANCZOS)
    img.save(path, "PNG")
    print("wrote", os.path.relpath(path, ROOT))


# ------------------------------------------------------------------ rooms ----
def bg_living(path):
    W, H = 1280, 720
    img = canvas(W, H)
    d = ImageDraw.Draw(img)
    d.rectangle([0, 0, sc(W), sc(470)], fill=(255, 238, 214, 255))
    d.rectangle([0, sc(470), sc(W), sc(H)], fill=(236, 200, 160, 255))
    for x in range(0, 1281, 120):
        line(d, [(x, 470), (x - 30, H)], (224, 184, 142, 255), 3)
    d.rectangle([0, sc(452), sc(W), sc(478)], fill=CREAM)
    line(d, [(0, 478), (W, 478)], (220, 182, 142, 255), 4)

    # big sunny window
    rrect(d, (430, 60, 900, 340), 26, fill=WHITE)
    rrect(d, (446, 76, 884, 324), 18, fill=(174, 224, 242, 255))
    ell(d, 530, 140, 40, 40, fill=(255, 226, 140, 255))
    for cx, cy, r in [(620, 170, 32), (700, 140, 38), (790, 180, 28),
                      (660, 240, 26), (800, 250, 32)]:
        ell(d, cx, cy, r, r * 0.75, fill=(255, 255, 255, 205))
    line(d, [(665, 76), (665, 324)], WHITE, 8)
    line(d, [(446, 200), (884, 200)], WHITE, 8)
    # curtains
    rrect(d, (386, 50, 448, 360), 26, fill=(255, 190, 150, 255))
    rrect(d, (882, 50, 944, 360), 26, fill=(255, 190, 150, 255))
    line(d, [(416, 70), (416, 340)], (255, 214, 186, 255), 6)
    line(d, [(912, 70), (912, 340)], (255, 214, 186, 255), 6)

    # sofa on the left
    rrect(d, (60, 330, 380, 470), 30, fill=TEAL, outline=TEAL_D, width=5)
    rrect(d, (76, 300, 364, 372), 26, fill=(120, 216, 208, 255),
          outline=TEAL_D, width=4)
    for x in (120, 240):
        rrect(d, (x, 300, x + 90, 358), 20, fill=(140, 226, 218, 255),
              outline=TEAL_D, width=3)
    rrect(d, (60, 430, 380, 486), 18, fill=TEAL_D)
    rrect(d, (44, 330, 76, 470), 16, fill=(120, 216, 208, 255),
          outline=TEAL_D, width=4)
    rrect(d, (364, 330, 396, 470), 16, fill=(120, 216, 208, 255),
          outline=TEAL_D, width=4)

    # rug
    d.ellipse([sc(300), sc(500), sc(1010), sc(660)], fill=(255, 218, 176, 255))
    d.ellipse([sc(340), sc(518), sc(970), sc(640)], fill=(255, 238, 210, 255))

    # side table with a cup
    rrect(d, (1010, 380, 1210, 410), 12, fill=WOOD, outline=WOOD_D, width=4)
    rrect(d, (1030, 410, 1050, 500), 8, fill=WOOD_D)
    rrect(d, (1170, 410, 1190, 500), 8, fill=WOOD_D)
    rrect(d, (1080, 330, 1130, 382), 10, fill=(139, 208, 240, 240),
          outline=BLUE_D, width=4)
    rrect(d, (1076, 326, 1134, 342), 8, fill=WHITE, outline=BLUE_D, width=3)
    # plant
    poly(d, [(1180, 620), (1240, 620), (1228, 540), (1192, 540)], fill=WOOD,
         outline=WOOD_D, width=3)
    for ang in (-60, -25, 10, 45):
        rad = math.radians(ang)
        line(d, [(1210, 540), (1210 + 62 * math.sin(rad), 540 - 62 * math.cos(rad))],
             GREEN, 10)
        ell(d, 1210 + 62 * math.sin(rad), 540 - 62 * math.cos(rad), 13, 18,
            fill=GREEN)

    # wall art
    rrect(d, (140, 110, 330, 250), 14, fill=WHITE, outline=WOOD_D, width=4)
    rrect(d, (154, 124, 316, 236), 8, fill=(150, 205, 235, 255))
    ell(d, 200, 170, 26, 26, fill=(255, 226, 140, 255))
    for x, y in [(250, 160), (280, 190), (230, 205)]:
        sparkle(d, x, y, 8, (255, 255, 255, 220))
    finish(img, W, H, path)


def bg_entrance(path):
    W, H = 1280, 720
    img = canvas(W, H)
    d = ImageDraw.Draw(img)
    d.rectangle([0, 0, sc(W), sc(480)], fill=(247, 236, 220, 255))
    d.rectangle([0, sc(480), sc(W), sc(H)], fill=(226, 213, 196, 255))
    for x in range(0, 1281, 160):
        line(d, [(x, 480), (x - 40, H)], (214, 200, 184, 255), 3)
    d.rectangle([0, sc(462), sc(W), sc(488)], fill=(255, 252, 244, 255))
    line(d, [(0, 488), (W, 488)], (214, 200, 184, 255), 4)

    # the front door
    rrect(d, (420, 70, 860, 470), 22, fill=WOOD, outline=WOOD_D, width=6)
    rrect(d, (452, 100, 640, 268), 14, fill=(238, 198, 154, 255),
          outline=WOOD_D, width=4)
    rrect(d, (662, 100, 830, 268), 14, fill=(238, 198, 154, 255),
          outline=WOOD_D, width=4)
    rrect(d, (452, 300, 828, 448), 14, fill=(238, 198, 154, 255),
          outline=WOOD_D, width=4)
    ell(d, 806, 336, 15, 15, fill=YELLOW, outline=YELLOW_D, width=4)
    rrect(d, (772, 322, 840, 350), 12, fill=YELLOW, outline=YELLOW_D, width=4)

    # coat hooks
    rrect(d, (100, 150, 300, 172), 10, fill=WOOD, outline=WOOD_D, width=3)
    for x in (140, 200, 260):
        ell(d, x, 180, 11, 11, fill=(140, 180, 196, 255))
    # hanging coat
    poly(d, [(186, 190), (214, 190), (230, 330), (170, 330)], fill=CORAL,
         outline=CORAL_D, width=4)
    rrect(d, (176, 320, 226, 350), 10, fill=CORAL_D)

    # shoe rack
    rrect(d, (940, 330, 1210, 350), 10, fill=WOOD, outline=WOOD_D, width=3)
    rrect(d, (940, 430, 1210, 450), 10, fill=WOOD, outline=WOOD_D, width=3)
    rrect(d, (940, 530, 1210, 550), 10, fill=WOOD, outline=WOOD_D, width=3)
    for x in (960, 1200):
        rrect(d, (x, 330, x + 18, 560), 8, fill=WOOD_D)
    # decorative shoes on the rack
    for i, (x, y) in enumerate([(990, 306), (1080, 306), (1160, 406)]):
        rrect(d, (x, y, x + 66, y + 30), 14, fill=BLUE, outline=BLUE_D, width=3)

    # mat
    rrect(d, (470, 500, 810, 590), 26, fill=(255, 224, 160, 255))
    rrect(d, (496, 518, 784, 572), 18, fill=(255, 240, 200, 255))
    for x in range(510, 780, 40):
        line(d, [(x, 524), (x, 566)], (255, 214, 140, 255), 3)

    # umbrella stand
    rrect(d, (120, 520, 220, 640), 16, fill=(150, 196, 214, 255),
          outline=(110, 160, 180, 255), width=4)
    line(d, [(150, 520), (150, 420)], WOOD_D, 8)
    arc(d, (128, 400, 176, 452), 180, 360, TEAL, 8)
    finish(img, W, H, path)


# ------------------------------------------------------------------ props ----
def prop_pants(path):
    W = H = 512
    img = canvas(W, H)
    d = ImageDraw.Draw(img)
    ell(d, 256, 452, 130, 16, fill=(60, 50, 90, 50))

    body = (108, 154, 208, 255)
    dark = (78, 122, 176, 255)
    # waistband
    rrect(d, (146, 96, 366, 150), 18, fill=dark, outline=INK, width=5)
    # hips + legs as one shape
    poly(d, [(146, 130), (366, 130), (356, 300), (300, 432), (256, 432),
             (250, 300), (262, 300), (256, 432), (212, 432), (156, 300)],
         fill=body, outline=INK, width=5)
    # crotch notch
    poly(d, [(232, 200), (256, 300), (280, 200)], fill=body)
    line(d, [(232, 200), (256, 300), (280, 200)], INK, 4)
    # leg cuffs
    rrect(d, (196, 400, 262, 444), 12, fill=dark, outline=INK, width=4)
    rrect(d, (250, 400, 316, 444), 12, fill=dark, outline=INK, width=4)
    # drawstring
    line(d, [(232, 124), (246, 160)], WHITE, 6)
    line(d, [(280, 124), (266, 160)], WHITE, 6)
    ell(d, 246, 162, 6, 6, fill=WHITE)
    ell(d, 266, 162, 6, 6, fill=WHITE)
    # pockets
    arc(d, (156, 150, 216, 230), 300, 60, dark, 5)
    arc(d, (296, 150, 356, 230), 120, 240, dark, 5)
    # star patch
    sparkle(d, 320, 300, 16, (255, 250, 205, 220))
    finish(img, W, H, path)


def _shoe(path, facing=1):
    """Side-view sneaker. facing=1 points right, facing=-1 points left."""
    W = H = 512
    img = canvas(W, H)
    d = ImageDraw.Draw(img)
    ell(d, 256, 420, 150, 18, fill=(60, 50, 90, 50))
    cx = 256

    def X(v):
        return cx + facing * (v - cx)

    # sole
    rrect(d, (86, 340, 430, 404), 30, fill=WHITE, outline=(210, 214, 226, 255),
          width=5)
    # upper body of the shoe
    poly(d, [(110, 344), (140, 240), (232, 214), (330, 226), (392, 288),
             (414, 344)], fill=CORAL, outline=CORAL_D, width=6)
    # toe cap
    poly(d, [(352, 250), (392, 288), (414, 344), (330, 344), (338, 276)],
         fill=(255, 168, 158, 255), outline=CORAL_D, width=4)
    # ankle collar
    rrect(d, (126, 168, 236, 250), 26, fill=(255, 168, 158, 255),
          outline=CORAL_D, width=5)
    ell(d, 181, 214, 44, 32, fill=(255, 214, 208, 255), outline=CORAL_D, width=4)
    # laces
    for i, y in enumerate((258, 284, 310)):
        line(d, [(216, y), (296, y + 8)], WHITE, 9)
    # tongue
    rrect(d, (206, 206, 300, 258), 14, fill=(255, 190, 182, 255),
          outline=CORAL_D, width=4)
    # stitching
    line(d, [(120, 330), (410, 330)], CORAL_D, 3)
    # tread
    for x in range(110, 420, 26):
        line(d, [(x, 388), (x, 402)], (222, 228, 238, 255), 4)
    # star patch near the heel
    sparkle(d, 152, 300, 18, (255, 255, 255, 210))
    if facing < 0:
        img = img.transpose(Image.FLIP_LEFT_RIGHT)
    finish(img, W, H, path)


def icon_pants(path):
    W = H = 256
    img = canvas(W, H)
    d = ImageDraw.Draw(img)
    body = (108, 154, 208, 255)
    dark = (78, 122, 176, 255)
    rrect(d, (74, 34, 182, 62), 10, fill=dark, outline=INK, width=4)
    poly(d, [(76, 50), (180, 50), (174, 140), (146, 216), (128, 216),
             (124, 140), (132, 140), (128, 216), (108, 216), (80, 140)],
         fill=body, outline=INK, width=4)
    poly(d, [(112, 84), (128, 140), (144, 84)], fill=body)
    line(d, [(112, 84), (128, 140), (144, 84)], INK, 3)
    rrect(d, (94, 198, 130, 222), 7, fill=dark, outline=INK, width=3)
    rrect(d, (126, 198, 162, 222), 7, fill=dark, outline=INK, width=3)
    line(d, [(116, 42), (122, 62)], WHITE, 4)
    line(d, [(140, 42), (134, 62)], WHITE, 4)
    finish(img, W, H, path)


def icon_shoe(path, facing=1):
    W = H = 256
    img = canvas(W, H)
    d = ImageDraw.Draw(img)
    rrect(d, (34, 168, 222, 204), 16, fill=WHITE, outline=(210, 214, 226, 255),
          width=4)
    poly(d, [(48, 170), (64, 108), (120, 92), (176, 100), (206, 140),
             (216, 170)], fill=CORAL, outline=CORAL_D, width=5)
    poly(d, [(178, 112), (206, 140), (216, 170), (176, 170), (180, 128)],
         fill=(255, 168, 158, 255), outline=CORAL_D, width=3)
    rrect(d, (56, 66, 122, 114), 16, fill=(255, 168, 158, 255),
          outline=CORAL_D, width=4)
    ell(d, 89, 88, 24, 18, fill=(255, 214, 208, 255), outline=CORAL_D, width=3)
    for y in (124, 140, 156):
        line(d, [(110, y), (156, y + 4)], WHITE, 6)
    rrect(d, (104, 96, 160, 124), 8, fill=(255, 190, 182, 255),
          outline=CORAL_D, width=3)
    sparkle(d, 74, 148, 11, (255, 255, 255, 210))
    if facing < 0:
        img = img.transpose(Image.FLIP_LEFT_RIGHT)
    finish(img, W, H, path)


if __name__ == "__main__":
    bg_living(os.path.join(BG, "bg_living.png"))
    bg_entrance(os.path.join(BG, "bg_entrance.png"))
    prop_pants(os.path.join(PROP, "prop_pants.png"))
    _shoe(os.path.join(PROP, "prop_shoe_l.png"), facing=-1)
    _shoe(os.path.join(PROP, "prop_shoe_r.png"), facing=1)
    icon_pants(os.path.join(PROP, "icon_pants.png"))
    icon_shoe(os.path.join(PROP, "icon_shoe_l.png"), facing=-1)
    icon_shoe(os.path.join(PROP, "icon_shoe_r.png"), facing=1)
