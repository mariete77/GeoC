#!/usr/bin/env python3
"""
🌍 Generador de Preguntas de Geografía Avanzada (Wikipedia API)

Obtiene datos geográficos de Wikipedia para generar preguntas sobre:
- Ríos más largos
- Montañas más altas
- Lagos más grandes
- Ciudades más pobladas
- Desiertos
- Volcanes

Uso:
  python3 scripts/generate_wikipedia_questions.py [opciones]
"""

import json
import random
import argparse
import sys
import urllib.request
import urllib.parse
import time
from typing import List, Dict, Set, Optional, Tuple
from collections import Counter

# ========================================
# 🌍 WIKIPEDIA API
# ========================================

WIKIPEDIA_API_URL = "https://es.wikipedia.org/w/api.php"

def wikipedia_search(query: str, limit: int = 5) -> List[Dict]:
    """Busca páginas en Wikipedia española"""
    params = {
        'action': 'query',
        'list': 'search',
        'srsearch': query,
        'srlimit': limit,
        'format': 'json',
        'utf8': '',
        'origin': '*'
    }
    
    url = f"{WIKIPEDIA_API_URL}?{urllib.parse.urlencode(params)}"
    req = urllib.request.Request(url, headers={'User-Agent': 'GeoQuiz/1.0'})
    
    try:
        with urllib.request.urlopen(req, timeout=10) as response:
            data = json.loads(response.read().decode('utf-8'))
            return data.get('query', {}).get('search', [])
    except Exception as e:
        print(f"❌ Error buscando '{query}': {e}")
        return []

def wikipedia_get_page_content(pageid: int) -> Optional[str]:
    """Obtiene el contenido de una página de Wikipedia"""
    params = {
        'action': 'query',
        'prop': 'extracts',
        'pageids': pageid,
        'explaintext': 'true',
        'exintro': 'true',
        'format': 'json',
        'utf8': '',
        'origin': '*'
    }
    
    url = f"{WIKIPEDIA_API_URL}?{urllib.parse.urlencode(params)}"
    req = urllib.request.Request(url, headers={'User-Agent': 'GeoQuiz/1.0'})
    
    try:
        with urllib.request.urlopen(req, timeout=10) as response:
            data = json.loads(response.read().decode('utf-8'))
            pages = data.get('query', {}).get('pages', {})
            page = pages.get(str(pageid))
            if page:
                return page.get('extract', '')
    except Exception as e:
        print(f"❌ Error obteniendo página {pageid}: {e}")
    
    return None

# ========================================
# 🌊 RÍOS
# ========================================

def search_longest_river_for_country(country_name: str) -> Optional[Dict]:
    """Busca el río más largo de un país"""
    queries = [
        f"Río más largo de {country_name}",
        f"Principales ríos de {country_name}",
        f"Ríos principales de {country_name}"
    ]
    
    for query in queries:
        results = wikipedia_search(query, limit=3)
        
        for result in results:
            title = result['title']
            
            # Buscar patrones en el título
            if 'río' in title.lower() and country_name.lower() in title.lower():
                pageid = result['pageid']
                content = wikipedia_get_page_content(pageid)
                
                if content:
                    return {
                        'type': 'river',
                        'name': title.replace(f'Río ', '').strip(),
                        'full_title': title,
                        'country': country_name,
                        'content': content,
                        'pageid': pageid
                    }
    
    return None

def get_rivers_for_countries(countries: List[str], limit: int = 20) -> List[Dict]:
    """Obtiene ríos para varios países"""
    rivers = []
    processed = set()
    
    for country in countries:
        if country in processed:
            continue
        
        river = search_longest_river_for_country(country)
        if river:
            rivers.append(river)
            processed.add(country)
            print(f"  ✅ Río encontrado para {country}: {river['name']}")
        
        if len(rivers) >= limit:
            break
        
        time.sleep(0.5)  # Evitar rate limiting
    
    return rivers

# ========================================
# 🏔️ MONTAÑAS
# ========================================

def search_highest_mountain_for_country(country_name: str) -> Optional[Dict]:
    """Busca la montaña más alta de un país"""
    queries = [
        f"Montaña más alta de {country_name}",
        f"Pico más alto de {country_name}",
        f"Montañas principales de {country_name}"
    ]
    
    for query in queries:
        results = wikipedia_search(query, limit=3)
        
        for result in results:
            title = result['title']
            
            # Buscar patrones en el título
            keywords = ['montaña', 'pico', 'monte', 'cima']
            if any(kw in title.lower() for kw in keywords) and country_name.lower() in title.lower():
                pageid = result['pageid']
                content = wikipedia_get_page_content(pageid)
                
                if content:
                    return {
                        'type': 'mountain',
                        'name': title,
                        'country': country_name,
                        'content': content,
                        'pageid': pageid
                    }
    
    return None

