"""
Corregir opciones de preguntas de silueta en Firestore.
Reemplaza las opciones sin sentido (monumentos, monedas, idiomas, etc.)
solo por nombres de paises como distractores.
"""
import json
import random
import urllib.request
import urllib.parse
import time
import os
import pathlib
import sys

PROJECT_ID = "geoquiz-7790d"
DB_PATH = f"projects/{PROJECT_ID}/databases/%28default%29/documents/questions"
BASE_URL = f"https://firestore.googleapis.com/v1/{DB_PATH}"

def get_access_token():
    cred_path = pathlib.Path.home() / ".config" / "configstore" / "firebase-tools.json"
    if not cred_path.exists():
        cred_path = pathlib.Path.home() / "AppData" / "Roaming" / "configstore" / "firebase-tools.json"
    if not cred_path.exists():
        print("No Firebase credentials found.")
        return None
    
    with open(cred_path, "r", encoding="utf-8") as f:
        data = json.load(f)
    
    tokens = data.get("tokens", {})
    access_token = tokens.get("access_token")
    refresh_token = tokens.get("refresh_token")
    
    expires_at = tokens.get("expires_at", 0)
    if expires_at and expires_at > time.time() + 60:
        print(f"Token valid (expires in {int(expires_at - time.time())}s)")
        return access_token
    
    # Try multiple known client secrets for Firebase CLI OAuth client
    client_secrets = [
        "j9iVZfS8kk8upbheD6mF2Vap",
        "j9iVZfS8kk8fyFhMU95pPqB7",
    ]
    if refresh_token:
        CLIENT_ID = "563584335869-fgrhgmd47bqnekij5i8b5pr3ho849se6.apps.googleusercontent.com"
        for secret in client_secrets:
            refresh_data = urllib.parse.urlencode({
                "grant_type": "refresh_token",
                "refresh_token": refresh_token,
                "client_id": CLIENT_ID,
                "client_secret": secret,
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
                    data["tokens"] = tokens
                    with open(cred_path, "w", encoding="utf-8") as f:
                        json.dump(data, f)
                    print("Token refreshed!")
                    return access_token
            except Exception as e:
                print(f"Token refresh failed with secret ending ...{secret[-4:]}: {e}")
    
    print("WARNING: Using stored token (may be expired)")
    return access_token

def field(v):
    if isinstance(v, str): return {"stringValue": v}
    elif isinstance(v, bool): return {"booleanValue": v}
    elif isinstance(v, int): return {"integerValue": str(v)}
    elif isinstance(v, float): return {"doubleValue": v}
    elif isinstance(v, list): return {"arrayValue": {"values": [field(item) for item in v]}}
    elif isinstance(v, dict): return {"mapValue": {"fields": {k: field(val) for k, val in v.items()}}}
    elif v is None: return {"nullValue": "NULL_VALUE"}
    return {"stringValue": str(v)}

def get_all_country_names():
    """Extract all country names from flag questions in the merged data."""
    countries = set()
    files_to_check = [
        "questions_fixed_options.json",
        "questions_all_merged.json",
        "questions_clean.json",
    ]
    script_dir = os.path.dirname(os.path.abspath(__file__))
    
    for fname in files_to_check:
        fpath = os.path.join(script_dir, fname)
        if not os.path.exists(fpath):
            continue
        with open(fpath, "r", encoding="utf-8") as f:
            try:
                questions = json.load(f)
                for q in questions:
                    if q.get("type") in ("flag", "silhouette"):
                        ans = q.get("correctAnswer", "")
                        if ans and len(ans) > 2:
                            countries.add(ans)
            except:
                pass
    
    return sorted(countries)

def fix_options_for_silhouette(question, all_countries):
    """Generate proper options for a silhouette question."""
    correct = question.get("correctAnswer", "")
    if not correct:
        return question
    
    available = [c for c in all_countries if c != correct]
    if len(available) < 3:
        question["options"] = []
        return question
    
    distractors = random.sample(available, 3)
    options = distractors + [correct]
    random.shuffle(options)
    question["options"] = options
    return question

def query_silhouettes_from_firestore(access_token):
    """Get all silhouette questions from Firestore."""
    query_url = f"{BASE_URL}:runQuery"
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
            "limit": 500
        }
    }).encode("utf-8")
    
    req = urllib.request.Request(query_url, data=query_body, method="POST")
    req.add_header("Authorization", f"Bearer {access_token}")
    req.add_header("Content-Type", "application/json")
    
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            results = json.loads(resp.read().decode())
        silhouettes = []
        for item in results:
            if "document" not in item:
                continue
            doc = item["document"]
            fields_raw = doc.get("fields", {})
            name = doc["name"]
            doc_id = name.split("/")[-1]
            
            # Convert Firestore fields back to dict
            def unwrap(v):
                if "stringValue" in v: return v["stringValue"]
                if "integerValue" in v: return int(v["integerValue"])
                if "booleanValue" in v: return v["booleanValue"]
                if "arrayValue" in v:
                    return [unwrap(x) for x in v["arrayValue"].get("values", [])]
                if "mapValue" in v:
                    return {k: unwrap(val) for k, val in v["mapValue"].get("fields", {}).items()}
                return None
            
            q = {"id": doc_id}
            for k, v in fields_raw.items():
                q[k] = unwrap(v)
            silhouettes.append(q)
        return silhouettes
    except Exception as e:
        print(f"Error querying Firestore: {e}")
        return None

