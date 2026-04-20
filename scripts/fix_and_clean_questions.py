#!/usr/bin/env python3
"""Fix and clean all question data, then output a single clean JSON file."""

import json
import os
import glob
import re

# ============================================================
# TRANSLATION DICTIONARIES
# ============================================================

COUNTRY_EN_TO_ES = {
    'Spain': 'España', 'France': 'Francia', 'Germany': 'Alemania',
    'Italy': 'Italia', 'Portugal': 'Portugal', 'United Kingdom': 'Reino Unido',
    'Netherlands': 'Países Bajos', 'Belgium': 'Bélgica', 'Switzerland': 'Suiza',
    'Austria': 'Austria', 'Poland': 'Polonia', 'Czechia': 'Chequia',
    'Czech Republic': 'Chequia', 'Greece': 'Grecia', 'Turkey': 'Turquía',
    'Russia': 'Rusia', 'Sweden': 'Suecia', 'Norway': 'Noruega',
    'Denmark': 'Dinamarca', 'Finland': 'Finlandia', 'Ireland': 'Irlanda',
    'Hungary': 'Hungría', 'Romania': 'Rumanía', 'Bulgaria': 'Bulgaria',
    'Serbia': 'Serbia', 'Croatia': 'Croacia', 'Slovakia': 'Eslovaquia',
    'Slovenia': 'Eslovenia', 'Ukraine': 'Ucrania', 'Belarus': 'Bielorrusia',
    'Lithuania': 'Lituania', 'Latvia': 'Letonia', 'Estonia': 'Estonia',
    'Iceland': 'Islandia', 'Albania': 'Albania', 'North Macedonia': 'Macedonia del Norte',
    'Moldova': 'Moldavia', 'Montenegro': 'Montenegro',
    'Bosnia and Herzegovina': 'Bosnia y Herzegovina', 'Luxembourg': 'Luxemburgo',
    'Malta': 'Malta', 'Cyprus': 'Chipre', 'Georgia': 'Georgia',
    'Armenia': 'Armenia', 'Azerbaijan': 'Azerbaiyán', 'Kazakhstan': 'Kazajistán',
    'Uzbekistan': 'Uzbekistán', 'Turkmenistan': 'Turkmenistán',
    'Kyrgyzstan': 'Kirguistán', 'Tajikistan': 'Tayikistán', 'Mongolia': 'Mongolia',
    'China': 'China', 'Japan': 'Japón', 'South Korea': 'Corea del Sur',
    'North Korea': 'Corea del Norte', 'Taiwan': 'Taiwán', 'Hong Kong': 'Hong Kong',
    'Macau': 'Macao', 'Philippines': 'Filipinas', 'Vietnam': 'Vietnam',
    'Thailand': 'Tailandia', 'Myanmar': 'Birmania', 'Cambodia': 'Camboya',
    'Laos': 'Laos', 'Malaysia': 'Malasia', 'Singapore': 'Singapur',
    'Indonesia': 'Indonesia', 'Brunei': 'Brunéi', 'East Timor': 'Timor Oriental',
    'India': 'India', 'Pakistan': 'Pakistán', 'Bangladesh': 'Bangladés',
    'Sri Lanka': 'Sri Lanka', 'Nepal': 'Nepal', 'Bhutan': 'Bután',
    'Maldives': 'Maldivas', 'Afghanistan': 'Afganistán', 'Iran': 'Irán',
    'Iraq': 'Irak', 'Syria': 'Siria', 'Jordan': 'Jordania', 'Lebanon': 'Líbano',
    'Israel': 'Israel', 'Palestine': 'Palestina', 'Saudi Arabia': 'Arabia Saudí',
    'United Arab Emirates': 'Emiratos Árabes Unidos', 'Kuwait': 'Kuwait',
    'Bahrain': 'Baréin', 'Qatar': 'Catar', 'Oman': 'Omán', 'Yemen': 'Yemen',
    'Egypt': 'Egipto', 'Libya': 'Libia', 'Tunisia': 'Túnez', 'Algeria': 'Argelia',
    'Morocco': 'Marruecos', 'Sudan': 'Sudán', 'South Sudan': 'Sudán del Sur',
    'Ethiopia': 'Etiopía', 'Somalia': 'Somalia', 'Kenya': 'Kenia',
    'Tanzania': 'Tanzania', 'Uganda': 'Uganda', 'Rwanda': 'Ruanda',
    'Burundi': 'Burundi', 'Djibouti': 'Yibuti', 'Eritrea': 'Eritrea',
    'Nigeria': 'Nigeria', 'Ghana': 'Ghana', 'Ivory Coast': 'Costa de Marfil',
    'Senegal': 'Senegal', 'Mali': 'Mali', 'Burkina Faso': 'Burkina Faso',
    'Niger': 'Níger', 'Chad': 'Chad', 'Cameroon': 'Camerún', 'Gabon': 'Gabón',
    'Congo': 'Congo', 'DR Congo': 'RD Congo', 'Angola': 'Angola',
    'Mozambique': 'Mozambique', 'Madagascar': 'Madagascar', 'Zambia': 'Zambia',
    'Zimbabwe': 'Zimbabue', 'Malawi': 'Malaui', 'Botswana': 'Botsuana',
    'Namibia': 'Namibia', 'South Africa': 'Sudáfrica', 'Lesotho': 'Lesoto',
    'Eswatini': 'Esuatini', 'Mauritius': 'Mauricio', 'Seychelles': 'Seychelles',
    'Comoros': 'Comoras', 'Cape Verde': 'Cabo Verde', 'Guinea': 'Guinea',
    'Sierra Leone': 'Sierra Leona', 'Liberia': 'Liberia', 'Togo': 'Togo',
    'Benin': 'Benín', 'Mauritania': 'Mauritania', 'Gambia': 'Gambia',
    'Guinea-Bissau': 'Guinea-Bisáu', 'Equatorial Guinea': 'Guinea Ecuatorial',
    'Sao Tome and Principe': 'Santo Tomé y Príncipe',
    'Central African Republic': 'República Centroafricana',
    'United States': 'Estados Unidos', 'Canada': 'Canadá', 'Mexico': 'México',
    'Guatemala': 'Guatemala', 'Belize': 'Belice', 'Honduras': 'Honduras',
    'El Salvador': 'El Salvador', 'Nicaragua': 'Nicaragua',
    'Costa Rica': 'Costa Rica', 'Panama': 'Panamá', 'Cuba': 'Cuba',
    'Jamaica': 'Jamaica', 'Haiti': 'Haití',
    'Dominican Republic': 'República Dominicana', 'Puerto Rico': 'Puerto Rico',
    'Trinidad and Tobago': 'Trinidad y Tobago', 'Barbados': 'Barbados',
    'Bahamas': 'Bahamas', 'Grenada': 'Granada', 'Saint Lucia': 'Santa Lucía',
    'Saint Vincent': 'San Vicente', 'Dominica': 'Dominica',
    'Antigua and Barbuda': 'Antigua y Barbuda',
    'Saint Kitts and Nevis': 'San Cristóbal y Nieves', 'Suriname': 'Surinam',
    'Guyana': 'Guyana', 'Colombia': 'Colombia', 'Venezuela': 'Venezuela',
    'Ecuador': 'Ecuador', 'Peru': 'Perú', 'Bolivia': 'Bolivia',
    'Paraguay': 'Paraguay', 'Chile': 'Chile', 'Argentina': 'Argentina',
    'Uruguay': 'Uruguay', 'Brazil': 'Brasil', 'Australia': 'Australia',
    'New Zealand': 'Nueva Zelanda', 'Papua New Guinea': 'Papúa Nueva Guinea',
    'Fiji': 'Fiyi', 'Solomon Islands': 'Islas Salomón', 'Vanuatu': 'Vanuatu',
    'Samoa': 'Samoa', 'Tonga': 'Tonga', 'Kiribati': 'Kiribati',
    'Tuvalu': 'Tuvalu', 'Nauru': 'Nauru', 'Palau': 'Palaos',
    'Marshall Islands': 'Islas Marshall', 'Micronesia': 'Micronesia',
    'Norfolk Island': 'Isla Norfolk',
    'Turks and Caicos Islands': 'Islas Turcas y Caicos',
    'Cayman Islands': 'Islas Caimán',
    'British Virgin Islands': 'Islas Vírgenes Británicas',
    'United States Virgin Islands': 'Islas Vírgenes de los Estados Unidos',
    'Svalbard and Jan Mayen': 'Svalbard y Jan Mayen',
    'Saint Pierre and Miquelon': 'San Pedro y Miquelón',
    'Guadeloupe': 'Guadalupe', 'Martinique': 'Martinica',
    'Faroe Islands': 'Islas Feroe', 'American Samoa': 'Samoa Americana',
    'Greenland': 'Groenlandia', 'Bermuda': 'Bermudas',
    'Northern Mariana Islands': 'Islas Marianas del Norte',
    'Caribbean Netherlands': 'Caribe Neerlandés',
    'Saint Helena': 'Santa Elena', 'Ascension': 'Ascensión',
    'Tristan da Cunha': 'Tristán de Acuña',
    'South Georgia': 'Georgia del Sur',
    'South Sandwich Islands': 'Islas Sandwich del Sur',
    'Christmas Island': 'Isla de Navidad',
    'Cocos (Keeling) Islands': 'Islas Cocos',
    'Norfolk Island': 'Isla Norfolk',
    'Niue': 'Niue', 'Tokelau': 'Tokelau', 'Cook Islands': 'Islas Cook',
    'Wallis and Futuna': 'Wallis y Futuna',
    'New Caledonia': 'Nueva Caledonia',
    'French Polynesia': 'Polinesia Francesa',
    'Pitcairn Islands': 'Islas Pitcairn',
    'Mayotte': 'Mayotte', 'Réunion': 'Reunión',
    'Aruba': 'Aruba', 'Curaçao': 'Curazao', 'Sint Maarten': 'San Martín',
    'Saint Barthélemy': 'San Bartolomé',
    'Saint Martin': 'San Martín',
    'Anguilla': 'Anguila', 'Montserrat': 'Montserrat',
    'Gibraltar': 'Gibraltar', 'Isle of Man': 'Isla de Man',
    'Jersey': 'Jersey', 'Guernsey': 'Guernsey',
    'Åland Islands': 'Islas Åland',
    'Bouvet Island': 'Isla Bouvet',
    'Heard Island and McDonald Islands': 'Isla Heard e Islas McDonald',
    'British Indian Ocean Territory': 'Territorio Británico del Océano Índico',
    'French Southern Territories': 'Tierras Australes Francesas',
    'Antarctica': 'Antártida',
    'South Ossetia': 'Osetia del Sur', 'Abkhazia': 'Abjasia',
    'Nagorno-Karabakh': 'Nagorno-Karabaj', 'Transnistria': 'Transnistria',
    'Somaliland': 'Somalilandia',
    'Northern Cyprus': 'Chipre del Norte',
    'Vatican City': 'Ciudad del Vaticano',
    'San Marino': 'San Marino', 'Monaco': 'Mónaco',
    'Liechtenstein': 'Liechtenstein',
    'Andorra': 'Andorra',
    'South Korea': 'Corea del Sur',
}

