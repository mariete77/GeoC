import json
import sys

filename = sys.argv[1] if len(sys.argv) > 1 else "scripts/questions_clean.json"
with open(filename, "r", encoding="utf-8") as f:
    data = json.load(f)

types = {}
for q in data:
    t = q.get("type", "UNKNOWN")
    types[t] = types.get(t, 0) + 1

print(f"File: {filename}")
print(f"Total questions: {len(data)}")
print(f"\nTypes found ({len(types)}):")
for t in sorted(types.keys()):
    print(f"  {t}: {types[t]}")