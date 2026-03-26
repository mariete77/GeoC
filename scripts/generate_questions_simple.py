#!/usr/bin/env python3
"""
🚀 GeoQuiz Battle - Generador de Preguntas (Python Simplificado)
"""

import json
import random
from typing import List, Dict, Set

# Dataset de países local (30 países principales)
COUNTRIES = [
    {"name": {"common": "España"}, "cca2": "ES", "capital": ["Madrid"], "population": 47450795, "area": 505990.0, "region": "Europe", "flags": {"png": "https://flagcdn.com/w320/es.png"}, "languages": {"spa": "Español"}, "currencies": {"EUR": {"name": "Euro", "symbol": "€"}}, "borders": ["PRT", "FRA"]},
    {"name": {"common": "Francia"}, "cca2": "FR", "capital": ["París"], "population": 65273511, "area": 551695.0, "region": "Europe", "flags": {"png": "https://flagcdn.com/w320/fr.png"}, "languages": {"fra": "Francés"}, "currencies": {"EUR": {"name": "Euro", "symbol": "€"}}, "borders": ["DEU", "ESP"]},
    {"name": {"common": "Alemania"}, "cca2": "DE", "capital": ["Berlín"], "population": 83240525, "area": 357114.0, "region": "Europe", "flags": {"png": "https://flagcdn.com/w320/de.png"}, "languages": {"deu": "Alemán"}, "currencies": {"EUR": {"name": "Euro", "symbol": "€"}}, "borders": ["FRA", "AUT"]},
    {"name": {"common": "Italia"}, "cca2": "IT", "capital": ["Roma"], "population": 59554023, "area": 301336.0, "region": "Europe", "flags": {"png": "https://flagcdn.com/w320/it.png"}, "languages": {"ita": "Italiano"}, "currencies": {"EUR": {"name": "Euro", "symbol": "€"}}, "borders": ["FRA", "AUT"]},
    {"name": {"common": "Portugal"}, "cca2": "PT", "capital": ["Lisboa"], "population": 10331926, "area": 92212.0, "region": "Europe", "flags": {"png": "https://flagcdn.com/w320/pt.png"}, "languages": {"por": "Portugués"}, "currencies": {"EUR": {"name": "Euro", "symbol": "€"}}, "borders": ["ESP"]},
    {"name": {"common": "Reino Unido"}, "cca2": "GB", "capital": ["Londres"], "population": 67326569, "area": 242495.0, "region": "Europe", "flags": {"png": "https://flagcdn.com/w320/gb.png"}, "languages": {"eng": "Inglés"}, "currencies": {"GBP": {"name": "Libra", "symbol": "£"}}, "borders": ["IRL"]},
    {"name": {"common": "Estados Unidos"}, "cca2": "US", "capital": ["Washington, D.C."], "population": 331893745, "area": 9372610.0, "region": "Americas", "flags": {"png": "https://flagcdn.com/w320/us.png"}, "languages": {"eng": "Inglés"}, "currencies": {"USD": {"name": "Dólar", "symbol": "$"}}, "borders": ["CAN", "MEX"]},
    {"name": {"common": "Canadá"}, "cca2": "CA", "capital": ["Ottawa"], "population": 38005238, "area": 9984670.0, "region": "Americas", "flags": {"png": "https://flagcdn.com/w320/ca.png"}, "languages": {"eng": "Inglés"}, "currencies": {"CAD": {"name": "Dólar", "symbol": "$"}}, "borders": ["USA"]},
    {"name": {"common": "México"}, "cca2": "MX", "capital": ["Ciudad de México"], "population": 128932753, "area": 1964375.0, "region": "Americas", "flags": {"png": "https://flagcdn.com/w320/mx.png"}, "languages": {"spa": "Español"}, "currencies": {"MXN": {"name": "Peso", "symbol": "$"}}, "borders": ["USA", "GTM"]},
    {"name": {"common": "Brasil"}, "cca2": "BR", "capital": ["Brasilia"], "population": 214326223, "area": 8515767.0, "region": "Americas", "flags": {"png": "https://flagcdn.com/w320/br.png"}, "languages": {"por": "Portugués"}, "currencies": {"BRL": {"name": "Real", "symbol": "R$"}}, "borders": ["ARG", "URY"]},
    {"name": {"common": "Argentina"}, "cca2": "AR", "capital": ["Buenos Aires"], "population": 45805823, "area": 2780400.0, "region": "Americas", "flags": {"png": "https://flagcdn.com/w320/ar.png"}, "languages": {"spa": "Español"}, "currencies": {"ARS": {"name": "Peso", "symbol": "$"}}, "borders": ["BRA", "CHL"]},
    {"name": {"common": "China"}, "cca2": "CN", "capital": ["Pekín"], "population": 1411778724, "area": 9706961.0, "region": "Asia", "flags": {"png": "https://flagcdn.com/w320/cn.png"}, "languages": {"zho": "Chino"}, "currencies": {"CNY": {"name": "Yuan", "symbol": "¥"}}, "borders": ["RUS", "IND"]},
    {"name": {"common": "Japón"}, "cca2": "JP", "capital": ["Tokio"], "population": 125681593, "area": 377930.0, "region": "Asia", "flags": {"png": "https://flagcdn.com/w320/jp.png"}, "languages": {"jpn": "Japonés"}, "currencies": {"JPY": {"name": "Yen", "symbol": "¥"}}, "borders": []},
    {"name": {"common": "India"}, "cca2": "IN", "capital": ["Nueva Delhi"], "population": 1406631776, "area": 3287263.0, "region": "Asia", "flags": {"png": "https://flagcdn.com/w320/in.png"}, "languages": {"hin": "Hindi"}, "currencies": {"INR": {"name": "Rupia", "symbol": "₹"}}, "borders": ["CHN", "PAK"]},
    {"name": {"common": "Australia"}, "cca2": "AU", "capital": ["Canberra"], "population": 25687041, "area": 7692024.0, "region": "Oceania", "flags": {"png": "https://flagcdn.com/w320/au.png"}, "languages": {"eng": "Inglés"}, "currencies": {"AUD": {"name": "Dólar", "symbol": "$"}}, "borders": []},
    {"name": {"common": "Rusia"}, "cca2": "RU", "capital": ["Moscú"], "population": 145912025, "area": 17098242.0, "region": "Europe", "flags": {"png": "https://flagcdn.com/w320/ru.png"}, "languages": {"rus": "Ruso"}, "currencies": {"RUB": {"name": "Rublo", "symbol": "₽"}}, "borders": ["CHN", "FIN"]},
    {"name": {"common": "Corea del Sur"}, "cca2": "KR", "capital": ["Seúl"], "population": 51844886, "area": 100210.0, "region": "Asia", "flags": {"png": "https://flagcdn.com/w320/kr.png"}, "languages": {"kor": "Coreano"}, "currencies": {"KRW": {"name": "Won", "symbol": "₩"}}, "borders": ["PRK"]},
    {"name": {"common": "Nigeria"}, "cca2": "NG", "capital": ["Abuya"], "population": 213401323, "area": 923768.0, "region": "Africa", "flags": {"png": "https://flagcdn.com/w320/ng.png"}, "languages": {"eng": "Inglés"}, "currencies": {"NGN": {"name": "Naira", "symbol": "₦"}}, "borders": ["BEN", "CMR"]},
    {"name": {"common": "Egipto"}, "cca2": "EG", "capital": ["El Cairo"], "population": 109262178, "area": 1010408.0, "region": "Africa", "flags": {"png": "https://flagcdn.com/w320/eg.png"}, "languages": {"ara": "Árabe"}, "currencies": {"EGP": {"name": "Libra", "symbol": "£"}}, "borders": ["LBY", "SDN"]},
    {"name": {"common": "Sudáfrica"}, "cca2": "ZA", "capital": ["Pretoria"], "population": 59308690, "area": 1221037.0, "region": "Africa", "flags": {"png": "https://flagcdn.com/w320/za.png"}, "languages": {"afr": "Afrikaans"}, "currencies": {"ZAR": {"name": "Rand", "symbol": "R"}}, "borders": ["LSO", "MOZ"]},
    {"name": {"common": "Turquía"}, "cca2": "TR", "capital": ["Ankara"], "population": 85042738, "area": 783562.0, "region": "Asia", "flags": {"png": "https://flagcdn.com/w320/tr.png"}, "languages": {"tur": "Turco"}, "currencies": {"TRY": {"name": "Lira", "symbol": "₺"}}, "borders": ["ARM", "AZE"]},
    {"name": {"common": "Polonia"}, "cca2": "PL", "capital": ["Varsovia"], "population": 37797006, "area": 312696.0, "region": "Europe", "flags": {"png": "https://flagcdn.com/w320/pl.png"}, "languages": {"pol": "Polaco"}, "currencies": {"PLN": {"name": "Złoty", "symbol": "zł"}}, "borders": ["DEU", "CZE"]},
    {"name": {"common": "Países Bajos"}, "cca2": "NL", "capital": ["Ámsterdam"], "population": 17534942, "area": 41543.0, "region": "Europe", "flags": {"png": "https://flagcdn.com/w320/nl.png"}, "languages": {"nld": "Neerlandés"}, "currencies": {"EUR": {"name": "Euro", "symbol": "€"}}, "borders": ["BEL", "DEU"]},
    {"name": {"common": "Bélgica"}, "cca2": "BE", "capital": ["Bruselas"], "population": 11589623, "area": 30528.0, "region": "Europe", "flags": {"png": "https://flagcdn.com/w320/be.png"}, "languages": {"nld": "Neerlandés"}, "currencies": {"EUR": {"name": "Euro", "symbol": "€"}}, "borders": ["FRA", "DEU"]},
    {"name": {"common": "Suiza"}, "cca2": "CH", "capital": ["Berna"], "population": 8654622, "area": 41284.0, "region": "Europe", "flags": {"png": "https://flagcdn.com/w320/ch.png"}, "languages": {"deu": "Alemán"}, "currencies": {"CHF": {"name": "Franco", "symbol": "Fr"}}, "borders": ["FRA", "DEU"]},
    {"name": {"common": "Austria"}, "cca2": "AT", "capital": ["Viena"], "population": 8932664, "area": 83879.0, "region": "Europe", "flags": {"png": "https://flagcdn.com/w320/at.png"}, "languages": {"deu": "Alemán"}, "currencies": {"EUR": {"name": "Euro", "symbol": "€"}}, "borders": ["DEU", "CHE"]},
    {"name": {"common": "Suecia"}, "cca2": "SE", "capital": ["Estocolmo"], "population": 10416196, "area": 450295.0, "region": "Europe", "flags": {"png": "https://flagcdn.com/w320/se.png"}, "languages": {"swe": "Sueco"}, "currencies": {"SEK": {"name": "Corona", "symbol": "kr"}}, "borders": ["NOR", "FIN"]},
    {"name": {"common": "Noruega"}, "cca2": "NO", "capital": ["Oslo"], "population": 5391369, "area": 323802.0, "region": "Europe", "flags": {"png": "https://flagcdn.com/w320/no.png"}, "languages": {"nor": "Noruego"}, "currencies": {"NOK": {"name": "Corona", "symbol": "kr"}}, "borders": ["SWE"]},
    {"name": {"common": "Grecia"}, "cca2": "GR", "capital": ["Atenas"], "population": 10724599, "area": 131957.0, "region": "Europe", "flags": {"png": "https://flagcdn.com/w320/gr.png"}, "languages": {"ell": "Griego"}, "currencies": {"EUR": {"name": "Euro", "symbol": "€"}}, "borders": ["ALB", "MKD"]},
    {"name": {"common": "Irlanda"}, "cca2": "IE", "capital": ["Dublín"], "population": 5041425, "area": 70273.0, "region": "Europe", "flags": {"png": "https://flagcdn.com/w320/ie.png"}, "languages": {"eng": "Inglés"}, "currencies": {"EUR": {"name": "Euro", "symbol": "€"}}, "borders": ["GBR"]},
]

