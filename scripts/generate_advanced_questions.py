#!/usr/bin/env python3
"""
🌍 Generador de Preguntas de Geografía Avanzada (Datos Predefinidos)

Usa datos predefinidos de ríos, montañas y lagos para generar preguntas.
Evita problemas con Wikipedia API y garantiza calidad.

Uso:
  python3 scripts/generate_advanced_questions.py [opciones]
"""

import json
import random
import argparse
from typing import List, Dict

# ========================================
# 📊 DATOS PREDEFINIDOS
# ========================================

RIVERS = {
    'España': ['Ebro', 'Tajo', 'Duero', 'Guadiana', 'Júcar', 'Guadalquivir'],
    'Francia': ['Loira', 'Ródano', 'Sena', 'Garona'],
    'Alemania': ['Rin', 'Danubio', 'Elba', 'Mosa'],
    'Italia': ['Po', 'Tíber', 'Arno', 'Adigio'],
    'Reino Unido': ['Támesis', 'Severn', 'Trent', 'Mersey'],
    'Portugal': ['Tajo', 'Douro', 'Guadiana'],
    'Estados Unidos': ['Misisipi', 'Colorado', 'Río Grande', 'Ohio', 'Columbia'],
    'Canadá': ['Mackenzie', 'San Lorenzo', 'Nelson', 'Churchill'],
    'México': ['Río Bravo', 'Lerma', 'Pánuco', 'Balsas'],
    'Brasil': ['Amazonas', 'Paraná', 'São Francisco', 'Tocantins'],
    'Argentina': ['Paraná', 'Uruguay', 'Río Negro', 'Colorado'],
    'Chile': ['Baker', 'Biobío', 'Maule'],
    'Perú': ['Amazonas', 'Marañón', 'Ucayali'],
    'Colombia': ['Magdalena', 'Cauca', 'Atrato'],
    'China': ['Yangtsé', 'Amarillo', 'Perla', 'Amur'],
    'India': ['Ganges', 'Brahmaputra', 'Indo', 'Godavari'],
    'Japón': ['Shinano', 'Tone', 'Ishikari'],
    'Rusia': ['Volga', 'Lena', 'Ob', 'Yenisei', 'Amur'],
    'Egipto': ['Nilo'],
    'Australia': ['Murray', 'Darling', 'Murrumbidgee'],
    'Sudáfrica': ['Orange', 'Limpopo', 'Vaal'],
}

MOUNTAINS = {
    'España': ['Teide', 'Mulhacén', 'Aneto', 'Veleta'],
    'Francia': ['Mont Blanc', 'Monte Viso', 'Pic du Midi de Bigorre'],
    'Alemania': ['Zugspitze', 'Watzmann', 'Schneekoppe'],
    'Italia': ['Monte Bianco', 'Cervino', 'Grossglockner', 'Ortles'],
    'Reino Unido': ['Ben Nevis', 'Snowdon', 'Scafell Pike'],
    'Suiza': ['Matterhorn', 'Dufourspitze', 'Dom'],
    'Austria': ['Grossglockner', 'Wildspitze', 'Weißkugel'],
    'Estados Unidos': ['Denali', 'Monte Rainier', 'Pico Whitney'],
    'Canadá': ['Monte Logan', 'Monte Saint Elias', 'Monte Lucania'],
    'México': ['Pico de Orizaba', 'Popocatépetl', 'Iztaccíhuatl'],
    'Brasil': ['Pico da Neblina', 'Pico 31 de Março'],
    'Argentina': ['Aconcagua', 'Ojos del Salado', 'Bonete'],
    'Chile': ['Ojos del Salado', 'Nevado Tres Cruces', 'Llullaillaco'],
    'Perú': ['Huascarán', 'Coropuna', 'Sajama'],
    'Colombia': ['Cristóbal Colón', 'Simón Bolívar', 'Ritacuba Blanco'],
    'China': ['Everest', 'K2', 'Kangchenjunga'],
    'India': ['Kangchenjunga', 'Nanda Devi', 'Kamet'],
    'Nepal': ['Everest', 'Kangchenjunga', 'Lhotse', 'Makalu'],
    'Japón': ['Monte Fuji', 'Monte Kita', 'Monte Hotaka'],
    'Rusia': ['Elbrus', 'Dykhtau', 'Koshtan-Tau'],
    'Egipto': ['Monte Santa Catalina', 'Gebel Shayeb'],
    'Kenia': ['Monte Kenia', 'Monte Elgon'],
    'Tanzania': ['Kilimanjaro', 'Monte Meru'],
    'Sudáfrica': ['Mafadi', 'Njesuthi', 'Monte Thaba Putsoa'],
    'Australia': ['Monte Kosciuszko', 'Pico Townsend', 'Twins Spire'],
}

