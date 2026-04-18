#!/usr/bin/env python3
"""
🎨 Generador de Preguntas con Variedad de Formulaciones (Python)

Uso:
  python3 scripts/generate_varied_questions.py [opciones]
"""

import json
import random
import argparse
import sys
import urllib.request
from typing import List, Dict, Set
from collections import Counter

# ========================================
# 📋 PLANTILLAS DE PREGUNTAS VARIADAS
# ========================================

CAPITAL_TEMPLATES = [
    "¿Cuál es la capital de {country}?",
    "¿En qué ciudad se encuentra el gobierno de {country}?",
    "¿Qué ciudad es la sede administrativa de {country}?",
    "¿{capital} es la capital de qué país?",
    "¿Dónde está la capital de {country}?",
    "¿Cuál es la ciudad principal de {country}?",
    "¿La capital de {country} se llama...?",
    "¿Qué ciudad es el centro político de {country}?",
]

CURRENCY_TEMPLATES = [
    "¿Cuál es la moneda de {country}?",
    "¿Qué moneda se usa en {country}?",
    "¿La moneda oficial de {country} es...?",
    "¿En {country} se usa qué moneda?",
    "¿Cuál es la divisa de {country}?",
    "¿Qué currency tienen en {country}?",
    "¿Qué billetes y monedas circulan en {country}?",
]

LANGUAGE_TEMPLATES = [
    "¿Cuál es el idioma oficial de {country}?",
    "¿Qué idioma se habla en {country}?",
    "¿El idioma principal de {country} es...?",
    "¿En {country} qué idioma se usa?",
    "¿Cuál es la lengua oficial de {country}?",
    "¿Qué idioma predomina en {country}?",
    "¿Los habitantes de {country} hablan principalmente...?",
]

REGION_TEMPLATES = [
    "¿En qué región se encuentra {country}?",
    "¿{country} está ubicado en qué región?",
    "¿A qué región pertenece {country}?",
    "¿En qué continente está {country}?",
    "¿{country} es un país de qué región?",
    "¿En qué parte del mundo está {country}?",
    "¿{country} se ubica en...?",
]

BORDER_TEMPLATES = [
    "¿Con qué país limita {country}?",
    "¿{country} comparte frontera con qué país?",
    "¿Qué país es vecino de {country}?",
    "¿Con qué país hace frontera {country}?",
]

POPULATION_TEMPLATES = [
    "¿Qué país tiene más población, {country1} o {country2}?",
    "¿Entre {country1} y {country2}, cuál tiene más habitantes?",
    "¿Cuál de estos países es más poblado: {country1} o {country2}?",
    "¿Qué nación tiene mayor población, {country1} o {country2}?",
]

AREA_TEMPLATES = [
    "¿Qué país es más extenso, {country1} o {country2}?",
    "¿Entre {country1} y {country2}, cuál tiene mayor superficie?",
    "¿Cuál de estos países ocupa más territorio: {country1} o {country2}?",
    "¿Qué nación es más grande en extensión, {country1} o {country2}?",
]

# ========================================
# 🎲 SISTEMA DE SELECCIÓN DE PLANTILLAS
# ========================================

def select_random_template(templates: List[str]) -> str:
    """Selecciona una plantilla aleatoria"""
    return random.choice(templates)

def fill_template(template: str, replacements: Dict[str, str]) -> str:
    """Reemplaza los marcadores con valores reales"""
    result = template
    for key, value in replacements.items():
        result = result.replace(f"{{{key}}}", value)
    return result

def generate_question_text(templates: List[str], replacements: Dict[str, str]) -> str:
    """Genera el texto de una pregunta usando plantilla aleatoria"""
    template = select_random_template(templates)
    return fill_template(template, replacements)

# ========================================
# 📡 OBTENCIÓN DE DATOS
# ========================================

