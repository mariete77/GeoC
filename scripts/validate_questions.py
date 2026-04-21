#!/usr/bin/env python3
"""
GeoC Question Validator — Fact-checks all quiz questions against real geographic data.
Outputs a report of incorrect/suspicious answers.
"""

import json
import sys

# ═══════════════════════════════════════════════════════════════
# GROUND TRUTH DATABASE — Verified geographic facts
# ═══════════════════════════════════════════════════════════════

# Country → Capital
CAPITALS = {
    "alemania": "berlín", "argentina": "buenos aires", "australia": "canberra",
    "bolivia": "la paz / sucre", "brasil": "brasilia", "canadá": "ottawa",
    "chile": "santiago", "china": "pekin", "colombia": "bogotá",
    "corea del sur": "seúl", "ecuador": "quito", "egipto": "el cairo",
    "españa": "madrid", "estados unidos": "washington d.c.", "francia": "parís",
    "india": "nueva delhi", "indonesia": "yakarta", "irlanda": "dublin",
    "islandia": "reykjavik", "italia": "roma", "japón": "tokio",
    "kenia": "nairobi", "marruecos": "rabat", "méxico": "ciudad de méxico",
    "nigeria": "abuya", "países bajos": "amsterdam", "perú": "lima",
    "polonia": "varsovia", "portugal": "lisboa", "reino unido": "londres",
    "rusia": "moscú", "sudáfrica": "pretoria", "suecia": "estocolmo",
    "suiza": "bern", "turquía": "ankara", "ucrania": "kiev",
    "venezuela": "caracas", "vietnam": "hanoi",
}

# Country → Highest mountain (name)
HIGHEST_MOUNTAIN = {
    "afganistán": "noshaq", "alemania": "zugspitze", "argentina": "aconcagua",
    "australia": "kosciuszko", "bolivia": "najahu", "brasil": "pico da neblina",
    "canadá": "logan", "chile": "ojos del salado", "china": "everest",
    "colombia": "pico cristóbal colón", "corea del sur": "hallasan",
    "ecuador": "chimborazo", "egipto": "catarina del monte santa catarina",
    "españa": "teide", "estados unidos": "denali", "francia": "mont blanc",
    "gran bretaña": "ben nevis", "grecia": "olimpo", "india": "kangchenjunga",
    "indonesia": "punjak jaya", "iran": "damavand", "italia": "monte bianco",
    "japón": "fuji", "kenia": "kenia", "marruecos": "toubkal",
    "méxico": "pico de orizaba", "nepal": "everest", "noruega": "galdhøpiggen",
    "perú": "huascarán", "polonia": "rysy", "portugal": "torre",
    "reino unido": "ben nevis", "rusia": "elbrus", "sudáfrica": "mafadi",
    "suecia": "kebnekaise", "suiza": "dufourspitze", "turquía": "ararat",
}

# Country → Longest river (within or primary)
LONGEST_RIVER = {
    "alemania": "rin", "argentina": "paraná", "australia": "murray",
    "bolivia": "mamoré", "brasil": "amazonas", "canadá": "mckenzie",
    "chile": "loa", "china": "yangtsé", "colombia": "magdalena",
    "corea del sur": "nakdong", "dinamarca": "gudenå", "ecuador": "napo",
    "egipto": "nilo", "españa": "tajo", "estados unidos": "misisipi-missouri",
    "francia": "loira", "grecia": "aliacmón", "india": "ganges-indus",
    "indonesia": "kapuas", "iran": "karun", "irlanda": "shannon",
    "italia": "po", "japón": "shinano", "kenia": "tana",
    "marruecos": "drâa", "méxico": "rio grande (bravo)",
    "noruega": "glomma", "perú": "amazonas", "polonia": "vístula",
    "portugal": "tago/tejo", "reino unido": "severn", "rusia": "ob",
    "sudáfrica": "orange", "suecia": "tolve-trollhättan å",
    "suiza": "rín/aare", "turquía": "kızılırmak",
}

# Country → Largest lake (natural)
LARGEST_LAKE = {
    "alemania": "lago müritz", "argentina": "lago argentino",
    "australia": "lago eyre", "bolivia": "titicaca", "brasil": "no hay grandes lagos naturales",
    "canadá": "lago superior", "chile": "llanquihue", "china": "qinghai",
    "colombia": "tota", "corea del sur": "lago de seúl",
    "ecuador": "cuicocha", "egipto": "nasser", "españa": "sanabria",
    "estados unidos": "lago superior", "francia": "lac du bourget",
    "grecia": "trichonida", "india": "chilika", "indonesia": "toba",
    "italia": "garda", "japón": "biwa", "kenia": "turkana",
    "marruecos": "bir aresh", "méxico": "chapala", "noruega": "mjøsa",
    "perú": "titicaca", "polonia": "śniardwy", "portugal": "alqueva (compartido)",
    "reino unido": "lough neagh", "rusia": "mar caspio (o lago baikal si solo agua dulce)",
    "sudáfrica": "van der kloof", "suecia": "vänern",
    "suiza": "ginebra", "turquía": "van",
}