LAKES = {
    'España': ['Lago de Sanabria', 'Embalse de Almansa', 'Embalse de Cíjara'],
    'Francia': ['Lago Lemán', 'Lago de Ginebra', 'Lago de Annecy'],
    'Alemania': ['Lago Constanza', 'Lago Müritz', 'Lago Chiemsee'],
    'Italia': ['Lago de Garda', 'Lago Mayor', 'Lago Como', 'Lago de Como'],
    'Reino Unido': ['Lago Ness', 'Lago Windermere', 'Lago Ullswater'],
    'Estados Unidos': ['Lago Superior', 'Lago Michigan', 'Lago Huron', 'Lago Erie', 'Lago Ontario'],
    'Canadá': ['Lago Superior', 'Lago Huron', 'Gran Lago del Oso', 'Gran Lago del Esclavo'],
    'México': ['Lago de Chapala', 'Lago de Pátzcuaro', 'Lago de Cuitzeo'],
    'Brasil': ['Lago de Itaipu', 'Lago de Sobradinho', 'Represa de Tucuruí'],
    'Argentina': ['Lago Argentino', 'Lago Viedma', 'Lago Buenos Aires'],
    'Chile': ['Lago Llanquihue', 'Lago General Carrera', 'Lago Todos los Santos'],
    'Perú': ['Lago Titicaca', 'Lago Junín', 'Lago Parón'],
    'China': ['Lago Qinghai', 'Lago Poyang', 'Lago Dongting'],
    'India': ['Lago Wular', 'Lago Chilka', 'Lago Kolleru'],
    'Rusia': ['Lago Baikal', 'Lago Onega', 'Lago Ladoga'],
    'Australia': ['Lago Eyre', 'Lago Torrens', 'Lago Gairdner'],
    'Egipto': ['Lago Nasser', 'Lago Toshka'],
}

CITIES = {
    'España': ['Barcelona', 'Valencia', 'Sevilla', 'Málaga', 'Bilbao', 'Zaragoza'],
    'Francia': ['Marseille', 'Lyon', 'Toulouse', 'Niza', 'Nantes'],
    'Alemania': ['Berlín', 'Hamburgo', 'Munich', 'Colonia', 'Frankfurt'],
    'Italia': ['Milán', 'Nápoles', 'Turín', 'Palermo', 'Génova'],
    'Reino Unido': ['Londres', 'Birmingham', 'Manchester', 'Glasgow', 'Liverpool'],
    'Estados Unidos': ['Nueva York', 'Los Ángeles', 'Chicago', 'Houston', 'Phoenix'],
    'Canadá': ['Toronto', 'Montreal', 'Vancouver', 'Calgary', 'Ottawa'],
    'México': ['Guadalajara', 'Monterrey', 'Puebla', 'Ciudad Juárez', 'León'],
    'Brasil': ['São Paulo', 'Río de Janeiro', 'Brasilia', 'Salvador', 'Fortaleza'],
    'Argentina': ['Córdoba', 'Rosario', 'Mendoza', 'San Miguel de Tucumán', 'La Plata'],
    'Chile': ['Valparaíso', 'Concepción', 'La Serena', 'Antofagasta'],
    'Perú': ['Arequipa', 'Trujillo', 'Chiclayo', 'Piura', 'Iquitos'],
    'Colombia': ['Medellín', 'Cali', 'Barranquilla', 'Cartagena', 'Cúcuta'],
    'China': ['Shanghái', 'Pekín', 'Guangzhou', 'Shenzhen', 'Wuhan'],
    'India': ['Bombay', 'Delhi', 'Bangalore', 'Hyderabad', 'Chennai'],
    'Japón': ['Tokio', 'Osaka', 'Kioto', 'Yokohama', 'Nagoya'],
    'Rusia': ['Moscú', 'San Petersburgo', 'Novosibirsk', 'Yekaterinburg', 'Nizhni Nóvgorod'],
    'Egipto': ['El Cairo', 'Alejandría', 'Giza', 'Shubra El-Kheima', 'Port Said'],
    'Kenia': ['Mombasa', 'Kisumu', 'Nakuru', 'Eldoret'],
    'Sudáfrica': ['Johannesburgo', 'Ciudad del Cabo', 'Durban', 'Pretoria', 'Port Elizabeth'],
    'Australia': ['Sídney', 'Melbourne', 'Brisbane', 'Perth', 'Adelaida'],
}

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
    "¿{city} es una ciudad de qué país?",
]

