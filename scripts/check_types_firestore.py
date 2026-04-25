"""Check type values in Firestore to see if they're camelCase or snake_case."""
import json, urllib.request, pathlib

def get_token():
    cred_path = pathlib.Path.home() / '.config' / 'configstore' / 'firebase-tools.json'
    with open(cred_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    return data.get('tokens', {}).get('access_token')

token = get_token()
PROJECT = 'geoquiz-7790d'
url = f'https://firestore.googleapis.com/v1/projects/{PROJECT}/databases/(default)/documents:runQuery'

# Check each type
for qtype in ['monumentImage', 'monumentCountry', 'monumentCity', 'historicBuilding',
              'monument_image', 'monument_country', 'monument_city', 'historic_building']:
    body = json.dumps({
        'structuredQuery': {
            'collectionSelector': {'collectionId': 'questions'},
            'where': {
                'fieldFilter': {
                    'field': {'fieldPath': 'type'},
                    'op': 'EQUAL',
                    'value': {'stringValue': qtype}
                }
            },
            'limit': 2
        }
    }).encode()
    req = urllib.request.Request(url, data=body, headers={
        'Authorization': f'Bearer {token}',
        'Content-Type': 'application/json',
    })
    try:
        with urllib.request.urlopen(req, timeout=15) as resp:
            docs = json.loads(resp.read().decode())
            count = len([d for d in docs if 'document' in d])
            if count > 0:
                doc = docs[0]['document']
                fields = doc.get('fields', {})
                name = doc['name'].split('/')[-1]
                t = fields.get('type', {}).get('stringValue', '?')
                print(f'  {qtype}: {count}+ found (e.g. {name} type={t})')
            else:
                print(f'  {qtype}: 0 found')
    except Exception as e:
        print(f'  {qtype}: Error - {e}')