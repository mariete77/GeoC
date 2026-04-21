#!/usr/bin/env python3
"""
GeoC Silhouette Quiz Generator — Generates gray silhouette questions for ALL countries.
Each question shows a country's outline in gray, user must type the country name.
Uses Natural Earth GeoJSON data for accurate country boundaries.
"""

import json
import os
import sys
import urllib.request
import subprocess

# ═══════════════════════════════════════════════════════════════
# CONFIGURATION
# ═══════════════════════════════════════════════════════════════

OUTPUT_DIR = "assets/silhouettes"
QUESTIONS_FILE = "scripts/questions_silhouettes.json"
IMAGE_SIZE = 400  # px width for output PNGs
GRAY_COLOR = "#888888"  # Medium gray for silhouettes
BG_COLOR = "#FFFFFF"   # White background

# Country name mappings (ISO → Spanish display name)
COUNTRY_NAMES = {
    "AD": "Andorra", "AE": "Emiratos Árabes Unidos", "AF": "Afganistán",
    "AG": "Antigua y Barbuda", "AL": "Albania", "AM": "Armenia",
    "AO": "Angola", "AR": "Argentina", "AT": "Austria", "AU": "Australia",
    "AZ": "Azerbaiyán", "BA": "Bosnia y Herzegovina", "BB": "Barbados",
    "BD": "Bangladés", "BE": "Bélgica", "BF": "Burkina Faso",
    "BG": "Bulgaria", "BI": "Burundi", "BJ": "Benín", "BN": "Brunéi",
    "BO": "Bolivia", "BR": "Brasil", "BS": "Bahamas", "BT": "Bután",
    "BW": "Botsuana", "BY": "Bielorrusia", "BZ": "Belice",
    "CA": "Canadá", "CD": "República Democrática del Congo",
    "CF": "República Centroafricana", "CG": "República del Congo",
    "CH": "Suiza", "CI": "Costa de Marfil", "CL": "Chile",
    "CM": "Camerún", "CN": "China", "CO": "Colombia", "CR": "Costa Rica",
    "CU": "Cuba", "CV": "Cabo Verde", "CY": "Chipre", "Chequia": "República Checa",
    "CZ": "República Checa", "DE": "Alemania", "DJ": "Yibuti",
    "DK": "Dinamarca", "DM": "Dominica", "DO": "Rep Dominicana",
    "DZ": "Argelia", "EC": "Ecuador", "EE": "Estonia", "EG": "Egipto",
    "ER": "Eritrea", "ES": "España", "ET": "Etiopía", "FI": "Finlandia",
    "FJ": "Fiyi", "FM": "Micronesia", "FR": "Francia", "GA": "Gabón",
    "GB": "Reino Unido", "GD": "Granada", "GE": "Georgia",
    "GH": "Ghana", "GM": "Gambia", "GN": "Guinea", "GQ": "Guinea Ecuatorial",
    "GR": "Grecia", "GT": "Guatemala", "GW": "Guinea-Bisáu",
    "GY": "Guyana", "HN": "Honduras", "HR": "Croacia", "HT": "Haití",
    "HU": "Hungría", "ID": "Indonesia", "IE": "Irlanda", "IL": "Israel",
    "IN": "India", "IQ": "Irak", "IR": "Irán", "IS": "Islandia",
    "IT": "Italia", "JM": "Jamaica", "JO": "Jordania", "JP": "Japón",
    "KE": "Kenia", "KG": "Kirguistán", "KH": "Camboya",
    "KI": "Kiribati", "KM": "Comoras", "KN": "San Cristóbal y Nieves",
    "KP": "Corea del Norte", "KR": "Corea del Sur", "KW": "Kuwait",
    "KZ": "Kazajistán", "LA": "Laos", "LB": "Líbano", "LC": "Santa Lucía",
    "LI": "Liechtenstein", "LK": "Sri Lanka", "LR": "Liberia",
    "LS": "Lesoto", "LT": "Lituania", "LU": "Luxemburgo", "LV": "Letonia",
    "LY": "Libia", "MA": "Marruecos", "MC": "Mónaco", "MD": "Moldavia",
    "ME": "Montenegro", "MG": "Madagascar", "MH": "Islas Marshall",
    "MK": "Macedonia del Norte", "ML": "Malí", "MM": "Birmania",
    "MN": "Mongolia", "MR": "Mauritania", "MT": "Malta", "MU": "Mauricio",
    "MV": "Maldivas", "MW": "Malaui", "MX": "México", "MY": "Malasia",
    "MZ": "Mozambique", "NA": "Namibia", "NE": "Níger", "NG": "Nigeria",
    "NI": "Nicaragua", "NL": "Países Bajos", "NO": "Noruega",
    "NP": "Nepal", "NR": "Nauru", "NZ": "Nueva Zelanda", "Omán": "Omán",
    "PA": "Panamá", "PE": "Perú", "PF": "Polinesia Francesa",
    "PG": "Papúa Nueva Guinea", "PH": "Filipinas", "PK": "Pakistán",
    "PL": "Polonia", "PS": "Palestina", "PT": "Portugal",
    "PY": "Paraguay", "QA": "Qatar", "RO": "Rumania", "RS": "Serbia",
    "RU": "Rusia", "RW": "Ruanda", "SA": "Arabia Saudita",
    "SB": "Islas Salomón", "SC": "Seychelles", "SD": "Sudán",
    "SE": "Suecia", "SG": "Singapur", "SH": "Santa Elena",
    "SI": "Eslovenia", "SJ": "Svalbard y Jan Mayen", "SK": "Eslovaquia",
    "SL": "Sierra Leona", "SM": "San Marino", "SN": "Senegal",
    "SO": "Somalia", "SR": "Surinám", "SS": "Sudán del Sur",
    "ST": "Santo Tomé y Príncipe", "SV": "El Salvador", "SY": "Siria",
    "SZ": "Esuatini", "TC": "Islas Turcas y Caicos", "TD": "Chad",
    "TF": "Tierras Australes Francesas", "TG": "Togo", "TH": "Tailandia",
    "TJ": "Tayikistán", "TK": "Tokelau", "TL": "Timor Oriental",
    "TM": "Turkmenistán", "TN": "Túnez", "TO": "Tonga", "TR": "Turquía",
    "TT": "Trinidad y Tobago", "TV": "Tuvalu", "TW": "Taiwán",
    "TZ": "Tanzania", "UA": "Ucrania", "UG": "Uganda",
    "US": "Estados Unidos", "UY": "Uruguay", "UZ": "Uzbekistán",
    "VA": "Ciudad del Vaticano", "VC": "San Vicente y las Granadinas",
    "VE": "Venezuela", "VN": "Vietnam", "VU": "Vanuatu",
    "WS": "Samoa", "YE": "Yemen", "ZA": "Sudáfrica", "ZM": "Zambia",
    "ZW": "Zimbabue",
}