# ========================================
# 🎨 GENERADOR DE PREGUNTAS
# ========================================

def generate_river_questions(countries: List[str], count_per_country: int = 1, start_id: int = 60000) -> List[Dict]:
    """Genera preguntas sobre ríos"""
    questions = []
    question_id = start_id
    
    for country in countries:
        if country not in RIVERS:
            continue
        
        rivers = RIVERS[country]
        num_questions = min(count_per_country, len(rivers))
        
        for i in range(num_questions):
            river = rivers[i]
            template = random.choice(RIVER_TEMPLATES)
            question_text = template.format(country=country)
            
            # Opciones: río correcto + 3 incorrectos de otros países
            all_rivers = []
            for c, r in RIVERS.items():
                all_rivers.extend(r)
            
            wrong_rivers = [r for r in all_rivers if r != river]
            options = [river] + random.sample(wrong_rivers, 3)
            random.shuffle(options)
            
            questions.append({
                'id': f'river_{question_id}',
                'type': 'river',
                'difficulty': 'medium',
                'questionText': question_text,
                'correctAnswer': river,
                'options': options,
                'extraData': {
                    'country': country,
                    'riverName': river
                }
            })
            question_id += 1
    
    return questions

def generate_mountain_questions(countries: List[str], count_per_country: int = 1, start_id: int = 61000) -> List[Dict]:
    """Genera preguntas sobre montañas"""
    questions = []
    question_id = start_id
    
    for country in countries:
        if country not in MOUNTAINS:
            continue
        
        mountains = MOUNTAINS[country]
        num_questions = min(count_per_country, len(mountains))
        
        for i in range(num_questions):
            mountain = mountains[i]
            template = random.choice(MOUNTAIN_TEMPLATES)
            question_text = template.format(country=country)
            
            all_mountains = []
            for c, m in MOUNTAINS.items():
                all_mountains.extend(m)
            
            wrong_mountains = [m for m in all_mountains if m != mountain]
            options = [mountain] + random.sample(wrong_mountains, 3)
            random.shuffle(options)
            
            questions.append({
                'id': f'mountain_{question_id}',
                'type': 'mountain',
                'difficulty': 'medium',
                'questionText': question_text,
                'correctAnswer': mountain,
                'options': options,
                'extraData': {
                    'country': country,
                    'mountainName': mountain
                }
            })
            question_id += 1
    
    return questions

def generate_lake_questions(countries: List[str], count_per_country: int = 1, start_id: int = 62000) -> List[Dict]:
    """Genera preguntas sobre lagos"""
    questions = []
    question_id = start_id
    
    for country in countries:
        if country not in LAKES:
            continue
        
        lakes = LAKES[country]
        num_questions = min(count_per_country, len(lakes))
        
        for i in range(num_questions):
            lake = lakes[i]
            template = random.choice(LAKE_TEMPLATES)
            question_text = template.format(country=country)
            
            all_lakes = []
            for c, l in LAKES.items():
                all_lakes.extend(l)
            
            wrong_lakes = [l for l in all_lakes if l != lake]
            options = [lake] + random.sample(wrong_lakes, 3)
            random.shuffle(options)
            
            questions.append({
                'id': f'lake_{question_id}',
                'type': 'lake',
                'difficulty': 'medium',
                'questionText': question_text,
                'correctAnswer': lake,
                'options': options,
                'extraData': {
                    'country': country,
                    'lakeName': lake
                }
            })
            question_id += 1
    
    return questions

