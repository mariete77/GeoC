#!/usr/bin/env python3
"""
📊 Añadir información educativa a preguntas de población y área

Para que el usuario aprenda tanto si acierta como si falla.
"""

import json
import glob
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

def add_info_to_questions():
    """Añade campo infoToShow a preguntas de población y área"""
    question_files = glob.glob('/home/node/.openclaw/workspace/GeoC/scripts/questions_*.json')
    
    total_updated = 0
    files_updated = 0
    
    for file_path in sorted(question_files):
        with open(file_path) as f:
            questions = json.load(f)
        
        updated = False
        
        for q in questions:
            qtype = q.get('type')
            
            if qtype == 'population':
                extra = q.get('extraData', {})
                countries = extra.get('countries', [])
                population1 = extra.get('population1', 0)
                population2 = extra.get('population2', 0)
                
                if countries and population1 and population2:
                    # Determinar qué país tiene más población
                    if population1 > population2:
                        winner = countries[0]
                        winner_pop = population1
                    else:
                        winner = countries[1]
                        winner_pop = population2
                    
                    # Verificar que el winner coincida con la respuesta correcta
                    if winner == q.get('correctAnswer', ''):
                        # Añadir información educativa
                        q['extraData']['infoToShow'] = f"{format_population(winner_pop)} habitantes"
                        updated = True
            
            elif qtype == 'area':
                extra = q.get('extraData', {})
                countries = extra.get('countries', [])
                area1 = extra.get('area1', 0)
                area2 = extra.get('area2', 0)
                
                if countries and area1 and area2:
                    # Determinar qué país es más extenso
                    if area1 > area2:
                        winner = countries[0]
                        winner_area = area1
                    else:
                        winner = countries[1]
                        winner_area = area2
                    
                    if winner == q.get('correctAnswer', ''):
                        q['extraData']['infoToShow'] = f"{format_area(winner_area)}"
                        updated = True
            
            if updated:
                total_updated += 1
        
        if updated:
            # Guardar archivo actualizado
            with open(file_path, 'w', encoding='utf-8') as f:
                json.dump(questions, f, indent=2, ensure_ascii=False)
            
            files_updated += 1
            print(f"✅ Actualizado: {file_path.split('/')[-1]}")
    
    print(f"\n🎉 ¡Actualización completada!")
    print(f"📁 Archivos actualizados: {files_updated}")
    print(f"📊 Preguntas actualizadas: {total_updated}")

if __name__ == '__main__':
    add_info_to_questions()