# Alternative names / aliases users might type
ALIASES = {
    "Estados Unidos": ["USA", "EE UU", "EE.UU.", "Estados Unidos de América", "United States"],
    "Reino Unido": ["UK", "Inglaterra", "Gran Bretaña", "United Kingdom", "Great Britain"],
    "República Checa": ["Chequia", "Checo"],
    "Irán": ["Persia"],
    "Birmania": ["Myanmar", "Birmania/Myanmar"],
    "Macedonia del Norte": ["Macedonia", "FYROM"],
    "Esuatini": ["Swazilandia", "Suazilandia"],
    "Cabo Verde": ["Cabo Verde", "Cabo Verde"],
    "República Democrática del Congo": ["Congo RD", "RDC", "Congo-Kinshasa", "DR Congo"],
    "República del Congo": ["Congo Brazzaville", "Congo R", "RC"],
    "Corea del Sur": ["Corea del Sur", "Surcorea"],
    "Corea del Norte": ["Corea del Norte", "Norcorea"],
}


def check_dependencies():
    """Check if required packages are installed."""
    try:
        import json
        return True
    except ImportError:
        return False


def download_geojson():
    """Download Natural Earth admin 0 boundaries GeoJSON."""
    url = "https://raw.githubusercontent.com/datasets/geo-countries/master/data/countries.geojson"
    local_path = "/tmp/countries.geojson"

    if os.path.exists(local_path):
        print(f"  ✅ GeoJSON already cached at {local_path}")
        return local_path

    print(f"  ⬇️  Downloading country boundaries from {url}...")
    try:
        urllib.request.urlretrieve(url, local_path)
        print(f"  ✅ Downloaded to {local_path}")
        return local_path
    except Exception as e:
        print(f"  ❌ Failed to download: {e}")
        return None


def install_package(pkg):
    """Install a pip package if not available."""
    try:
        __import__(pkg.replace("-", "_"))
        return True
    except ImportError:
        print(f"  📦 Installing {pkg}...")
        subprocess.check_call([sys.executable, "-m", "pip", "install", pkg, "-q"])
        return True


def render_svg_to_png(svg_content, output_path, size=IMAGE_SIZE):
    """Render SVG string to PNG file using cairosvg."""
    import cairosvg
    cairosvg.svg2png(
        bytestring=svg_content.encode("utf-8"),
        write_to=output_path,
        output_width=size,
        output_height=size,
    )


