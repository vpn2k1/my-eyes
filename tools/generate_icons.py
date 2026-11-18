"""Regenerate the original flat UI artwork: python3.11 tools/generate_icons.py (Pillow)."""
from pathlib import Path
from PIL import Image, ImageDraw
import math

ROOT = Path(__file__).resolve().parents[1] / 'assets' / 'icons'
SCALE = 4
INK = '#253c62'
BLUE = '#74b9f2'
AMBER = '#f4be55'
PAPER = '#f5f7fd'
TEAL = '#71cfbe'
CORAL = '#f19b87'


def make(name):
    image = Image.new('RGBA', (192, 192))
    d = ImageDraw.Draw(image)

    def box(bounds, fill, radius=4, outline=INK):
        d.rounded_rectangle(tuple(v*SCALE for v in bounds), radius*SCALE,
                            fill=fill, outline=outline, width=2*SCALE)

    def ellipse(bounds, fill, outline=INK):
        d.ellipse(tuple(v*SCALE for v in bounds), fill=fill,
                  outline=outline, width=2*SCALE)

    def line(points, fill=INK, width=2.5):
        xy = [(int(x*SCALE), int(y*SCALE)) for x, y in points]
        d.line(xy, fill=fill, width=round(width*SCALE), joint='curve')
        for x, y in xy:
            r = width*SCALE/2
            d.ellipse((x-r, y-r, x+r, y+r), fill=fill)

    def poly(points, fill, outline=INK):
        d.polygon([(x*SCALE, y*SCALE) for x, y in points], fill=fill)
        if outline:
            line(points + [points[0]], outline, 2)

    if name in ('camera', 'video', 'switchCamera'):
        box((5, 13, 35 if name == 'video' else 43, 37), BLUE, 6)
        if name == 'video':
            poly([(35, 20), (44, 15), (44, 35), (35, 30)], AMBER)
            ellipse((13, 20, 27, 33), PAPER)
        else:
            box((15, 8, 31, 15), AMBER, 3)
            ellipse((15, 18, 33, 36), PAPER)
            ellipse((20, 23, 28, 31), INK)
        if name == 'switchCamera':
            line([(8, 42), (36, 42), (32, 39)], AMBER)
    elif name in ('photo', 'brokenImage'):
        box((6, 7, 42, 41), PAPER, 6)
        ellipse((28, 13, 36, 21), AMBER)
        poly([(9, 35), (19, 22), (27, 31), (32, 26), (39, 36)], TEAL)
        if name == 'brokenImage':
            line([(24, 8), (20, 20), (27, 26), (22, 40)], CORAL, 3)
    elif name == 'learn':
        poly([(5, 10), (16, 8), (24, 12), (32, 8), (43, 10), (43, 38), (32, 36), (24, 40), (16, 36), (5, 38)], PAPER)
        poly([(7, 12), (16, 11), (21, 14), (21, 35), (16, 33), (7, 35)], BLUE, None)
        line([(24, 13), (24, 37)])
        line([(29, 18), (37, 16)], AMBER)
        line([(29, 24), (37, 22)], AMBER)
        line([(29, 30), (35, 29)], AMBER)
    elif name == 'search':
        line([(32, 32), (42, 42)], INK, 6)
        ellipse((5, 5, 36, 36), BLUE)
        ellipse((10, 10, 31, 31), PAPER)
        for x, y, color in [(16, 17, AMBER), (24, 16, TEAL), (20, 25, CORAL)]:
            ellipse((x-3, y-3, x+3, y+3), color, color)
    elif name in ('eye', 'compare'):
        if name == 'eye':
            pts = [(5+i*38/40, 24-13*math.sin(math.pi*i/40)) for i in range(41)]
            pts += [(43-i*38/40, 24+13*math.sin(math.pi*i/40)) for i in range(41)]
            poly(pts, PAPER)
            ellipse((14, 14, 34, 34), BLUE)
            poly([(24, 16), (30, 19), (32, 25), (24, 32)], AMBER, None)
            ellipse((20, 20, 28, 28), INK)
            ellipse((21, 20, 24, 23), PAPER, PAPER)
        else:
            box((5, 8, 43, 40), PAPER, 6)
            box((8, 11, 23, 37), BLUE, 3, BLUE)
            box((25, 11, 40, 37), AMBER, 3, AMBER)
            line([(24, 5), (24, 43)])
            ellipse((19, 19, 29, 29), PAPER)
    elif name == 'settings':
        for i in range(8):
            a = i*math.pi/4
            line([(24+13*math.cos(a), 24+13*math.sin(a)),
                  (24+18*math.cos(a), 24+18*math.sin(a))], INK, 7)
        ellipse((9, 9, 39, 39), BLUE)
        ellipse((18, 18, 30, 30), PAPER)
        ellipse((32, 5, 41, 14), AMBER)
    elif name in ('info', 'help'):
        ellipse((6, 6, 42, 42), BLUE if name == 'info' else AMBER)
        if name == 'info':
            ellipse((22, 13, 26, 17), INK, INK)
            line([(24, 23), (24, 33)], INK, 3)
        else:
            line([(17, 18), (19, 14), (26, 14), (30, 18), (29, 22), (24, 26)], INK, 3)
            ellipse((22, 32, 26, 36), INK, INK)
    elif name == 'bulb':
        ellipse((11, 7, 37, 33), AMBER)
        box((18, 31, 30, 39), BLUE, 2)
        line([(21, 43), (27, 43)])
        line([(24, 30), (24, 23), (20, 19)])
        line([(24, 23), (28, 19)])
        for a in (0, math.pi, -math.pi/2):
            line([(24+18*math.cos(a), 20+18*math.sin(a)), (24+21*math.cos(a), 20+21*math.sin(a))], AMBER, 2)
    elif name in ('flashOn', 'flashOff'):
        poly([(27, 5), (10, 27), (23, 27), (20, 43), (39, 19), (26, 19)], AMBER)
        if name == 'flashOff':
            line([(7, 7), (41, 41)], PAPER, 6)
            line([(7, 7), (41, 41)], INK, 3)
    elif name == 'adjust':
        for y, x, color in [(12, 17, BLUE), (24, 32, AMBER), (36, 21, TEAL)]:
            line([(6, y), (42, y)], PAPER, 5)
            line([(6, y), (42, y)], INK, 2)
            ellipse((x-5, y-5, x+5, y+5), color)
    elif name == 'palette':
        ellipse((5, 6, 43, 42), AMBER)
        ellipse((28, 27, 43, 42), None)
        # A thumb hole and paint wells remain recognizable without hue.
        ellipse((29, 30, 36, 37), PAPER)
        for x, y, color in [(14, 23, BLUE), (20, 14, TEAL), (31, 17, CORAL)]:
            ellipse((x-4, y-4, x+4, y+4), color)
    elif name == 'chevron':
        line([(19, 13), (30, 24), (19, 35)])
    elif name == 'back':
        line([(26, 12), (14, 24), (26, 36)])
        line([(15, 24), (40, 24)])
    elif name == 'check':
        line([(11, 24), (20, 33), (38, 14)], INK, 4)
    elif name == 'external':
        line([(23, 9), (10, 9), (10, 38), (39, 38), (39, 26)])
        line([(24, 24), (40, 8), (29, 8)])
        line([(40, 8), (40, 19)])
    elif name == 'restart':
        pts = [(24+15*math.cos(a), 25+15*math.sin(a)) for a in [(-.7+i*5.1/50) for i in range(51)]]
        line(pts)
        line([(9, 9), (19, 9), (19, 19)])
    else:
        raise ValueError(name)
    image.resize((144, 144), Image.Resampling.LANCZOS).save(ROOT / f'{name}.webp', lossless=True)


if __name__ == '__main__':
    ROOT.mkdir(parents=True, exist_ok=True)
    for name in ('camera video switchCamera photo brokenImage learn search eye compare settings info help bulb flashOn flashOff adjust palette chevron back check external restart'.split()):
        make(name)
