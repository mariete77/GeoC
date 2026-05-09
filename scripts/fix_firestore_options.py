import json
import urllib.request
import urllib.parse
import pathlib
import time
import random

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
        
        try:
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
        except Exception as e:
            print(f"Error refreshing token: {e}")
            return None
    print("No credentials found. Run 'firebase login'.")
    return None

def fetch_all_questions(token):
    print("Fetching all questions from Firestore (esto puede tomar un minuto)...")
    url = f"https://firestore.googleapis.com/v1/projects/{PROJECT_ID}/databases/(default)/documents:runQuery"
    query = {
        "structuredQuery": {
            "from": [{"collectionId": "questions"}],
        }
    }
    body = json.dumps(query).encode("utf-8")
    req = urllib.request.Request(url, data=body, method="POST")
    req.add_header("Content-Type", "application/json")
    req.add_header("Authorization", f"Bearer {token}")

    questions = []
    try:
        with urllib.request.urlopen(req, timeout=60) as resp:
            results = json.loads(resp.read().decode())
            for r in results:
                doc = r.get("document", {})
                if doc:
                    doc_id = doc.get("name", "").split("/")[-1]
                    fields = doc.get("fields", {})
                    questions.append({
                        "id": doc_id,
                        "name": doc.get("name"),
                        "fields": fields
                    })
    except Exception as e:
        print(f"Error fetching questions: {e}")
    print(f"Fetched {len(questions)} questions.")
    return questions

def update_question_options(token, doc_name, new_options):
    url = f"https://firestore.googleapis.com/v1/{doc_name}?updateMask.fieldPaths=options"
    
    values = [{"stringValue": opt} for opt in new_options]
    
    body = {
        "fields": {
            "options": {
                "arrayValue": {
                    "values": values
                }
            }
        }
    }
    
    req = urllib.request.Request(url, data=json.dumps(body).encode("utf-8"), method="PATCH")
    req.add_header("Content-Type", "application/json")
    req.add_header("Authorization", f"Bearer {token}")
    
    try:
        with urllib.request.urlopen(req, timeout=10) as resp:
            pass
        return True
    except Exception as e:
        print(f"Error updating {doc_name}: {e}")
        return False

def fix_firestore_options():
    token = get_access_token()
    if not token:
        return

    questions = fetch_all_questions(token)
    if not questions:
        return

    # Backup locally
    with open("questions_backup.json", "w", encoding="utf-8") as f:
        json.dump(questions, f, ensure_ascii=False, indent=2)
    print("Backup saved to questions_backup.json")

    # Group by type and collect valid answers
    type_to_answers = {}
    for q in questions:
        qtype = q["fields"].get("type", {}).get("stringValue", "unknown")
        correct = q["fields"].get("correctAnswer", {}).get("stringValue")
        if correct:
            if qtype not in type_to_answers:
                type_to_answers[qtype] = set()
            type_to_answers[qtype].add(correct)
            
    print(f"\nRespuestas válidas encontradas por categoría: { {k: len(v) for k,v in type_to_answers.items()} }\n")

    updated_count = 0
    for q in questions:
        qtype = q["fields"].get("type", {}).get("stringValue", "unknown")
        correct = q["fields"].get("correctAnswer", {}).get("stringValue")
        options_field = q["fields"].get("options", {}).get("arrayValue", {}).get("values", [])
        current_options = [opt.get("stringValue", "") for opt in options_field]
        
        if not correct or not current_options:
            continue
            
        valid_answers = type_to_answers.get(qtype, set())
        if len(valid_answers) < 4:
            continue
            
        # An option is "unknown" if it's not in the valid answers set for that category
        unknown_count = sum(1 for opt in current_options if opt not in valid_answers)
        
        if qtype in ['population', 'area']:
            if len(current_options) != 2 or unknown_count > 0:
                pool = list(valid_answers - {correct})
                distractor = random.choice(pool)
                new_options = [correct, distractor]
                random.shuffle(new_options)
            else:
                continue
        else:
            if len(current_options) != 4 or unknown_count > 0 or correct not in current_options:
                pool = list(valid_answers - {correct})
                if len(pool) >= 3:
                    distractors = random.sample(pool, 3)
                    new_options = distractors + [correct]
                    random.shuffle(new_options)
                else:
                    continue
            else:
                continue

        if set(new_options) != set(current_options):
            print(f"🔧 Corrigiendo {q['id']} ({qtype}):")
            print(f"   Viejas opciones: {current_options}")
            print(f"   Nuevas opciones: {new_options}")
            
            success = update_question_options(token, q["name"], new_options)
            if success:
                updated_count += 1
                
            time.sleep(0.1) # Pausa para no saturar la API

    print(f"\n¡Completado! Se corrigieron las opciones de {updated_count} preguntas.")

if __name__ == '__main__':
    fix_firestore_options()
