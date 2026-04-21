#!/usr/bin/env python3
"""
🔧 Corregir opciones que revelan la respuesta (Versión con depuración)
"""

import json
import glob
import random
import re
from typing import Set

def extract_country_from_question(question: str) -> Set[str]:
    question_lower = question.lower()
    country_names = set()
    
    patterns = [
        r'de\s+([a-záéíóúñ\s]+)\??',
        r'en\s+([a-záéíóúñ\s]+)\??',
        r'del\s+([a-záéíóúñ\s]+)\??',
    ]
    
    for pattern in patterns:
        matches = re.findall(pattern, question_lower)
        for match in matches:
            name = match.strip()
            for article in ['la', 'el', 'los', 'las', 'un', 'una']:
                if name.startswith(article + ' '):
                    name = name[len(article)+1:]
            if len(name) > 2:
                country_names.add(name)
    
    return country_names

def contains_country_name(option: str, country_names: Set[str]) -> bool:
    option_lower = option.lower()
    for country in country_names:
        if country in option_lower:
            return True
    return False

def fix_revealing_options():
    question_files = glob.glob('/home/node/.openclaw/workspace/GeoC/scripts/questions_*.json')
    
    # Cargar todas las opciones correctas por tipo
    all_correct_by_type = {
        'currency': set(),
        'language': set(),
        'capital': set(),
    }
    
    for file_path in sorted(question_files):
        with open(file_path) as f:
            questions = json.load(f)
        
        for q in questions:
            qtype = q.get('type')
            if qtype in all_correct_by_type:
                all_correct_by_type[qtype].add(q.get('correctAnswer', ''))
    
    print(f"Opciones correctas cargadas:")
    for qtype, options in all_correct_by_type.items():
        print(f"  {qtype}: {len(options)} opciones")
    
    total_fixed = 0
    files_fixed = 0
    problems_checked = 0
    
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
            
            # Extraer nombres de países
            country_names = extract_country_from_question(question_text)
            
            if not country_names:
                continue
            
            # Verificar opciones que contengan nombres de países
            new_options = []
            needs_fix = False
            
            for opt in options:
                if opt != correct and contains_country_name(opt, country_names):
                    problems_checked += 1
                    
                    # Generar alternativa
                    all_options = set(options) | {correct}
                    available = all_correct_by_type[qtype] - all_options
                    
                    if available:
                        valid_alternatives = []
                        for alt in available:
                            if not contains_country_name(alt, country_names):
                                valid_alternatives.append(alt)
                        
                        if valid_alternatives:
                            alternative = random.choice(list(valid_alternatives))
                            new_options.append(alternative)
                            needs_fix = True
                            total_fixed += 1
                        else:
                            alternative = random.choice(list(available))
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
    print(f"🔍 Problemas encontrados: {problems_checked}")
    print(f"📁 Archivos corregidos: {files_fixed}")
    print(f"🔧 Opciones corregidas: {total_fixed}")

if __name__ == '__main__':
    fix_revealing_options()
