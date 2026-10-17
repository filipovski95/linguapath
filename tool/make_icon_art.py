"""Draws the Saylark app icon: a speech bubble with an open doorway, and a lark flying out of it.
Writes tool/icons/icon-full.png and icon-foreground.png (1024px); then run tool/make_icons.py."""
import math, sys
from PIL import Image, ImageDraw, ImageFilter

S = 4  # supersampling
N = 1024 * S
VIOLET_A, VIOLET_B = (132, 100, 255), (78, 52, 206)
SUN_A, SUN_B = (255, 216, 102), (255, 170, 30)
INK = (43, 30, 112)
WHITE = (255, 255, 255)

def p(x, y): return (x * S, y * S)

def grad(size, a, b, angle=0.75):
    w, h = size
    g = Image.new('RGB', (256, 256))
    px = g.load()
    for y in range(256):
        for x in range(256):
            t = (x / 255) * (1 - angle) + (y / 255) * angle
            px[x, y] = tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))
    return g.resize(size, Image.BICUBIC)

def bez(p0, p1, p2, p3, n=40):
    out = []
    for i in range(n + 1):
        t = i / n
        mt = 1 - t
        out.append((mt**3*p0[0] + 3*mt*mt*t*p1[0] + 3*mt*t*t*p2[0] + t**3*p3[0],
                    mt**3*p0[1] + 3*mt*mt*t*p1[1] + 3*mt*t*t*p2[1] + t**3*p3[1]))
    return out

def path(*segs):
    pts = []
    for s in segs: pts += s
    return [p(x, y) for x, y in pts]

def bubble_mask():
    m = Image.new('L', (N, N), 0)
    d = ImageDraw.Draw(m)
    d.rounded_rectangle([p(170, 190), p(854, 770)], radius=170 * S, fill=255)
    d.polygon(path([(250, 700), (215, 905), (430, 760)]), fill=255)
    return m

def door_mask():
    m = Image.new('L', (N, N), 0)
    d = ImageDraw.Draw(m)
    cx, top, r, bottom = 470, 330, 150, 690
    d.rectangle([p(cx - r, top + r), p(cx + r, bottom)], fill=255)
    d.ellipse([p(cx - r, top), p(cx + r, top + 2 * r)], fill=255)
    return m

def lark(d, ox, oy, k=1.0, rot=-18, fill=INK):
    c, s_ = math.cos(math.radians(rot)), math.sin(math.radians(rot))
    T = lambda pts: [(ox + (x * c - y * s_) * k, oy + (x * s_ + y * c) * k) for x, y in pts]
    # chubby body: tail at left, round head at right
    body = path(T(bez((-110, 10), (-70, -55), (40, -78), (100, -55))),
                T(bez((100, -55), (150, -38), (160, 15), (120, 35))),
                T(bez((120, 35), (70, 90), (-50, 75), (-110, 10))))
    d.polygon(body, fill=fill)
    # sunny belly
    d.polygon(path(T(bez((0, 45), (40, 75), (95, 60), (125, 28))),
                   T(bez((125, 28), (95, 25), (40, 25), (0, 45)))), fill=SUN_B)
    # short beak
    d.polygon(path(T([(148, -20), (178, -8), (146, 4)])), fill=(255, 170, 30))
    # forked tail
    d.polygon(path(T([(-95, 0), (-185, -45), (-160, 5), (-190, 50), (-95, 25)])), fill=fill)
    # wing raised up and back
    d.polygon(path(T(bez((-20, -45), (-30, -120), (-80, -170), (-150, -190))),
                   T(bez((-150, -190), (-60, -185), (40, -130), (50, -50)))), fill=fill)
    return T

def eye(d, x, y, r):
    d.ellipse([p(x - r, y - r), p(x + r, y + r)], fill=WHITE)
    d.ellipse([p(x - r * 0.45, y - r * 0.45), p(x + r * 0.45, y + r * 0.45)], fill=INK)

def artwork(transparent):
    img = Image.new('RGBA', (N, N), (0, 0, 0, 0))
    if not transparent:
        bg = grad((N, N), VIOLET_A, VIOLET_B).convert('RGBA')
        glow = Image.new('L', (N, N), 0)
        ImageDraw.Draw(glow).ellipse([p(-150, -200), p(560, 460)], fill=60)
        glow = glow.filter(ImageFilter.GaussianBlur(140 * S))
        bg.paste(Image.new('RGBA', (N, N), WHITE), (0, 0), glow)
        img = bg
    bm = bubble_mask()
    # soft shadow under bubble
    sh = bm.filter(ImageFilter.GaussianBlur(28 * S)).point(lambda v: int(v * 0.35))
    shadow = Image.new('RGBA', (N, N), (30, 15, 90, 255))
    img.paste(shadow, (0, int(22 * S)), sh)
    img.paste(Image.new('RGBA', (N, N), WHITE + (255,)), (0, 0), bm)
    # doorway with sunny world inside
    dm = door_mask()
    sun = grad((N, N), SUN_A, SUN_B, angle=0.9).convert('RGBA')
    dd = ImageDraw.Draw(sun)
    dd.ellipse([p(420, 430), p(560, 570)], fill=(255, 246, 214, 255))  # sun
    dd.rectangle([p(0, 610), p(1024, 1024)], fill=(255, 150, 20, 255))  # horizon
    img.paste(sun, (0, 0), dm)
    d = ImageDraw.Draw(img)
    # door frame step
    d.rounded_rectangle([p(300, 684), p(640, 712)], radius=14 * S, fill=(232, 226, 255, 255))
    # the lark flying out of the doorway, up and to the right
    T = lark(d, 585, 505, k=1.25)
    (ex, ey), = T([(105, -25)])
    eye(d, ex, ey, 14)
    (cx_, cy_), = T([(95, 5)])
    d.ellipse([p(cx_ - 13, cy_ - 8), p(cx_ + 13, cy_ + 8)], fill=(255, 140, 170, 255))
    return img.resize((1024, 1024), Image.LANCZOS)

def foreground():
    art = artwork(True)
    # adaptive icons crop to the centre 66%: scale artwork down into the safe zone
    small = art.resize((720, 720), Image.LANCZOS)
    out = Image.new('RGBA', (1024, 1024), (0, 0, 0, 0))
    out.alpha_composite(small, (152, 140))
    return out

if __name__ == '__main__':
    outdir = sys.argv[1] if len(sys.argv) > 1 else 'tool/icons'
    artwork(False).save(f'{outdir}/icon-full.png')
    foreground().save(f'{outdir}/icon-foreground.png')
    print('icon art written to', outdir)
