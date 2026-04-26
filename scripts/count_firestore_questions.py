import json, urllib.request, pathlib, os

def get_token():
    # Try multiple common paths for firebase-tools.json
    paths = [
        pathlib.Path.home() / '.config' / 'configstore' / 'firebase-tools.json',
        pathlib.Path(os.environ.get('APPDATA', '')) / 'configstore' / 'firebase-tools.json',
        pathlib.Path.home() / '.firebasejs' / 'tokens.json'
    ]
    for p in paths:
        if p.exists():
            try:
                with open(p, 'r', encoding='utf-8') as f:
                    data = json.load(f)
                token = data.get('tokens', {}).get('access_token')
                if token: return token
            except: pass
    return None

token = get_token()
if not token:
    print("Could not find Firebase token. Please log in with 'firebase login'.")
    exit(1)

PROJECT = 'geoquiz-7790d'
url = f'https://firestore.googleapis.com/v1/projects/{PROJECT}/databases/(default)/documents:runQuery'

body = json.dumps({
    'structuredQuery': {
        'collectionSelector': {'collectionId': 'questions'},
        'select': {'fields': []}, # Only get IDs
    }
}).encode()

req = urllib.request.Request(url, data=body, headers={
    'Authorization': f'Bearer {token}',
    'Content-Type': 'application/json',
})

try:
    with urllib.request.urlopen(req, timeout=30) as resp:
        docs = json.loads(resp.read().decode())
        # Filter out empty results or metadata
        count = len([d for d in docs if 'document' in d])
        print(f'TOTAL_QUESTIONS_IN_FIRESTORE: {count}')
        if count > 0:
            print("Sample question type check:")
            # Get first 5 to check their types
            for i in range(min(5, count)):
                doc = docs[i]['document']
                name = doc['name'].split('/')[-1]
                # To get fields we need another request or better select
                print(f"  Found document: {name}")
except Exception as e:
    print(f'Error: {e}')
