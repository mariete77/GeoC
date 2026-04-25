from PIL import Image
import numpy as np
import os

sil_dir = os.path.join(os.path.dirname(__file__), '..', 'assets', 'silhouettes')

converted = 0
errors = 0

for f in sorted(os.listdir(sil_dir)):
    if not f.endswith('.png'):
        continue
    path = os.path.join(sil_dir, f)
    try:
        img = Image.open(path)
        
        if img.mode == 'RGBA':
            print(f'  SKIP {f} (already RGBA)')
            continue
        
        # Convert to numpy array
        arr = np.array(img.convert('RGB'))  # (H, W, 3)
        
        # Calculate brightness (grayscale)
        brightness = arr.mean(axis=2)  # (H, W)
        
        # Alpha = inverse of brightness (white → 0, dark → 255)
        alpha = np.clip(255 - brightness, 0, 255).astype(np.uint8)
        
        # Silhouette color: dark blue-grey (#37474F = 55, 71, 79)
        sil_color = np.array([55, 71, 79], dtype=np.float32)
        
        # Create RGBA array
        factor = alpha.astype(np.float32) / 255.0
        rgb = (sil_color[np.newaxis, np.newaxis, :] * factor[:, :, np.newaxis]).astype(np.uint8)
        
        rgba = np.dstack([rgb, alpha])
        
        img_out = Image.fromarray(rgba, 'RGBA')
        img_out.save(path, 'PNG')
        converted += 1
        if converted % 20 == 0:
            print(f'  {converted} converted...')
    except Exception as e:
        errors += 1
        print(f'  ERROR {f}: {e}')

print(f'\nTotal converted: {converted}')
print(f'Errors: {errors}')