def generate_wrong_options(countries: List[Dict], correct: str, count: int, exclude: Set[str] = None) -> List[str]:
    """Generar opciones incorrectas"""
    exclude = exclude or set()
    exclude.add(correct)
    
    wrong = []
    max_attempts = count * 10
    attempts = 0
    
    while len(wrong) < count and attempts < max_attempts:
        country = random.choice(countries)
        name = country['name']['common']
        if name not in exclude:
            wrong.append(name)
            exclude.add(name)
        attempts += 1
    
    return wrong

def generate_flag_questions(countries: List[Dict], count: int, start_id: int) -> List[Dict]:
    """Generar preguntas de banderas"""
    print("🏳️ Generando preguntas de banderas...")
    
    questions = []
    used_codes = set()
    
    for i in range(min(count, len(countries))):
        attempts = 0
        while attempts < 100:
            country = random.choice(countries)
            if country['cca2'] not in used_codes:
                name = country['name']['common']
                code = country['cca2']
                flag_url = country['flags']['png']
                
                wrong = generate_wrong_options(countries, name, 3, used_codes)
                options = [name] + wrong
                random.shuffle(options)
                
                questions.append({
                    'id': f'flag_{start_id + i}',
                    'type': 'flag',
                    'difficulty': 'medium',
                    'questionText': '¿De qué país es esta bandera?',
                    'correctAnswer': name,
                    'options': options,
                    'imageUrl': flag_url,
                    'extraData': {'countryCode': code.lower(), 'countryName': name}
                })
                used_codes.add(code)
                break
            attempts += 1
    
    print(f"   ✅ {len(questions)} preguntas generadas")
    return questions

