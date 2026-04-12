"""Import questions to Firestore via REST API - batched for large files."""
import json
import urllib.request
import sys
import time

PROJECT_ID = "geoquiz-7790d"
API_KEY = "AIzaSyCFOIzMkKStbRpsM2dtNoLJcTbWp83xe9w"
BASE = f"projects/{PROJECT_ID}/databases/(default)/documents/questions"
BATCH_SIZE = 100  # Firestore limit per batchWrite

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

# Load questions
filename = sys.argv[1] if len(sys.argv) > 1 else "scripts/questions_full.json"
with open(filename, "r", encoding="utf-8") as f:
    questions = json.load(f)

print(f"Loaded {len(questions)} questions from {filename}")

# Split into batches
batches = [questions[i:i+BATCH_SIZE] for i in range(0, len(questions), BATCH_SIZE)]
total_imported = 0

for batch_num, batch in enumerate(batches, 1):
    writes = []
    for q in batch:
        doc_id = q["id"]
        fields = {k: field(v) for k, v in q.items()}
        writes.append({"update": {"name": f"{BASE}/{doc_id}", "fields": fields}})

    body = json.dumps({"writes": writes}).encode("utf-8")
    url = f"https://firestore.googleapis.com/v1/projects/{PROJECT_ID}/databases/(default)/documents:batchWrite?key={API_KEY}"

    req = urllib.request.Request(url, data=body, headers={"Content-Type": "application/json"}, method="POST")

    try:
        with urllib.request.urlopen(req, timeout=60) as resp:
            result = json.loads(resp.read().decode())
            total_imported += len(batch)
            print(f"Batch {batch_num}/{len(batches)}: {len(batch)} questions imported (total: {total_imported}/{len(questions)})")
    except Exception as e:
        print(f"Error in batch {batch_num}: {e}")
        sys.exit(1)

    if batch_num < len(batches):
        time.sleep(1)  # Rate limit

print(f"\n✅ Done! {total_imported} questions imported to Firestore.")
