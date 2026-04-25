from PIL import Image
import os

# Inspect a few sample silhouettes
samples = ['es.png', 'us.png', 'br.png', 'jp.png', 'au.png', 'de.png', 'fr.png', 'it.png']
sil_dir = os.path.join(os.path.dirname(__file__), '..', 'assets', 'silhouettes')

for name in samples:
    path = os.path.join(sil_dir, name)
    if not os.path.exists(path):
        print(f'{name}: NOT FOUND')
        continue
    img = Image.open(path)
    w, h = img.size
    print(f'{name}: {w}x{h}, mode={img.mode}')
    
    # Sample colors at key positions
    print(f'  (0,0): {img.getpixel((0,0))}')
    print(f'  (center): {img.getpixel((w//2, h//2))}')
    print(f'  (w-1,0): {img.getpixel((w-1, 0))}')
    print(f'  (0,h-1): {img.getpixel((0, h-1))}')
    print(f'  (w-1,h-1): {img.getpixel((w-1, h-1))}')
    
    # Find unique colors in the image (sample a grid)
    colors = set()
    step = max(1, min(w, h) // 10)
    for x in range(0, w, step):
        for y in range(0, h, step):
            colors.add(img.getpixel((x, y)))
    print(f'  Unique colors (sampled): {len(colors)} -> {list(colors)[:10]}')
    print()