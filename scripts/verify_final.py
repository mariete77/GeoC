#!/usr/bin/env python3
"""
🔍 Verificación final del archivo corregido
"""

import json
import os

script_dir = '/home/node/.openclaw/workspace/GeoC/scripts'
file_to_check = os.path.join(script_dir, 'questions_all_merged_fixed.json')

print("🔍 VERIFICACIÓN FINAL DEL ARCHIVO CORREGIDO\n")
print(f"📂 Archivo: {file_to_check}\n")

with open(file_to_check, 'r', encoding='utf-8') as f:
    questions = json.load(f)

print(f"✅ Cargadas {len(questions)} preguntas\n")

problem_ids = ['flag_30009', 'population_30071', 'lake_52000']
found = {}

for q in questions:
    qid = q.get('id', '')
    
    if qid in problem_ids:
        found[qid] = {
            'type': q.get('type', ''),
            'questionText': q.get('questionText', ''),
            'options': q.get('options', []),
            'correctAnswer': q.get('correctAnswer', ''),
            'extraData': q.get('extraData', {}),
            'options_count': len(q.get('options', [])),
            'has_infoToShow': 'infoToShow' in q.get('extraData', {})
        }

print("=== RESULTADOS DE VERIFICACIÓN ===\n")

if 'flag_30009' in found:
    q = found['flag_30009']
    print(f"ID: flag_30009")
    print(f"Tipo: {q['type']}")
    print(f"Opciones ({q['options_count']}): {q['options']}")
    print(f"Correcta: {q['correctAnswer']}")
    print(f"✅ Estado: {'Tiene 4 opciones - CORRECTO' if q['options_count'] >= 4 else 'ERROR'}")
    print()
else:
    print("⚠️  flag_30009 NO ENCONTRADO\n")

if 'population_30071' in found:
    q = found['population_30071']
    print(f"ID: population_30071")
    print(f"Tipo: {q['type']}")
    print(f"InfoToShow: {q['has_infoToShow']}")
    print(f"✅ Estado: {'Tiene infoToShow - CORRECTO' if q['has_infoToShow'] else 'ERROR'}")
    print()
else:
    print("⚠️  population_30071 NO ENCONTRADO\n")

if 'lake_52000' in found:
    q = found['lake_52000']
    print(f"ID: lake_52000")
    print(f"Tipo: {q['type']}")
    print(f"Opciones ({q['options_count']}): {q['options']}")
    print(f"Correcta: {q['correctAnswer']}")
    print(f"✅ Estado: {'Tiene 4 opciones - CORRECTO' if q['options_count'] >= 4 else 'ERROR'}")
    print()
else:
    print("⚠️  lake_52000 NO ENCONTRADO\n")

# Conteo de preguntas válidas
invalid_count = 0
valid_count = 0

for q in questions:
    qtype = q.get('type', '')
    options = q.get('options', [])
    correct = q.get('correctAnswer', '')
    
    # Validación básica
    if qtype == 'flag' and not q.get('imageUrl'):
        invalid_count += 1
    elif qtype == 'population' and 'infoToShow' not in q.get('extraData', {}):
        invalid_count += 1
    elif qtype == 'area' and 'infoToShow' not in q.get('extraData', {}):
        invalid_count += 1
    elif len(options) < 2:
        invalid_count += 1
    elif correct not in options:
        invalid_count += 1
    else:
        valid_count += 1

print("=" * 60)
print("📊 RESUMEN DE VALIDACIÓN")
print("=" * 60)
print(f"Total preguntas: {len(questions)}")
print(f"Válidas: {valid_count} ({valid_count/len(questions)*100:.1f}%)")
print(f"Inválidas: {invalid_count} ({invalid_count/len(questions)*100:.1f}%)")

if invalid_count == 0:
    print("\n🎉 ¡ÉXITO! El 100% de las preguntas son válidas")
else:
    print(f"\n⚠️  Aún hay {invalid_count} preguntas inválidas")
