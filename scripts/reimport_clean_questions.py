"""Reimport clean questions to Firestore: delete old, import new via REST API."""
import json
import urllib.request
import urllib.parse
import sys
import time
import pathlib

PROJECT_ID = "geoquiz-7790d"
BASE = f"projects/{PROJECT_ID}/databases/(default)/documents/questions"
BATCH_SIZE = 100  # Firestore batchWrite limit

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
    
    import time as _time
    if expires_at and expires_at > _time.time() + 60:
        print(f"✅ Token still valid (expires in {int(expires_at - _time.time())}s)")
        return access_token
    
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

def api_request(url, token, method="GET", body=None):
    """Make authenticated Firestore REST API request."""
    headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {token}",
    }
    data = json.dumps(body).encode("utf-8") if body else None
    req = urllib.request.Request(url, data=data, headers=headers, method=method)
    with urllib.request.urlopen(req, timeout=60) as resp:
        return json.loads(resp.read().decode())

# ─── MAIN ───
print("🔄 Reimportando preguntas limpias a Firestore\n")

access_token = get_access_token()
if not access_token:
    print("❌ No Firebase access token found. Run 'firebase login' first.")
    sys.exit(1)
print("✅ Using OAuth token from Firebase CLI\n")

# 1. Delete all existing questions
print("🗑️  Fase 1: Borrando preguntas existentes...")
deleted = 0
page_token = None

while True:
    url = f"https://firestore.googleapis.com/v1/{BASE}?pageSize=100"
    if page_token:
        url += f"&pageToken={page_token}"
    
    result = api_request(url, access_token)
    docs = result.get("documents", [])
    
    if not docs:
        break
    
    # Delete in batches of 100
    for i in range(0, len(docs), BATCH_SIZE):
        batch_docs = docs[i:i+BATCH_SIZE]
        writes = [{"delete": doc["name"]} for doc in batch_docs]
        
        body = {"writes": writes}
        api_request(
            f"https://firestore.googleapis.com/v1/projects/{PROJECT_ID}/databases/(default)/documents:batchWrite",
            access_token, "POST", body
        )
        deleted += len(batch_docs)
        print(f"   🗑️  Borrados: {deleted}")
    
    page_token = result.get("nextPageToken")
    if not page_token:
        break
    time.sleep(0.5)

print(f"✅ {deleted} preguntas borradas\n")

# 2. Load clean questions
print("📖 Fase 2: Cargando preguntas limpias...")
import os
os.chdir(os.path.dirname(os.path.abspath(__file__)))

clean_file = "questions_clean.json"
if not os.path.exists(clean_file):
    print(f"❌ No se encontró {clean_file}")
    print("💡 Ejecuta primero: python scripts/fix_and_clean_questions.py")
    sys.exit(1)

with open(clean_file, "r", encoding="utf-8") as f:
    questions = json.load(f)

print(f"✅ {len(questions)} preguntas limpias cargadas\n")

# Count by type
type_counts = {}
for q in questions:
    t = q.get("type", "unknown")
    type_counts[t] = type_counts.get(t, 0) + 1
print("Por tipo:")
for t, c in sorted(type_counts.items(), key=lambda x: -x[1]):
    print(f"  {t}: {c}")

# 3. Import in batches
print(f"\n📤 Fase 3: Importando {len(questions)} preguntas...")
batches = [questions[i:i+BATCH_SIZE] for i in range(0, len(questions), BATCH_SIZE)]
total_imported = 0
total_batches = len(batches)

for batch_num, batch in enumerate(batches, 1):
    writes = []
    for q in batch:
        doc_id = q["id"]
        # Remove internal fields
        clean_q = {k: v for k, v in q.items() if k not in ("_source", "_remove")}
        fields = {k: field(v) for k, v in clean_q.items()}
        writes.append({"update": {"name": f"{BASE}/{doc_id}", "fields": fields}})

    body = {"writes": writes}
    url = f"https://firestore.googleapis.com/v1/projects/{PROJECT_ID}/databases/(default)/documents:batchWrite"
    
    try:
        api_request(url, access_token, "POST", body)
        total_imported += len(batch)
        pct = (batch_num / total_batches) * 100
        print(f"  Batch {batch_num}/{total_batches} ({pct:.0f}%): {len(batch)} → total: {total_imported}/{len(questions)}")
    except Exception as e:
        print(f"  ❌ Error en batch {batch_num}: {e}")
        time.sleep(2)
    
    if batch_num < total_batches:
        time.sleep(0.5)

print(f"\n✅ ¡Reimportación completada! {total_imported}/{len(questions)} preguntas importadas.")