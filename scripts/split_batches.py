import json
import math
import os

def split_json():
    with open('scripts/questions_fixed_options.json', 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    # Crear carpeta para fragmentos si no existe
    if not os.path.exists('scripts/batches'):
        os.makedirs('scripts/batches')
        
    batch_size = 100
    total = len(data)
    for i in range(0, total, batch_size):
        batch = data[i:i + batch_size]
        with open(f'scripts/batches/batch_{i//batch_size}.json', 'w', encoding='utf-8') as f:
            json.dump(batch, f, indent=2, ensure_ascii=False)
            
    print(f"✅ Dividido en {math.ceil(total/batch_size)} archivos de {batch_size} preguntas.")

if __name__ == '__main__':
    split_json()