def fetch_countries() -> List[Dict]:
    """Obtiene datos de países desde REST Countries API"""
    print("📡 Conectando a REST Countries API...")

    try:
        url = "https://restcountries.com/v3.1/all?fields=name,cca2,capital,population,area,languages,currencies,region,flags"
        req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})

        with urllib.request.urlopen(req, timeout=30) as response:
            if response.status != 200:
                raise Exception(f"Error al obtener datos: {response.status}")

            data = json.loads(response.read().decode('utf-8'))

        # Filtrar países con datos requeridos
        filtered = [
            country for country in data
            if country.get('name') and country['name'].get('common') and country.get('cca2')
        ]

        print(f"✅ {len(filtered)} países obtenidos")
        return filtered

    except Exception as e:
        print(f"❌ Error: {e}")
        raise

# ========================================
# 🎨 GENERADORES DE PREGUNTAS
# ========================================

def generate_wrong_options(countries: List[Dict], correct_answer: str, count: int, exclude: Set[str] = None) -> List[str]:
    """Genera opciones incorrectas"""
    wrong = []
    excluded = exclude or set()
    excluded.add(correct_answer)

    while len(wrong) < count:
        country = random.choice(countries)
        name = country['name']['common']

        if name not in excluded:
            wrong.append(name)
            excluded.add(name)

    return wrong

def generate_wrong_capitals(countries: List[Dict], correct_capital: str, count: int) -> List[str]:
    """Genera capitales incorrectas"""
    wrong = []
    excluded = {correct_capital}

    while len(wrong) < count:
        country = random.choice(countries)
        capital = country.get('capital')

        if capital and len(capital) > 0:
            cap_name = capital[0]
            if cap_name not in excluded:
                wrong.append(cap_name)
                excluded.add(cap_name)

    return wrong

def generate_wrong_currencies(countries: List[Dict], correct_currency: str, count: int) -> List[str]:
    """Genera monedas incorrectas"""
    wrong = []
    excluded = {correct_currency}

    while len(wrong) < count:
        country = random.choice(countries)
        currencies = country.get('currencies')

        if currencies and len(currencies) > 0:
            curr_code = list(currencies.keys())[0]
            curr_data = currencies[curr_code]
            curr_name = curr_data.get('name')

            if curr_name and curr_name not in excluded:
                wrong.append(curr_name)
                excluded.add(curr_name)

    return wrong

def generate_wrong_languages(countries: List[Dict], correct_language: str, count: int) -> List[str]:
    """Genera idiomas incorrectos"""
    wrong = []
    excluded = {correct_language}

    while len(wrong) < count:
        country = random.choice(countries)
        languages = country.get('languages')

        if languages and len(languages) > 0:
            lang_code = list(languages.keys())[0]
            lang_name = languages[lang_code]

            if lang_name not in excluded:
                wrong.append(lang_name)
                excluded.add(lang_name)

    return wrong

def generate_wrong_regions(regions: List[str], correct_region: str, count: int) -> List[str]:
    """Genera regiones incorrectas"""
    wrong = []
    excluded = {correct_region}

    while len(wrong) < count:
        region = random.choice(regions)

        if region not in excluded:
            wrong.append(region)
            excluded.add(region)

    return wrong

def determine_difficulty(country: Dict, qtype: str) -> str:
    """Determina la dificultad de una pregunta"""
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
    elif qtype in ['language', 'currency']:
        if name in well_known:
            return 'easy'
        elif region in ['europe', 'americas']:
            return 'medium'
        else:
            return 'hard'
    else:
        if name in well_known:
            return 'easy'
        elif population > 50000000:
            return 'medium'
        else:
            return 'hard'

def combine_difficulty(diff1: str, diff2: str) -> str:
    """Combina dificultades"""
    levels = {'easy': 1, 'medium': 2, 'hard': 3}
    avg = (levels[diff1] + levels[diff2]) / 2

    if avg <= 1.5:
        return 'easy'
    elif avg <= 2.5:
        return 'medium'
    else:
        return 'hard'