def create_country_svg(coordinates, fill_color=GRAY_COLOR, size=IMAGE_SIZE):
    """Create an SVG of a country's polygon(s) filled with gray color."""
    # Simple bounding box calculation
    all_coords = []
    def extract_coords(geom):
        if geom["type"] == "Polygon":
            all_coords.extend(geom["coordinates"][0])
        elif geom["type"] == "MultiPolygon":
            for poly in geom["coordinates"]:
                all_coords.extend(poly[0])

    extract_coords(coordinates)

    if not all_coords:
        return None

    lons = [c[0] for c in all_coords]
    lats = [c[1] for c in all_coords]
    min_lon, max_lon = min(lons), max(lons)
    min_lat, max_lat = min(lats), max(lats)

    lon_range = max_lon - min_lon or 1
    lat_range = max_lat - min_lat or 1

    # Add 5% padding
    pad_lon = lon_range * 0.05
    pad_lat = lat_range * 0.05
    min_lon -= pad_lon; max_lon += pad_lon
    min_lat -= pad_lat; max_lat += pad_lat

    # Build path data
    def coords_to_path(ring):
        parts = []
        for i, coord in enumerate(ring):
            x = ((coord[0] - min_lon) / (max_lon - min_lon)) * size
            y = size - ((coord[1] - min_lat) / (max_lat - min_lat)) * size
            cmd = "M" if i == 0 else "L"
            parts.append(f"{cmd}{x:.2f},{y:.2f}")
        parts.append("Z")
        return " ".join(parts)

    paths = []
    if coordinates["type"] == "Polygon":
        for ring in coordinates["coordinates"]:
            paths.append(coords_to_path(ring))
    elif coordinates["type"] == "MultiPolygon":
        for poly in coordinates["coordinates"]:
            for ring in poly:
                paths.append(coords_to_path(ring))

    svg = f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {size} {size}" width="{size}" height="{size}">
  <rect width="{size}" height="{size}" fill="{BG_COLOR}"/>
  <path d="{chr(10).join(paths)}" fill="{fill_color}" stroke="#666666" stroke-width="1"/>
</svg>'''
    return svg


def generate_all_silhouettes():
    """Main function: generate silhouette images and questions for all countries."""
    print("\n🗺️  GeoC Silhouette Generator")
    print("=" * 50)

    # Ensure dependencies
    install_package("cairosvg")

    # Create output directory
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    os.makedirs(os.path.dirname(QUESTIONS_FILE), exist_ok=True)

    # Download/get GeoJSON
    geojson_path = download_geojson()
    if not geojson_path:
        print("❌ Cannot proceed without GeoJSON")
        return

    with open(geojson_path) as f:
        geo_data = json.load(f)

    questions = []
    generated = 0
    skipped = []

    for feature in geo_data["features"]:
        props = feature["properties"]
        geometry = feature["geometry"]

        # Get ISO code (try different field names)
        iso_code = (
            props.get("ISO3166-1-Alpha-2") or
            props.get("ISO_A2") or
            props.get("iso_a2") or
            props.get("ADM0_A2") or ""
        ).upper().strip()

        # Skip empty or invalid codes
        if not iso_code or iso_code in ("-99", ""):
            skipped.append(props.get("ADMIN", "unknown"))
            continue

        # Get country name
        country_name = COUNTRY_NAMES.get(iso_code) or props.get("ADMIN", "")

        if not country_name:
            skipped.append(iso_code)
            continue

        # Create SVG
        svg_content = create_country_svg(geometry)
        if not svg_content:
            skipped.append(country_name)
            continue

        # Render to PNG
        png_filename = f"{iso_code.lower()}.png"
        png_path = os.path.join(OUTPUT_DIR, png_filename)
        try:
            render_svg_to_png(svg_content, png_path)
        except Exception as e:
            print(f"  ⚠️  Failed to render {country_name}: {e}")
            skipped.append(country_name)
            continue

        # Build accepted answers list
        accepted = [country_name.lower()]
        if country_name in ALIASES:
            for alias in ALIASES[country_name]:
                accepted.append(alias.lower())

        # Create question entry
        qid = f"silhouette_{iso_code.lower()}"
        question = {
            "id": qid,
            "type": "silhouette",
            "difficulty": "medium",
            "questionText": "¿Qué país es esta silueta?",
            "correctAnswer": country_name,
            "options": [],  # Empty = type-answer mode (user types the answer)
            "imageUrl": png_path,  # Will be asset path in app
            "extraData": {
                "countryCode": iso_code.lower(),
                "countryName": country_name,
                "acceptedAnswers": accepted,
            },
        }
        questions.append(question)
        generated += 1

        if generated % 20 == 0:
            print(f"  📍 Generated {generated} silhouettes...")

    # Save questions JSON
    with open(QUESTIONS_FILE, "w") as f:
        json.dump(questions, f, ensure_ascii=False, indent=2)

    # Summary
    print(f"\n{'='*50}")
    print(f"\n✅ GENERACIÓN COMPLETADA:")
    print(f"  🗺️  Siluetas generadas: {generated}")
    print(f"  📁 Imágenes en: {OUTPUT_DIR}/")
    print(f"  📝 Preguntas en: {QUESTIONS_FILE}")
    print(f"  ⏭️  Saltados: {len(skipped)} países")
    if skipped:
        print(f"     (no tenían código ISO válido: {skipped[:10]}{'...' if len(skipped) > 10 else ''})")

    print(f"\n💡 Para usar en la app:")
    print(f"  1. Las imágenes están en assets/silhouettes/")
    print(f"  2. Añade 'assets/silhouettes/' al pubspec.yaml si no está")
    print(f"  3. Importa {QUESTIONS_FILE} a Firestore junto con questions_clean.json")
    print(f"  4. El type 'silhouette' con options=[] activa el modo texto automáticamente")

    return questions


if __name__ == "__main__":
    generate_all_silhouettes()
