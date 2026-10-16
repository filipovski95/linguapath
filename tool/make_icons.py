"""Resize tool/icons/*.png into Android launcher icons, web icons and the Play Store icon."""
import os
from PIL import Image, ImageDraw
full = Image.open('tool/icons/icon-full.png').convert('RGBA')
fg = Image.open('tool/icons/icon-foreground.png').convert('RGBA')
res = 'android/app/src/main/res'
def rounded(im, r=0.22):
    m = Image.new('L', im.size, 0)
    ImageDraw.Draw(m).rounded_rectangle([0, 0, im.width - 1, im.height - 1], radius=int(im.width * r), fill=255)
    out = im.copy(); out.putalpha(m); return out
for name, k in {'mdpi': 1, 'hdpi': 1.5, 'xhdpi': 2, 'xxhdpi': 3, 'xxxhdpi': 4}.items():
    os.makedirs(f'{res}/mipmap-{name}', exist_ok=True)
    rounded(full).resize((int(48 * k),) * 2, Image.LANCZOS).save(f'{res}/mipmap-{name}/ic_launcher.png')
    fg.resize((int(108 * k),) * 2, Image.LANCZOS).save(f'{res}/mipmap-{name}/ic_launcher_foreground.png')
open(f'{res}/values/ic_launcher_background.xml', 'w').write(
    '<?xml version="1.0" encoding="utf-8"?>\n<resources>\n    <color name="ic_launcher_background">#FFC531</color>\n</resources>\n')
full.convert('RGB').resize((512, 512), Image.LANCZOS).save('store/play-icon-512.png')
for sz, fn, r in [(192, 'Icon-192.png', True), (512, 'Icon-512.png', True), (192, 'Icon-maskable-192.png', False), (512, 'Icon-maskable-512.png', False)]:
    im = rounded(full) if r else full
    im.resize((sz, sz), Image.LANCZOS).save(f'web/icons/{fn}')
rounded(full).resize((32, 32), Image.LANCZOS).save('web/favicon.png')
print('icons written')
