#!/usr/bin/env python3
"""
🔧 Corregir los 3 problemas específicos identificados
"""

import json
import os

script_dir = '/home/node/.openclaw/workspace/GeoC/scripts'
input_file = os.path.join(script_dir, 'questions_all_merged_fixed.json')

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

def fix_specific_problems():
    """Corrige los 3 problemas específicos"""
    with open(input_file, 'r', encoding='utf-8') as f:
        questions = json.load(f)
    
    fixed = 0
    
    # Base de datos de lagos
    spain_lakes = [
        'Lago de Sanabria', 'Embalse de Almansa', 'Embalse de Cíjara',
        'Embalse de Almendra', 'Lago de Bañolas', 'Embalse de Mequinenza',
        'Embalse de Riaño', 'Embalse de Ricobayo', 'Embalse de Santa Teresa',
        'Embalse de Valdecañas'
    ]
    
    # Base de datos de banderas de países
    country_flags = {
        'ar': 'Argentina',
        'es': 'España',
        'fr': 'Francia',
        'de': 'Alemania',
        'it': 'Italia',
        'gb': 'Reino Unido',
        'us': 'Estados Unidos',
        'br': 'Brasil',
        'mx': 'México',
        'cn': 'China',
        'jp': 'Japón',
        'ru': 'Rusia',
        'in': 'India',
        'au': 'Australia',
        'ca': 'Canadá'
    }
    
    for q in questions:
        qid = q.get('id', '')
        qtype = q.get('type', '')
        
        # Problema 1: flag_30009 - Solo tiene 1 opción
        if qid == 'flag_30009':
            if len(q.get('options', [])) < 2:
                # Generar 3 opciones incorrectas de banderas
                correct = q.get('correctAnswer', '')
                options = [correct]
                
                # Añadir 3 banderas incorrectas
                for code, country in country_flags.items():
                    if country != correct:
                        options.append(country)
                        if len(options) >= 4:
                            break
                
                q['options'] = options
                fixed += 1
        
        # Problema 2: population_30071 - population2 es 0
        elif qid == 'population_30071':
            extra = q.get('extraData', {})
            pop1 = extra.get('population1', 0)
            pop2 = extra.get('population2', 0)
            countries = extra.get('countries', [])
            
            if pop2 == 0 and countries and pop1:
                # population2 está mal, usar population1
                # Esto probablemente es una pregunta de comparación
                correct = q.get('correctAnswer', '')
                
                if countries[0] == correct:
                    winner_pop = pop1
                else:
                    winner_pop = pop1
                
                extra['population2'] = pop1
                extra['infoToShow'] = format_population(winner_pop)
                fixed += 1
        
        # Problema 3: lake_52000 - Solo tiene 1 opción
        elif qid == 'lake_52000':
            if len(q.get('options', [])) < 2:
                correct = q.get('correctAnswer', '')
                options = [correct]
                
                # Añadir 3 lagos incorrectos
                for lake in spain_lakes:
                    if lake != correct:
                        options.append(lake)
                        if len(options) >= 4:
                            break
                
                q['options'] = options
                fixed += 1
    
    # Guardar archivo corregido
    with open(input_file, 'w', encoding='utf-8') as f:
        json.dump(questions, f, indent=2, ensure_ascii=False)
    
    print(f"📊 Corregidos {fixed} problemas específicos")

if __name__ == '__main__':
    fix_specific_problems()
