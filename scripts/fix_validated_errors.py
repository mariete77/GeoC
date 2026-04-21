#!/usr/bin/env python3
"""
GeoC Question FIXER — Corrects all validated errors in questions_clean.json.
Reads validation results and applies corrections.
"""

import json

# ═══════════════════════════════════════════════════════════════
# CORRECTIONS DATABASE — question_id → correct answer + fixed options
# ═══════════════════════════════════════════════════════════════

CORRECTIONS = {
    # ── LAKES ────────────────────────────────────────────────
    "lake_62017": {
        "correctAnswer": "Lago de Sanabria",
        "options": ["Lago Onega", "Lago de Sanabria", "Lago de Sobradinho", "Lago Buenos Aires"],
    },
    "lake_62015": {
        "correctAnswer": "Lago Nasser",
        "options": ["Lago de Chapala", "Gran Lago del Esclavo", "Lago Nasser", "Lago Constanza"],
    },
    "lake_62006": {
        "correctAnswer": "Brasil no tiene grandes lagos naturales",
        "options": ["Lago Llanquihue", "Lago Parón", "Lago de Cuitzeo", "Brasil no tiene grandes lagos naturales"],
    },
    "lake_62008": {
        "correctAnswer": "Lago Superior",
        "options": ["Lago Onega", "Lago Lemán", "Lago Superior", "Lago Huron"],
    },
    "lake_62023": {
        "correctAnswer": "Lago Chilika",
        "options": ["Lago Parón", "Represa de Tucuruí", "Lago Onega", "Lago Chilika"],
    },
    "lake_62027": {
        "correctAnswer": "Lago de Chapala",
        "options": ["Lago Gairdner", "Lago de Chapala", "Lago Onega", "Lago Huron"],
    },
    "lake_62007": {
        "correctAnswer": "Brasil no tiene grandes lagos naturales",
        "options": ["Gran Lago del Oso", "Lago de Itaipu", "Lago Gairdner", "Brasil no tiene grandes lagos naturales"],
    },
    "lake_62021": {
        "correctAnswer": "Lac du Bourget",
        "options": ["Lac du Bourget", "Gran Lago del Oso", "Lago Windermere", "Lago Llanquihue"],
    },
    "lake_62013": {
        "correctAnswer": "Lago Qinghai",
        "options": ["Represa de Tucuruí", "Lago Qinghai", "Embalse de Almansa", "Lago de Como"],
    },
    "lake_62003": {
        "correctAnswer": "Lago Argentino",
        "options": ["Lago Argentino", "Represa de Tucuruí", "Lago Eyre", "Lago Qinghai"],
    },
    "lake_62005": {
        "correctAnswer": "Lago Eyre",
        "options": ["Lago de Cuitzeo", "Lago Eyre", "Lago de Sanabria", "Lago Lemán"],
    },
    "lake_62029": {
        "correctAnswer": "Lago Titicaca",
        "options": ["Lago Parón", "Lago Chilka", "Lago Titicaca", "Lago Superior"],
    },
    "lake_62011": {
        "correctAnswer": "Lago Llanquihue",
        "options": ["Lago Müritz", "Lago Llanquihue", "Lago Baikal", "Lago Chilka"],
    },
    "lake_62019": {
        "correctAnswer": "Lago Superior",
        "options": ["Lago de Annecy", "Lago Llanquihue", "Lago Superior", "Lago Viedma"],
    },
    "lake_62022": {
        "correctAnswer": "Lago Chilika",
        "options": ["Lago Llanquihue", "Lago Chilika", "Lago Viedma", "Lago Superior"],
    },
    "lake_62009": {
        "correctAnswer": "Lago Superior",
        "options": ["Lago Dongting", "Lago de Itaipu", "Lago Superior", "Lago de Sobradinho"],
    },
    "lake_62020": {
        "correctAnswer": "Lac du Bourget",
        "options": ["Lago Llanquihue", "Lago Lemán", "Lago Viedma", "Lac du Bourget"],
    },
    "lake_62030": {
        "correctAnswer": "Lac du Bourget",
        "options": ["Lago Qinghai", "Lago de Ginebra", "Embalse de Almansa", "Lac du Bourget"],
    },
    "lake_62032": {
        "correctAnswer": "Lago Chilika",
        "options": ["Lago Wular", "Lago Como", "Gran Lago del Esclavo", "Lago Chilika"],
    },
    "lake_62042": {
        "correctAnswer": "Lago Titicaca",
        "options": ["Lago de Como", "Lago Onega", "Lago Llanquihue", "Lago Titicaca"],
    },
    "lake_62033": {
        "correctAnswer": "Lago Chilika",
        "options": ["Lago General Carrera", "Lago Chilika", "Lago Parón", "Lago Müritz"],
    },
    "lake_62036": {
        "correctAnswer": "Lago Garda",
        "options": ["Lago Toshka", "Lago Chiemsee", "Lago Superior", "Lago Garda"],
    },
    "lake_62037": {
        "correctAnswer": "Lago Garda",
        "options": ["Lago Onega", "Lago Superior", "Lago Titicaca", "Lago Garda"],
    },
    "lake_62040": {
        "correctAnswer": "Lago de Chapala",
        "options": ["Lago Todos los Santos", "Lago de Chapala", "Lago Ness", "Lago Gairdner"],
    },
    "lake_62043": {
        "correctAnswer": "Lago Titicaca",
        "options": ["Lago Parón", "Lago Müritz", "Lago de Cuitzeo", "Lago Titicaca"],
    },
    "lake_62046": {
        "correctAnswer": "Lago Titicaca",
        "options": ["Lago Junín", "Lago Parón", "Gran Lago del Esclavo", "Lago Titicaca"],
    },
    "lake_62039": {
        "correctAnswer": "Lago de Chapala",
        "options": ["Lago Como", "Lago Dongting", "Lago de Ginebra", "Lago de Chapala"],
    },
    "lake_62045": {
        "correctAnswer": "Lago Titicaca",
        "options": ["Lago Toshka", "Lago Junín", "Lago Superior", "Lago Titicaca"],
    },
    "lake_62034": {
        "correctAnswer": "Lago Chilika",
        "options": ["Lago de Itaipu", "Lago Huron", "Lago Chilika", "Lago General Carrera"],
    },
    "lake_62031": {
        "correctAnswer": "Lac du Bourget",
        "options": ["Lago de Sanabria", "Lago Ullswater", "Lac du Bourget", "Lago Buenos Aires"],
    },
    # Rotten / garbage lake questions → DELETE or fix
    "lake_52000": None,  # Garbage: "Lagos de España" as answer

    # ── RIVERS ───────────────────────────────────────────────
    "river_60010": {
        "correctAnswer": "Loa",
        "options": ["Ucayali", "Mersey", "Loa", "Misisipi"],
    },
    "river_60013": {
        "correctAnswer": "Yangtsé",
        "options": ["Colorado", "Rin", "Yangtsé", "Yenisei"],
    },
    "river_60001": {
        "correctAnswer": "Rin",
        "options": ["Tone", "Baker", "Rin", "Río Grande"],
    },
    "river_60005": {
        "correctAnswer": "Murray",
        "options": ["Elba", "Murray", "Júcar", "Amazonas"],
    },
    "river_60022": {
        "correctAnswer": "Loira",
        "options": ["Adigio", "Brahmaputra", "Loira", "Nelson"],
    },
    "river_60028": {
        "correctAnswer": "Shinano",
        "options": ["Nilo", "Shinano", "Orange", "Amur"],
    },
    "river_60017": {
        "correctAnswer": "Tajo",
        "options": ["Tajo", "Po", "Baker", "Mackenzie"],
    },
    "river_60003": {
        "correctAnswer": "Paraná",
        "options": ["Cauca", "Garona", "Nilo", "Paraná"],
    },
    "river_60011": {
        "correctAnswer": "Loa",
        "options": ["San Lorenzo", "Biobío", "Loa", "Magdalena"],
    },
    "river_60026": {
        "correctAnswer": "Po",
        "options": ["Indo", "Amazonas", "Po", "Pánuco"],
    },
    "river_60032": {
        "correctAnswer": "Amazonas",
        "options": ["Támesis", "Shinano", "Colorado", "Amazonas"],
    },
    "river_60029": {
        "correctAnswer": "Río Grande",
        "options": ["Ohio", "Júcar", "Río Grande", "Darling"],
    },
    "river_60015": {
        "correctAnswer": "Magdalena",
        "options": ["Maule", "Tíber", "Magdalena", "Cauca"],
    },
    "river_60008": {
        "correctAnswer": "Mackenzie",
        "options": ["Amazonas", "Sena", "Mackenzie", "Pánuco"],
    },
    "river_60030": {
        "correctAnswer": "Ganges",
        "options": ["Arno", "Ganges", "Perla", "Yamuna"],
    },
    "river_60007": {
        "correctAnswer": "Amazonas",
        "options": ["Nelson", "Misisipi", "Columbia", "Amazonas"],
    },
    "river_60020": {
        "correctAnswer": "Misisipi-Missouri",
        "options": ["Uruguay", "Ganges", "Colorado", "Misisipi-Missouri"],
    },
    "river_60009": {
        "correctAnswer": "Mackenzie",
        "options": ["Nilo", "Guadalquivir", "Mackenzie", "Brahmaputra"],
    },
    "river_60024": {
        "correctAnswer": "Ganges",
        "options": ["Arno", "Brahmaputra", "Ganges", "Perla"],
    },
    "river_60041": {
        "correctAnswer": "Shinano",
        "options": ["Brahmaputra", "Volga", "Shinano", "Río Grande"],
    },
    "river_60047": {
        "correctAnswer": "Amazonas",
        "options": ["São Francisco", "Amazonas", "Darling", "Paraná"],
    },
    "river_60039": {
        "correctAnswer": "Po",
        "options": ["Ob", "Arno", "Yangtsé", "Limpopo"],
    },
    "river_60044": {
        "correctAnswer": "Río Grande",
        "options": ["Lerma", "Garona", "Loira", "Río Grande"],
    },
    "river_60035": {
        "correctAnswer": "Ganges",
        "options": ["San Lorenzo", "Vaal", "Ucayali", "Ganges"],
    },
    "river_60043": {
        "correctAnswer": "Río Grande",
        "options": ["Río Grande", "Ob", "Danubio", "Ohio"],
    },
    "river_60033": {
        "correctAnswer": "Loira",
        "options": ["Sena", "Tíber", "Magdalena", "Río Negro"],
    },
    "river_60048": {
        "correctAnswer": "Amazonas",
        "options": ["Yangtsé", "Amazonas", "Atrato", "San Lorenzo"],
    },
    "river_60053": {
        "correctAnswer": "Río Grande",
        "options": ["Colorado", "Balsas", "Río Grande", "Nelson"],
    },
    "river_60058": {
        "correctAnswer": "Amazonas",
        "options": ["Amur", "Amazonas", "Uruguay", "Douro"],
    },
    "river_60056": {
        "correctAnswer": "Río Grande",
        "options": ["Balsas", "Mackenzie", "San Lorenzo", "Támesis"],
    },
    "river_60055": {
        "correctAnswer": "Río Grande",
        "options": ["Colorado", "Nilo", "Pánuco", "Godavari"],
    },
    "river_60054": {
        "correctAnswer": "Río Grande",
        "options": ["Douro", "Lerma", "Murray", "Paraná"],
    },
    "river_60051": {
        "correctAnswer": "Shinano",
        "options": ["Guadiana", "Shinano", "Paraná", "Baker"],
    },
    "river_60052": {
        "correctAnswer": "Shinano",
        "options": ["Cauca", "Churchill", "Shinano", "Ródano"],
    },
    "river_60059": {
        "correctAnswer": "Amazonas",
        "options": ["Biobío", "Orange", "Amazonas", "Cauca"],
    },
    "river_60045": {
        "correctAnswer": "Río Grande",
        "options": ["Río Grande", "Murray", "Pánuco", "Tajo"],
    },
    "river_60038": {
        "correctAnswer": "Po",
        "options": ["Tíber", "Amur", "Baker", "Colorado"],
    },
    "river_60042": {
        "correctAnswer": "Shinano",
        "options": ["Tíber", "Ishikari", "Elba", "Tajo"],
    },
    "river_60036": {
        "correctAnswer": "Ganges",
        "options": ["Shinano", "Pánuco", "Indo", "Garona"],
    },
    "river_60049": {
        "correctAnswer": "Po",
        "options": ["Lena", "Churchill", "Adigio", "Balsas"],
    },
    # Rotten river questions → DELETE
    "river_50000": None,   # "Piedras (España)"
    "river_50001": None,   # "Ríos de Italia"

    # ── MOUNTAINS ────────────────────────────────────────────
    "mountain_61039": {
        "correctAnswer": "Huascarán",
        "options": ["Huascarán", "Coropuna", "Nevado Tres Cruces", "Wildspitze"],
    },
    "mountain_61017": {
        "correctAnswer": "Pico Cristóbal Colón",
        "options": ["Coropuna", "Scafell Pike", "Kangchenjunga", "Pico Cristóbal Colón"],
    },
    "mountain_61035": {
        "correctAnswer": "Pico de Orizaba",
        "options": ["Njesuthi", "Pico de Orizaba", "Ben Nevis", "Sajama"],
    },
    "mountain_61027": {
        "correctAnswer": "Kanchenjunga",
        "options": ["Everest", "Monte Kosciuszko", "Kanchenjunga", "Kilimanjaro"],
    },
    "mountain_61021": {
        "correctAnswer": "Teide",
        "options": ["Teide", "Mulhacén", "Monte Fuji", "Kosciuszko"],
    },
    "mountain_61013": {
        "correctAnswer": "Ojos del Salado",
        "options": ["Ojos del Salado", "Njesuthi", "Simón Bolívar", "Twins Spire"],
    },
    "mountain_61011": {
        "correctAnswer": "Logan",
        "options": ["Nevado Tres Cruces", "Simón Bolívar", "Logan", "Ritacuba Blanco"],
    },
    "mountain_61025": {
        "correctAnswer": "Mont Blanc",
        "options": ["Ojos del Salado", "Mont Blanc", "Watzmann", "Monte Kita"],
    },
    "mountain_62000": {
        "correctAnswer": "Müritz",
        "options": ["Müritz", "Lago Chiemsee", "Lago Huron", "Lago de Sanabria"],
    },
    "mountain_61031": {
        "correctAnswer": "Fuji",
        "options": ["Ojos del Salado", "Dom", "Fuji", "K2"],
    },
    "mountain_61023": {
        "correctAnswer": "Denali",
        "options": ["Pico da Neblina", "Monte Saint Elias", "Denali", "Sajama"],
    },
    "mountain_61001": {
        "correctAnswer": "Zugspitze",
        "options": ["Teide", "Kilimanjaro", "Zugspitze", "Ritacuba Blanco"],
    },
    "mountain_61015": {
        "correctAnswer": "Everest",
        "options": ["Monte Logan", "Monte Thaba Putsoa", "Ojos del Salado", "Everest"],
    },
    "mountain_61003": {
        "correctAnswer": "Aconcagua",
        "options": ["Mafadi", "Aconcagua", "Monte Kita", "Monte Elgon"],
    },
    "mountain_61009": {
        "correctAnswer": "Pico da Neblina",
        "options": ["Wildspitze", "Grossglockner", "Pico da Neblina", "Pico 31 de Março"],
    },
    "mountain_61018": {
        "correctAnswer": "Monte Catalina",
        "options": ["Aconcagua", "Monte Catalina", "Dom", "Cristóbal Colón"],
    },
    "mountain_61033": {
        "correctAnswer": "Monte Kenia",
        "options": ["Ben Nevis", "Monte Kenia", "Monte Elgon", "Grossglockner"],
    },
    "mountain_61037": {
        "correctAnswer": "Huascarán",
        "options": ["Elbrus", "Huascarán", "Grossglockner", "Monte Saint Elias"],
    },
    "mountain_61041": {
        "correctAnswer": "Monte Bianco",
        "options": ["Sajama", "Watzmann", "Monte Bianco", "Pic du Midi de Bigorre"],
    },
    "mountain_61045": {
        "correctAnswer": "Fuji",
        "options": ["Bonete", "Fuji", "Denali", "Weißkugel"],
    },
    "mountain_61053": {
        "correctAnswer": "Everest",
        "options": ["Lhotse", "Aconcagua", "Makalu", "Everest"],
    },
    "mountain_61056": {
        "correctAnswer": "Huascarán",
        "options": ["Dom", "Sajama", "Huascarán", "Monte Meru"],
    },
    "mountain_61050": {
        "correctAnswer": "Pico de Orizaba",
        "options": ["Iztaccíhuatl", "Kangchenjunga", "Mont Blanc", "Pico de Orizaba"],
    },
    "mountain_61052": {
        "correctAnswer": "Everest",
        "options": ["Lhotse", "Aconcagua", "Makalu", "Everest"],
    },
    "mountain_61047": {
        "correctAnswer": "Monte Kenia",
        "options": ["Scafell Pike", "Monte Kenia", "Gebel Shayeb", "Everest"],
    },
    "mountain_61049": {
        "correctAnswer": "Pico de Orizaba",
        "options": ["Monte Bianco", "Iztaccíhuatl", "Monte Kosciuszko", "Pico de Orizaba"],
    },
    "mountain_61044": {
        "correctAnswer": "Fuji",
        "options": ["Lhotse", "Monte Rainier", "Monte Bianco", "Fuji"],
    },
    "mountain_61042": {
        "correctAnswer": "Monte Bianco",
        "options": ["Grossglockner", "Monte Bianco", "Pico da Neblina", "Schneekoppe"],
    },
    "mountain_61059": {
        "correctAnswer": "Huascarán",
        "options": ["Denali", "Monte Elgon", "Huascarán", "Popocatépetl"],
    },
    "mountain_61058": {
        "correctAnswer": "Huascarán",
        "options": ["Ritacuba Blanco", "Monte Kosciuszko", "Huascarán", "Ortles"],
    },
    "mountain_61019": {
        "correctAnswer": "Gebel Katrín",
        "options": ["Pic du Midi de Bigorre", "Pico 31 de Março", "Gebel Katrín", "Monte Hotaka"],
    },
    # Rotten mountain questions → DELETE
    "mountain_51001": None,  # "Gran Premio de la montaña en el Giro de Italia"
    "mountain_51000": None,  # "Gran Premio de la montaña en el Tour de Francia"
}