LANGUAGE_EN_TO_ES = {
    'English': 'inglés', 'Spanish': 'español', 'French': 'francés',
    'Portuguese': 'portugués', 'German': 'alemán', 'Italian': 'italiano',
    'Dutch': 'neerlandés', 'Arabic': 'árabe', 'Chinese': 'chino',
    'Japanese': 'japonés', 'Korean': 'coreano', 'Russian': 'ruso',
    'Hindi': 'hindi', 'Bengali': 'bengalí', 'Turkish': 'turco',
    'Vietnamese': 'vietnamita', 'Thai': 'tailandés', 'Polish': 'polaco',
    'Ukrainian': 'ucraniano', 'Romanian': 'rumano', 'Hungarian': 'húngaro',
    'Czech': 'checo', 'Greek': 'griego', 'Swedish': 'sueco',
    'Norwegian': 'noruego', 'Danish': 'danés', 'Finnish': 'finés',
    'Malay': 'malayo', 'Indonesian': 'indonesio', 'Filipino': 'filipino',
    'Swahili': 'suajili', 'Malagasy': 'malgache', 'Amharic': 'amárico',
    'Burmese': 'birmano', 'Nepali': 'nepalí', 'Sinhala': 'cingalés',
    'Khmer': 'jemer', 'Lao': 'lao', 'Dzongkha': 'dzongkha',
    'Tigrinya': 'tigriña', 'Somali': 'somalí', 'Kinyarwanda': 'kinyarwanda',
    'Kirundi': 'kirundi', 'Tswana': 'tswana', 'Chibarwe': 'chibarwe',
    'Catalan': 'catalán', 'Galician': 'gallego', 'Basque': 'euskera',
    'Welsh': 'galés', 'Irish': 'irlandés', 'Maltese': 'maltés',
    'Luxembourgish': 'luxemburgués', 'Icelandic': 'islandés',
    'Macedonian': 'macedonio', 'Albanian': 'albanés', 'Bulgarian': 'búlgaro',
    'Serbian': 'serbio', 'Croatian': 'croata', 'Bosnian': 'bosnio',
    'Slovenian': 'esloveno', 'Slovak': 'eslovaco', 'Latvian': 'letón',
    'Lithuanian': 'lituano', 'Estonian': 'estonio', 'Georgian': 'georgiano',
    'Armenian': 'armenio', 'Azerbaijani': 'azerí', 'Kazakh': 'kazajo',
    'Uzbek': 'uzbeko', 'Turkmen': 'turcomano', 'Kyrgyz': 'kirguís',
    'Tajik': 'tayiko', 'Mongolian': 'mongol', 'Tibetan': 'tibetano',
    'Dari': 'darí', 'Pashto': 'pastún', 'Urdu': 'urdu', 'Punjabi': 'panyabí',
    'Gujarati': 'guyaratí', 'Tamil': 'tamil', 'Telugu': 'telugu',
    'Kannada': 'canarés', 'Malayalam': 'malayalam', 'Marathi': 'maratí',
    'Odia': 'oriya', 'Assamese': 'asamés', 'Sindhi': 'sindhi',
    'Kashmiri': 'cachemiro', 'Persian (Farsi)': 'persa', 'Hebrew': 'hebreo',
    'Kurdish': 'kurdo', 'Berber': 'bereber', 'Hausa': 'hausa',
    'Yoruba': 'yoruba', 'Igbo': 'igbo', 'Zulu': 'zulú', 'Xhosa': 'xhosa',
    'Afrikaans': 'afrikáans', 'Sesotho': 'sesoto', 'Sundanese': 'sondanés',
    'Javanese': 'javanés', 'Belizean Creole': 'criollo beliceño',
    'Carolinian': 'carolinio', 'Chamorro': 'chamorro',
    'Marshallese': 'marshalés', 'Palauan': 'palauano', 'Tongan': 'tongano',
    'Samoan': 'samoano', 'Fijian': 'fiyiano', 'Bislama': 'bislama',
    'Tok Pisin': 'tok pisin', 'Solomon Islands Pijin': 'pijin',
    'Tuvaluan': 'tuvaluano', 'Kiribati': 'kiribatiano', 'Nauruan': 'nauruano',
    'Haitian Creole': 'criollo haitiano', 'Creole': 'criollo',
    'Papiamento': 'papiamento', 'Bhojpuri': 'bhojpuri',
    'Aymara': 'aimara', 'Quechua': 'quechua', 'Guaraní': 'guaraní',
    'Azerbaijani': 'azerí', 'Gikuyu': 'kikuyu',
    'Northern Sotho': 'sotho del norte', 'Southern Sotho': 'sotho del sur',
    'Tsonga': 'tsonga', 'Venda': 'venda', 'Ndebele': 'ndebele',
    'Swazi': 'suazi', 'Northern Ndebele': 'ndebele del norte',
    'Southern Ndebele': 'ndebele del sur',
}

