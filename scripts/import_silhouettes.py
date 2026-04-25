"""Import silhouette questions to Firestore via REST API."""
import json
import urllib.request
import urllib.parse
import sys
import time
import os
import pathlib

PROJECT_ID = "geoquiz-7790d"
BASE = f"projects/{PROJECT_ID}/databases/(default)/documents/questions"
BATCH_SIZE = 100

def get_access_token():
    """Read access token from Firebase CLI credentials, refresh if expired."""
    cred_path = pathlib.Path.home() / ".config" / "configstore" / "firebase-tools.json"
    if not cred_path.exists():
        cred_path = pathlib.Path.home() / "AppData" / "Roaming" / "firebase-tools.json"
    if not cred_path.exists():
        return None
    
    with open(cred_path, "r", encoding="utf-8") as f:
        data = json.load(f)
    
    tokens = data.get("tokens", {})
    expires_at = tokens.get("expires_at", 0)
    access_token = tokens.get("access_token")
    refresh_token = tokens.get("refresh_token")
    
    if expires_at and expires_at > time.time() + 60:
        print(f"  Token valid (expires in {int(expires_at - time.time())}s)")
        return access_token
    
    if refresh_token:
        print("  Refreshing token...")
        CLIENT_ID = "563584335869-fgrhgmd47bqnekij5i8b5pr3ho849se6.apps.googleusercontent.com"
        CLIENT_SECRET = "j9iVZfS8kk8upbheD6mF2Vap"
        
        refresh_data = urllib.parse.urlencode({
            "grant_type": "refresh_token",
            "refresh_token": refresh_token,
            "client_id": CLIENT_ID,
            "client_secret": CLIENT_SECRET,
        }).encode("utf-8")
        
        req = urllib.request.Request(
            "https://oauth2.googleapis.com/token",
            data=refresh_data,
            headers={"Content-Type": "application/x-www-form-urlencoded"},
            method="POST"
        )
        
        try:
            with urllib.request.urlopen(req, timeout=30) as resp:
                new_tokens = json.loads(resp.read().decode())
                access_token = new_tokens["access_token"]
                tokens["access_token"] = access_token
                tokens["expires_at"] = time.time() + new_tokens.get("expires_in", 3600)
                tokens["expires_in"] = new_tokens.get("expires_in", 3600)
                data["tokens"] = tokens
                with open(cred_path, "w", encoding="utf-8") as f:
                    json.dump(data, f)
                print("  Token refreshed!")
                return access_token
        except Exception as e:
            print(f"  Token refresh failed: {e}")
            return access_token
    
    return access_token

def field(v):
    if isinstance(v, str):
        return {"stringValue": v}
    elif isinstance(v, bool):
        return {"booleanValue": v}
    elif isinstance(v, int):
        return {"integerValue": str(v)}
    elif isinstance(v, float):
        return {"doubleValue": v}
    elif isinstance(v, dict):
        return {"mapValue": {"fields": {k: field(val) for k, val in v.items()}}}
    elif isinstance(v, list):
        return {"arrayValue": {"values": [field(item) for item in v]}}
    elif v is None:
        return {"nullValue": "NULL_VALUE"}
    return {"stringValue": str(v)}

# --- Main ---
print("=== Import Silhouette Questions to Firestore ===\n")

# Get token
print("1. Getting Firebase token...")
access_token = get_access_token()
if not access_token:
    print("ERROR: No token. Run 'firebase login' first.")
    sys.exit(1)
print("   OK\n")

# Load silhouettes
script_dir = os.path.dirname(os.path.abspath(__file__))
sil_file = os.path.join(script_dir, "questions_silhouettes.json")

print(f"2. Loading {sil_file}...")
with open(sil_file, "r", encoding="utf-8") as f:
    questions = json.load(f)
print(f"   {len(questions)} silhouette questions loaded\n")

# Check first question structure
print(f"3. Sample question:")
sample = questions[0]
print(f"   id: {sample['id']}")
print(f"   type: {sample['type']}")
print(f"   answer: {sample['correctAnswer']}")
print(f"   imageUrl: {sample.get('imageUrl', 'NONE')}")
print(f"   options: {sample.get('options', [])}")
print()

# Import in batches
print(f"4. Importing {len(questions)} questions in batches of {BATCH_SIZE}...")
batches = [questions[i:i+BATCH_SIZE] for i in range(0, len(questions), BATCH_SIZE)]
total_imported = 0

for batch_num, batch in enumerate(batches, 1):
    writes = []
    for q in batch:
        doc_id = q["id"]
        fields = {k: field(v) for k, v in q.items()}
        writes.append({"update": {"name": f"{BASE}/{doc_id}", "fields": fields}})

    body = json.dumps({"writes": writes}).encode("utf-8")
    url = f"https://firestore.googleapis.com/v1/projects/{PROJECT_ID}/databases/(default)/documents:batchWrite"

    headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {access_token}",
    }
    req = urllib.request.Request(url, data=body, headers=headers, method="POST")

    try:
        with urllib.request.urlopen(req, timeout=60) as resp:
            result = json.loads(resp.read().decode())
            total_imported += len(batch)
            print(f"   Batch {batch_num}/{len(batches)}: {len(batch)} imported (total: {total_imported}/{len(questions)})")
    except Exception as e:
        print(f"   ERROR batch {batch_num}: {e}")
        time.sleep(2)

    if batch_num < len(batches):
        time.sleep(1)

print(f"\n5. Import complete: {total_imported}/{len(questions)} questions imported")

# Verify - count silhouettes in Firestore
print("\n6. Verifying...")
query_url = f"https://firestore.googleapis.com/v1/projects/{PROJECT_ID}/databases/(default)/documents/questions:runQuery"
query_body = json.dumps({
    "structuredQuery": {
        "from": [{"collectionId": "questions"}],
        "where": {
            "fieldFilter": {
                "field": {"fieldPath": "type"},
                "op": "EQUAL",
                "value": {"stringValue": "silhouette"}
            }
        },
        "select": {"fields": [{"fieldPath": "id"}, {"fieldPath": "correctAnswer"}]}
    }
}).encode("utf-8")

req = urllib.request.Request(query_url, data=query_body, method="POST")
req.add_header("Authorization", f"Bearer {access_token}")
req.add_header("Content-Type", "application/json")

try:
    with urllib.request.urlopen(req, timeout=30) as resp:
        results = json.loads(resp.read().decode())
    count = sum(1 for item in results if "document" in item)
    print(f"   Silhouette questions in Firestore: {count}")
    for item in results[:5]:
        if "document" in item:
            fields = item["document"].get("fields", {})
            qid = fields.get("id", {}).get("stringValue", "?")
            ans = fields.get("correctAnswer", {}).get("stringValue", "?")
            print(f"     - {qid}: {ans}")
except Exception as e:
    print(f"   Verification error: {e}")

print("\nDone!")