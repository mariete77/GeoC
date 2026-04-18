#!/usr/bin/env python3
"""
🔧 Corregir nombres de monedas en inglés a español
"""

import json
import glob
from typing import Dict

# ========================================
# 💰 DICCIONARIO DE MONEDAS (inglés → español)
# ========================================

CURRENCY_TRANSLATIONS = {
    # Dólares
    'Australian dollar': 'Dólar australiano',
    'Bahamian dollar': 'Dólar bahameño',
    'Bajan dollar': 'Dólar bahameño',
    'Barbadian dollar': 'Dólar barbadense',
    'Belize dollar': 'Dólar beliceño',
    'Bermudian dollar': 'Dólar bermudeño',
    'Brunei dollar': 'Dólar de Brunéi',
    'Canadian dollar': 'Dólar canadiense',
    'Cayman Islands dollar': 'Dólar de las Islas Caimán',
    'East Caribbean dollar': 'Dólar del Caribe Oriental',
    'Fijian dollar': 'Dólar fiyiano',
    'Guyanese dollar': 'Dólar guyanés',
    'Hong Kong dollar': 'Dólar de Hong Kong',
    'Jamaican dollar': 'Dólar jamaicano',
    'Liberian dollar': 'Dólar liberiano',
    'Namibian dollar': 'Dólar namibio',
    'New Zealand dollar': 'Dólar neozelandés',
    'Singapore dollar': 'Dólar singapurense',
    'Solomon Islands dollar': 'Dólar de las Islas Salomón',
    'Surinamese dollar': 'Dólar surinamés',
    'New Taiwan dollar': 'Nuevo dólar taiwanés',
    'Trinidad and Tobago dollar': 'Dólar de Trinidad y Tobago',
    'United States dollar': 'Dólar estadounidense',
    'Cook Islands dollar': 'Dólar de las Islas Cook',
    'Eastern Caribbean dollar': 'Dólar del Caribe Oriental',

    # Euros
    'euro': 'Euro',

    # Libras
    'British pound': 'Libra esterlina',
    'Egyptian pound': 'Libra egipcia',
    'Lebanese pound': 'Libra libanesa',
    'South Sudanese pound': 'Libra sursudanesa',
    'Syrian pound': 'Libra siria',

    # Yenes
    'Japanese yen': 'Yen japonés',

    # Yuanes
    'Chinese yuan': 'Yuan chino',

    # Rupias
    'Afghan afghani': 'Afgano afgano',
    'Bangladeshi taka': 'Taka bangladesí',
    'Bhutanese ngultrum': 'Ngultrum butanés',
    'Indian rupee': 'Rupia india',
    'Mauritian rupee': 'Rupia mauriciana',
    'Nepalese rupee': 'Rupia nepalí',
    'Pakistani rupee': 'Rupia paquistaní',
    'Seychellois rupee': 'Rupia seychellense',
    'Sri Lankan rupee': 'Rupia de Sri Lanka',

    # Francos
    'Burundian franc': 'Franco burundés',
    'Central African CFA franc': 'Franco CFA de África Central',
    'Comorian franc': 'Franco comorano',
    'Congolese franc': 'Franco congoleño',
    'Djiboutian franc': 'Franco yibutí',
    'Guinean franc': 'Franco guineano',
    'Rwandan franc': 'Franco ruandés',
    'Swiss franc': 'Franco suizo',
    'West African CFA franc': 'Franco CFA de África Occidental',
    'CFP franc': 'Franco CFP',
    'Franco francés': 'Franco francés',

    # Dinares
    'Algerian dinar': 'Dinar argelino',
    'Bahraini dinar': 'Dinar bareiní',
    'Iraqi dinar': 'Dinar iraquí',
    'Jordanian dinar': 'Dinar jordano',
    'Kuwaiti dinar': 'Dinar kuwaití',
    'Libyan dinar': 'Dinar libio',
    'Serbian dinar': 'Dinar serbio',
    'Tunisian dinar': 'Dinar tunecino',

    # Otras monedas
    'Afghan afghani': 'Afgano afgano',
    'Armenian dram': 'Dram armenio',
    'Azerbaijani manat': 'Manat azerbayano',
    'Bangladeshi taka': 'Taka bangladesí',
    'Bolivian boliviano': 'Boliviano boliviano',
    'Brazilian real': 'Real brasileño',
    'Cambodian riel': 'Riel camboyano',
    'Chilean peso': 'Peso chileno',
    'Chinese yuan': 'Yuan chino',
    'Colombian peso': 'Peso colombiano',
    'Costa Rican colón': 'Colón costarricense',
    'Cuban peso': 'Peso cubano',
    'Cuban convertible peso': 'Peso convertible cubano',
    'Czech koruna': 'Corona checa',
    'Danish krone': 'Corona danesa',
    'Ethiopian birr': 'Birr etíope',
    'Gambian dalasi': 'Dalasi gambiano',
    'Georgian lari': 'Lari georgiano',
    'Ghanaian cedi': 'Cedi ghanés',
    'Guatemalan quetzal': 'Quetzal guatemalteco',
    'Haitian gourde': 'Gourde haitiano',
    'Hungarian forint': 'Florín húngaro',
    'Indonesian rupiah': 'Rupia indonesia',
    'Iranian rial': 'Rial iraní',
    'Israeli new shekel': 'Nuevo séquel israelí',
    'Japanese yen': 'Yen japonés',
    'Kazakhstani tenge': 'Tenge kazajo',
    'Kenyan shilling': 'Chelín keniano',
    'Kyrgyzstani som': 'Som kirguís',
    'Laotian kip': 'Kip laosiano',
    'Lesotho loti': 'Loti lesoto',
    'Macedonian denar': 'Dinar macedonio',
    'Malagasy ariary': 'Ariary malgache',
    'Malaysian ringgit': 'Ringgit malayo',
    'Mauritanian ouguiya': 'Ouguiya mauritana',
    'Mexican peso': 'Peso mexicano',
    'Moldovan leu': 'Leu moldavo',
    'Mongolian tögrög': 'Tögrög mongol',
    'Moroccan dirham': 'Dírham marroquí',
    'Mozambican metical': 'Metical mozambiqueño',
    'Myanmar kyat': 'Kyat birmano',
    'Namibian dollar': 'Dólar namibio',
    'Nigerian naira': 'Naira nigeriana',
    'North Korean won': 'Won norcoreano',
    'Norwegian krone': 'Corona noruega',
    'Omani rial': 'Rial omaní',
    'Pakistani rupee': 'Rupia paquistaní',
    'Panamanian balboa': 'Balboa panameño',
    'Papua New Guinean kina': 'Kina papú',
    'Paraguayan guaraní': 'Guaraní paraguayo',
    'Peruvian sol': 'Sol peruano',
    'Philippine peso': 'Peso filipino',
    'Polish złoty': 'Złoty polaco',
    'Qatari rial': 'Rial catarí',
    'Romanian leu': 'Leu rumano',
    'Russian ruble': 'Rublo ruso',
    'Saudi riyal': 'Riyal saudí',
    'Somali shilling': 'Chelín somalí',
    'South African rand': 'Rand sudafricano',
    'South Korean won': 'Won surcoreano',
    'Sri Lankan rupee': 'Rupia de Sri Lanka',
    'Swazi lilangeni': 'Lilangeni suazi',
    'Swedish krona': 'Corona sueca',
    'Syrian pound': 'Libra siria',
    'Tajikistani somoni': 'Somoni tayiko',
    'Tanzanian shilling': 'Chelín tanzano',
    'Thai baht': 'Baht tailandés',
    'Turkish lira': 'Lira turca',
    'Turkmenistan manat': 'Manat turcomano',
    'UAE dirham': 'Dírham de los Emiratos Árabes Unidos',
    'Ugandan shilling': 'Chelín ugandés',
    'Ukrainian hryvnia': 'Grivna ucraniana',
    'Uruguayan peso': 'Peso uruguayo',
    'Uzbekistani soʻm': 'Som uzbeko',
    'Venezuelan bolívar soberano': 'Bolívar soberano venezolano',
    'Vietnamese đồng': 'Dong vietnamita',
    'Yemeni rial': 'Rial yemení',
    'Zambian kwacha': 'Kwacha zambiano',
    'Zimbabwean dollar': 'Dólar zimbabuense',
    'Argentine peso': 'Peso argentino',
    'Dominican peso': 'Peso dominicano',
}

