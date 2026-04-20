"""Import questions to Firestore via REST API - batched for large files."""
import json
import urllib.request
import urllib.parse
import sys
import time
import os
import pathlib

PROJECT_ID = "geoquiz-7790d"
API_KEY = "AIzaSyCFOIzMkKStbRpsM2dtNoLJcTbWp83xe9w"
BASE = f"projects/{PROJECT_ID}/databases/(default)/documents/questions"
BATCH_SIZE = 100  # Firestore limit per batchWrite

def get_access_token():
    """Read access token from Firebase CLI credentials, refreshing if needed."""
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
        
        # Token expired, refresh it
        refresh_token = tokens.get("refresh_token")
        if not refresh_token:
            print("❌ No refresh token found. Run 'firebase login --reauth'.")
            return None
        
        print("🔄 Refreshing expired token...")
        refresh_data = urllib.parse.urlencode({
            "grant_type": "refresh_token",
            "refresh_token": refresh_token,
            "client_id": "563584335869-fgrhgmd47bqnekij5i8b5pr03ho849e6.apps.googleusercontent.com",
            "client_secret": "j9iVZfS8kk8fyFhMU95pPqB7",
        }).encode()
        
        req = urllib.request.Request(
            "https://oauth2.googleapis.com/token",
            data=refresh_data,
            method="POST"
        )
        req.add_header("Content-Type", "application/x-www-form-urlencoded")
        
        try:
            with urllib.request.urlopen(req, timeout=30) as resp:
                new_tokens = json.loads(resp.read().decode())
                data["tokens"]["access_token"] = new_tokens["access_token"]
                data["tokens"]["expires_at"] = int(_time.time() * 1000) + new_tokens.get("expires_in", 3600) * 1000
                if "refresh_token" in new_tokens:
                    data["tokens"]["refresh_token"] = new_tokens["refresh_token"]
                
                # Save refreshed token
                with open(cred_path, "w", encoding="utf-8") as f:
                    json.dump(data, f)
                
                print("✅ Token refreshed successfully")
                return new_tokens["access_token"]
        except Exception as e:
            print(f"❌ Failed to refresh token: {e}")
            print("Run 'firebase login --reauth' manually.")
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
        return {"mapValue": {"fields": {k: field(val) for k, val in v.items()}}}
    elif isinstance(v, list):
        return {"arrayValue": {"values": [field(item) for item in v]}}
    elif v is None:
        return {"nullValue": "NULL_VALUE"}
    return {"stringValue": str(v)}

# Get OAuth access token from Firebase CLI
access_token = get_access_token()
if not access_token:
    print("❌ No Firebase access token found. Run 'firebase login' first.")
    sys.exit(1)
print(f"✅ Using OAuth token from Firebase CLI")

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
            print(f"Batch {batch_num}/{len(batches)}: {len(batch)} questions imported (total: {total_imported}/{len(questions)})")
    except Exception as e:
        print(f"Error in batch {batch_num}: {e}")
        sys.exit(1)

    if batch_num < len(batches):
        time.sleep(1)  # Rate limit

print(f"\n✅ Done! {total_imported} questions imported to Firestore.")
