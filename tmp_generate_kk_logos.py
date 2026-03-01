from PIL import Image, ImageDraw, ImageFont, ImageFilter
from pathlib import Path

OUT = Path('/Users/kamilkasprzak/Documents/inne/output/imagegen')
OUT.mkdir(parents=True, exist_ok=True)

W = H = 2048  # supersample for clean edges
TARGET = 1024

font_candidates = [
    '/System/Library/Fonts/Supplemental/Arial Bold.ttf',
    '/System/Library/Fonts/Supplemental/Arial Black.ttf',
    '/Library/Fonts/Arial Bold.ttf',
]

def get_font(size):
    for path in font_candidates:
        try:
            return ImageFont.truetype(path, size)
        except Exception:
            pass
    return ImageFont.load_default()

def downsample(img):
    return img.resize((TARGET, TARGET), Image.Resampling.LANCZOS)

def radial_bg(c0, c1, glow=(80,140,220,110)):
    img = Image.new('RGBA', (W, H), c0 + (255,))
    ov = Image.new('RGBA', (W, H), (0,0,0,0))
    d = ImageDraw.Draw(ov)
    # layered gradient rings
    for r, a in [(980,18), (760,30), (560,50), (420,78)]:
        d.ellipse((W//2-r, H//2-r, W//2+r, H//2+r), fill=(c1[0], c1[1], c1[2], a))
    # top-left accent glow
    g = Image.new('RGBA', (W, H), (0,0,0,0))
    gd = ImageDraw.Draw(g)
    gd.ellipse((-320, -360, 1200, 1160), fill=glow)
    g = g.filter(ImageFilter.GaussianBlur(95))
    return Image.alpha_composite(Image.alpha_composite(img, ov), g)

def draw_grid(img, step_small=42, step_big=126):
    d = ImageDraw.Draw(img)
    for x in range(0, W, step_small):
        d.line([(x,0),(x,H)], fill=(32,66,108,70), width=1)
    for y in range(0, H, step_small):
        d.line([(0,y),(W,y)], fill=(32,66,108,70), width=1)
    for x in range(0, W, step_big):
        d.line([(x,0),(x,H)], fill=(72,125,190,118), width=2)
    for y in range(0, H, step_big):
        d.line([(0,y),(W,y)], fill=(72,125,190,118), width=2)
    return img

def circle_panel(img, fill=(13,34,60,255), outline=(122,189,255,255), w=38, m=220):
    d = ImageDraw.Draw(img)
    d.ellipse((m,m,W-m,H-m), fill=fill, outline=outline, width=w)
    return (m,m,W-m,H-m)

def draw_kk_text(img, text='KK', size=760, y_shift=170, primary=(210,239,255,255), shadow=(68,142,221,255), glow=(80,170,255,180)):
    d = ImageDraw.Draw(img)
    f = get_font(size)
    bb = d.textbbox((0,0), text, font=f)
    tw, th = bb[2]-bb[0], bb[3]-bb[1]
    x = (W-tw)//2
    y = (H-th)//2 + y_shift

    # glow layer
    g = Image.new('RGBA', (W,H), (0,0,0,0))
    gd = ImageDraw.Draw(g)
    gd.text((x+6,y+6), text, font=f, fill=glow)
    g = g.filter(ImageFilter.GaussianBlur(7))
    img.alpha_composite(g)

    # shadow + face
    d.text((x+14,y+14), text, font=f, fill=shadow)
    d.text((x,y), text, font=f, fill=primary)
    return x,y,tw,th,f

def add_triangle(img, p=((1360,560),(1580,705),(1290,780)), c=(255,57,166,255)):
    d = ImageDraw.Draw(img)
    d.polygon(p, fill=c)

def vignette(img, strength=90):
    v = Image.new('L', (W,H), 0)
    d = ImageDraw.Draw(v)
    d.ellipse((-260,-260,W+260,H+260), fill=255)
    v = v.filter(ImageFilter.GaussianBlur(strength))
    shade = Image.new('RGBA', (W,H), (0,0,0,95))
    return Image.composite(img, Image.alpha_composite(img, shade), v)

# A: premium CAD neon
imgA = radial_bg((8,22,43), (17,44,80), glow=(74,144,235,115))
maskA = Image.new('L', (W,H), 0)
mdA = ImageDraw.Draw(maskA)
mdA.ellipse((220,220,W-220,H-220), fill=255)
gridA = draw_grid(Image.new('RGBA', (W,H), (0,0,0,0)))
imgA = Image.composite(Image.alpha_composite(imgA, gridA), imgA, maskA)
circle_panel(imgA, fill=(13,35,62,255), outline=(126,194,255,255), w=38, m=220)
draw_kk_text(imgA, size=740, y_shift=170, primary=(218,243,255,255), shadow=(69,146,228,255), glow=(102,184,255,180))
add_triangle(imgA)
imgA = vignette(imgA, 120)

downsample(imgA).save(OUT/'kk-avatar-premium-v1.png')

# B: minimal modern monoline
imgB = radial_bg((9,20,37), (28,51,90), glow=(56,112,196,85))
circle_panel(imgB, fill=(12,29,53,255), outline=(118,182,250,255), w=30, m=240)
d = ImageDraw.Draw(imgB)
# custom geometric KK strokes for clarity at tiny size
st = 86
left_x = 620
baseline_y = 1340
top_y = 770
# first K
d.line([(left_x, top_y), (left_x, baseline_y)], fill=(188,226,255,255), width=st)
d.line([(left_x, 1060), (930, top_y)], fill=(188,226,255,255), width=st)
d.line([(left_x, 1060), (920, baseline_y)], fill=(188,226,255,255), width=st)
# second K
x2 = 1140
d.line([(x2, top_y), (x2, baseline_y)], fill=(94,181,255,255), width=st)
d.line([(x2, 1060), (1450, top_y)], fill=(94,181,255,255), width=st)
d.line([(x2, 1060), (1440, baseline_y)], fill=(94,181,255,255), width=st)
# accent dot
d.ellipse((1370,640,1480,750), fill=(255,72,172,255))
imgB = vignette(imgB, 110)
downsample(imgB).save(OUT/'kk-avatar-premium-v2.png')

# C: split-color futuristic
imgC = radial_bg((7,20,40), (22,57,103), glow=(92,166,255,130))
circle_panel(imgC, fill=(11,30,56,255), outline=(122,190,255,255), w=34, m=220)
x,y,tw,th,f = draw_kk_text(imgC, size=730, y_shift=170, primary=(223,245,255,255), shadow=(72,147,226,255), glow=(96,176,255,180))
# magenta clip on second K
clip = Image.new('L', (W,H), 0)
cd = ImageDraw.Draw(clip)
cd.rectangle((x + tw//2 + 10, y-40, x+tw+80, y+th+80), fill=255)
mag = Image.new('RGBA', (W,H), (0,0,0,0))
md = ImageDraw.Draw(mag)
md.text((x,y), 'KK', font=f, fill=(255,78,178,255))
imgC = Image.composite(mag, imgC, clip)
# diagonal technical line
d = ImageDraw.Draw(imgC)
d.line([(470,1530),(1570,730)], fill=(255,210,118,230), width=20)
imgC = vignette(imgC, 120)
downsample(imgC).save(OUT/'kk-avatar-premium-v3.png')

# D: dark luxe badge
imgD = radial_bg((10,17,30), (24,38,66), glow=(52,98,170,78))
# double ring
d = ImageDraw.Draw(imgD)
d.ellipse((210,210,W-210,H-210), fill=(11,24,46,255), outline=(94,158,232,255), width=26)
d.ellipse((252,252,W-252,H-252), outline=(61,105,168,230), width=8)
# subtle crosshair
d.line([(W//2,340),(W//2,H-340)], fill=(49,86,136,70), width=4)
d.line([(340,H//2),(H-340,H//2)], fill=(49,86,136,70), width=4)
# KK
draw_kk_text(imgD, size=700, y_shift=170, primary=(206,234,255,255), shadow=(58,124,194,255), glow=(79,154,233,170))
add_triangle(imgD, p=((1330,590),(1530,720),(1280,790)), c=(232,63,161,255))
imgD = vignette(imgD, 125)
downsample(imgD).save(OUT/'kk-avatar-premium-v4.png')

print('generated')
for name in ['kk-avatar-premium-v1.png','kk-avatar-premium-v2.png','kk-avatar-premium-v3.png','kk-avatar-premium-v4.png']:
    print(OUT/name)