def get_mountains_for_countries(countries: List[str], limit: int = 20) -> List[Dict]:
    """Obtiene montañas para varios países"""
    mountains = []
    processed = set()
    
    for country in countries:
        if country in processed:
            continue
        
        mountain = search_highest_mountain_for_country(country)
        if mountain:
            mountains.append(mountain)
            processed.add(country)
            print(f"  ✅ Montaña encontrada para {country}: {mountain['name']}")
        
        if len(mountains) >= limit:
            break
        
        time.sleep(0.5)
    
    return mountains

# ========================================
# 💧 LAGOS
# ========================================

def search_largest_lake_for_country(country_name: str) -> Optional[Dict]:
    """Busca el lago más grande de un país"""
    queries = [
        f"Lago más grande de {country_name}",
        f"Principales lagos de {country_name}"
    ]
    
    for query in queries:
        results = wikipedia_search(query, limit=3)
        
        for result in results:
            title = result['title']
            
            if 'lago' in title.lower() and country_name.lower() in title.lower():
                pageid = result['pageid']
                content = wikipedia_get_page_content(pageid)
                
                if content:
                    return {
                        'type': 'lake',
                        'name': title.replace(f'Lago ', '').strip(),
                        'full_title': title,
                        'country': country_name,
                        'content': content,
                        'pageid': pageid
                    }
    
    return None

def get_lakes_for_countries(countries: List[str], limit: int = 20) -> List[Dict]:
    """Obtiene lagos para varios países"""
    lakes = []
    processed = set()
    
    for country in countries:
        if country in processed:
            continue
        
        lake = search_largest_lake_for_country(country)
        if lake:
            lakes.append(lake)
            processed.add(country)
            print(f"  ✅ Lago encontrado para {country}: {lake['name']}")
        
        if len(lakes) >= limit:
            break
        
        time.sleep(0.5)
    
    return lakes

# ========================================
# 🏙️ CIUDADES MÁS POBLADAS
# ========================================

def search_largest_cities_for_country(country_name: str) -> List[Dict]:
    """Busca las ciudades más pobladas de un país"""
    query = f"Principales ciudades de {country_name}"
    results = wikipedia_search(query, limit=5)
    
    cities = []
    for result in results:
        title = result['title']
        
        # Excluir si es la capital (ya tenemos ese tipo de pregunta)
        if 'capital' in title.lower():
            continue
        
        pageid = result['pageid']
        content = wikipedia_get_page_content(pageid)
        
        if content:
            cities.append({
                'type': 'city',
                'name': title,
                'country': country_name,
                'content': content,
                'pageid': pageid
            })
    
    return cities[:3]  # Retornar las 3 primeras

# ========================================
# 📋 PLANTILLAS DE PREGUNTAS
# ========================================

RIVER_TEMPLATES = [
    "¿Cuál es el río más largo de {country}?",
    "¿Qué río es el más largo de {country}?",
    "¿El río más largo de {country} se llama...?",
    "¿Cuál es el principal río de {country}?",
]

MOUNTAIN_TEMPLATES = [
    "¿Cuál es la montaña más alta de {country}?",
    "¿Qué pico es el más alto de {country}?",
    "¿La montaña más alta de {country} es...?",
    "¿Cuál es el punto más alto de {country}?",
]

LAKE_TEMPLATES = [
    "¿Cuál es el lago más grande de {country}?",
    "¿Qué lago es el más grande de {country}?",
    "¿El lago más grande de {country} se llama...?",
    "¿Cuál es el principal lago de {country}?",
]

CITY_TEMPLATES = [
    "¿Cuál de estas ciudades pertenece a {country}?",
    "¿Qué ciudad está ubicada en {country}?",
    "¿La ciudad de {city} está en qué país?",
]

# ========================================
# 🎨 GENERADOR DE PREGUNTAS
# ========================================

def generate_river_questions(rivers: List[Dict], start_id: int = 50000) -> List[Dict]:
    """Genera preguntas sobre ríos"""
    questions = []
    
    for i, river in enumerate(rivers):
        template = random.choice(RIVER_TEMPLATES)
        question_text = template.format(country=river['country'])
        
        # Generar opciones incorrectas
        all_rivers = [r for r in rivers if r != river]
        wrong_rivers = random.sample(all_rivers, min(3, len(all_rivers)))
        
        options = [river['name']] + [r['name'] for r in wrong_rivers]
        random.shuffle(options)
        
        questions.append({
            'id': f'river_{start_id + i}',
            'type': 'river',
            'difficulty': 'medium',
            'questionText': question_text,
            'correctAnswer': river['name'],
            'options': options,
            'extraData': {
                'country': river['country'],
                'riverName': river['name'],
                'pageid': river['pageid']
            }
        })
    
    return questions

