#!/usr/bin/env python3
"""
🚀 GeoQuiz Battle - Generador de Preguntas (Python)
Version compatible con generate_questions_enhanced.dart
"""

import json
import random
import sys
import os
from typing import List, Dict, Set

# Importar dataset local
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from countries_data import COUNTRIES_DATA

def fetch_countries() -> List[Dict]:
    """Obtener países desde dataset local"""
    print("📊 Cargando dataset de países...")
    
    countries = COUNTRIES_DATA.copy()
    print(f"✅ {len(countries)} países cargados\n")
    return countries
    
    # Filtrar países válidos
    valid = [c for c in data 
              if c.get('name') and c['name'].get('common') 
              and c.get('cca2') and c.get('population') and c.get('area')]
    
    print(f"✅ {len(valid)} países válidos\n")
    return valid

def generate_wrong_options(countries: List[Dict], correct: str, count: int, exclude: Set[str] = None) -> List[str]:
    """Generar opciones incorrectas"""
    exclude = exclude or set()
    exclude.add(correct)
    
    wrong = []
    while len(wrong) < count:
        country = random.choice(countries)
        name = country['name']['common']
        if name not in exclude:
            wrong.append(name)
            exclude.add(name)
    
    return wrong

def determine_difficulty(country: Dict, qtype: str) -> str:
    """Determinar dificultad basada en país y tipo"""
    name = country['name']['common'].lower()
    population = country.get('population', 0)
    area = country.get('area', 0)
    region = country.get('region', '').lower()
    
    well_known = {
        'spain', 'france', 'germany', 'italy', 'united kingdom', 'united states',
        'canada', 'mexico', 'brazil', 'argentina', 'china', 'japan', 'india',
        'australia', 'russia', 'portugal', 'netherlands', 'belgium', 'switzerland'
    }
    
    if qtype in ['flag', 'capital']:
        if name in well_known:
            return 'easy'
        elif population > 10000000 or area > 1000000:
            return 'medium'
        else:
            return 'hard'
    elif qtype in ['population', 'area']:
        if population > 100000000 or area > 5000000:
            return 'easy'
        elif population > 10000000 or area > 500000:
            return 'medium'
        else:
            return 'hard'
    else:
        if name in well_known:
            return 'easy'
        elif region in ['europe', 'americas']:
            return 'medium'
        else:
            return 'hard'

def generate_flag_questions(countries: List[Dict], count: int, start_id: int) -> List[Dict]:
    """Generar preguntas de banderas"""
    print("🏳️ Generando preguntas de banderas...")
    
    flag_countries = [c for c in countries if c.get('flags') and c['flags'].get('png')]
    questions = []
    used: Set[str] = set()
    
    for i in range(min(count, len(flag_countries))):
        # Encontrar país no usado
        attempts = 0
        country = None
        while country is None and attempts < 100:
            c = random.choice(flag_countries)
            if c['cca2'] not in used:
                country = c
                used.add(c['cca2'])
            attempts += 1
        
        if country is None:
            continue
        
        name = country['name']['common']
        code = country['cca2']
        flag_url = country['flags']['png']
        
        wrong = generate_wrong_options(countries, name, 3, used)
        options = [name] + wrong
        random.shuffle(options)
        
        questions.append({
            'id': f'flag_{start_id + i}',
            'type': 'flag',
            'difficulty': determine_difficulty(country, 'flag'),
            'questionText': '¿De qué país es esta bandera?',
            'correctAnswer': name,
            'options': options,
            'imageUrl': flag_url,
            'extraData': {
                'countryCode': code.lower(),
                'countryName': name
            }
        })
    
    print(f"   ✅ {len(questions)} preguntas generadas")
    return questions

