import json, glob, os
from collections import defaultdict

os.chdir(os.path.dirname(os.path.abspath(__file__)))
files = sorted(glob.glob('questions_*.json'))
total = 0
all_types = defaultdict(int)

for f in files:
    try:
        data = json.load(open(f, encoding='utf-8'))
        count = len(data)
        total += count
        types = defaultdict(int)
        for q in data:
            t = q.get('type', 'unknown')
            types[t] += 1
            all_types[t] += 1
        types_str = ', '.join(f'{k}:{v}' for k,v in sorted(types.items()))
        print(f'{f}: {count} ({types_str})')
    except Exception as e:
        print(f'{f}: ERROR - {e}')

print(f'\nTOTAL questions in JSON files: {total}')
print(f'\nAll types across all files:')
for t, c in sorted(all_types.items(), key=lambda x: -x[1]):
    print(f'  {t}: {c}')