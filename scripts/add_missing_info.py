#!/usr/bin/env python3
"""
📊 Añadir información educativa a preguntas de población y área faltantes
"""

import json
from typing import Dict

def format_population(population: int) -> str:
    """Formatea número de población"""
    if population >= 1000000000:
        return f"{population / 1000000000:.1f} mil millones"
    elif population >= 1000000:
        return f"{population / 1000000:.1f} millones"
    else:
        return f"{population / 1000:.0f} mil"

def format_area(area: float) -> str:
    """Formatea área en km²"""
    if area >= 1000000:
        return f"{area / 1000000:.1f} millones de km²"
    elif area >= 1000:
        return f"{area / 1000:.0f} mil km²"
    else:
        return f"{area:.0f} km²"

def add_missing_info():
    """Añade información educativa faltante"""
    # Ruta absoluta
    script_dir = '/home/node/.openclaw/workspace/GeoC/scripts'
    input_file = f'{script_dir}/questions_all_merged_fixed.json'
    output_file = input_file
    
    with open(input_file, 'r', encoding='utf-8') as f:
        questions = json.load(f)
    
    fixed = 0
    
    for q in questions:
        qtype = q.get('type', '')
        extra = q.get('extraData', {})
        
        if qtype == 'population' and 'infoToShow' not in extra:
            countries = extra.get('countries', [])
            pop1 = extra.get('population1', 0)
            pop2 = extra.get('population2', 0)
            correct = q.get('correctAnswer', '')
            
            if countries and pop1 and pop2 and correct:
                # Determinar ganador
                if countries[0] == correct:
                    winner_pop = pop1
                else:
                    winner_pop = pop2
                
                extra['infoToShow'] = format_population(winner_pop)
                fixed += 1
        
        elif qtype == 'area' and 'infoToShow' not in extra:
            countries = extra.get('countries', [])
            area1 = extra.get('area1', 0)
            area2 = extra.get('area2', 0)
            correct = q.get('correctAnswer', '')
            
            if countries and area1 and area2 and correct:
                # Determinar ganador
                if countries[0] == correct:
                    winner_area = area1
                else:
                    winner_area = area2
                
                extra['infoToShow'] = format_area(winner_area)
                fixed += 1
    
    # Guardar archivo corregido
    with open('scripts/questions_all_merged_fixed.json', 'w', encoding='utf-8') as f:
        json.dump(questions, f, indent=2, ensure_ascii=False)
    
    print(f"📊 Información añadida a {fixed} preguntas")

if __name__ == '__main__':
    add_missing_info()
