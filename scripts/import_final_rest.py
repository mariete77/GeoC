import json, urllib.request, urllib.parse, os, sys, pathlib, time

PROJECT_ID = 'geoquiz-7790d'
BASE = f'projects/{PROJECT_ID}/databases/(default)/documents/questions'

def get_access_token():
    """Read access token from Firebase CLI credentials, refreshing if needed."""
    cred_path = pathlib.Path.home() / ".config" / "configstore" / "firebase-tools.json"
    if not cred_path.exists():
        # Try Windows path
        cred_path = pathlib.Path.home() / "AppData" / "Roaming" / "configstore" / "firebase-tools.json"
    if cred_path.exists():
        with open(cred_path, "r", encoding="utf-8") as f:
            data = json.load(f)
        tokens = data.get("tokens", {})
        expires_at = tokens.get("expires_at", 0)
        now_ms = int(time.time() * 1000)
        
        if expires_at > now_ms:
            return tokens.get("access_token")
        
        # Token expired, refresh it
        refresh_token = tokens.get("refresh_token")
        if not refresh_token:
            print("No refresh token found. Run 'firebase login --reauth'.")
            return None
        
        print("Refreshing expired token...")
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
                data["tokens"]["expires_at"] = int(time.time() * 1000) + new_tokens.get("expires_in", 3600) * 1000
                if "refresh_token" in new_tokens:
                    data["tokens"]["refresh_token"] = new_tokens["refresh_token"]
                
                with open(cred_path, "w", encoding="utf-8") as f:
                    json.dump(data, f)
                
                print("Token refreshed successfully")
                return new_tokens["access_token"]
        except Exception as e:
            print(f"Failed to refresh token: {e}")
            print("Run 'firebase login --reauth' manually.")
            return None
    
    # Fallback: try firebase CLI directly
    print("No Firebase credentials found at expected paths.")
    print("Trying to get token via Firebase CLI...")
    import subprocess
    try:
        result = subprocess.run(
            ["firebase", "auth:print-access-token", "--project", PROJECT_ID],
            capture_output=True, text=True, timeout=30
        )
        if result.returncode == 0 and result.stdout.strip():
            return result.stdout.strip()
    except Exception:
        pass
    
    return None

def format_value(v):
    if isinstance(v, str): return {'stringValue': v}
    if isinstance(v, bool): return {'booleanValue': v}
    if isinstance(v, int): return {'integerValue': str(v)}
    if isinstance(v, float): return {'doubleValue': v}
    if isinstance(v, list): return {'arrayValue': {'values': [format_value(i) for i in v]}}
    if isinstance(v, dict): return {'mapValue': {'fields': {k: format_value(val) for k, val in v.items()}}}
    if v is None: return {'nullValue': 'NULL_VALUE'}
    return {'stringValue': str(v)}

def import_batch_to_firestore(filepath, access_token):
    with open(filepath, 'r', encoding='utf-8') as f:
        questions = json.load(f)

    # Firestore batchWrite supports max 100 writes
    BATCH_SIZE = 100
    batches = [questions[i:i+BATCH_SIZE] for i in range(0, len(questions), BATCH_SIZE)]
    
    total_imported = 0
    for batch_num, batch in enumerate(batches, 1):
        writes = []
        for q in batch:
            fields = {k: format_value(v) for k, v in q.items() if k != 'id' and v is not None}
            writes.append({
                'update': {
                    'name': f'{BASE}/{q["id"]}',
                    'fields': fields
                }
            })

        url = f"https://firestore.googleapis.com/v1/projects/{PROJECT_ID}/databases/(default)/documents:batchWrite"
        body = json.dumps({'writes': writes}).encode()
        
        headers = {
            'Content-Type': 'application/json',
            'Authorization': f'Bearer {access_token}',
        }
        req = urllib.request.Request(url, data=body, headers=headers, method='POST')
        with urllib.request.urlopen(req, timeout=60) as resp:
            if resp.status == 200:
                total_imported += len(batch)
            else:
                raise Exception(f"HTTP {resp.status}")
    
    return total_imported

# Ejecución
if __name__ == '__main__':
    # Get OAuth token
    access_token = get_access_token()
    if not access_token:
        print("ERROR: No Firebase access token found. Run 'firebase login' first.")
        sys.exit(1)
    print(f"Using OAuth token from Firebase CLI")
    
    batches_dir = 'scripts/batches'
    files = sorted([f for f in os.listdir(batches_dir) if f.endswith('.json')])
    total_files = len(files)
    total_questions = 0
    
    for i, filename in enumerate(files, 1):
        print(f"[{i}/{total_files}] Importing {filename}...")
        try:
            count = import_batch_to_firestore(os.path.join(batches_dir, filename), access_token)
            total_questions += count
            print(f"  OK - {count} questions (total: {total_questions})")
            time.sleep(0.5)  # Rate limit
        except urllib.error.HTTPError as e:
            error_body = e.read().decode('utf-8', errors='replace')
            print(f"  ERROR: HTTP {e.code} - {error_body[:500]}")
            sys.exit(1)
        except Exception as e:
            print(f"  ERROR: {e}")
            sys.exit(1)
    
    print(f"\nDONE! {total_questions} questions imported from {total_files} batch files.")