# ========================================
# 🎨 GENERADORES POR TIPO
# ========================================

def generate_flag_questions(countries: List[Dict], count: int, start_id: int) -> List[Dict]:
    """Genera preguntas de banderas"""
    questions = []
    used_codes = set()

    flag_countries = [c for c in countries if c.get('flags') and c['flags'].get('png')]

    for i in range(min(count, len(flag_countries))):
        attempts = 0
        country = None

        while country is None and attempts < 100:
            candidate = random.choice(flag_countries)
            code = candidate['cca2']

            if code not in used_codes:
                country = candidate
                used_codes.add(code)
            attempts += 1

        if country is None:
            continue

        name = country['name']['common']
        code = country['cca2']
        flag_url = country['flags']['png']

        wrong = generate_wrong_options(countries, name, 3, used_codes)
        all_options = [name] + wrong
        random.shuffle(all_options)

        difficulty = determine_difficulty(country, 'flag')

        questions.append({
            'id': f'flag_{start_id + i}',
            'type': 'flag',
            'difficulty': difficulty,
            'questionText': '¿De qué país es esta bandera?',
            'correctAnswer': name,
            'options': all_options,
            'imageUrl': flag_url,
            'extraData': {
                'countryCode': code.lower(),
                'countryName': name,
            }
        })

    return questions

def generate_capital_questions(countries: List[Dict], count: int, start_id: int) -> List[Dict]:
    """Genera preguntas de capitales con plantillas variadas"""
    questions = []
    used_codes = set()

    capital_countries = [
        c for c in countries
        if c.get('capital') and len(c['capital']) > 0 and c['capital'][0]
    ]

    for i in range(min(count, len(capital_countries))):
        attempts = 0
        country = None

        while country is None and attempts < 100:
            candidate = random.choice(capital_countries)
            code = candidate['cca2']

            if code not in used_codes:
                country = candidate
                used_codes.add(code)
            attempts += 1

        if country is None:
            continue

        name = country['name']['common']
        capital = country['capital'][0]
        difficulty = determine_difficulty(country, 'capital')

        # 50% de probabilidad de formulación inversa
        if random.random() < 0.5:
            # Inversa: "{capital} es la capital de qué país?"
            question_text = generate_question_text(CAPITAL_TEMPLATES, {
                'capital': capital,
                'country': name
            })

            wrong = generate_wrong_options(countries, name, 3, used_codes)
            all_options = [name] + wrong
            random.shuffle(all_options)

            questions.append({
                'id': f'capital_{start_id + i}',
                'type': 'capital',
                'difficulty': difficulty,
                'questionText': question_text,
                'correctAnswer': name,
                'options': all_options,
                'extraData': {
                    'countryCode': country['cca2'].lower(),
                    'countryName': name,
                }
            })
        else:
            # Normal: "¿Cuál es la capital de {country}?"
            question_text = generate_question_text(CAPITAL_TEMPLATES, {
                'capital': capital,
                'country': name
            })

            wrong = generate_wrong_capitals(countries, capital, 3)
            all_options = [capital] + wrong
            random.shuffle(all_options)

            questions.append({
                'id': f'capital_{start_id + i}',
                'type': 'capital',
                'difficulty': difficulty,
                'questionText': question_text,
                'correctAnswer': capital,
                'options': all_options,
                'extraData': {
                    'countryCode': country['cca2'].lower(),
                    'countryName': name,
                }
            })

    return questions

