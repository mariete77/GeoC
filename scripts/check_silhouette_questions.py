import json
import os
import glob

# Find all JSON files with questions
json_files = glob.glob("scripts/*.json") + glob.glob("data/*.json")
print("=== JSON question files ===")
for jf in json_files:
    try:
        with open(jf, "r", encoding="utf-8") as f:
            qs = json.load(f)
        if isinstance(qs, list):
            sils = [q for q in qs if isinstance(q, dict) and q.get("type") == "silhouette"]
            print(f"{jf}: {len(qs)} questions, {len(sils)} silhouettes")
            if sils:
                for s in sils[:3]:
                    print(f"    id={s.get('id')}, imageUrl={s.get('imageUrl', 'NONE')}, answer={s.get('correctAnswer', '')}")
        else:
            print(f"{jf}: not a list")
    except Exception as e:
        print(f"{jf}: error - {e}")

# Check available silhouette images
sil_dir = "assets/silhouettes"
if os.path.exists(sil_dir):
    images = sorted(os.listdir(sil_dir))
    pngs = [f for f in images if f.endswith(".png")]
    print(f"\nSilhouette images: {len(pngs)}")
    for p in pngs[:5]:
        print(f"  {p}")
    if len(pngs) > 5:
        print(f"  ... and {len(pngs)-5} more")

# Also check what types exist in questions_full.json
qf = "scripts/questions_full.json"
if os.path.exists(qf):
    with open(qf, "r", encoding="utf-8") as f:
        qs = json.load(f)
    types = {}
    for q in qs:
        t = q.get("type", "unknown")
        types[t] = types.get(t, 0) + 1
    print(f"\nTypes in {qf}:")
    for t, c in sorted(types.items(), key=lambda x: -x[1]):
        print(f"  {t}: {c}")
