#!/usr/bin/env python3
"""
🔧 Corregir opciones que revelan la respuesta (Versión simple y agresiva)
"""

import json
import glob
import re

def contains_any_word(question: str, option: str, min_length: int = 3) -> bool:
    """Detecta si la opción contiene palabras del enunciado"""
    question_lower = question.lower()
    option_lower = option.lower()
    
    # Palabras a ignorar en español
    ignore_words = {'¿', 'qué', 'cuál', 'dónde', 'cómo', 'cuándo', 'a', 'de', 'en', 'la', 'el', 'los', 'las', 'un', 'una', 'es', 'está', 'se', 'encuentra', 'pertenece', 'es', 'tipo', 'país', 'moneda', 'idioma', 'capital', 'bandera'}
    
    # Extraer palabras del enunciado
    question_words = set()
    for word in re.findall(r'\b\w+\b', question_lower):
        if len(word) >= min_length and word not in ignore_words:
            question_words.add(word)
    
    # Verificar si alguna palabra del enunciado está en la opción
    for word in question_words:
        if word in option_lower:
            return True
    
    return False

def fix_revealing_options():
    """Corrige opciones que revelan la respuesta"""
    question_files = glob.glob('/home/node/.openclaw/workspace/GeoC/scripts/questions_*.json')
    
    # Cargar todas las opciones correctas por tipo
    all_correct_by_type = {
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
            if qtype in all_correct_by_type:
                all_correct_by_type[qtype].add(q.get('correctAnswer', ''))
    
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
            
            if qtype not in all_correct_by_type:
                continue
            
            # Verificar cada opción
            new_options = []
            needs_fix = False
            
            for opt in options:
                if opt != correct and contains_any_word(question_text, opt):
                    # Generar alternativa
                    all_available = all_correct_by_type[qtype] - set(options) - {correct}
                    
                    if all_available:
                        # Buscar alternativa que no revele la respuesta
                        valid_alternatives = []
                        for alt in all_available:
                            if not contains_any_word(question_text, alt):
                                valid_alternatives.append(alt)
                        
                        if valid_alternatives:
                            alternative = random.choice(list(valid_alternatives))
                            new_options.append(alternative)
                            needs_fix = True
                            total_fixed += 1
                        else:
                            # Si todas las alternativas revelan, usar cualquiera
                            alternative = random.choice(list(all_available))
                            new_options.append(alternative)
                            needs_fix = True
                            total_fixed += 1
                    else:
                        new_options.append(opt)
                else:
                    new_options.append(opt)
            
            if needs_fix:
                random.shuffle(new_options)
                q['options'] = new_options
                fixed = True
        
        if fixed:
            with open(file_path, 'w', encoding='utf-8') as f:
                json.dump(questions, f, indent=2, ensure_ascii=False)
            
            files_fixed += 1
            print(f"✅ Corregido: {file_path.split('/')[-1]}")
    
    print(f"\n🎉 ¡Corrección completada!")
    print(f"📁 Archivos corregidos: {files_fixed}")
    print(f"🔧 Opciones corregidas: {total_fixed}")

if __name__ == '__main__':
    fix_revealing_options()
