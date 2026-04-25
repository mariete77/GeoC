import json
from collections import Counter

with open('scripts/questions_clean.json', 'r', encoding='utf-8') as f:
    questions = json.load(f)

types = Counter(q.get('type', '?') for q in questions)
print(f'Total questions: {len(questions)}')
print()
for t, c in sorted(types.items()):
    print(f'  {t}: {c}')