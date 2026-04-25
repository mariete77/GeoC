import json
import urllib.request
import pathlib
import time

PROJECT_ID = "geoquiz-7790d"

def get_access_token():
    cred_path = pathlib.Path.home() / ".config" / "configstore" / "firebase-tools.json"
    if cred_path.exists():
        with open(cred_path, "r", encoding="utf-8") as f:
            data = json.load(f)
        tokens = data.get("tokens", {})
        expires_at = tokens.get("expires_at", 0)
        now_ms = int(time.time() * 1000)
        
        if expires_at > now_ms:
            return tokens.get("access_token")
        
        # Token expired, refresh
        refresh_token = tokens.get("refresh_token")
        if not refresh_token:
            print("No refresh token. Run 'firebase login --reauth'.")
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
            data=refresh_data, method="POST"
        )
        req.add_header("Content-Type", "application/x-www-form-urlencoded")
        
        with urllib.request.urlopen(req, timeout=30) as resp:
            new_tokens = json.loads(resp.read().decode())
            data["tokens"]["access_token"] = new_tokens["access_token"]
            data["tokens"]["expires_at"] = int(time.time() * 1000) + new_tokens.get("expires_in", 3600) * 1000
            if "refresh_token" in new_tokens:
                data["tokens"]["refresh_token"] = new_tokens["refresh_token"]
            with open(cred_path, "w", encoding="utf-8") as f:
                json.dump(data, f)
            print("Token refreshed!")
            return new_tokens["access_token"]
    return None

token = get_access_token()
if not token:
    print("ERROR: No token")
    exit(1)

# Query Firestore for silhouette questions using structuredQuery
url = f"https://firestore.googleapis.com/v1/projects/{PROJECT_ID}/databases/(default)/documents:runQuery"

query = {
    "structuredQuery": {
        "from": [{"collectionId": "questions"}],
        "where": {
            "fieldFilter": {
                "field": {"fieldPath": "type"},
                "op": "EQUAL",
                "value": {"stringValue": "silhouette"}
            }
        },
        "limit": 5
    }
}

body = json.dumps(query).encode("utf-8")
req = urllib.request.Request(url, data=body, method="POST")
req.add_header("Content-Type", "application/json")
req.add_header("Authorization", f"Bearer {token}")

try:
    with urllib.request.urlopen(req, timeout=30) as resp:
        results = json.loads(resp.read().decode())
        silhouette_count = 0
        for r in results:
            doc = r.get("document", {})
            if doc:
                fields = doc.get("fields", {})
                doc_id = doc.get("name", "").split("/")[-1]
                qtype = fields.get("type", {}).get("stringValue", "")
                image_url = fields.get("imageUrl", {}).get("stringValue", "NONE")
                answer = fields.get("correctAnswer", {}).get("stringValue", "")
                print(f"  Found: id={doc_id}, type={qtype}, imageUrl={image_url}, answer={answer}")
                silhouette_count += 1
        
        if silhouette_count == 0:
            print("  NO silhouette questions found in Firestore!")
        else:
            print(f"\n  Total silhouettes found (showing first 5): {silhouette_count}")
except Exception as e:
    print(f"Error querying Firestore: {e}")

# Also count total questions
print("\n--- Total questions count ---")
count_url = f"https://firestore.googleapis.com/v1/projects/{PROJECT_ID}/databases/(default)/documents:runAggregationQuery"
count_query = {
    "structuredAggregationQuery": {
        "structuredQuery": {
            "from": [{"collectionId": "questions"}]
        },
        "aggregations": [{
            "alias": "count",
            "count": {}
        }]
    }
}
body2 = json.dumps(count_query).encode("utf-8")
req2 = urllib.request.Request(count_url, data=body2, method="POST")
req2.add_header("Content-Type", "application/json")
req2.add_header("Authorization", f"Bearer {token}")

try:
    with urllib.request.urlopen(req2, timeout=30) as resp:
        result = json.loads(resp.read().decode())
        for r in result:
            cnt = r.get("result", {}).get("aggregateFields", {}).get("count", {}).get("integerValue", "?")
            print(f"Total questions in Firestore: {cnt}")
except Exception as e:
    print(f"Error counting: {e}")