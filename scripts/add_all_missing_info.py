#!/usr/bin/env python3
"""
📊 Añadir infoToShow a TODAS las preguntas de population y area
"""

import json
import os

script_dir = '/home/node/.openclaw/workspace/GeoC/scripts'
input_file = os.path.join(script_dir, 'questions_all_merged_final.json')
output_file = input_file

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
    print("📊 Añadiendo infoToShow a TODAS las preguntas de population y area\n")
    
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
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(questions, f, indent=2, ensure_ascii=False)
    
    print(f"✅ Información añadida a {fixed} preguntas")
    print(f"📁 Guardado en: {output_file}")

if __name__ == '__main__':
    add_missing_info()