def generate_currency_questions(countries: List[Dict], count: int, start_id: int) -> List[Dict]:
    """Genera preguntas de monedas con plantillas variadas"""
    questions = []
    used_codes = set()

    currency_countries = [
        c for c in countries
        if c.get('currencies') and len(c['currencies']) > 0
    ]

    for i in range(min(count, len(currency_countries))):
        attempts = 0
        country = None

        while country is None and attempts < 100:
            candidate = random.choice(currency_countries)
            code = candidate['cca2']

            if code not in used_codes:
                country = candidate
                used_codes.add(code)
            attempts += 1

        if country is None:
            continue

        name = country['name']['common']
        currencies = country['currencies']
        curr_code = list(currencies.keys())[0]
        curr_data = currencies[curr_code]
        curr_name = curr_data['name']

        difficulty = determine_difficulty(country, 'currency')

        question_text = generate_question_text(CURRENCY_TEMPLATES, {
            'country': name
        })

        wrong = generate_wrong_currencies(countries, curr_name, 3)
        all_options = [curr_name] + wrong
        random.shuffle(all_options)

        questions.append({
            'id': f'currency_{start_id + i}',
            'type': 'currency',
            'difficulty': difficulty,
            'questionText': question_text,
            'correctAnswer': curr_name,
            'options': all_options,
            'extraData': {
                'countryCode': country['cca2'].lower(),
                'countryName': name,
                'currencyCode': curr_code,
            }
        })

    return questions

def generate_language_questions(countries: List[Dict], count: int, start_id: int) -> List[Dict]:
    """Genera preguntas de idiomas con plantillas variadas"""
    questions = []
    used_codes = set()

    language_countries = [
        c for c in countries
        if c.get('languages') and len(c['languages']) > 0
    ]

    for i in range(min(count, len(language_countries))):
        attempts = 0
        country = None

        while country is None and attempts < 100:
            candidate = random.choice(language_countries)
            code = candidate['cca2']

            if code not in used_codes:
                country = candidate
                used_codes.add(code)
            attempts += 1

        if country is None:
            continue

        name = country['name']['common']
        languages = country['languages']
        lang_code = list(languages.keys())[0]
        lang_name = languages[lang_code]

        difficulty = determine_difficulty(country, 'language')

        question_text = generate_question_text(LANGUAGE_TEMPLATES, {
            'country': name
        })

        wrong = generate_wrong_languages(countries, lang_name, 3)
        all_options = [lang_name] + wrong
        random.shuffle(all_options)

        questions.append({
            'id': f'language_{start_id + i}',
            'type': 'language',
            'difficulty': difficulty,
            'questionText': question_text,
            'correctAnswer': lang_name,
            'options': all_options,
            'extraData': {
                'countryCode': country['cca2'].lower(),
                'countryName': name,
                'languageCode': lang_code,
            }
        })

    return questions

def generate_region_questions(countries: List[Dict], count: int, start_id: int) -> List[Dict]:
    """Genera preguntas de regiones con plantillas variadas"""
    questions = []
    used_codes = set()

    region_countries = [
        c for c in countries
        if c.get('region') and c['region']
    ]

    region_translations = {
        'Europe': 'Europa',
        'Americas': 'América',
        'Asia': 'Asia',
        'Africa': 'África',
        'Oceania': 'Oceanía',
        'Antarctic': 'Antártida',
    }

    regions_list = list(region_translations.values())

    for i in range(min(count, len(region_countries))):
        attempts = 0
        country = None

        while country is None and attempts < 100:
            candidate = random.choice(region_countries)
            code = candidate['cca2']

            if code not in used_codes:
                country = candidate
                used_codes.add(code)
            attempts += 1

        if country is None:
            continue

        name = country['name']['common']
        region = country['region']
        region_spanish = region_translations.get(region, region)

        difficulty = determine_difficulty(country, 'region')

        question_text = generate_question_text(REGION_TEMPLATES, {
            'country': name
        })

        wrong = generate_wrong_regions(regions_list, region_spanish, 3)
        all_options = [region_spanish] + wrong
        random.shuffle(all_options)

        questions.append({
            'id': f'region_{start_id + i}',
            'type': 'region',
            'difficulty': difficulty,
            'questionText': question_text,
            'correctAnswer': region_spanish,
            'options': all_options,
            'extraData': {
                'countryCode': country['cca2'].lower(),
                'countryName': name,
                'region': region,
                'regionSpanish': region_spanish,
            }
        })

    return questions

