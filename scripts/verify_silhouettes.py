"""Verify silhouette questions in Firestore - check individual docs + count via query."""
import json, urllib.request, pathlib

cred_path = pathlib.Path.home() / ".config" / "configstore" / "firebase-tools.json"
if not cred_path.exists():
    cred_path = pathlib.Path.home() / "AppData" / "Roaming" / "firebase-tools.json"

data = json.load(open(cred_path, "r", encoding="utf-8"))
token = data["tokens"]["access_token"]

# Check several specific documents
print("=== Checking individual silhouette documents ===")
found = 0
not_found = 0
test_ids = ["silhouette_es", "silhouette_us", "silhouette_id", "silhouette_mx", 
            "silhouette_br", "silhouette_jp", "silhouette_de", "silhouette_it",
            "silhouette_ar", "silhouette_cl", "silhouette_co", "silhouette_au",
            "silhouette_in", "silhouette_ru", "silhouette_cn", "silhouette_za",
            "silhouette_eg", "silhouette_ng", "silhouette_se", "silhouette_no"]

for doc_id in test_ids:
    url = f"https://firestore.googleapis.com/v1/projects/geoquiz-7790d/databases/(default)/documents/questions/{doc_id}"
    req = urllib.request.Request(url)
    req.add_header("Authorization", f"Bearer {token}")
    try:
        resp = urllib.request.urlopen(req, timeout=10)
        result = json.loads(resp.read().decode())
        fields = result.get("fields", {})
        answer = fields.get("correctAnswer", {}).get("stringValue", "?")
        image = fields.get("imageUrl", {}).get("stringValue", "?")
        print(f"  OK  {doc_id}: {answer} ({image})")
        found += 1
    except urllib.error.HTTPError as e:
        if e.code == 404:
            print(f"  --  {doc_id}: not found (not in JSON)")
            not_found += 1
        else:
            print(f"  ERR {doc_id}: HTTP {e.code}")
    except Exception as e:
        print(f"  ERR {doc_id}: {e}")

print(f"\nFound: {found}/{len(test_ids)} checked")

# Count all documents with pagination
print("\n=== Counting ALL questions by type (paginated) ===")
all_docs = []
page_token = None
base_url = "https://firestore.googleapis.com/v1/projects/geoquiz-7790d/databases/(default)/documents/questions"

while True:
    url = base_url + "?pageSize=300"
    if page_token:
        url += "&pageToken=" + page_token
    req = urllib.request.Request(url)
    req.add_header("Authorization", f"Bearer {token}")
    try:
        resp = urllib.request.urlopen(req, timeout=30)
        result = json.loads(resp.read().decode())
        docs = result.get("documents", [])
        all_docs.extend(docs)
        page_token = result.get("nextPageToken")
        if not page_token or not docs:
            break
    except Exception as e:
        print(f"Error: {e}")
        break

types = {}
for doc in all_docs:
    fields = doc.get("fields", {})
    t = fields.get("type", {}).get("stringValue", "unknown")
    types[t] = types.get(t, 0) + 1

print(f"Total documents: {len(all_docs)}")
for t, c in sorted(types.items(), key=lambda x: -x[1]):
    marker = " <<<" if t == "silhouette" else ""
    print(f"  {t}: {c}{marker}")

sil_count = types.get("silhouette", 0)
print(f"\n*** Silhouette questions in Firestore: {sil_count} ***")