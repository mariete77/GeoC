"""Verify silhouette questions exist in Firestore."""
import json
import urllib.request
import pathlib

PROJECT_ID = "geoquiz-7790d"

# Get token
cred_path = pathlib.Path.home() / ".config" / "configstore" / "firebase-tools.json"
with open(cred_path, "r", encoding="utf-8") as f:
    data = json.load(f)
token = data.get("tokens", {}).get("access_token")

# Check specific silhouette docs
test_ids = ["silhouette_es", "silhouette_fr", "silhouette_mx", "silhouette_br", "silhouette_us"]
found = 0
missing = 0

for doc_id in test_ids:
    url = f"https://firestore.googleapis.com/v1/projects/{PROJECT_ID}/databases/(default)/documents/questions/{doc_id}"
    req = urllib.request.Request(url)
    req.add_header("Authorization", f"Bearer {token}")
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            result = json.loads(resp.read().decode())
        fields = result.get("fields", {})
        answer = fields.get("correctAnswer", {}).get("stringValue", "?")
        qtype = fields.get("type", {}).get("stringValue", "?")
        image = fields.get("imageUrl", {}).get("stringValue", "?")
        print(f"  {doc_id}: type={qtype}, answer={answer}, image={image}")
        found += 1
    except urllib.error.HTTPError as e:
        print(f"  {doc_id}: NOT FOUND ({e.code})")
        missing += 1

print(f"\nFound: {found}/{len(test_ids)}, Missing: {missing}/{len(test_ids)}")

# Also run a structured query to count silhouettes
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
req.add_header("Authorization", f"Bearer {token}")
req.add_header("Content-Type", "application/json")

try:
    with urllib.request.urlopen(req, timeout=30) as resp:
        results = json.loads(resp.read().decode())
    
    count = 0
    for item in results:
        if "document" in item:
            count += 1
    
    print(f"\nTotal silhouette questions in Firestore (via query): {count}")
except Exception as e:
    print(f"Query error: {e}")