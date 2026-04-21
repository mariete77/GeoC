#!/usr/bin/env python3
"""
🔧 Corregir opciones que revelan la respuesta (Versión mejorada)
"""

import json
import glob
import random
from typing import Set

def has_leading_word(question: str, option: str) -> bool:
    """Detecta si la opción contiene palabras del enunciado"""
    question_lower = question.lower()
    option_lower = option.lower()
    
    # Palabras a ignorar en español
    ignore_words = ['¿', 'qué', 'cuál', 'dónde', 'cómo', 'cuándo', 'a', 'de', 'en', 'la', 'el', 'los', 'las', 'un', 'una', 'es', 'está', 'se', 'encuentra', 'pertenece', 'tipo', 'es']
    
    # Obtener palabras del enunciado (mínimo 3 caracteres)
    question_words = [word.strip('¿?¡!.,;:') for word in question_lower.split() if word not in ignore_words and len(word) > 3]
    
    # Verificar si alguna palabra del enunciado está en la opción
    for word in question_words:
        if word in option_lower:
            return True
    
    return False

def extract_country_name(question_text: str) -> str:
    """Extrae el nombre del país de la pregunta"""
    words = question_text.split()
    for i, word in enumerate(words):
        if word.lower() in ['de', 'en', 'del'] and i + 1 < len(words):
            return words[i + 1]
    return ''

def fix_leading_options():
    """Corrige opciones que revelan la respuesta"""
    question_files = glob.glob('/home/node/.openclaw/workspace/GeoC/scripts/questions_*.json')
    
    # Cargar todas las opciones correctas por tipo
    all_correct_options_by_type = {
        'currency': set(),
        'language': set(),
        'capital': set(),
        'flag': set()
    }
    
    for file_path in sorted(question_files):
        with open(file_path) as f:
            questions = json.load(f)
        
        for q in questions:
            qtype = q.get('type')
            if qtype in all_correct_options_by_type:
                all_correct_options_by_type[qtype].add(q.get('correctAnswer', ''))
    
    total_fixed = 0
    files_fixed = 0
    
    for file_path in sorted(question_files):
        with open(file_path) as f:
            questions = json.load(f)
        
        fixed = False
        
        for q in questions:
            question_text = q.get('questionText', '')
            qtype = q.get('type', '')
            options = q.get('options', [])
            correct = q.get('correctAnswer', '')
            
            if qtype not in all_correct_options_by_type:
                continue
            
            # Extraer nombre del país si existe
            country_name = ''
            if qtype in ['currency', 'language', 'capital']:
                country_name = extract_country_name(question_text)
            
            # Verificar opciones que revelan la respuesta
            new_options = []
            needs_fix = False
            
            for opt in options:
                if has_leading_word(question_text, opt) and opt != correct:
                    # Generar alternativa usando otras opciones correctas del mismo tipo
                    all_options = set(options) | {correct}
                    available_alternatives = all_correct_options_by_type[qtype] - all_options
                    
                    if available_alternatives:
                        # Filtrar alternativas que no revelan la respuesta
                        valid_alternatives = []
                        for alt in available_alternatives:
                            if not has_leading_word(question_text, alt):
                                valid_alternatives.append(alt)
                        
                        # Filtrar también por país si es posible
                        if country_name and country_name.lower() in alt.lower():
                            continue
                        
                        if valid_alternatives:
                            alternative = random.choice(list(valid_alternatives))
                            new_options.append(alternative)
                            needs_fix = True
                            total_fixed += 1
                        else:
                            # Si todas las alternativas revelan, usar cualquiera
                            alternative = random.choice(list(available_alternatives))
                            new_options.append(alternative)
                            needs_fix = True
                            total_fixed += 1
                    else:
                        new_options.append(opt)
                else:
                    new_options.append(opt)
            
            if needs_fix:
                # Mezclar opciones
                random.shuffle(new_options)
                q['options'] = new_options
                fixed = True
        
        if fixed:
            # Guardar archivo corregido
            with open(file_path, 'w', encoding='utf-8') as f:
                json.dump(questions, f, indent=2, ensure_ascii=False)
            
            files_fixed += 1
            print(f"✅ Corregido: {file_path.split('/')[-1]}")
    
    print(f"\n🎉 ¡Corrección completada!")
    print(f"📁 Archivos corregidos: {files_fixed}")
    print(f"🔧 Opciones corregidas: {total_fixed}")

if __name__ == '__main__':
    fix_leading_options()
