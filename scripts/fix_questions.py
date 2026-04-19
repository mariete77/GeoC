#!/usr/bin/env python3
"""
🔧 Corregir preguntas donde la respuesta correcta no está en las opciones
"""

import json
import glob

def fix_questions():
    """Corrige preguntas donde la respuesta correcta no está en las opciones"""
    # Buscar todos los archivos de preguntas
    question_files = glob.glob('/home/node/.openclaw/workspace/GeoC/scripts/questions_*.json')
    
    total_fixed = 0
    files_fixed = 0
    
    for file_path in sorted(question_files):
        with open(file_path) as f:
            questions = json.load(f)
        
        fixed = False
        
        for i, q in enumerate(questions):
            correct_answer = q.get('correctAnswer', '')
            options = q.get('options', [])
            
            # Verificar si la respuesta correcta está en las opciones
            if correct_answer and correct_answer not in options:
                print(f"⚠️  Bug encontrado en {file_path.split('/')[-1]}")
                print(f"   ID: {q.get('id')}")
                print(f"   Pregunta: {q.get('questionText')}")
                print(f"   Opciones: {options}")
                print(f"   Correcta (no en opciones): {correct_answer}")
                
                # Corregir: reemplazar una de las opciones incorrectas con la correcta
                if len(options) >= 2:
                    # Reemplazar la primera opción incorrecta
                    q['options'][0] = correct_answer
                    fixed = True
                    total_fixed += 1
                    print(f"   ✅ Corregido: Reemplazada opción con la correcta\n")
                else:
                    print(f"   ❌ No se puede corregir: Menos de 2 opciones\n")
        
        if fixed:
            # Guardar archivo corregido
            with open(file_path, 'w', encoding='utf-8') as f:
                json.dump(questions, f, indent=2, ensure_ascii=False)
            
            files_fixed += 1
    
    print(f"\n🎉 ¡Corrección completada!")
    print(f"📁 Archivos corregidos: {files_fixed}")
    print(f"🔧 Preguntas corregidas: {total_fixed}")

if __name__ == '__main__':
    fix_questions()
