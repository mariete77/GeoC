import json, os

files = [
    'scripts/questions_historic_buildings.json',
    'scripts/questions_monuments_batch1.json',
    'scripts/questions_monuments_batch2.json',
    'scripts/questions_monuments_batch3.json',
    'scripts/questions_monuments_batch4.json',
]

total = 0
for f in files:
    if os.path.exists(f):
        with open(f, encoding='utf-8') as fh:
            data = json.load(fh)
            print(f'{f}: {len(data)} preguntas')
            total += len(data)
    else:
        print(f'{f}: NO EXISTE')

print(f'\nTotal nuevas preguntas: {total}')

# Also check what types exist
all_questions = []
for f in files:
    if os.path.exists(f):
        with open(f, encoding='utf-8') as fh:
            all_questions.extend(json.load(fh))

types = {}
for q in all_questions:
    t = q.get('type', 'unknown')
    types[t] = types.get(t, 0) + 1

print('\nTipos:')
for t, c in sorted(types.items()):
    print(f'  {t}: {c}')