def main():
    with open("scripts/questions_clean.json") as f:
        questions = json.load(f)

    print(f"📝 Total preguntas originales: {len(questions)}\n")

    fixed = 0
    deleted = 0
    not_found = []

    for qid, correction in CORRECTIONS.items():
        # Find the question by ID
        idx = next((i for i, q in enumerate(questions) if q["id"] == qid), None)
        if idx is None:
            not_found.append(qid)
            continue

        q = questions[idx]

        if correction is None:
            # Delete garbage question
            old_q = q["questionText"]
            questions.pop(idx)
            deleted += 1
            print(f"  🗑️  ELIMINADA [{qid}]: \"{old_q[:60]}...\"")
        else:
            # Fix the answer and options
            old_answer = q["correctAnswer"]
            q["correctAnswer"] = correction["correctAnswer"]
            q["options"] = correction["options"]
            fixed += 1
            print(f"  ✅ [{qid}]: '{old_answer}' → '{correction['correctAnswer']}'")

    # Write corrected file
    with open("scripts/questions_clean.json", "w") as f:
        json.dump(questions, f, ensure_ascii=False, indent=2)

    print(f"\n{'='*60}")
    print(f"\n✅ RESUMEN DE CORRECCIONES:")
    print(f"  🔧 Corregidas: {fixed}")
    print(f"  🗑️  Eliminadas (basura): {deleted}")
    print(f"  ❌ No encontradas: {len(not_found)}")
    print(f"  📝 Total final: {len(questions)} preguntas")
    print(f"\n💾 Guardado en: scripts/questions_clean.json")

    if not_found:
        print(f"\n⚠️  IDs no encontradas: {not_found}")


if __name__ == "__main__":
    main()