def generate_capital_questions(countries: List[Dict], count: int, start_id: int) -> List[Dict]:
    """Generar preguntas de capitales"""
    print("🏛️ Generando preguntas de capitales...")
    
    questions = []
    used_codes = set()
    
    for i in range(min(count, len(countries))):
        attempts = 0
        while attempts < 100:
            country = random.choice(countries)
            if country['cca2'] not in used_codes and country.get('capital') and country['capital']:
                name = country['name']['common']
                capital = country['capital'][0]
                
                wrong = []
                excluded = {capital}
                attempts_opt = 0
                while len(wrong) < 3 and attempts_opt < 100:
                    c = random.choice(countries)
                    if c.get('capital') and c['capital']:
                        cap = c['capital'][0]
                        if cap not in excluded:
                            wrong.append(cap)
                            excluded.add(cap)
                    attempts_opt += 1
                
                options = [capital] + wrong
                random.shuffle(options)
                
                questions.append({
                    'id': f'capital_{start_id + i}',
                    'type': 'capital',
                    'difficulty': 'medium',
                    'questionText': f'¿Cuál es la capital de {name}?',
                    'correctAnswer': capital,
                    'options': options,
                    'extraData': {'countryCode': country['cca2'].lower(), 'countryName': name}
                })
                used_codes.add(country['cca2'])
                break
            attempts += 1
    
    print(f"   ✅ {len(questions)} preguntas generadas")
    return questions

