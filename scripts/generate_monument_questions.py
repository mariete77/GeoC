#!/usr/bin/env python3
"""
🏛️ Generador de Preguntas de Monumentos y Edificios

Genera preguntas sobre monumentos, edificios famosos, rascacielos, etc.

Uso:
  python3 scripts/generate_monument_questions.py [opciones]
"""

import json
import random
import argparse
from typing import List, Dict

# ========================================
# 🏛️ DATOS DE MONUMENTOS Y EDIFICIOS
# ========================================

MONUMENTS = [
    # EUROPA
    {'name': 'Torre Eiffel', 'city': 'París', 'country': 'Francia', 'type': 'torre', 'image': 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/85/Tour_Eiffel_Wikimedia_Commons_%28cropped%29.jpg/320px-Tour_Eiffel_Wikimedia_Commons_%28cropped%29.jpg'},
    {'name': 'Torre de Pisa', 'city': 'Pisa', 'country': 'Italia', 'type': 'torre', 'image': 'https://upload.wikimedia.org/wikipedia/commons/thumb/b/b9/Tower_of_Pisa_%28cropped%29.jpg/320px-Tower_of_Pisa_%28cropped%29.jpg'},
    {'name': 'Torre de Londres', 'city': 'Londres', 'country': 'Reino Unido', 'type': 'torre', 'image': 'https://upload.wikimedia.org/wikipedia/commons/thumb/3/32/Tower_of_London_from_the_Shard.jpg/320px-Tower_of_London_from_the_Shard.jpg'},
    {'name': 'Torre Belém', 'city': 'Lisboa', 'country': 'Portugal', 'type': 'torre', 'image': 'https://upload.wikimedia.org/wikipedia/commons/thumb/0/03/Torre_Bel%C3%A9m_Lisbon_%28cropped%29.jpg/320px-Torre_Bel%C3%A9m_Lisbon_%28cropped%29.jpg'},
    {'name': 'Partenón', 'city': 'Atenas', 'country': 'Grecia', 'type': 'templo', 'image': 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/45/Parthenon_from_west.jpg/320px-Parthenon_from_west.jpg'},
    {'name': 'Coliseo', 'city': 'Roma', 'country': 'Italia', 'type': 'anfiteatro', 'image': 'https://upload.wikimedia.org/wikipedia/commons/thumb/d/de/Colosseo_2020.jpg/320px-Colosseo_2020.jpg'},
    {'name': 'Acueducto de Segovia', 'city': 'Segovia', 'country': 'España', 'type': 'acueducto', 'image': 'https://upload.wikimedia.org/wikipedia/commons/thumb/d/d7/Acueducto_de_Segovia_01.jpg/320px-Acueducto_de_Segovia_01.jpg'},
    {'name': 'Alhambra', 'city': 'Granada', 'country': 'España', 'type': 'palacio', 'image': 'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Alhambra_-_Granada%2C_Espa%C3%B1a.jpg/320px-Alhambra_-_Granada%2C_Espa%C3%B1a.jpg'},
    {'name': 'Sagrada Familia', 'city': 'Barcelona', 'country': 'España', 'type': 'catedral', 'image': 'https://upload.wikimedia.org/wikipedia/commons/thumb/7/77/Barcelona_-_Casa_Batll%C3%B3_-_Sagrada_Fam%C3%ADlia.jpg/320px-Barcelona_-_Casa_Batll%C3%B3_-_Sagrada_Fam%C3%ADlia.jpg'},
    {'name': 'Big Ben', 'city': 'Londres', 'country': 'Reino Unido', 'type': 'reloj', 'image': 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/82/London_-_Big_Ben_and_the_Houses_of_Parliament.jpg/320px-London_-_Big_Ben_and_the_Houses_of_Parliament.jpg'},
    {'name': 'London Eye', 'city': 'Londres', 'country': 'Reino Unido', 'type': 'rueda', 'image': 'https://upload.wikimedia.org/wikipedia/commons/thumb/d/d7/London_Eye_%28aerial%29.jpg/320px-London_Eye_%28aerial%29.jpg'},
    {'name': 'Puente de la Torre', 'city': 'Londres', 'country': 'Reino Unido', 'type': 'puente', 'image': 'https://upload.wikimedia.org/wikipedia/commons/thumb/d/d6/Tower_Bridge_London_Feb_2006.jpg/320px-Tower_Bridge_London_Feb_2006.jpg'},
    {'name': 'Catedral de Colonia', 'city': 'Colonia', 'country': 'Alemania', 'type': 'catedral', 'image': 'https://upload.wikimedia.org/wikipedia/commons/thumb/0/0e/Cologne_Cathedral_-_exterior_front_facade.jpg/320px-Cologne_Cathedral_-_exterior_front_facade.jpg'},
    {'name': 'Catedral de Notre Dame', 'city': 'París', 'country': 'Francia', 'type': 'catedral', 'image': 'https://upload.wikimedia.org/wikipedia/commons/thumb/b/bb/Notre_Dame_de_Paris_%28cropped%29.jpg/320px-Notre_Dame_de_Paris_%28cropped%29.jpg'},
    {'name': 'Brandenburger Tor', 'city': 'Berlín', 'country': 'Alemania', 'type': 'puerta', 'image': 'https://upload.wikimedia.org/wikipedia/commons/thumb/d/d3/Brandenburger_Tor_2004.jpg/320px-Brandenburger_Tor_2004.jpg'},
    {'name': 'Muro de Berlín', 'city': 'Berlín', 'country': 'Alemania', 'type': 'muro', 'image': 'https://upload.wikimedia.org/wikipedia/commons/thumb/6/6a/Berlin_Wall_remains_from_1975_near_Helmstedt.jpg/320px-Berlin_Wall_remains_from_1975_near_Helmstedt.jpg'},
    {'name': 'Puentes de Viena', 'city': 'Viena', 'country': 'Austria', 'type': 'puente'},
    {'name': 'Castillo de Praga', 'city': 'Praga', 'country': 'República Checa', 'type': 'castillo', 'image': 'https://upload.wikimedia.org/wikipedia/commons/thumb/6/6c/Prague_Panorama.jpg/320px-Prague_Panorama.jpg'},
    {'name': 'Puente Carlos', 'city': 'Praga', 'country': 'República Checa', 'type': 'puente', 'image': 'https://upload.wikimedia.org/wikipedia/commons/thumb/7/71/Karluv_most_prague.jpg/320px-Karluv_most_prague.jpg'},
    {'name': 'Museo del Louvre', 'city': 'París', 'country': 'Francia', 'type': 'museo', 'image': 'https://upload.wikimedia.org/wikipedia/commons/thumb/6/66/Louvre_Museum_Wikimedia_Commons_%28cropped%29.jpg/320px-Louvre_Museum_Wikimedia_Commons_%28cropped%29.jpg'},
    {'name': 'Castillo de Neuschwanstein', 'city': 'Füssen', 'country': 'Alemania', 'type': 'castillo', 'image': 'https://upload.wikimedia.org/wikipedia/commons/thumb/f/f6/01_Neuschwanstein_%28cropped%29.jpg/320px-01_Neuschwanstein_%28cropped%29.jpg'},
    {'name': 'Panteón', 'city': 'Roma', 'country': 'Italia', 'type': 'templo', 'image': 'https://upload.wikimedia.org/wikipedia/commons/thumb/1/15/Pantheon_Rome.jpg/320px-Pantheon_Rome.jpg'},
    {'name': 'Fuente de Trevi', 'city': 'Roma', 'country': 'Italia', 'type': 'fuente', 'image': 'https://upload.wikimedia.org/wikipedia/commons/thumb/d/d6/Trevi_Fountain_%28Rome%29.jpg/320px-Trevi_Fountain_%28Rome%29.jpg'},
    {'name': 'Basílica de San Pedro', 'city': 'Vaticano', 'country': 'Vaticano', 'type': 'basílica', 'image': 'https://upload.wikimedia.org/wikipedia/commons/thumb/1/18/Vatican_City_St_Peter%27s_Basilica.jpg/320px-Vatican_City_St_Peter%27s_Basilica.jpg'},
    {'name': 'Catedral de San Basilio', 'city': 'Moscú', 'country': 'Rusia', 'type': 'catedral', 'image': 'https://upload.wikimedia.org/wikipedia/commons/thumb/b/b0/St_Basils_Cathedral_-_2008.jpg/320px-St_Basils_Cathedral_-_2008.jpg'},
    {'name': 'Palacio de Invierno', 'city': 'San Petersburgo', 'country': 'Rusia', 'type': 'palacio', 'image': 'https://upload.wikimedia.org/wikipedia/commons/thumb/5/50/Hermitage_Museum_Winter_Palace.jpg/320px-Hermitage_Museum_Winter_Palace.jpg'},
    {'name': 'Plaza Roja', 'city': 'Moscú', 'country': 'Rusia', 'type': 'plaza', 'image': 'https://upload.wikimedia.org/wikipedia/commons/thumb/f/f8/Red_Square_Moscow_2013.jpg/320px-Red_Square_Moscow_2013.jpg'},
    
    # AMÉRICA
    {'name': 'Estatua de la Libertad', 'city': 'Nueva York', 'country': 'Estados Unidos', 'type': 'estatua', 'image': 'https://upload.wikimedia.org/wikipedia/commons/thumb/a/a1/Statue_of_Liberty_7.jpg/320px-Statue_of_Liberty_7.jpg'},
    {'name': 'Empire State Building', 'city': 'Nueva York', 'country': 'Estados Unidos', 'type': 'rascacielos', 'image': 'https://upload.wikimedia.org/wikipedia/commons/thumb/1/10/Empire_State_Building_%28aerial_view%29.jpg/320px-Empire_State_Building_%28aerial_view%29.jpg'},
    {'name': 'One World Trade Center', 'city': 'Nueva York', 'country': 'Estados Unidos', 'type': 'rascacielos', 'image': 'https://upload.wikimedia.org/wikipedia/commons/thumb/d/d3/One_World_Trade_Center_%28June_2013%29.jpg/320px-One_World_Trade_Center_%28June_2013%29.jpg'},
    {'name': 'Cristo Redentor', 'city': 'Río de Janeiro', 'country': 'Brasil', 'type': 'estatua', 'image': 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/4d/Christ_the_Redeemer_-_Rio_de_Janeiro%2C_Brazil.jpg/320px-Christ_the_Redeemer_-_Rio_de_Janeiro%2C_Brazil.jpg'},
    {'name': 'Machu Picchu', 'city': 'Cuzco', 'country': 'Perú', 'type': 'ruinas', 'image': 'https://upload.wikimedia.org/wikipedia/commons/thumb/e/eb/Machu_Picchu%2C_Peru.jpg/320px-Machu_Picchu%2C_Peru.jpg'},
    {'name': 'Chichén Itzá', 'city': 'Yucatán', 'country': 'México', 'type': 'ruinas', 'image': 'https://upload.wikimedia.org/wikipedia/commons/thumb/5/5e/Chichen_Itza_2022.jpg/320px-Chichen_Itza_2022.jpg'},
    {'name': 'Pirámides de Giza', 'city': 'El Cairo', 'country': 'Egipto', 'type': 'pirámide', 'image': 'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e3/Kheops-Pyramid.jpg/320px-Kheops-Pyramid.jpg'},
    {'name': 'Esfinge de Giza', 'city': 'El Cairo', 'country': 'Egipto', 'type': 'estatua', 'image': 'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c8/Sphinx_Giza_Egypt.jpg/320px-Sphinx_Giza_Egypt.jpg'},
    {'name': 'Monte Rushmore', 'city': 'Dakota del Sur', 'country': 'Estados Unidos', 'type': 'escultura', 'image': 'https://upload.wikimedia.org/wikipedia/commons/thumb/a/a7/Mount_Rushmore2.jpg/320px-Mount_Rushmore2.jpg'},
    {'name': 'Golden Gate Bridge', 'city': 'San Francisco', 'country': 'Estados Unidos', 'type': 'puente', 'image': 'https://upload.wikimedia.org/wikipedia/commons/thumb/0/0c/GoldenGateBridge-001.jpg/320px-GoldenGateBridge-001.jpg'},
    {'name': 'Puente de Brooklyn', 'city': 'Nueva York', 'country': 'Estados Unidos', 'type': 'puente', 'image': 'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e5/Brooklyn_Bridge.jpg/320px-Brooklyn_Bridge.jpg'},
    {'name': 'CN Tower', 'city': 'Toronto', 'country': 'Canadá', 'type': 'torre', 'image': 'https://upload.wikimedia.org/wikipedia/commons/thumb/d/d2/Toronto_-_CN_Tower_%282007%29.jpg/320px-Toronto_-_CN_Tower_%282007%29.jpg'},
    {'name': 'Torre del Ángel', 'city': 'Ciudad de México', 'country': 'México', 'type': 'torre', 'image': 'https://upload.wikimedia.org/wikipedia/commons/thumb/d/d7/Torre_Latinoamericana_2019.jpg/320px-Torre_Latinoamericana_2019.jpg'},
    {'name': 'Teotihuacán', 'city': 'Estado de México', 'country': 'México', 'type': 'ruinas', 'image': 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/4c/Teotihuacan_01.jpg/320px-Teotihuacan_01.jpg'},
    {'name': 'Cataratas del Iguazú', 'city': 'Foz do Iguaçu', 'country': 'Brasil', 'type': 'cataratas', 'image': 'https://upload.wikimedia.org/wikipedia/commons/thumb/6/63/Iguazu_Falls_13.jpg/320px-Iguazu_Falls_13.jpg'},
    {'name': 'Teatro Solís', 'city': 'Montevideo', 'country': 'Uruguay', 'type': 'teatro', 'image': 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/46/Montevideo_Teatro_Solis.jpg/320px-Montevideo_Teatro_Solis.jpg'},
    {'name': 'Teatro Colón', 'city': 'Buenos Aires', 'country': 'Argentina', 'type': 'teatro', 'image': 'https://upload.wikimedia.org/wikipedia/commons/thumb/5/57/Teatro_Colon_Buenos_Aires.jpg/320px-Teatro_Colon_Buenos_Aires.jpg'},
    {'name': 'Casa Blanca', 'city': 'Washington D.C.', 'country': 'Estados Unidos', 'type': 'palacio', 'image': 'https://upload.wikimedia.org/wikipedia/commons/thumb/3/38/White_House_north_2018.jpg/320px-White_House_north_2018.jpg'},
    {'name': 'Capitolio de EE.UU.', 'city': 'Washington D.C.', 'country': 'Estados Unidos', 'type': 'edificio', 'image': 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/4e/US_Capitol_north_side.jpg/320px-US_Capitol_north_side.jpg'},
    {'name': 'Cascadas del Niágara', 'city': 'Niagara Falls', 'country': 'Canadá', 'type': 'cataratas', 'image': 'https://upload.wikimedia.org/wikipedia/commons/thumb/6/6e/Niagara_Falls_01.jpg/320px-Niagara_Falls_01.jpg'},
    
    # ASIA
    {'name': 'Muro de China', 'city': 'Pekín', 'country': 'China', 'type': 'muro', 'image': 'https://upload.wikimedia.org/wikipedia/commons/thumb/2/23/The_Great_Wall_of_China_at_Jinshanling-edit.jpg/320px-The_Great_Wall_of_China_at_Jinshanling-edit.jpg'},
    {'name': 'Ciudad Prohibida', 'city': 'Pekín', 'country': 'China', 'type': 'palacio', 'image': 'https://upload.wikimedia.org/wikipedia/commons/thumb/3/3b/Forbidden_City_Skyline.jpg/320px-Forbidden_City_Skyline.jpg'},
    {'name': 'Torre de Shanghái', 'city': 'Shanghái', 'country': 'China', 'type': 'rascacielos', 'image': 'https://upload.wikimedia.org/wikipedia/commons/thumb/9/94/Shanghai_Tower_in_2018.jpg/320px-Shanghai_Tower_in_2018.jpg'},
    {'name': 'Petra', 'city': 'Wadi Musa', 'country': 'Jordania', 'type': 'ruinas', 'image': 'https://upload.wikimedia.org/wikipedia/commons/thumb/2/2d/The_Treasury_Petra_Jordan.jpg/320px-The_Treasury_Petra_Jordan.jpg'},
    {'name': 'Taj Mahal', 'city': 'Agra', 'country': 'India', 'type': 'mausoleo', 'image': 'https://upload.wikimedia.org/wikipedia/commons/thumb/b/bd/Taj_Mahal%2C_Agra%2C_India_edit3.jpg/320px-Taj_Mahal%2C_Agra%2C_India_edit3.jpg'},
    {'name': 'Angkor Wat', 'city': 'Siem Reap', 'country': 'Camboya', 'type': 'templo', 'image': 'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e6/Angkor_Wat.jpg/320px-Angkor_Wat.jpg'},
    {'name': 'Torre de Tokio', 'city': 'Tokio', 'country': 'Japón', 'type': 'torre', 'image': 'https://upload.wikimedia.org/wikipedia/commons/thumb/a/a3/Tokyo_Tower_20090104.jpg/320px-Tokyo_Tower_20090104.jpg'},
    {'name': 'Torre Skytree', 'city': 'Tokio', 'country': 'Japón', 'type': 'torre', 'image': 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/4f/Skytree_2013.jpg/320px-Skytree_2013.jpg'},
    {'name': 'Monte Fuji', 'city': 'Honshu', 'country': 'Japón', 'type': 'volcán', 'image': 'https://upload.wikimedia.org/wikipedia/commons/thumb/f/f5/Mount_Fuji_from_Lake_Shinji_2015.jpg/320px-Mount_Fuji_from_Lake_Shinji_2015.jpg'},
    {'name': 'Templo Dorado', 'city': 'Kioto', 'country': 'Japón', 'type': 'templo', 'image': 'https://upload.wikimedia.org/wikipedia/commons/thumb/5/58/Kinkaku-ji_2014.jpg/320px-Kinkaku-ji_2014.jpg'},
    {'name': 'Templo del Gran Buda', 'city': 'Kamakura', 'country': 'Japón', 'type': 'templo', 'image': 'https://upload.wikimedia.org/wikipedia/commons/thumb/b/be/Kamakura_Budda_Daibutsu_front_1885.jpg/320px-Kamakura_Budda_Daibutsu_front_1885.jpg'},
    {'name': 'Torre Burj Khalifa', 'city': 'Dubái', 'country': 'Emiratos Árabes Unidos', 'type': 'rascacielos', 'image': 'https://upload.wikimedia.org/wikipedia/commons/thumb/0/0d/Burj_Khalifa_2014_Dec.jpg/320px-Burj_Khalifa_2014_Dec.jpg'},
    {'name': 'Puente de Bosphorus', 'city': 'Estambul', 'country': 'Turquía', 'type': 'puente', 'image': 'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e3/Bosporus_Bridge.jpg/320px-Bosporus_Bridge.jpg'},
    {'name': 'Hagia Sophia', 'city': 'Estambul', 'country': 'Turquía', 'type': 'iglesia', 'image': 'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c2/Hagia_Sophia_Mars_2013.jpg/320px-Hagia_Sophia_Mars_2013.jpg'},
    {'name': 'Palacio Taj', 'city': 'Agra', 'country': 'India', 'type': 'palacio', 'image': 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/4b/Taj_Mahal_Agra.jpg/320px-Taj_Mahal_Agra.jpg'},
    {'name': 'Templo de Borobudur', 'city': 'Yogyakarta', 'country': 'Indonesia', 'type': 'templo', 'image': 'https://upload.wikimedia.org/wikipedia/commons/thumb/5/5c/Borobudur-Temple-02.jpg/320px-Borobudur-Temple-02.jpg'},
    {'name': 'Templo de Bagan', 'city': 'Bagan', 'country': 'Birmania', 'type': 'templo', 'image': 'https://upload.wikimedia.org/wikipedia/commons/thumb/d/d5/Bagan_Temples_2018.jpg/320px-Bagan_Temples_2018.jpg'},
    
    # ÁFRICA
    {'name': 'Tabla Mountain', 'city': 'Ciudad del Cabo', 'country': 'Sudáfrica', 'type': 'montaña', 'image': 'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e6/Table_Mountain_from_Signal_Hill.jpg/320px-Table_Mountain_from_Signal_Hill.jpg'},
    {'name': 'Pirámides de Meroe', 'city': 'Meroe', 'country': 'Sudán', 'type': 'pirámide', 'image': 'https://upload.wikimedia.org/wikipedia/commons/thumb/2/25/Meroe_Pyramids_03.jpg/320px-Meroe_Pyramids_03.jpg'},
    {'name': 'Templo de Luxor', 'city': 'Luxor', 'country': 'Egipto', 'type': 'templo', 'image': 'https://upload.wikimedia.org/wikipedia/commons/thumb/5/5e/Luxor_Temple_by_night.jpg/320px-Luxor_Temple_by_night.jpg'},
    
    # OCEANÍA
    {'name': 'Ópera de Sídney', 'city': 'Sídney', 'country': 'Australia', 'type': 'teatro', 'image': 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/40/Sydney_Opera_House_Sails.jpg/320px-Sydney_Opera_House_Sails.jpg'},
    {'name': 'Puente del Puerto de Sídney', 'city': 'Sídney', 'country': 'Australia', 'type': 'puente', 'image': 'https://upload.wikimedia.org/wikipedia/commons/thumb/a/a8/Sydney_Harbour_Bridge_edit.jpg/320px-Sydney_Harbour_Bridge_edit.jpg'},
    {'name': 'Ayers Rock', 'city': 'Yulara', 'country': 'Australia', 'type': 'monolito', 'image': 'https://upload.wikimedia.org/wikipedia/commons/thumb/3/31/Uluru_Sunset.jpg/320px-Uluru_Sunset.jpg'},
    {'name': 'Gran Barrera de Coral', 'city': 'Queensland', 'country': 'Australia', 'type': 'arrecife', 'image': 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/42/Great_Barrier_Reef_Australia.jpg/320px-Great_Barrier_Reef_Australia.jpg'},
]

# ========================================
# 📋 PLANTILLAS DE PREGUNTAS
# ========================================

MONUMENT_TEMPLATES = [
    "¿En qué ciudad se encuentra {monument}?",
    "¿{monument} está ubicado en qué ciudad?",
    "¿Cuál es la ciudad de {monument}?",
    "¿{monument} se encuentra en qué ciudad?",
]

MONUMENT_COUNTRY_TEMPLATES = [
    "¿En qué país se encuentra {monument}?",
    "¿{monument} está ubicado en qué país?",
    "¿De qué país es {monument}?",
    "¿{monument} se encuentra en qué país?",
]

MONUMENT_CITY_COUNTRY_TEMPLATES = [
    "¿En qué país está {city}, donde se encuentra {monument}?",
    "¿{monument} está en qué país?",
]

# ========================================
# 🎨 GENERADOR DE PREGUNTAS
# ========================================

def generate_monument_questions(monuments: List[Dict], count: int = 100, start_id: int = 70000) -> List[Dict]:
    """Genera preguntas sobre monumentos"""
    questions = []
    used_monuments = set()
    
    for i in range(min(count, len(monuments))):
        monument = monuments[i]
        monument_name = monument['name']
        city = monument['city']
        country = monument['country']
        
        if monument_name in used_monuments:
            continue
        
        used_monuments.add(monument_name)
        
        # 50% pregunta sobre ciudad, 50% sobre país
        if random.random() < 0.5:
            # Pregunta sobre ciudad
            template = random.choice(MONUMENT_TEMPLATES)
            question_text = template.format(monument=monument_name)
            
            # Opciones: ciudad correcta + 3 incorrectas
            all_cities = list(set([m['city'] for m in monuments if m['city'] != city]))
            wrong_cities = random.sample(all_cities, min(3, len(all_cities)))
            options = [city] + wrong_cities
            random.shuffle(options)
            
            difficulty = 'medium' if monument.get('image') else 'hard'
            
            questions.append({
                'id': f'monument_{start_id + i}',
                'type': 'monument_city',
                'difficulty': difficulty,
                'questionText': question_text,
                'correctAnswer': city,
                'options': options,
                'imageUrl': monument.get('image'),
                'extraData': {
                    'monumentName': monument_name,
                    'city': city,
                    'country': country,
                    'monumentType': monument.get('type', 'unknown')
                }
            })
        else:
            # Pregunta sobre país
            template = random.choice(MONUMENT_COUNTRY_TEMPLATES)
            question_text = template.format(monument=monument_name)
            
            all_countries = list(set([m['country'] for m in monuments if m['country'] != country]))
            wrong_countries = random.sample(all_countries, min(3, len(all_countries)))
            options = [country] + wrong_countries
            random.shuffle(options)
            
            difficulty = 'easy' if monument.get('image') else 'medium'
            
            questions.append({
                'id': f'monument_{start_id + i}',
                'type': 'monument_country',
                'difficulty': difficulty,
                'questionText': question_text,
                'correctAnswer': country,
                'options': options,
                'imageUrl': monument.get('image'),
                'extraData': {
                    'monumentName': monument_name,
                    'city': city,
                    'country': country,
                    'monumentType': monument.get('type', 'unknown')
                }
            })
    
    return questions

def generate_monument_image_questions(monuments: List[Dict], count: int = 50, start_id: int = 71000) -> List[Dict]:
    """Genera preguntas de monumentos con imagen (tipo quiz de fotos)"""
    # Filtrar monumentos con imagen
    monuments_with_image = [m for m in monuments if m.get('image')]
    
    questions = []
    used_monuments = set()
    
    for i in range(min(count, len(monuments_with_image))):
        monument = monuments_with_image[i]
        monument_name = monument['name']
        city = monument['city']
        country = monument['country']
        
        if monument_name in used_monuments:
            continue
        
        used_monuments.add(monument_name)
        
        # Pregunta tipo quiz de foto: "¿Qué monumento es este?"
        # Opciones: monumento correcto + 3 incorrectos
        all_monuments = [m['name'] for m in monuments_with_image if m['name'] != monument_name]
        wrong_monuments = random.sample(all_monuments, min(3, len(all_monuments)))
        options = [monument_name] + wrong_monuments
        random.shuffle(options)
        
        questions.append({
            'id': f'monument_image_{start_id + i}',
            'type': 'monument_image',
            'difficulty': 'medium',
            'questionText': f'¿Qué monumento o edificio es este?',
            'correctAnswer': monument_name,
            'options': options,
            'imageUrl': monument['image'],
            'extraData': {
                'monumentName': monument_name,
                'city': city,
                'country': country,
                'monumentType': monument.get('type', 'unknown')
            }
        })
    
    return questions

# ========================================
# 🚀 FUNCIÓN PRINCIPAL
# ========================================

def main():
    parser = argparse.ArgumentParser(description='Generador de Preguntas de Monumentos')
    parser.add_argument('--types', default='city,country,image',
                       help='Tipos de preguntas (city, country, image)')
    parser.add_argument('--count', type=int, default=50,
                       help='Cantidad de preguntas por tipo')
    parser.add_argument('--output', default='scripts/questions_monuments.json',
                       help='Archivo de salida')

    args = parser.parse_args()

    types = args.types.split(',')
    count = args.count
    output = args.output

    print('🏛️ Generador de Preguntas de Monumentos\n')
    print(f'🎯 Configuración:')
    print(f'   • Tipos: {", ".join(types)}')
    print(f'   • Cantidad por tipo: {count}')
    print(f'   • Salida: {output}\n')

    print(f'📊 Monumentos disponibles: {len(MONUMENTS)}')
    
    all_questions = []

    if 'city' in types:
        print(f'\n🏙️ Generando preguntas sobre ciudades de monumentos...')
        questions = generate_monument_questions(MONUMENTS, count=count)
        # Filtrar solo las de ciudad
        questions = [q for q in questions if q['type'] == 'monument_city']
        all_questions.extend(questions)
        print(f'   ✅ {len(questions)} preguntas')

    if 'country' in types:
        print(f'\n🌍 Generando preguntas sobre países de monumentos...')
        questions = generate_monument_questions(MONUMENTS, count=count)
        # Filtrar solo las de país
        questions = [q for q in questions if q['type'] == 'monument_country']
        all_questions.extend(questions)
        print(f'   ✅ {len(questions)} preguntas')

    if 'image' in types:
        print(f'\n📸 Generando preguntas de imágenes de monumentos...')
        questions = generate_monument_image_questions(MONUMENTS, count=count)
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
    
    # Contar preguntas con imagen
    with_image = len([q for q in all_questions if q.get('imageUrl')])
    print(f'\n📸 Con imagen: {with_image}/{len(all_questions)} ({with_image/len(all_questions)*100:.1f}%)')

if __name__ == '__main__':
    main()