def generate_mountain_questions(mountains: List[Dict], start_id: int = 51000) -> List[Dict]:
    """Genera preguntas sobre montañas"""
    questions = []
    
    for i, mountain in enumerate(mountains):
        template = random.choice(MOUNTAIN_TEMPLATES)
        question_text = template.format(country=mountain['country'])
        
        all_mountains = [m for m in mountains if m != mountain]
        wrong_mountains = random.sample(all_mountains, min(3, len(all_mountains)))
        
        options = [mountain['name']] + [m['name'] for m in wrong_mountains]
        random.shuffle(options)
        
        questions.append({
            'id': f'mountain_{start_id + i}',
            'type': 'mountain',
            'difficulty': 'medium',
            'questionText': question_text,
            'correctAnswer': mountain['name'],
            'options': options,
            'extraData': {
                'country': mountain['country'],
                'mountainName': mountain['name'],
                'pageid': mountain['pageid']
            }
        })
    
    return questions

def generate_lake_questions(lakes: List[Dict], start_id: int = 52000) -> List[Dict]:
    """Genera preguntas sobre lagos"""
    questions = []
    
    for i, lake in enumerate(lakes):
        template = random.choice(LAKE_TEMPLATES)
        question_text = template.format(country=lake['country'])
        
        all_lakes = [l for l in lakes if l != lake]
        wrong_lakes = random.sample(all_lakes, min(3, len(all_lakes)))
        
        options = [lake['name']] + [l['name'] for l in wrong_lakes]
        random.shuffle(options)
        
        questions.append({
            'id': f'lake_{start_id + i}',
            'type': 'lake',
            'difficulty': 'medium',
            'questionText': question_text,
            'correctAnswer': lake['name'],
            'options': options,
            'extraData': {
                'country': lake['country'],
                'lakeName': lake['name'],
                'pageid': lake['pageid']
            }
        })
    
    return questions

# ========================================
# 🚀 FUNCIÓN PRINCIPAL
# ========================================

def main():
    parser = argparse.ArgumentParser(description='Generador de Preguntas Wikipedia')
    parser.add_argument('--types', default='river,mountain,lake',
                       help='Tipos de preguntas (river, mountain, lake)')
    parser.add_argument('--countries', default='10',
                       help='Cantidad de países a procesar')
    parser.add_argument('--output', default='scripts/questions_wikipedia.json',
                       help='Archivo de salida')

    args = parser.parse_args()

    types = args.types.split(',')
    num_countries = int(args.countries)
    output = args.output

    print('🌍 Generador de Preguntas Wikipedia\n')
    print(f'🎯 Configuración:')
    print(f'   • Tipos: {", ".join(types)}')
    print(f'   • Países: {num_countries}')
    print(f'   • Salida: {output}\n')

    # Lista de países para buscar
    countries_to_search = [
        'España', 'Francia', 'Italia', 'Alemania', 'Reino Unido',
        'Estados Unidos', 'Canadá', 'México', 'Brasil', 'Argentina',
        'China', 'Japón', 'India', 'Rusia', 'Australia',
        'Egipto', 'Sudáfrica', 'Perú', 'Chile', 'Colombia'
    ]

    countries_to_search = countries_to_search[:num_countries]

    all_questions = []

    if 'river' in types:
        print(f'🌊 Buscando ríos...')
        rivers = get_rivers_for_countries(countries_to_search, limit=num_countries)
        if rivers:
            questions = generate_river_questions(rivers)
            all_questions.extend(questions)
            print(f'   ✅ {len(questions)} preguntas de ríos')

    if 'mountain' in types:
        print(f'\n🏔️ Buscando montañas...')
        mountains = get_mountains_for_countries(countries_to_search, limit=num_countries)
        if mountains:
            questions = generate_mountain_questions(mountains)
            all_questions.extend(questions)
            print(f'   ✅ {len(questions)} preguntas de montañas')

    if 'lake' in types:
        print(f'\n💧 Buscando lagos...')
        lakes = get_lakes_for_countries(countries_to_search, limit=num_countries)
        if lakes:
            questions = generate_lake_questions(lakes)
            all_questions.extend(questions)
            print(f'   ✅ {len(questions)} preguntas de lagos')

    # Mezclar y guardar
    random.shuffle(all_questions)

    with open(output, 'w', encoding='utf-8') as f:
        json.dump(all_questions, f, indent=2, ensure_ascii=False)

    print(f'\n🎉 ¡Generación completada!')
    print(f'📊 Total: {len(all_questions)} preguntas')
    print(f'💾 Guardado en: {output}')

if __name__ == '__main__':
    main()
