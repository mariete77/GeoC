"""Merge all new monument/building questions into one file for import."""
import json, os

files = [
    'scripts/questions_historic_buildings.json',
    'scripts/questions_monuments_batch1.json',
    'scripts/questions_monuments_batch2.json',
    'scripts/questions_monuments_batch3.json',
    'scripts/questions_monuments_batch4.json',
]

all_questions = []
for f in files:
    if os.path.exists(f):
        with open(f, encoding='utf-8') as fh:
            data = json.load(fh)
            all_questions.extend(data)
            print(f'{f}: {len(data)} preguntas')

# Show a sample
print(f'\nTotal: {len(all_questions)} preguntas')
print(f'\nEjemplo pregunta:')
if all_questions:
    sample = all_questions[0]
    for k, v in sample.items():
        if isinstance(v, str) and len(v) > 100:
            print(f'  {k}: {v[:100]}...')
        else:
            print(f'  {k}: {v}')

# Check all have 'id' field
missing_id = [i for i, q in enumerate(all_questions) if 'id' not in q]
if missing_id:
    print(f'\n⚠️ {len(missing_id)} preguntas sin campo "id"')
else:
    print(f'\n✅ Todas las preguntas tienen campo "id"')

# Save merged file
output = 'scripts/questions_monuments_all.json'
with open(output, 'w', encoding='utf-8') as fh:
    json.dump(all_questions, fh, ensure_ascii=False, indent=2)
print(f'\nSaved merged file: {output}')