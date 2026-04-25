"""Fix silhouette question IDs and add country field."""
import json

with open('scripts/questions_silhouettes.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

print(f'Before fix:')
print(f'  Total: {len(data)}')
print(f'  Sample ID: {data[0]["id"]}')
print(f'  Sample imageUrl: {data[0]["imageUrl"]}')

# Fix IDs and country field based on imageUrl
for q in data:
    img = q.get('imageUrl', '')
    # Extract country code from imageUrl like 'assets/silhouettes/es.png'
    if '/' in img:
        code = img.split('/')[-1].replace('.png', '')
        q['id'] = f'silhouette_{code}'
        q['country'] = code.upper()
        if 'extraData' not in q:
            q['extraData'] = {}
        q['extraData']['countryCode'] = code

# Save fixed file
with open('scripts/questions_silhouettes.json', 'w', encoding='utf-8') as f:
    json.dump(data, f, ensure_ascii=False, indent=2)

print(f'\nAfter fix:')
print(f'  Total: {len(data)}')
sample_ids = [q['id'] for q in data[:5]]
print(f'  Sample IDs: {sample_ids}')
sample_countries = [q.get('country', '') for q in data[:5]]
print(f'  Sample countries: {sample_countries}')
unique_ids = len(set(q['id'] for q in data))
print(f'  Unique IDs: {unique_ids}')
print(f'\n  Full sample:')
print(json.dumps(data[0], ensure_ascii=False, indent=2))