CURRENCY_EN_TO_ES = {
    'euro': 'euro', 'United States dollar': 'dólar estadounidense',
    'British pound': 'libra esterlina', 'Japanese yen': 'yen japonés',
    'Chinese yuan': 'yuan chino', 'Swiss franc': 'franco suizo',
    'Canadian dollar': 'dólar canadiense', 'Australian dollar': 'dólar australiano',
    'New Zealand dollar': 'dólar neozelandés', 'Indian rupee': 'rupia india',
    'Pakistani rupee': 'rupia pakistaní', 'Nepalese rupee': 'rupia nepalí',
    'Sri Lankan rupee': 'rupia srilankesa', 'Bangladeshi taka': 'taka bangladeshí',
    'Indonesian rupiah': 'rupia indonesia', 'Philippine peso': 'peso filipino',
    'Mexican peso': 'peso mexicano', 'Chilean peso': 'peso chileno',
    'Colombian peso': 'peso colombiano', 'Argentine peso': 'peso argentino',
    'Cuban peso': 'peso cubano', 'Dominican peso': 'peso dominicano',
    'Brazilian real': 'real brasileño', 'South Korean won': 'won surcoreano',
    'North Korean won': 'won norcoreano', 'Thai baht': 'bat tailandés',
    'Vietnamese dong': 'dong vietnamita', 'Malaysian ringgit': 'ringgit malayo',
    'Singapore dollar': 'dólar singapurense', 'Brunei dollar': 'dólar de Brunéi',
    'Cambodian riel': 'riel camboyano', 'Lao kip': 'kip laosiano',
    'Myanmar kyat': 'kyat birmano', 'South African rand': 'rand sudafricano',
    'Nigerian naira': 'naira nigeriana', 'Ghanaian cedi': 'cedi ghanés',
    'Kenyan shilling': 'chelín keniano', 'Tanzanian shilling': 'chelín tanzano',
    'Ugandan shilling': 'chelín ugandés', 'Somali shilling': 'chelín somalí',
    'Ethiopian birr': 'birr etíope', 'Egyptian pound': 'libra egipcia',
    'Moroccan dirham': 'dirham marroquí', 'Tunisian dinar': 'dinar tunecino',
    'Algerian dinar': 'dinar argelino', 'Libyan dinar': 'dinar libio',
    'Jordanian dinar': 'dinar jordano', 'Bahraini dinar': 'dinar bahreiní',
    'Kuwaiti dinar': 'dinar kuwaití', 'Iraqi dinar': 'dinar iraquí',
    'Saudi riyal': 'riyal saudí', 'Qatari riyal': 'riyal catarí',
    'Omani rial': 'rial omaní', 'Yemeni rial': 'rial yemení',
    'Emirati dirham': 'dirham emiratí', 'Israeli new shekel': 'nuevo séquel israelí',
    'Lebanese pound': 'libra libanesa', 'Syrian pound': 'libra siria',
    'Turkish lira': 'lira turca', 'Russian ruble': 'rublo ruso',
    'Belarusian ruble': 'rublo bielorruso', 'Ukrainian hryvnia': 'grivna ucraniana',
    'Polish złoty': 'zloty polaco', 'Czech koruna': 'corona checa',
    'Hungarian forint': 'florín húngaro', 'Romanian leu': 'leu rumano',
    'Bulgarian lev': 'lev búlgaro', 'Serbian dinar': 'dinar serbio',
    'Croatian kuna': 'kuna croata', 'Macedonian denar': 'denar macedonio',
    'Albanian lek': 'lek albanés', 'Icelandic króna': 'corona islandesa',
    'Norwegian krone': 'corona noruega', 'Danish krone': 'corona danesa',
    'Swedish krona': 'corona sueca', 'Armenian dram': 'dram armenio',
    'Azerbaijani manat': 'manat azerí', 'Georgian lari': 'lari georgiano',
    'Kazakhstani tenge': 'tenge kazajo', 'Uzbekistani som': 'som uzbeko',
    'Turkmenistani manat': 'manat turcomano', 'Kyrgyzstani som': 'som kirguís',
    'Tajikistani somoni': 'somoni tayiko', 'Mongolian tugrik': 'tugrik mongol',
    'Afghan afghani': 'afgani afgano', 'Iranian rial': 'rial iraní',
    'Nepalese rupee': 'rupia nepalí', 'Maldivian rufiyaa': 'rufiyaa maldiva',
    'Bhutanese ngultrum': 'ngultrum butanés', 'Sri Lankan rupee': 'rupia srilankesa',
    'Haitian gourde': 'gourde haitiano', 'Jamaican dollar': 'dólar jamaicano',
    'Trinidad and Tobago dollar': 'dólar trinitense',
    'Barbadian dollar': 'dólar barbadense', 'Bahamian dollar': 'dólar bahameño',
    'Belize dollar': 'dólar beliceño', 'Guyanese dollar': 'dólar guyanés',
    'Surinamese dollar': 'dólar surinamés',
    'Eastern Caribbean dollar': 'dólar del Caribe Oriental',
    'Costa Rican colón': 'colón costarricense',
    'Salvadoran colón': 'colón salvadoreño',
    'Nicaraguan córdoba': 'córdoba nicaragüense',
    'Honduran lempira': 'lempira hondureño',
    'Guatemalan quetzal': 'quetzal guatemalteco',
    'Panamanian balboa': 'balboa panameño',
    'Venezuelan bolívar soberano': 'bolívar soberano venezolano',
    'Colombian peso': 'peso colombiano',
    'Peruvian sol': 'sol peruano', 'Bolivian boliviano': 'boliviano boliviano',
    'Paraguayan guaraní': 'guaraní paraguayo',
    'Uruguayan peso': 'peso uruguayo',
    'Fijian dollar': 'dólar fiyiano', 'Papua New Guinean kina': 'kina papú',
    'Solomon Islands dollar': 'dólar salomonense', 'Vanuatu vatu': 'vatu vanuatuense',
    'Samoan tala': 'tala samoano', 'Tongan paʻanga': "pa'anga tongano",
    'Zambian kwacha': 'kwacha zambiano', 'Malawian kwacha': 'kwacha malauí',
    'Zimbabwean dollar': 'dólar zimbabuense',
    'Botswana pula': 'pula botsuano', 'Lesotho loti': 'loti lesotense',
    'Eswatini lilangeni': 'lilangeni suazi',
    'Namibian dollar': 'dólar namibio', 'Mozambican metical': 'metical mozambiqueño',
    'Angolan kwanza': 'kwanza angoleño', 'São Tomé and Príncipe dobra': 'dobra santotomense',
    'Cape Verdean escudo': 'escudo caboverdiano',
    'Guinean franc': 'franco guineano', 'Sierra Leonean leone': 'leone sierraleonés',
    'Liberian dollar': 'dólar liberiano', 'Burkinabé CFA franc': 'franco CFA burkinés',
    'Mauritanian ouguiya': 'ouguiya mauritano', 'Malian CFA franc': 'franco CFA malí',
    'West African CFA franc': 'franco CFA de África Occidental',
    'Central African CFA franc': 'franco CFA de África Central',
    'Comorian franc': 'franco comorense', 'Mauritian rupee': 'rupia mauriciana',
    'Seychellois rupee': 'rupia seychellense',
    'Djiboutian franc': 'franco yibutiano', 'Eritrean nakfa': 'nakfa eritreo',
    'Rwandan franc': 'franco ruandés', 'Burundian franc': 'franco burundés',
    'South Sudanese pound': 'libra sursudanesa', 'Sudanese pound': 'libra sudanesa',
    'Chadian CFA franc': 'franco CFA chadiano',
    'Congolese franc': 'franco congoleño',
    'New Taiwan dollar': 'nuevo dólar taiwanés',
    'Hong Kong dollar': 'dólar hongkonés', 'Macanese pataca': 'pataca macaense',
    'Bermudian dollar': 'dólar bermudeño',
    'Cayman Islands dollar': 'dólar caimanés',
    'Faroese króna': 'corona feroesa',
    'Greenlandic króna': 'corona groenlandesa',
    'Venezuelan bolívar soberano': 'bolívar venezolano',
    'Panamanian balboa': 'balboa panameño',
    'Ugandan shilling': 'chelín ugandés',
    'Zambian kwacha': 'kwacha zambiano',
    'Liberian dollar': 'dólar liberiano',
    'South Sudanese pound': 'libra sursudanesa',
    'Sudanese pound': 'libra sudanesa',
    'Costa Rican colón': 'colón costarricense',
    'Venezuelan bolívar soberano': 'bolívar venezolano',
    'Colombian peso': 'peso colombiano',
    'Ghanaian cedi': 'cedi ghanés',
}