def translate_currency(currency_name: str) -> str:
    """Traduce un nombre de moneda del inglés al español"""
    return CURRENCY_TRANSLATIONS.get(currency_name, currency_name)

# ========================================
# 🔧 FUNCIÓN PRINCIPAL
# ========================================

def main():
    # Buscar archivos de preguntas
    question_files = glob.glob('/home/node/.openclaw/workspace/GeoC/scripts/questions_*.json')

    total_corrected = 0
    files_corrected = 0

    for file_path in sorted(question_files):
        with open(file_path) as f:
            questions = json.load(f)
        
        corrected = False
        
        for q in questions:
            if q.get('type') == 'currency':
                original_options = q.get('options', [])
                original_correct = q.get('correctAnswer', '')
                
                # Traducir opciones
                translated_options = [translate_currency(opt) for opt in original_options]
                translated_correct = translate_currency(original_correct)
                
                # Verificar si hubo cambios
                if translated_options != original_options or translated_correct != original_correct:
                    q['options'] = translated_options
                    q['correctAnswer'] = translated_correct
                    corrected = True
                    total_corrected += 1

        if corrected:
            # Guardar archivo corregido
            with open(file_path, 'w', encoding='utf-8') as f:
                json.dump(questions, f, indent=2, ensure_ascii=False)
            
            files_corrected += 1
            print(f"✅ Corregido: {file_path.split('/')[-1]}")

    print(f"\n🎉 ¡Corrección completada!")
    print(f"📁 Archivos corregidos: {files_corrected}")
    print(f"💰 Monedas traducidas: {total_corrected}")

if __name__ == '__main__':
    main()
