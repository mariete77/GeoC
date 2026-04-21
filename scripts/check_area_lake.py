import json

data = json.load(open('scripts/questions_clean.json', 'r', encoding='utf-8'))

# Check actual field names
if data:
    print('=== FIRST QUESTION KEYS ===')
    print(list(data[0].keys()))
    print()
    print(json.dumps(data[0], ensure_ascii=False)[:500])
    print()

# Check area questions
area = [q for q in data if q.get('type') == 'area']
print(f'=== AREA QUESTIONS: {len(area)} ===')
for q in area[:3]:
    print(json.dumps(q, ensure_ascii=False)[:400])
    print()

# Search for "lago" in any field
lakes = []
for q in data:
    s = json.dumps(q, ensure_ascii=False).lower()
    if 'lago' in s:
        lakes.append(q)
print(f'=== LAKE QUESTIONS: {len(lakes)} ===')
for q in lakes[:5]:
    print(json.dumps(q, ensure_ascii=False)[:300])
    print()

# Check all merged too
import os
if os.path.exists('scripts/questions_all_merged.json'):
    data2 = json.load(open('scripts/questions_all_merged.json', 'r', encoding='utf-8'))
    lakes2 = []
    for q in data2:
        s = json.dumps(q, ensure_ascii=False).lower()
        if 'lago' in s:
            lakes2.append(q)
    print(f'=== LAKE in MERGED: {len(lakes2)} ===')
    for q in lakes2[:5]:
        print(json.dumps(q, ensure_ascii=False)[:300])
        print()