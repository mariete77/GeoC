from PIL import Image
import os

sil_dir = os.path.join(os.path.dirname(__file__), '..', 'assets', 'silhouettes')
issues = []
total = 0

for f in sorted(os.listdir(sil_dir)):
    if not f.endswith('.png'):
        continue
    total += 1
    path = os.path.join(sil_dir, f)
    try:
        img = Image.open(path)
        w, h = img.size
        mode = img.mode
        if mode != 'RGBA':
            issues.append(f'{f}: NO ALPHA (mode={mode})')
        if w < 20 or h < 20:
            issues.append(f'{f}: TOO SMALL ({w}x{h})')
        if w > 3000 or h > 3000:
            issues.append(f'{f}: VERY LARGE ({w}x{h})')
    except Exception as e:
        issues.append(f'{f}: ERROR - {e}')

print(f'Total: {total} silhouettes')
print(f'Issues: {len(issues)}')
for i in issues:
    print(f'  {i}')
if not issues:
    print('All OK (size/mode check)')