# Known INCORRECT answers found in dataset — explicit corrections
KNOWN_ERRORS = {
    # LAKES
    ("lake", "españa"): ("embalse de almansa", "lago de sanabria"),
    ("lake", "egipto"): ("lago toshka", "lago nasser"),
    ("lake", "brasil"): ("lago de itaipu", "no es lago natural; Brasil no tiene grandes lagos naturales"),
    ("lake", "canadá"): ("lago superior", "lago superior (compartido con EE.UU.)"),
    # RIVERS
    ("river", "alemania"): ("danubio", "el río Rin es el más largo en Alemania"),
    ("river", "francia"): ("ródano", "el Loire es el río más largo de Francia"),
    ("river", "españa"): ("ebro", "el Tajo es el río más largo de España"),
    ("river", "argentina"): ("uruguay", "el Paraná es el río más largo de Argentina"),
    ("river", "australia"): ("darling", "el Murray es el principal; Darling es afluente"),
    # MOUNTAINS
    ("mountain", "perú"): ("coropuna", "Huascarán es la montaña más alta del Perú (6,768m)"),
    ("mountain", "méxico"): ("popocatépetl", "Pico de Orizaba es la montaña más alta de México (5,636m)"),
    ("mountain", "india"): ("nanda devi", "Kanchenjunga está en la frontera; Nanda Devi es la más alta íntegramente en India — discutible"),
    ("mountain", "colombia"): ("simón bolívar", "Pico Cristóbal Colón es el más alto (5,730m), Simón Bolívar casi igual"),
}


def normalize(text):
    """Normalize text for comparison."""
    return text.lower().strip().normalize("NFKD") if hasattr(str, "normalize") else text.lower().strip()


def find_country_in_question(question_text):
    """Try to extract the country name from a question."""
    import re
    countries_lower = {k.lower(): k for k in list(CAPITALS.keys()) + list(HIGHEST_MOUNTAIN.keys())}
    for clow, cname in sorted(countries_lower.items(), key=lambda x: -len(x[0])):
        if clow in question_text.lower():
            return cname, clow
    return None, None


def validate_question(q):
    """Validate a single question. Returns (is_correct, reason) tuple."""
    qtype = q["type"]
    qtext = q["questionText"]
    correct = normalize(q["correctAnswer"])
    country, country_low = find_country_in_question(qtext)

    issues = []

    # Check against known errors database
    if (qtype, country_low) in KNOWN_ERRORS:
        wrong_answer, right_answer = KNOWN_ERRORS[(qtype, country_low)]
        if wrong_answer in correct:
            return False, f"❌ ERROR: '{q['correctAnswer']}' → debería ser '{right_answer}'"

    # Type-specific validations
    if qtype == "capital" and country:
        expected = normalize(CAPITALS.get(country_low, ""))
        if expected and expected not in correct and correct not in expected:
            # Fuzzy check: maybe close enough
            return None, f"⚠️  Revisar capital: ¿'{q['correctAnswer']}' es correcta para {country}?"

    elif qtype == "mountain" and country:
        expected = normalize(HIGHEST_MOUNTAIN.get(country_low, ""))
        if expected and expected not in correct and correct not in expected:
            return False, f"❌ ERROR montaña: '{q['correctAnswer']}' ≠ '{HIGHEST_MOUNTAIN.get(country_low, '?')}' para {country}"

    elif qtype == "river" and country:
        expected = normalize(LONGEST_RIVER.get(country_low, ""))
        if expected and expected not in correct and correct not in expected:
            return False, f"❌ ERROR río: '{q['correctAnswer']}' ≠ '{LONGEST_RIVER.get(country_low, '?')}' para {country}"

    elif qtype == "lake" and country:
        expected = normalize(LARGEST_LAKE.get(country_low, ""))
        if expected and expected not in correct and correct not in expected:
            # Special case: embalses are NOT lakes
            if "embalse" in correct or "represa" in correct:
                return False, f"❌ ERROR lago: '{q['correctAnswer']}' es un embalse, NO un lago natural"
            return False, f"❌ ERROR lago: '{q['correctAnswer']}' ≠ '{LARGEST_LAKE.get(country_low, '?')}' para {country}"

    return None, None


def main():
    with open("scripts/questions_clean.json") as f:
        questions = json.load(f)

    print(f"🔍 Validando {len(questions)} preguntas...\n")
    print("=" * 70)

    errors = []
    warnings = []
    validated_types = {"lake", "river", "mountain", "capital"}
    skipped = 0

    for i, q in enumerate(questions):
        if q["type"] not in validated_types:
            skipped += 1
            continue

        is_error, reason = validate_question(q)
        if is_error is False:
            errors.append((q, reason))
        elif reason:
            warnings.append((q, reason))

    # ── Print ERRORS ────────────────────────────────────────
    print(f"\n🔴 ERRORES CONFIRMADOS ({len(errors)}):\n")
    for q, reason in errors:
        print(f"  [{q['id']}] ({q['type'].upper()})")
        print(f"  P: {q['questionText']}")
        print(f"  A: {q['correctAnswer']}")
        print(f"  Opts: {q['options']}")
        print(f"  → {reason}")
        print()

    # ── Print WARNINGS ──────────────────────────────────────
    print(f"\n🟡 REVISAR MANUALMENTE ({len(warnings)}):\n")
    for q, reason in warnings:
        print(f"  [{q['id']}] ({q['type'].upper()})")
        print(f"  P: {q['questionText']}")
        print(f"  A: {q['correctAnswer']}")
        print(f"  → {reason}")
        print()

    # ── Summary ────────────────────────────────────────────
    checked = len(questions) - skipped
    print("=" * 70)
    print(f"\n📊 RESUMEN:")
    print(f"  ✅ Tipos validados: {', '.join(sorted(validated_types))}")
    print(f"  🔴 Errores confirmados: {len(errors)}")
    print(f"  🟡 A revisar manualmente: {len(warnings)}")
    print(f"  ⏭️  No validados (flag/population/etc.): {skipped}")
    print(f"  📝 Total revisadas: {checked} / {len(questions)}")

    # Save errors to file for fixing
    if errors:
        error_ids = [q["id"] for q, _ in errors]
        with open("scripts/validation_errors.json", "w") as f:
            json.dump(error_ids, f, indent=2)
        print(f"\n💾 IDs con error guardados en: scripts/validation_errors.json")


if __name__ == "__main__":
    main()