def generate_population_questions(countries: List[Dict], count: int, start_id: int) -> List[Dict]:
    """Genera preguntas de población con plantillas variadas"""
    questions = []
    used_pairs = set()

    sorted_countries = sorted(countries, key=lambda c: c.get('population', 0), reverse=True)

    for i in range(count):
        attempts = 0
        country1 = country2 = None

        while (country1 is None or country2 is None) and attempts < 100:
            idx1 = random.randint(0, len(sorted_countries) // 2)
            idx2 = random.randint(len(sorted_countries) // 2, len(sorted_countries) - 1)

            c1 = sorted_countries[idx1]
            c2 = sorted_countries[idx2]

            pair_key = f"{c1['cca2']}-{c2['cca2']}"
            reverse_key = f"{c2['cca2']}-{c1['cca2']}"

            if pair_key not in used_pairs and reverse_key not in used_pairs:
                country1 = c1
                country2 = c2
                used_pairs.add(pair_key)
            attempts += 1

        if country1 is None or country2 is None:
            continue

        name1 = country1['name']['common']
        name2 = country2['name']['common']
        pop1 = country1['population']
        pop2 = country2['population']

        correct = name1 if pop1 > pop2 else name2

        diff1 = determine_difficulty(country1, 'population')
        diff2 = determine_difficulty(country2, 'population')
        difficulty = combine_difficulty(diff1, diff2)

        # Ordenar aleatoriamente en la pregunta
        ordered = [name1, name2] if random.random() < 0.5 else [name2, name1]

        question_text = generate_question_text(POPULATION_TEMPLATES, {
            'country1': ordered[0],
            'country2': ordered[1]
        })

        questions.append({
            'id': f'population_{start_id + i}',
            'type': 'population',
            'difficulty': difficulty,
            'questionText': question_text,
            'correctAnswer': correct,
            'options': [name1, name2],
            'extraData': {
                'countries': [name1, name2],
                'population1': pop1,
                'population2': pop2,
            }
        })

    return questions

def generate_area_questions(countries: List[Dict], count: int, start_id: int) -> List[Dict]:
    """Genera preguntas de área con plantillas variadas"""
    questions = []
    used_pairs = set()

    sorted_countries = sorted(countries, key=lambda c: c.get('area', 0), reverse=True)

    for i in range(count):
        attempts = 0
        country1 = country2 = None

        while (country1 is None or country2 is None) and attempts < 100:
            idx1 = random.randint(0, len(sorted_countries) // 2)
            idx2 = random.randint(len(sorted_countries) // 2, len(sorted_countries) - 1)

            c1 = sorted_countries[idx1]
            c2 = sorted_countries[idx2]

            pair_key = f"{c1['cca2']}-{c2['cca2']}"
            reverse_key = f"{c2['cca2']}-{c1['cca2']}"

            if pair_key not in used_pairs and reverse_key not in used_pairs:
                country1 = c1
                country2 = c2
                used_pairs.add(pair_key)
            attempts += 1

        if country1 is None or country2 is None:
            continue

        name1 = country1['name']['common']
        name2 = country2['name']['common']
        area1 = country1['area']
        area2 = country2['area']

        correct = name1 if area1 > area2 else name2

        diff1 = determine_difficulty(country1, 'area')
        diff2 = determine_difficulty(country2, 'area')
        difficulty = combine_difficulty(diff1, diff2)

        ordered = [name1, name2] if random.random() < 0.5 else [name2, name1]

        question_text = generate_question_text(AREA_TEMPLATES, {
            'country1': ordered[0],
            'country2': ordered[1]
        })

        questions.append({
            'id': f'area_{start_id + i}',
            'type': 'area',
            'difficulty': difficulty,
            'questionText': question_text,
            'correctAnswer': correct,
            'options': [name1, name2],
            'extraData': {
                'countries': [name1, name2],
                'area1': area1,
                'area2': area2,
            }
        })

    return questions

# ========================================
# 🚀 FUNCIÓN PRINCIPAL
# ========================================

def main():
    parser = argparse.ArgumentParser(description='Generador de Preguntas con Variedad')
    parser.add_argument('--types', default='capital,currency,language',
                       help='Tipos de preguntas (separados por coma)')
    parser.add_argument('--count', type=int, default=25,
                       help='Cantidad de preguntas por tipo')
    parser.add_argument('--output', default='scripts/questions_varied.json',
                       help='Archivo de salida')

    args = parser.parse_args()

    types = args.types.split(',')
    count = args.count
    output = args.output

    print('🎨 Generador de Preguntas con Variedad\n')
    print(f'🎯 Configuración:')
    print(f'   • Tipos: {", ".join(types)}')
    print(f'   • Cantidad por tipo: {count}')
    print(f'   • Salida: {output}\n')

    try:
        countries = fetch_countries()

        questions = []
        question_id = 30000

        for qtype in types:
            print(f'🔧 Generando preguntas de tipo: {qtype}')

            try:
                if qtype == 'flag':
                    type_questions = generate_flag_questions(countries, count, question_id)
                elif qtype == 'capital':
                    type_questions = generate_capital_questions(countries, count, question_id)
                elif qtype == 'currency':
                    type_questions = generate_currency_questions(countries, count, question_id)
                elif qtype == 'language':
                    type_questions = generate_language_questions(countries, count, question_id)
                elif qtype == 'region':
                    type_questions = generate_region_questions(countries, count, question_id)
                elif qtype == 'population':
                    type_questions = generate_population_questions(countries, count, question_id)
                elif qtype == 'area':
                    type_questions = generate_area_questions(countries, count, question_id)
                elif qtype == 'all':
                    all_types = ['capital', 'currency', 'language', 'region', 'population', 'area']
                    type_questions = []
                    for t in all_types:
                        if t == 'capital':
                            tq = generate_capital_questions(countries, count // len(all_types), question_id)
                        elif t == 'currency':
                            tq = generate_currency_questions(countries, count // len(all_types), question_id)
                        elif t == 'language':
                            tq = generate_language_questions(countries, count // len(all_types), question_id)
                        elif t == 'region':
                            tq = generate_region_questions(countries, count // len(all_types), question_id)
                        elif t == 'population':
                            tq = generate_population_questions(countries, count // len(all_types), question_id)
                        elif t == 'area':
                            tq = generate_area_questions(countries, count // len(all_types), question_id)
                        type_questions.extend(tq)
                        question_id += len(tq)
                else:
                    raise Exception(f'Tipo no soportado: {qtype}')

                questions.extend(type_questions)
                question_id += len(type_questions)
                print(f'   ✅ {len(type_questions)} preguntas generadas')

            except Exception as e:
                print(f'   ❌ Error: {e}')

        # Mezclar preguntas
        random.shuffle(questions)

        # Guardar archivo
        with open(output, 'w', encoding='utf-8') as f:
            json.dump(questions, f, indent=2, ensure_ascii=False)

        print(f'\n🎉 ¡Generación completada!')
        print_statistics(questions)
        print(f'\n💾 Guardado en: {output}')

    except Exception as e:
        print(f'❌ Error: {e}')
        sys.exit(1)

def print_statistics(questions: List[Dict]):
    """Imprime estadísticas de las preguntas generadas"""
    by_type = Counter()
    by_difficulty = Counter()

    for q in questions:
        by_type[q['type']] += 1
        by_difficulty[q['difficulty']] += 1

    print('📊 Estadísticas:')
    print(f'   • Total: {len(questions)} preguntas')

    print('\n📊 Por tipo:')
    for qtype, count in sorted(by_type.items()):
        print(f'   • {qtype}: {count}')

    print('\n📊 Por dificultad:')
    for diff, count in sorted(by_difficulty.items()):
        print(f'   • {diff}: {count}')

if __name__ == '__main__':
    main()