def generate_population_questions(countries: List[Dict], count: int, start_id: int) -> List[Dict]:
    """Generar preguntas de población"""
    print("👥 Generando preguntas de población...")
    
    sorted_countries = sorted(countries, key=lambda x: x.get('population', 0), reverse=True)
    questions = []
    used_pairs = set()
    
    for i in range(count):
        attempts = 0
        c1, c2 = None, None
        
        while (c1 is None or c2 is None) and attempts < 100:
            idx1 = random.randint(0, max(1, len(sorted_countries) // 2) - 1)
            idx2 = random.randint(len(sorted_countries) // 2, len(sorted_countries) - 1)
            
            cand1, cand2 = sorted_countries[idx1], sorted_countries[idx2]
            
            pair_key = f"{cand1['cca2']}-{cand2['cca2']}"
            
            if pair_key not in used_pairs:
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
            'extraData': {'countries': [name1, name2], 'population1': pop1, 'population2': pop2}
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
    
    # Configuración
    questions_per_type = 10
    start_id = 30000
    questions = []
    
    # Generar por tipo
    questions.extend(generate_flag_questions(COUNTRIES, questions_per_type, start_id))
    start_id += len(questions)
    
    questions.extend(generate_capital_questions(COUNTRIES, questions_per_type, start_id))
    start_id += len(questions)
    
    questions.extend(generate_population_questions(COUNTRIES, questions_per_type, start_id))
    
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