def upload_fixes_to_firestore(fixed_questions, access_token):
    """Upload fixed silhouette questions to Firestore using batchWrite."""
    BATCH_SIZE = 100
    total = len(fixed_questions)
    uploaded = 0
    
    for i in range(0, total, BATCH_SIZE):
        batch = fixed_questions[i:i+BATCH_SIZE]
        writes = []
        for q in batch:
            doc_id = q["id"]
            # Only update: options, extraData
            fields = {"options": field(q.get("options", [])),
                      "extraData": field(q.get("extraData", {})),
                      "imageUrl": field(q.get("imageUrl", "")),
                      "correctAnswer": field(q.get("correctAnswer", ""))}
            writes.append({"update": {"name": f"{DB_PATH}/{doc_id}", "fields": fields}})
        
        body = json.dumps({"writes": writes}).encode("utf-8")
        url = f"https://firestore.googleapis.com/v1/projects/{PROJECT_ID}/databases/%28default%29/documents:batchWrite"
        headers = {"Content-Type": "application/json", "Authorization": f"Bearer {access_token}"}
        req = urllib.request.Request(url, data=body, headers=headers, method="POST")
        
        try:
            with urllib.request.urlopen(req, timeout=60) as resp:
                uploaded += len(batch)
                pct = (i + len(batch)) / total * 100
                print(f"  Batch {i//BATCH_SIZE + 1}/{(total-1)//BATCH_SIZE + 1} ({pct:.0f}%): {len(batch)} uploaded (total: {uploaded}/{total})")
        except Exception as e:
            print(f"  Error in batch {i//BATCH_SIZE + 1}: {e}")
        
        time.sleep(0.5)
    
    return uploaded

def main():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    os.chdir(script_dir)
    
    print("=" * 60)
    print("  GEO C - Fix Silhouette Options")
    print("=" * 60)
    
    # Step 1: Get access token
    print("\n1. Getting Firebase access token...")
    token = get_access_token()
    if not token:
        print("ERROR: No Firebase token")
        sys.exit(1)
    print("   OK")
    
    # Step 2: Get all country names from question data
    print("\n2. Extracting country names from questions...")
    all_countries = get_all_country_names()
    print(f"   Found {len(all_countries)} country names")
    
    # Step 3: Query Firestore for current silhouettes
    print("\n3. Fetching silhouettes from Firestore...")
    silhouettes = query_silhouettes_from_firestore(token)
    if silhouettes is None:
        print("   Could not query Firestore. Reading from local files...")
        sil_file = os.path.join(script_dir, "questions_silhouettes.json")
        with open(sil_file, "r", encoding="utf-8") as f:
            silhouettes = json.load(f)
        print(f"   Loaded {len(silhouettes)} from local file")
    else:
        print(f"   Found {len(silhouettes)} silhouettes in Firestore")
    
    if not silhouettes:
        print("ERROR: No silhouettes found")
        sys.exit(1)
    
    # Step 4: Show sample before
    print("\n4. Sample before fix:")
    for s in silhouettes[:3]:
        opts = s.get("options", [])
        print(f"   {s['id']}: correct={s.get('correctAnswer','?')}, options={opts}")
    
    # Step 5: Fix options
    print(f"\n5. Fixing options for {len(silhouettes)} silhouettes...")
    fix_count = 0
    for q in silhouettes:
        old_opts = q.get("options", [])
        q = fix_options_for_silhouette(q, all_countries)
        new_opts = q.get("options", [])
        if old_opts != new_opts:
            fix_count += 1
    print(f"   Fixed {fix_count} silhouettes")
    
    # Step 6: Show sample after
    print("\n6. Sample after fix:")
    for s in silhouettes[:3]:
        opts = s.get("options", [])
        print(f"   {s['id']}: correct={s.get('correctAnswer','?')}, options={opts}")
    
    # Step 7: Confirm and upload
    print(f"\n7. Uploading {len(silhouettes)} fixed silhouettes to Firestore...")
    
    uploaded = upload_fixes_to_firestore(silhouettes, token)
    print(f"\n8. Done! {uploaded}/{len(silhouettes)} silhouettes updated in Firestore.")
    
    # Step 8: Verify
    print("\n9. Verifying...")
    verify = query_silhouettes_from_firestore(token)
    if verify:
        good = sum(1 for s in verify if len(s.get("options", [])) == 4)
        print(f"   Silhouettes with 4 options: {good}/{len(verify)}")
        for s in verify[:3]:
            print(f"   {s['id']}: options={s.get('options', [])}")
    
    print("\nDone!")

if __name__ == "__main__":
    main()
