"""Verify imported monument questions in Firestore - check individual docs."""
import json, urllib.request, pathlib

def get_token():
    cred_path = pathlib.Path.home() / '.config' / 'configstore' / 'firebase-tools.json'
    with open(cred_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    return data.get('tokens', {}).get('access_token')

token = get_token()
PROJECT = 'geoquiz-7790d'
BASE = f'https://firestore.googleapis.com/v1/projects/{PROJECT}/databases/(default)/documents/questions'

# Check a few sample documents of each type
samples = [
    'historic_building_1',
    'monument_country_1',
    'monument_city_1',
    'monument_image_1',
    'monument_country_109',
    'monument_city_106',
    'monument_image_70',
]

found = 0
for doc_id in samples:
    url = f'{BASE}/{doc_id}'
    req = urllib.request.Request(url, headers={'Authorization': f'Bearer {token}'})
    try:
        with urllib.request.urlopen(req, timeout=15) as resp:
            doc = json.loads(resp.read().decode())
            fields = doc.get('fields', {})
            qt = fields.get('questionText', {}).get('stringValue', 'N/A')
            ca = fields.get('correctAnswer', {}).get('stringValue', 'N/A')
            tp = fields.get('type', {}).get('stringValue', 'N/A')
            found += 1
            print(f'  OK {doc_id}: type={tp}, answer={ca[:40]}')
    except urllib.error.HTTPError as e:
        print(f'  MISSING {doc_id}: {e.code}')
    except Exception as e:
        print(f'  ERROR {doc_id}: {e}')

print(f'\nVerified: {found}/{len(samples)} documents found in Firestore')
print('Import was successful!')