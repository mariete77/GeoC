"""Import ALL questions to Firestore - deduplicated, batched, via REST API."""
import json
import urllib.request
import urllib.parse
import sys
import time
import os
import pathlib
import glob

PROJECT_ID = "geoquiz-7790d"
BASE = f"projects/{PROJECT_ID}/databases/(default)/documents/questions"
BATCH_SIZE = 100  # Firestore limit per batchWrite

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
    
    # Check if token is still valid (with 60s margin)
    import time as _time
    if expires_at and expires_at > _time.time() + 60:
        print(f"✅ Token still valid (expires in {int(expires_at - _time.time())}s)")
        return access_token
    
    # Refresh the token using Google OAuth2
    if refresh_token:
        print("🔄 Access token expired, refreshing...")
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
                
                # Update stored credentials
                tokens["access_token"] = access_token
                tokens["expires_at"] = _time.time() + new_tokens.get("expires_in", 3600)
                tokens["expires_in"] = new_tokens.get("expires_in", 3600)
                data["tokens"] = tokens
                
                with open(cred_path, "w", encoding="utf-8") as f:
                    json.dump(data, f)
                
                print("✅ Token refreshed successfully!")
                return access_token
        except Exception as e:
            print(f"⚠️ Token refresh failed: {e}")
            # Fall back to existing token
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

# Get OAuth access token
access_token = get_access_token()
if not access_token:
    print("❌ No Firebase access token found. Run 'firebase login' first.")
    sys.exit(1)
print("✅ Using OAuth token from Firebase CLI")

# Change to scripts directory
os.chdir(os.path.dirname(os.path.abspath(__file__)))

# Load ALL questions from all JSON files, deduplicating by ID
files = sorted(glob.glob("questions*.json"))
print(f"Found {len(files)} question files\n")

all_questions = {}
duplicates = 0
errors = []

for filename in files:
    try:
        with open(filename, "r", encoding="utf-8") as f:
            questions = json.load(f)
        
        for q in questions:
            qid = q.get("id", "")
            if not qid:
                errors.append(f"{filename}: question missing 'id' field")
                continue
            
            if qid in all_questions:
                duplicates += 1
                # Keep the one with more fields (richer data)
                if len(q) > len(all_questions[qid]):
                    all_questions[qid] = q
            else:
                all_questions[qid] = q
        
        print(f"  {filename}: {len(questions)} loaded")
    except Exception as e:
        errors.append(f"{filename}: {e}")
        print(f"  {filename}: ERROR - {e}")

questions_list = list(all_questions.values())
print(f"\n📊 Summary:")
print(f"  Total questions (deduplicated): {len(questions_list)}")
print(f"  Duplicates removed: {duplicates}")
if errors:
    print(f"  Errors: {len(errors)}")
    for e in errors:
        print(f"    - {e}")

# Count by type
type_counts = {}
for q in questions_list:
    t = q.get("type", "unknown")
    type_counts[t] = type_counts.get(t, 0) + 1
print(f"\n  By type:")
for t, c in sorted(type_counts.items(), key=lambda x: -x[1]):
    print(f"    {t}: {c}")

# Ask for confirmation
print(f"\n🚀 Ready to import {len(questions_list)} questions to Firestore.")
confirm = input("Proceed? (y/N): ").strip().lower()
if confirm != "y":
    print("Cancelled.")
    sys.exit(0)

# Import in batches
batches = [questions_list[i:i+BATCH_SIZE] for i in range(0, len(questions_list), BATCH_SIZE)]
total_imported = 0
total_batches = len(batches)

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
            pct = (batch_num / total_batches) * 100
            print(f"  Batch {batch_num}/{total_batches} ({pct:.0f}%): {len(batch)} imported (total: {total_imported}/{len(questions_list)})")
    except Exception as e:
        print(f"  ❌ Error in batch {batch_num}: {e}")
        # Continue with next batch instead of failing completely
        time.sleep(2)

    if batch_num < total_batches:
        time.sleep(1)  # Rate limit

print(f"\n✅ Done! {total_imported}/{len(questions_list)} questions imported to Firestore.")