# Countries where capital = country name (these are valid edge cases)
# Singapur, Luxemburgo, Mónaco, Vaticano, San Marino, Yibuti
VALID_CAPITAL_EQUALS_COUNTRY = {
    'sg': 'Singapur',  # Singapore city is the capital of Singapore
    'lu': 'Luxemburgo',  # Luxembourg city is the capital of Luxembourg
    'mc': 'Mónaco',  # Monaco is the capital of Monaco
    'dj': 'Yibuti',  # Djibouti city is the capital of Djibouti
    'tn': 'Túnez',  # Tunis is the capital of Tunisia (but in ES both are "Túnez")
}

# Maps for type-answer questions (no options)
SILHOUETTE_COUNTRIES = {
    'ar', 'au', 'br', 'ca', 'cn', 'de', 'eg', 'es', 'fr', 'gb',
    'in', 'it', 'jp', 'kr', 'mx', 'ng', 'ru', 'sa', 'us', 'za',
    'tr', 'co', 'pe', 'cl', 'ar', 'se', 'no', 'fi', 'pl', 'ua',
}


def load_all_questions():
    """Load all questions from all JSON files, deduplicate by ID."""
    all_questions = {}
    files = glob.glob('scripts/questions*.json')
    files = [f for f in files if 'muestra' not in f]
    
    stats = {'files': 0, 'loaded': 0, 'duplicates': 0}
    
    for filepath in sorted(files):
        try:
            with open(filepath, 'r', encoding='utf-8') as f:
                questions = json.load(f)
                stats['files'] += 1
                for q in questions:
                    qid = q.get('id', '')
                    stats['loaded'] += 1
                    if qid not in all_questions:
                        q['_source'] = os.path.basename(filepath)
                        all_questions[qid] = q
                    else:
                        stats['duplicates'] += 1
        except Exception as e:
            print(f"Error loading {filepath}: {e}")
    
    print(f"Loaded {stats['loaded']} questions from {stats['files']} files")
    print(f"After dedup: {len(all_questions)} unique ({stats['duplicates']} duplicates removed)")
    return list(all_questions.values())


