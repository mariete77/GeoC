"""Deduplicate monument questions with unique IDs and import to Firestore."""
import json
import urllib.request
import urllib.parse
import sys
import time
import pathlib

PROJECT_ID = "geoquiz-7790d"
BASE = f"projects/{PROJECT_ID}/databases/(default)/documents/questions"
BATCH_SIZE = 100

def get_access_token():
    import time as _time
    cred_path = pathlib.Path.home() / ".config" / "configstore" / "firebase-tools.json"
    if cred_path.exists():
        with open(cred_path, "r", encoding="utf-8") as f:
            data = json.load(f)
        tokens = data.get("tokens", {})
        expires_at = tokens.get("expires_at", 0)
        now_ms = int(_time.time() * 1000)
        if expires_at > now_ms:
            return tokens.get("access_token")
        refresh_token = tokens.get("refresh_token")
        if not refresh_token:
            return None
        refresh_data = urllib.parse.urlencode({
            "grant_type": "refresh_token",
            "refresh_token": refresh_token,
            "client_id": "563584335869-fgrhgmd47bqnekij5i8b5pr03ho849e6.apps.googleusercontent.com",
            "client_secret": "j9iVZfS8kk8fyFhMU95pPqB7",
        }).encode()
        req = urllib.request.Request("https://oauth2.googleapis.com/token", data=refresh_data, method="POST")
        req.add_header("Content-Type", "application/x-www-form-urlencoded")
        try:
            with urllib.request.urlopen(req, timeout=30) as resp:
                new_tokens = json.loads(resp.read().decode())
                data["tokens"]["access_token"] = new_tokens["access_token"]
                data["tokens"]["expires_at"] = int(_time.time() * 1000) + new_tokens.get("expires_in", 3600) * 1000
                if "refresh_token" in new_tokens:
                    data["tokens"]["refresh_token"] = new_tokens["refresh_token"]
                with open(cred_path, "w", encoding="utf-8") as f:
                    json.dump(data, f)
                print("✅ Token refreshed")
                return new_tokens["access_token"]
        except Exception as e:
            print(f"❌ Token refresh failed: {e}")
            return None
    return None

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
        return {"mapValue": {"fields": {k2: field(val) for k2, val in v.items()}}}
    elif isinstance(v, list):
        return {"arrayValue": {"values": [field(item) for item in v]}}
    elif v is None:
        return {"nullValue": "NULL_VALUE"}
    return {"stringValue": str(v)}

# Load
with open("scripts/questions_monuments_all.json", "r", encoding="utf-8") as f:
    questions = json.load(f)
print(f"Loaded {len(questions)} questions")

# Deduplicate by keeping unique combos of (questionText + correctAnswer + type)
seen = {}
unique_questions = []
type_counters = {}  # type -> sequential count

for q in questions:
    qtype = q.get("type", "unknown")
    # Create a unique key based on questionText to detect true duplicates
    key = (q.get("questionText", ""), q.get("correctAnswer", ""), qtype)
    if key not in seen:
        seen[key] = True
        # Generate sequential unique ID per type
        type_counters[qtype] = type_counters.get(qtype, 0) + 1
        q["id"] = f"{qtype}_{type_counters[qtype]}"
        unique_questions.append(q)

print(f"After dedup: {len(unique_questions)} unique questions")
print(f"Types: {type_counters}")

# Verify no duplicate IDs
ids = [q["id"] for q in unique_questions]
assert len(ids) == len(set(ids)), f"Still have {len(ids) - len(set(ids))} duplicate IDs!"

# Save deduped file
with open("scripts/questions_monuments_deduped.json", "w", encoding="utf-8") as f:
    json.dump(unique_questions, f, ensure_ascii=False, indent=2)
print("Saved deduped file")

# Import to Firestore
access_token = get_access_token()
if not access_token:
    print("❌ No token. Run 'firebase login --reauth'")
    sys.exit(1)
print("✅ Got OAuth token")

batches = [unique_questions[i:i+BATCH_SIZE] for i in range(0, len(unique_questions), BATCH_SIZE)]
total_imported = 0

for batch_num, batch in enumerate(batches, 1):
    writes = []
    for q in batch:
        doc_id = q["id"]
        fields = {k: field(v) for k, v in q.items() if v is not None}
        writes.append({"update": {"name": f"{BASE}/{doc_id}", "fields": fields}})

    body = json.dumps({"writes": writes}).encode("utf-8")
    url = f"https://firestore.googleapis.com/v1/projects/{PROJECT_ID}/databases/(default)/documents:batchWrite"
    req = urllib.request.Request(url, data=body, headers={
        "Content-Type": "application/json",
        "Authorization": f"Bearer {access_token}",
    }, method="POST")

    try:
        with urllib.request.urlopen(req, timeout=60) as resp:
            resp.read()
            total_imported += len(batch)
            print(f"Batch {batch_num}/{len(batches)}: {len(batch)} imported (total: {total_imported}/{len(unique_questions)})")
    except urllib.error.HTTPError as e:
        error_body = e.read().decode('utf-8', errors='replace')
        print(f"Error batch {batch_num}: {e}")
        print(f"Body: {error_body[:2000]}")
        sys.exit(1)
    except Exception as e:
        print(f"Error batch {batch_num}: {e}")
        sys.exit(1)
    
    if batch_num < len(batches):
        time.sleep(1)

print(f"\n✅ Done! {total_imported} questions imported to Firestore.")