def generate_city_questions(countries: List[str], count_per_country: int = 1, start_id: int = 63000) -> List[Dict]:
    """Genera preguntas sobre ciudades"""
    questions = []
    question_id = start_id
    
    for country in countries:
        if country not in CITIES:
            continue
        
        cities = CITIES[country]
        num_questions = min(count_per_country, len(cities))
        
        for i in range(num_questions):
            city = cities[i]
            
            # 50% probabilidad de pregunta inversa
            if random.random() < 0.5:
                # Inversa: "{city} está en qué país?"
                template = random.choice(CITY_TEMPLATES[2:])
                question_text = template.format(city=city)
                
                # Opciones: país correcto + 3 incorrectos
                wrong_countries = [c for c in countries if c != country]
                options = [country] + random.sample(wrong_countries, 3)
                random.shuffle(options)
                
                questions.append({
                    'id': f'city_{question_id}',
                    'type': 'city',
                    'difficulty': 'easy',
                    'questionText': question_text,
                    'correctAnswer': country,
                    'options': options,
                    'extraData': {
                        'cityName': city,
                        'country': country
                    }
                })
            else:
                # Normal: "¿Qué ciudad está ubicada en {country}?"
                template = random.choice(CITY_TEMPLATES[:2])
                question_text = template.format(country=country)
                
                # Opciones: ciudad correcta + 3 incorrectas de otros países
                all_cities = []
                for c, cits in CITIES.items():
                    all_cities.extend(cits)
                
                wrong_cities = [c for c in all_cities if c != city]
                options = [city] + random.sample(wrong_cities, 3)
                random.shuffle(options)
                
                questions.append({
                    'id': f'city_{question_id}',
                    'type': 'city',
                    'difficulty': 'easy',
                    'questionText': question_text,
                    'correctAnswer': city,
                    'options': options,
                    'extraData': {
                        'cityName': city,
                        'country': country
                    }
                })
            question_id += 1
    
    return questions

# ========================================
# 🚀 FUNCIÓN PRINCIPAL
# ========================================

def main():
    parser = argparse.ArgumentParser(description='Generador de Preguntas Avanzadas')
    parser.add_argument('--types', default='river,mountain,lake,city',
                       help='Tipos de preguntas (river, mountain, lake, city)')
    parser.add_argument('--countries', default='20',
                       help='Cantidad de países a usar')
    parser.add_argument('--count', type=int, default=1,
                       help='Preguntas por país y tipo')
    parser.add_argument('--output', default='scripts/questions_advanced.json',
                       help='Archivo de salida')

    args = parser.parse_args()

    types = args.types.split(',')
    num_countries = int(args.countries)
    count = args.count
    output = args.output

    print('🌍 Generador de Preguntas Avanzadas\n')
    print(f'🎯 Configuración:')
    print(f'   • Tipos: {", ".join(types)}')
    print(f'   • Países: {num_countries}')
    print(f'   • Preguntas por tipo y país: {count}')
    print(f'   • Salida: {output}\n')

    # Países disponibles
    available_countries = sorted(set(list(RIVERS.keys()) + list(MOUNTAINS.keys()) + list(LAKES.keys()) + list(CITIES.keys())))
    selected_countries = available_countries[:num_countries]

    all_questions = []

    if 'river' in types:
        print(f'🌊 Generando preguntas de ríos...')
        questions = generate_river_questions(selected_countries, count)
        all_questions.extend(questions)
        print(f'   ✅ {len(questions)} preguntas')

    if 'mountain' in types:
        print(f'🏔️ Generando preguntas de montañas...')
        questions = generate_mountain_questions(selected_countries, count)
        all_questions.extend(questions)
        print(f'   ✅ {len(questions)} preguntas')

    if 'lake' in types:
        print(f'💧 Generando preguntas de lagos...')
        questions = generate_lake_questions(selected_countries, count)
        all_questions.extend(questions)
        print(f'   ✅ {len(questions)} preguntas')

    if 'city' in types:
        print(f'🏙️ Generando preguntas de ciudades...')
        questions = generate_city_questions(selected_countries, count)
        all_questions.extend(questions)
        print(f'   ✅ {len(questions)} preguntas')

    # Mezclar y guardar
    random.shuffle(all_questions)

    with open(output, 'w', encoding='utf-8') as f:
        json.dump(all_questions, f, indent=2, ensure_ascii=False)

    print(f'\n🎉 ¡Generación completada!')
    print(f'📊 Total: {len(all_questions)} preguntas')
    print(f'💾 Guardado en: {output}')

    # Estadísticas
    by_type = {}
    for q in all_questions:
        qtype = q['type']
        by_type[qtype] = by_type.get(qtype, 0) + 1
    
    print(f'\n📊 Por tipo:')
    for qtype, count in sorted(by_type.items()):
        print(f'   • {qtype}: {count}')

if __name__ == '__main__':
    main()
