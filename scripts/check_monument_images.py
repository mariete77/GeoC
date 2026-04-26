"""Quick check of monument/historicBuilding docs in Firestore."""
import json, urllib.request, pathlib

cred_path = pathlib.Path.home() / ".config" / "configstore" / "firebase-tools.json"
if not cred_path.exists():
    cred_path = pathlib.Path.home() / "AppData" / "Roaming" / "firebase-tools.json"
data = json.load(open(cred_path, "r", encoding="utf-8"))
token = data["tokens"]["access_token"]

def get_doc(doc_id):
    url = f"https://firestore.googleapis.com/v1/projects/geoquiz-7790d/databases/(default)/documents/questions/{doc_id}"
    req = urllib.request.Request(url)
    req.add_header("Authorization", f"Bearer {token}")
    try:
        resp = urllib.request.urlopen(req, timeout=10)
        result = json.loads(resp.read().decode())
        return result.get("fields", {})
    except Exception as e:
        return {"ERROR": str(e)}

# Check monumentImage docs
print("=== monumentImage samples ===")
for i in range(5):
    fields = get_doc(f"monument_image_{i}")
    if "ERROR" in fields:
        print(f"  monument_image_{i}: {fields['ERROR']}")
    else:
        img = fields.get("imageUrl", {}).get("stringValue", "NULL")
        ans = fields.get("correctAnswer", {}).get("stringValue", "?")
        qtxt = fields.get("questionText", {}).get("stringValue", "?")
        extra = fields.get("extraData", {}).get("mapValue", {}).get("fields", {})
        print(f"  monument_image_{i}: imageUrl={img}, answer={ans}, qText={qtxt[:50]}")

print("\n=== historicBuilding samples ===")
for i in range(4):
    fields = get_doc(f"historic_building_{i}")
    if "ERROR" in fields:
        print(f"  historic_building_{i}: {fields['ERROR']}")
    else:
        img = fields.get("imageUrl", {}).get("stringValue", "NULL")
        ans = fields.get("correctAnswer", {}).get("stringValue", "?")
        qtxt = fields.get("questionText", {}).get("stringValue", "?")
        print(f"  historic_building_{i}: imageUrl={img}, answer={ans}, qText={qtxt[:50]}")

print("\n=== monumentCountry samples ===")
for i in range(3):
    fields = get_doc(f"monument_country_{i}")
    if "ERROR" in fields:
        print(f"  monument_country_{i}: {fields['ERROR']}")
    else:
        img = fields.get("imageUrl", {}).get("stringValue", "NULL")
        ans = fields.get("correctAnswer", {}).get("stringValue", "?")
        print(f"  monument_country_{i}: imageUrl={img}, answer={ans}")

# Check local monument JSON files
import os, glob
print("\n=== Local JSON files with monument data ===")
for f in glob.glob("scripts/*monument*") + glob.glob("scripts/*building*") + glob.glob("questions/*monument*"):
    print(f"  {f}")
    try:
        with open(f, 'r', encoding='utf-8') as fh:
            qdata = json.load(fh)
            if isinstance(qdata, list) and len(qdata) > 0:
                sample = qdata[0]
                print(f"    Sample: id={sample.get('id')}, imageUrl={sample.get('imageUrl', 'NULL')}, answer={sample.get('correctAnswer')}")
                has_img = sum(1 for q in qdata if q.get('imageUrl'))
                print(f"    Total: {len(qdata)}, with imageUrl: {has_img}")
    except:
        pass