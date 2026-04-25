"""Fix type field naming in Firestore: snake_case → camelCase to match Dart enum."""
import json, urllib.request, pathlib

def get_token():
    cred_path = pathlib.Path.home() / '.config' / 'configstore' / 'firebase-tools.json'
    with open(cred_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    return data.get('tokens', {}).get('access_token')

token = get_token()
PROJECT = 'geoquiz-7790d'
BASE = f'https://firestore.googleapis.com/v1/projects/{PROJECT}/databases/(default)/documents'

# Mapping from snake_case (in Firestore) to camelCase (Dart enum)
TYPE_FIXES = {
    'monument_country': 'monumentCountry',
    'monument_city': 'monumentCity',
    'monument_image': 'monumentImage',
    'historic_building': 'historicBuilding',
}

# Step 1: List all questions that need fixing
print("Finding questions with snake_case types...")
docs_to_fix = []

for old_type in TYPE_FIXES:
    url = f'{BASE}/questions?filter=type={old_type}&pageSize=300'
    req = urllib.request.Request(url, headers={'Authorization': f'Bearer {token}'})
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            data = json.loads(resp.read().decode())
            docs = data.get('documents', [])
            for doc in docs:
                name = doc['name'].split('/')[-1]
                docs_to_fix.append((name, old_type, TYPE_FIXES[old_type]))
    except Exception as e:
        print(f'  Error listing {old_type}: {e}')

print(f"Found {len(docs_to_fix)} documents to fix")

# Step 2: Patch each document
fixed = 0
for doc_id, old_type, new_type in docs_to_fix:
    url = f'{BASE}/questions/{doc_id}?updateMask.fieldPaths=type'
    body = json.dumps({
        "fields": {
            "type": {"stringValue": new_type}
        }
    }).encode()

    req = urllib.request.Request(url, data=body, headers={
        'Authorization': f'Bearer {token}',
        'Content-Type': 'application/json',
    }, method='PATCH')

    try:
        with urllib.request.urlopen(req, timeout=15) as resp:
            fixed += 1
            if fixed <= 5 or fixed % 50 == 0:
                print(f'  Fixed {doc_id}: {old_type} → {new_type}')
    except Exception as e:
        print(f'  ERROR fixing {doc_id}: {e}')

print(f'\nDone! Fixed {fixed}/{len(docs_to_fix)} documents')