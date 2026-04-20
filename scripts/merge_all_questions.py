"""Merge all question JSON files into one single file, deduplicating by ID."""
import json
import glob
import os
from collections import defaultdict

os.chdir(os.path.dirname(os.path.abspath(__file__)))
files = sorted(glob.glob('questions_*.json'))

all_questions = {}
all_types = defaultdict(int)
duplicates = 0

for f in files:
    try:
        data = json.load(open(f, encoding='utf-8'))
        for q in data:
            qid = q.get('id', '')
            if qid in all_questions:
                duplicates += 1
            else:
                all_questions[qid] = q
                all_types[q.get('type', 'unknown')] += 1
        print(f'  {f}: {len(data)} questions loaded')
    except Exception as e:
        print(f'  {f}: ERROR - {e}')

questions_list = list(all_questions.values())
print(f'\nTotal unique questions: {len(questions_list)} ({duplicates} duplicates removed)')
print(f'\nBreakdown by type:')
for t, c in sorted(all_types.items(), key=lambda x: -x[1]):
    print(f'  {t}: {c}')

# Save merged file
output = 'questions_all_merged.json'
with open(output, 'w', encoding='utf-8') as f:
    json.dump(questions_list, f, ensure_ascii=False, indent=2)
print(f'\nSaved to {output}')