def generate_capital_questions(countries: List[Dict], count: int, start_id: int) -> List[Dict]:
    """Generar preguntas de capitales"""
    print("🏛️ Generando preguntas de capitales...")
    
    capital_countries = [c for c in countries 
                         if c.get('capital') and c['capital'] 
                         and c['capital'][0]]
    questions = []
    used: Set[str] = set()
    
    for i in range(min(count, len(capital_countries))):
        attempts = 0
        country = None
        while country is None and attempts < 100:
            c = random.choice(capital_countries)
            if c['cca2'] not in used:
                country = c
                used.add(c['cca2'])
            attempts += 1
        
        if country is None:
            continue
        
        name = country['name']['common']
        capital = country['capital'][0]
        
        # Generar opciones incorrectas de otras capitales
        wrong = []
        excluded = {capital}
        while len(wrong) < 3:
            c = random.choice(capital_countries)
            if c.get('capital') and c['capital'][0]:
                cap = c['capital'][0]
                if cap not in excluded:
                    wrong.append(cap)
                    excluded.add(cap)
        
        options = [capital] + wrong
        random.shuffle(options)
        
        questions.append({
            'id': f'capital_{start_id + i}',
            'type': 'capital',
            'difficulty': determine_difficulty(country, 'capital'),
            'questionText': f'¿Cuál es la capital de {name}?',
            'correctAnswer': capital,
            'options': options,
            'extraData': {
                'countryCode': country['cca2'].lower(),
                'countryName': name
            }
        })
    
    print(f"   ✅ {len(questions)} preguntas generadas")
    return questions

def generate_population_questions(countries: List[Dict], count: int, start_id: int) -> List[Dict]:
    """Generar preguntas de población"""
    print("👥 Generando preguntas de población...")
    
    sorted_countries = sorted(countries, key=lambda x: x.get('population', 0), reverse=True)
    questions = []
    used_pairs: Set[str] = set()
    
    for i in range(count):
        attempts = 0
        c1, c2 = None, None
        
        while (c1 is None or c2 is None) and attempts < 100:
            idx1 = random.randint(0, len(sorted_countries) // 2)  # Más poblados
            idx2 = random.randint(len(sorted_countries) // 2, len(sorted_countries))  # Menos poblados
            
            cand1, cand2 = sorted_countries[idx1], sorted_countries[idx2]
            
            pair_key = f"{cand1['cca2']}-{cand2['cca2']}"
            reverse_key = f"{cand2['cca2']}-{cand1['cca2']}"
            
            if pair_key not in used_pairs and reverse_key not in used_pairs:
                c1, c2 = cand1, cand2
                used_pairs.add(pair_key)
            attempts += 1
        
        if c1 is None or c2 is None:
            continue
        
        name1, name2 = c1['name']['common'], c2['name']['common']
        pop1, pop2 = c1['population'], c2['population']
        
        correct = name1 if pop1 > pop2 else name2
        
        questions.append({
            'id': f'population_{start_id + i}',
            'type': 'population',
            'difficulty': 'medium',
            'questionText': '¿Qué país tiene más población?',
            'correctAnswer': correct,
            'options': [name1, name2],
            'extraData': {
                'countries': [name1, name2],
                'population1': pop1,
                'population2': pop2
            }
        })
    
    print(f"   ✅ {len(questions)} preguntas generadas")
    return questions

def print_statistics(questions: List[Dict]):
    """Imprimir estadísticas"""
    by_type = {}
    by_difficulty = {}
    
    for q in questions:
        qtype = q['type']
        diff = q['difficulty']
        by_type[qtype] = by_type.get(qtype, 0) + 1
        by_difficulty[diff] = by_difficulty.get(diff, 0) + 1
    
    print('\n📊 Estadísticas:')
    print(f'   • Total: {len(questions)} preguntas')
    print('\n📊 Por tipo:')
    for t, c in by_type.items():
        print(f'   • {t}: {c}')
    
    print('\n📊 Por dificultad:')
    for d, c in by_difficulty.items():
        print(f'   • {d}: {c}')

def main():
    print('🚀 GeoQuiz Battle - Generador de Preguntas (Python)\n')
    
    # Obtener países
    countries = fetch_countries()
    if not countries:
        print('❌ No se pudieron obtener países')
        return
    
    # Configuración
    questions_per_type = 25
    start_id = 20000
    questions = []
    
    # Generar por tipo
    questions.extend(generate_flag_questions(countries, questions_per_type, start_id))
    start_id += len(questions)
    
    questions.extend(generate_capital_questions(countries, questions_per_type, start_id))
    start_id += len(questions)
    
    questions.extend(generate_population_questions(countries, questions_per_type, start_id))
    
    # Mezclar
    random.shuffle(questions)
    
    # Guardar
    output_file = 'scripts/questions_python_generated.json'
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(questions, f, indent=2, ensure_ascii=False)
    
    print(f'\n🎉 ¡Generación completada!')
    print_statistics(questions)
    print(f'\n💾 Guardado en: {output_file}')
    print('\n📤 Para importar a Firestore:')
    print('   dart scripts/import_questions_firestore.dart')

if __name__ == '__main__':
    main()