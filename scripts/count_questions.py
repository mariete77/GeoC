import json, glob, os

os.chdir(os.path.dirname(os.path.abspath(__file__)))
files = sorted(glob.glob('questions*.json'))
total = 0
for f in files:
    with open(f, 'r', encoding='utf-8') as fh:
        data = json.load(fh)
        count = len(data)
        total += count
        print(f'{f}: {count} preguntas')

print(f'\nTOTAL: {total} preguntas en {len(files)} archivos')