#!/usr/bin/env python3
"""
🔧 Corregir preguntas donde la respuesta correcta no está en las opciones

Asegura que el 100% de las preguntas sean válidas antes de importar.
"""

import json
import random
import os
from typing import List, Dict

def fix_questions_file(input_file: str, output_file: str) -> Dict:
    """Corrige un archivo de preguntas"""
    with open(input_file, 'r', encoding='utf-8') as f:
        questions = json.load(f)
    
    stats = {
        'total': len(questions),
        'fixed': 0,
        'already_valid': 0,
        'no_options': 0
    }
    
    for q in questions:
        qtype = q.get('type', '')
        options = q.get('options', [])
        correct = q.get('correctAnswer', '')
        
        # Si no hay opciones, saltar
        if not options:
            stats['no_options'] += 1
            continue
        
        # Verificar si la respuesta correcta está en las opciones
        if correct in options:
            stats['already_valid'] += 1
            continue
        
        # Corregir: reemplazar una opción incorrecta con la correcta
        # Para preguntas de comparación (2 opciones), tenemos que ser cuidadosos
        if qtype in ['population', 'area'] and len(options) == 2:
            # Son preguntas de comparación con solo 2 opciones
            # Una debería ser la correcta
            if options[0] != correct and options[1] != correct:
                # Ninguna de las 2 opciones es la correcta
                # Reemplazar la primera
                options[0] = correct
                stats['fixed'] += 1
            elif options[0] != correct:
                options[0] = correct
                stats['fixed'] += 1
            elif options[1] != correct:
                options[1] = correct
                stats['fixed'] += 1
        else:
            # Preguntas normales con 4 opciones
            # Reemplazar la primera opción incorrecta
            for i in range(len(options)):
                if options[i] != correct:
                    options[i] = correct
                    stats['fixed'] += 1
                    break
        
        q['options'] = options
    
    # Guardar archivo corregido
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(questions, f, indent=2, ensure_ascii=False)
    
    return stats

def main():
    # Ruta absoluta
    script_dir = os.path.dirname(os.path.abspath(__file__))
    input_file = os.path.join(script_dir, 'questions_all_merged.json')
    output_file = os.path.join(script_dir, 'questions_all_merged_fixed.json')
    
    print("🔧 Corrección de Preguntas Inválidas\n")
    print(f"📂 Entrada: {input_file}")
    print(f"📂 Salida: {output_file}\n")
    
    if not os.path.exists(input_file):
        print(f"❌ Error: No se encontró el archivo {input_file}")
        return
    
    stats = fix_questions_file(input_file, output_file)
    
    print("📊 RESULTADOS\n")
    print(f"Total preguntas: {stats['total']}")
    print(f"Ya válidas: {stats['already_valid']}")
    print(f"Corregidas: {stats['fixed']}")
    print(f"Sin opciones: {stats['no_options']}")
    
    validity_pct = (stats['already_valid'] + stats['fixed']) / stats['total'] * 100
    print(f"\n✅ Validez final: {validity_pct:.1f}%")
    
    if stats['already_valid'] + stats['fixed'] == stats['total']:
        print(f"\n🎉 ¡Éxito! Todas las {stats['total']} preguntas son válidas")
    else:
        print(f"\n⚠️  Atención: {stats['no_options']} preguntas sin opciones")

if __name__ == '__main__':
    main()