def fix_country_in_text(text):
    """Replace English country names with Spanish in question text."""
    # Sort by length (longest first) to avoid partial matches
    for en, es in sorted(COUNTRY_EN_TO_ES.items(), key=lambda x: -len(x[0])):
        if en in text:
            text = text.replace(en, es)
    return text


def fix_language_name(name):
    """Translate language name from English to Spanish."""
    name_lower = name.strip()
    # Case-insensitive lookup
    for en, es in LANGUAGE_EN_TO_ES.items():
        if en.lower() == name_lower.lower():
            return es
    return name  # Return as-is if not found


def fix_currency_name(name):
    """Translate currency name from English to Spanish."""
    name_lower = name.strip()
    for en, es in CURRENCY_EN_TO_ES.items():
        if en.lower() == name_lower.lower():
            return es
    return name


def fix_spanglish(text):
    """Fix Spanglish in question text."""
    text = text.replace('¿Qué currency tienen en', '¿Qué moneda tienen en')
    text = text.replace('¿Qué currency usan en', '¿Qué moneda usan en')
    return text


def fix_question(q):
    """Apply all fixes to a single question. Returns (fixed_question, changes_list)."""
    changes = []
    qtype = q.get('type', '')
    
    # 1. Fix questionText - English country names
    qtext = q.get('questionText', '')
    if qtext:
        new_text = fix_country_in_text(qtext)
        new_text = fix_spanglish(new_text)
        if new_text != qtext:
            changes.append(f"questionText: '{qtext}' → '{new_text}'")
            q['questionText'] = new_text
    
    # 2. Fix language answers
    if qtype == 'language':
        # Fix correctAnswer
        old_answer = q.get('correctAnswer', '')
        new_answer = fix_language_name(old_answer)
        if new_answer != old_answer:
            changes.append(f"correctAnswer: '{old_answer}' → '{new_answer}'")
            q['correctAnswer'] = new_answer
        
        # Fix options
        new_options = []
        for opt in q.get('options', []):
            new_opt = fix_language_name(opt)
            new_options.append(new_opt)
        if new_options != q.get('options', []):
            old_opts = q['options'][:]
            q['options'] = new_options
            changes.append(f"options: {old_opts} → {new_options}")
    
    # 3. Fix currency answers
    if qtype == 'currency':
        old_answer = q.get('correctAnswer', '')
        new_answer = fix_currency_name(old_answer)
        if new_answer != old_answer:
            changes.append(f"correctAnswer: '{old_answer}' → '{new_answer}'")
            q['correctAnswer'] = new_answer
        
        new_options = []
        for opt in q.get('options', []):
            new_opt = fix_currency_name(opt)
            new_options.append(new_opt)
        if new_options != q.get('options', []):
            old_opts = q['options'][:]
            q['options'] = new_options
            changes.append(f"options fixed")
    
    # 4. Fix capital = country name (remove invalid ones)
    if qtype == 'capital':
        answer = q.get('correctAnswer', '')
        country_code = q.get('extraData', {}).get('countryCode', '')
        
        # Check if answer = country name in extraData
        country_name = q.get('extraData', {}).get('countryName', '')
        if answer == country_name and country_code not in VALID_CAPITAL_EQUALS_COUNTRY:
            changes.append(f"INVALID CAPITAL: answer='{answer}' = country name, MARKING FOR REMOVAL")
            q['_remove'] = True
    
    # 5. Fix countryName in extraData to Spanish
    extra = q.get('extraData', {})
    if extra and 'countryName' in extra:
        old_cn = extra['countryName']
        new_cn = fix_country_in_text(old_cn)
        if new_cn != old_cn:
            extra['countryName'] = new_cn
            changes.append(f"countryName: '{old_cn}' → '{new_cn}'")
    
    # 6. Fix region name in extraData
    if extra and 'regionSpanish' in extra:
        # Use regionSpanish if available, that's already correct
        pass
    
    # 7. Fix options that contain English country names for flag/region/border types
    if qtype in ['flag', 'region', 'border', 'capital', 'area', 'population']:
        new_options = []
        changed = False
        for opt in q.get('options', []):
            new_opt = fix_country_in_text(opt)
            new_options.append(new_opt)
            if new_opt != opt:
                changed = True
        if changed:
            q['options'] = new_options
            changes.append(f"options country names translated")
        
        # Also fix correctAnswer
        old_ans = q.get('correctAnswer', '')
        new_ans = fix_country_in_text(old_ans)
        if new_ans != old_ans:
            q['correctAnswer'] = new_ans
            changes.append(f"correctAnswer country: '{old_ans}' → '{new_ans}'")
    
    return q, changes


