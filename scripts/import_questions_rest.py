"""Import questions to Firestore via REST API - single batch call."""
import json
import urllib.request

PROJECT_ID = "geoquiz-7790d"
API_KEY = "AIzaSyCFOIzMkKStbRpsM2dtNoLJcTbWp83xe9w"
BASE = f"projects/{PROJECT_ID}/databases/(default)/documents/questions"

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

with open("scripts/questions.json", "r", encoding="utf-8") as f:
    questions = json.load(f)

writes = []
for q in questions:
    doc_id = q["id"]
    fields = {k: field(v) for k, v in q.items()}
    writes.append({"update": {"name": f"{BASE}/{doc_id}", "fields": fields}})

body = json.dumps({"writes": writes}).encode("utf-8")
url = f"https://firestore.googleapis.com/v1/projects/{PROJECT_ID}/databases/(default)/documents:batchWrite?key={API_KEY}"

req = urllib.request.Request(url, data=body, headers={"Content-Type": "application/json"}, method="POST")

try:
    with urllib.request.urlopen(req, timeout=30) as resp:
        result = json.loads(resp.read().decode())
        print(f"Response: {json.dumps(result, indent=2)[:500]}")
        print(f"\nImported {len(questions)} questions to Firestore!")
except Exception as e:
    print(f"Error: {e}")
    import sys
    sys.exit(1)