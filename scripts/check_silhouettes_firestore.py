import json, urllib.request, pathlib, time

PROJECT_ID = "geoquiz-7790d"

def get_token():
    p = pathlib.Path.home() / ".config" / "configstore" / "firebase-tools.json"
    if p.exists():
        with open(p, "r", encoding="utf-8") as f:
            data = json.load(f)
        tokens = data.get("tokens", {})
        expires_at = tokens.get("expires_at", 0)
        if expires_at > int(time.time() * 1000):
            return tokens.get("access_token")
        refresh_token = tokens.get("refresh_token")
        if not refresh_token:
            print("No refresh token. Run firebase login --reauth.")
            return None
        refresh_data = urllib.parse.urlencode({
            "grant_type": "refresh_token",
            "refresh_token": refresh_token,
            "client_id": "563584335869-fgrhgmd47bqnekij5i8b5pr03ho849e6.apps.googleusercontent.com",
            "client_secret": "j9iVZfS8kk8fyFhMU95pPqB7",
        }).encode()
        req = urllib.request.Request("https://oauth2.googleapis.com/token", data=refresh_data, method="POST")
        req.add_header("Content-Type", "application/x-www-form-urlencoded")
        with urllib.request.urlopen(req, timeout=30) as resp:
            new_tokens = json.loads(resp.read().decode())
            data["tokens"]["access_token"] = new_tokens["access_token"]
            data["tokens"]["expires_at"] = int(time.time() * 1000) + new_tokens.get("expires_in", 3600) * 1000
            if "refresh_token" in new_tokens:
                data["tokens"]["refresh_token"] = new_tokens["refresh_token"]
            with open(p, "w", encoding="utf-8") as f:
                json.dump(data, f)
            return new_tokens["access_token"]
    return None

token = get_token()
if not token:
    print("ERROR: No token")
    exit(1)

url = f"https://firestore.googleapis.com/v1/projects/{PROJECT_ID}/databases/(default)/documents:runQuery"

# Count ALL silhouette questions
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
        "limit": 500
    }
}

body = json.dumps(query).encode("utf-8")
req = urllib.request.Request(url, data=body, method="POST")
req.add_header("Content-Type", "application/json")
req.add_header("Authorization", f"Bearer {token}")

silhouettes = []
try:
    with urllib.request.urlopen(req, timeout=60) as resp:
        results = json.loads(resp.read().decode())
        for r in results:
            doc = r.get("document", {})
            if doc:
                fields = doc.get("fields", {})
                doc_id = doc.get("name", "").split("/")[-1]
                image_url = fields.get("imageUrl", {}).get("stringValue", "NONE")
                answer = fields.get("correctAnswer", {}).get("stringValue", "")
                country = fields.get("country", {}).get("stringValue", "")
                silhouettes.append({"id": doc_id, "answer": answer, "country": country, "imageUrl": image_url})
except Exception as e:
    print(f"Error: {e}")

print(f"=== SILHOUETTE QUESTIONS IN FIRESTORE ===")
print(f"Total found: {len(silhouettes)}")

# Count by country
countries = {}
for s in silhouettes:
    c = s["country"] or "unknown"
    countries[c] = countries.get(c, 0) + 1

print(f"\nBy country ({len(countries)} countries):")
for c in sorted(countries.keys()):
    print(f"  {c}: {countries[c]}")

# Show first 10
print(f"\nFirst 10 questions:")
for s in silhouettes[:10]:
    img_short = s["imageUrl"][:80] if s["imageUrl"] != "NONE" else "NONE"
    print(f"  {s['id']}: {s['answer']} ({s['country']}) img={img_short}")

# Count total questions
print("\n=== TOTAL QUESTIONS ===")
count_url = f"https://firestore.googleapis.com/v1/projects/{PROJECT_ID}/databases/(default)/documents:runAggregationQuery"
count_query = {
    "structuredAggregationQuery": {
        "structuredQuery": {"from": [{"collectionId": "questions"}]},
        "aggregations": [{"alias": "count", "count": {}}]
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

# Count by type
print("\n=== QUESTIONS BY TYPE ===")
types_to_check = ["silhouette", "flag", "capital", "monument", "mountain", "river", "lake", "desert", "volcano", "building"]
for t in types_to_check:
    type_query = {
        "structuredAggregationQuery": {
            "structuredQuery": {
                "from": [{"collectionId": "questions"}],
                "where": {
                    "fieldFilter": {
                        "field": {"fieldPath": "type"},
                        "op": "EQUAL",
                        "value": {"stringValue": t}
                    }
                }
            },
            "aggregations": [{"alias": "count", "count": {}}]
        }
    }
    body3 = json.dumps(type_query).encode("utf-8")
    req3 = urllib.request.Request(count_url, data=body3, method="POST")
    req3.add_header("Content-Type", "application/json")
    req3.add_header("Authorization", f"Bearer {token}")
    try:
        with urllib.request.urlopen(req3, timeout=15) as resp:
            result = json.loads(resp.read().decode())
            for r in result:
                cnt = r.get("result", {}).get("aggregateFields", {}).get("count", {}).get("integerValue", "0")
                print(f"  {t}: {cnt}")
    except Exception as e:
        print(f"  {t}: error - {e}")