def main():
    print("=" * 60)
    print("FIXING ALL QUESTIONS")
    print("=" * 60)
    
    questions = load_all_questions()
    
    total_changes = 0
    questions_removed = 0
    change_types = {}
    
    for i, q in enumerate(questions):
        q, changes = fix_question(q)
        if changes:
            total_changes += 1
            for c in changes:
                key = c.split(':')[0] if ':' in c else c
                change_types[key] = change_types.get(key, 0) + 1
        if q.get('_remove'):
            questions_removed += 1
    
    # Remove marked questions
    clean_questions = [q for q in questions if not q.get('_remove')]
    
    # Remove internal fields
    for q in clean_questions:
        q.pop('_source', None)
        q.pop('_remove', None)
    
    print(f"\nQuestions with changes: {total_changes}")
    print(f"Questions removed (bad capitals): {questions_removed}")
    print(f"Final clean questions: {len(clean_questions)}")
    
    # Count by type
    types = {}
    for q in clean_questions:
        t = q.get('type', 'unknown')
        types[t] = types.get(t, 0) + 1
    print("\nBy type (after cleaning):")
    for t, count in sorted(types.items()):
        print(f"  {t}: {count}")
    
    # Save to file
    output_path = 'scripts/questions_clean.json'
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(clean_questions, f, ensure_ascii=False, indent=2)
    
    print(f"\nSaved to {output_path}")
    print(f"File size: {os.path.getsize(output_path) / 1024:.1f} KB")
    
    # Verify no remaining issues
    print("\n" + "=" * 60)
    print("VERIFICATION")
    print("=" * 60)
    
    remaining_english = 0
    remaining_spanglish = 0
    for q in clean_questions:
        ans = q.get('correctAnswer', '')
        if ans in LANGUAGE_EN_TO_ES:
            remaining_english += 1
        for opt in q.get('options', []):
            if opt in LANGUAGE_EN_TO_ES:
                remaining_english += 1
                break
        qtext = q.get('questionText', '')
        if 'currency' in qtext.lower():
            remaining_spanglish += 1
    
    print(f"Remaining English language answers: {remaining_english}")
    print(f"Remaining Spanglish: {remaining_spanglish}")
    
    if remaining_english > 0:
        print("\nWARNING: Some English answers remain. Manual review needed.")
        count = 0
        for q in clean_questions:
            ans = q.get('correctAnswer', '')
            if ans in LANGUAGE_EN_TO_ES:
                print(f"  [{q['id']}] answer: '{ans}'")
                count += 1
                if count >= 20:
                    print("  ... (truncated)")
                    break


if __name__ == '__main__':
    main()