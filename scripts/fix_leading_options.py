#!/usr/bin/env python3
"""
🔧 Corregir opciones que revelan la respuesta

Genera nuevas opciones que no contengan palabras del enunciado
para evitar que sea demasiado fácil.
"""

import json
import glob
import random
from typing import List, Set

def has_leading_word(question: str, option: str) -> bool:
    """Detecta si la opción contiene palabras del enunciado"""
    question_lower = question.lower()
    option_lower = option.lower()
    
    # Palabras a ignorar en español
    ignore_words = ['¿', 'qué', 'cuál', 'dónde', 'cómo', 'cuándo', 'a', 'de', 'en', 'la', 'el', 'los', 'las', 'un', 'una', 'es', 'está', 'se', 'encuentra', 'pertenece', 'tipo', 'es']
    
    # Obtener palabras del enunciado (mínimo 3 caracteres)
    question_words = [word.strip('¿?¡!.,;:') for word in question_lower.split() if word not in ignore_words and len(word) > 2]
    
    # Verificar si alguna palabra del enunciado está en la opción
    for word in question_words:
        if word in option_lower:
            return True
    
    return False

def get_alternative_option(
    correct_option: str,
    question_type: str,
    all_options: Set[str],
    question_text: str,
    country: str = None
) -> str:
    """Genera una opción alternativa que no revele la respuesta"""
    
    # Palabras del enunciado a evitar
    ignore_words = ['¿', 'qué', 'cuál', 'dónde', 'cómo', 'cuándo', 'a', 'de', 'en', 'la', 'el', 'los', 'las', 'un', 'una', 'es', 'está', 'se', 'encuentra', 'pertenece', 'tipo', 'es']
    question_lower = question_text.lower()
    forbidden_words = [word.strip('¿?¡!.,;:') for word in question_lower.split() if word not in ignore_words and len(word) > 2]
    
    # Lista de opciones alternativas por tipo
    alternatives_by_type = {
        'currency': [
            'Euro', 'Libra esterlina', 'Yen japonés', 'Yuan chino',
            'Dólar estadounidense', 'Franco suizo', 'Rublo ruso',
            'Dólar australiano', 'Dólar canadiense', 'Won surcoreano',
            'Rupia india', 'Dinar saudí', 'Real brasileño', 'Peso mexicano'
        ],
        'language': [
            'Español', 'Inglés', 'Francés', 'Alemán', 'Chino',
            'Japonés', 'Portugués', 'Italiano', 'Ruso', 'Árabe',
            'Hindi', 'Bengalí', 'Portugués', 'Japonés', 'Ruso'
        ],
        'capital': [
            'Madrid', 'París', 'Londres', 'Berlín', 'Roma',
            'Washington D.C.', 'Tokio', 'Pekín', 'Moscú', 'Brasilia',
            'Buenos Aires', 'Lima', 'Santiago', 'Ciudad de México', 'Bogotá'
        ],
        'flag': [
            'Alemania', 'Francia', 'España', 'Italia', 'Reino Unido',
            'Estados Unidos', 'China', 'Japón', 'Rusia', 'Brasil',
            'México', 'Argentina', 'Canadá', 'Australia', 'India'
        ]
    }
    
    # Obtener alternativas del tipo de pregunta
    alternatives = alternatives_by_type.get(question_type, [])
    
    # Filtrar alternativas que no estén en all_options y no contengan palabras prohibidas
    valid_alternatives = []
    for alt in alternatives:
        if alt not in all_options and alt != correct_option:
            # Verificar que no contenga palabras prohibidas
            if not any(forbidden_word in alt.lower() for forbidden_word in forbidden_words):
                valid_alternatives.append(alt)
    
    if valid_alternatives:
        return random.choice(valid_alternatives)
    
    # Si no hay alternativas, devolver una genérica
    if question_type == 'currency':
        return 'Euro'
    elif question_type == 'language':
        return 'Inglés'
    elif question_type == 'capital':
        return 'Madrid'
    elif question_type == 'flag':
        return 'Francia'
    else:
        return 'Otro'

def fix_leading_options():
    """Corrige opciones que revelan la respuesta"""
    question_files = glob.glob('/home/node/.openclaw/workspace/GeoC/scripts/questions_*.json')
    
    # Cargar todas las opciones correctas por tipo para generar alternativas
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
            
            # Verificar opciones que revelan la respuesta
            new_options = []
            needs_fix = False
            
            for opt in options:
                if has_leading_word(question_text, opt) and opt != correct:
                    # Generar alternativa usando otras opciones correctas del mismo tipo
                    all_options = set(options) | {correct}
                    available_alternatives = all_correct_options_by_type[qtype] - all_options
                    
                    if available_alternatives:
                        # Filtrar alternativas que no revelen la respuesta
                        valid_alternatives = []
                        for alt in available_alternatives:
                            if not has_leading_word(question_text, alt):
                                valid_alternatives.append(alt)
                        
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
