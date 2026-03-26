/// 🚀 Script Mejorado para Generar Preguntas de Geografía
///
/// Uso:
/// dart scripts/generate_questions_enhanced.dart [opciones]
///
/// Opciones:
/// --types=flag,capital,population,area,language,currency,border,region
/// --count=50 (preguntas por tipo)
/// --difficulty=easy,medium,hard,mixed
/// --output=questions_enhanced.json

import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:http/http.dart' as http;

void main(List<String> args) async {
  print('🚀 GeoQuiz Battle - Generador Mejorado de Preguntas\n');

  // Parse arguments
  final argsMap = _parseArguments(args);
  
  if (argsMap.containsKey('help') || args.isEmpty) {
    _printHelp();
    return;
  }

  final types = (argsMap['types'] ?? 'flag,capital,population,area').split(',');
  final countPerType = int.tryParse(argsMap['count'] ?? '25') ?? 25;
  final difficulty = argsMap['difficulty'] ?? 'mixed';
  final outputFile = argsMap['output'] ?? 'scripts/questions_enhanced.json';

  print('🎯 Configuración:');
  print('   • Tipos: ${types.join(', ')}');
  print('   • Cantidad por tipo: $countPerType');
  print('   • Dificultad: $difficulty');
  print('   • Salida: $outputFile\n');

  try {
    // Fetch country data
    final countries = await _fetchCountries();
    if (countries.isEmpty) {
      throw Exception('No se pudieron obtener datos de países');
    }

    print('✅ ${countries.length} países obtenidos de la API\n');

    final questions = <Map<String, dynamic>>[];
    int questionId = 10000; // Start with high ID to avoid conflicts

    // Generate questions for each requested type
    for (final type in types) {
      print('🔧 Generando preguntas de tipo: $type');
      
      try {
        final typeQuestions = await _generateQuestionsByType(
          type: type,
          countries: countries,
          count: countPerType,
          difficulty: difficulty,
          startId: questionId,
        );
        
        questions.addAll(typeQuestions);
        questionId += typeQuestions.length;
        print('   ✅ ${typeQuestions.length} preguntas generadas');
        
      } catch (e) {
        print('   ❌ Error generando tipo $type: $e');
      }
    }

    // Shuffle questions
    questions.shuffle();

    // Save to file
    final output = const JsonEncoder.withIndent('  ').convert(questions);
    await File(outputFile).writeAsString(output);

    print('\n🎉 ¡Generación completada!');
    _printStatistics(questions);
    print('\n💾 Guardado en: $outputFile');
    print('\n📤 Para importar a Firestore:');
    print('   dart scripts/import_questions_firestore.dart');

  } catch (e) {
    print('❌ Error: $e');
    exit(1);
  }
}

/// Parse command line arguments
Map<String, String> _parseArguments(List<String> args) {
  final map = <String, String>{};
  
  for (final arg in args) {
    if (arg.startsWith('--')) {
      final parts = arg.substring(2).split('=');
      if (parts.length == 2) {
        map[parts[0]] = parts[1];
      } else {
        map[parts[0]] = 'true';
      }
    } else if (arg == '-h' || arg == '--help') {
      map['help'] = 'true';
    }
  }
  
  return map;
}

/// Print help information
void _printHelp() {
  print('''
📚 USO:
  dart scripts/generate_questions_enhanced.dart [OPCIONES]

🎯 OPCIONES:
  --types=TIPOS      Tipos de preguntas (separados por coma)
                     Valores: flag, capital, population, area, 
                     language, currency, border, region, all
                     Default: flag,capital,population,area
  
  --count=NUM        Cantidad de preguntas por tipo (default: 25)
  --difficulty=VAL   easy, medium, hard, mixed (default: mixed)
  --output=RUTA      Archivo de salida (default: scripts/questions_enhanced.json)
  -h, --help         Muestra esta ayuda

📝 TIPOS DE PREGUNTAS:

  1. flag - Banderas
     • "¿De qué país es esta bandera?"
     • Usa imagen de bandera

  2. capital - Capitales
     • "¿Cuál es la capital de X?"
     • 4 opciones (1 correcta, 3 incorrectas)

  3. population - Población
     • "¿Qué país tiene más población?"
     • Comparación entre 2 países

  4. area - Extensión territorial
     • "¿Qué país es más extenso?"
     • Comparación entre 2 países

  5. language - Idioma oficial
     • "¿Cuál es el idioma oficial de X?"
     • Usa idiomas principales

  6. currency - Moneda
     • "¿Cuál es la moneda de X?"
     • Usa código de moneda (EUR, USD, etc.)

  7. border - Países fronterizos
     • "¿Con qué país limita X?"
     • Basado en fronteras reales

  8. region - Región/Continente
     • "¿En qué región se encuentra X?"
     • Europa, América, Asia, África, Oceanía

  9. all - Todos los tipos anteriores

💡 EJEMPLOS:
  # Generar 50 preguntas de banderas y capitales
  dart scripts/generate_questions_enhanced.dart --types=flag,capital --count=50

  # Generar todas las preguntas posibles
  dart scripts/generate_questions_enhanced.dart --types=all --count=100

  # Generar preguntas difíciles solo
  dart scripts/generate_questions_enhanced.dart --difficulty=hard

  # Especificar archivo de salida
  dart scripts/generate_questions_enhanced.dart --output=mis_preguntas.json
  ''');
}

/// Fetch countries from REST Countries API
Future<List<Map<String, dynamic>>> _fetchCountries() async {
  print('📡 Conectando a REST Countries API...');
  
  final response = await http.get(
    Uri.parse('https://restcountries.com/v3.1/all?fields=name,cca2,cca3,capital,population,area,languages,currencies,borders,region,subregion,flags'),
  );

  if (response.statusCode != 200) {
    throw Exception('Error al obtener datos: ${response.statusCode}');
  }

  final data = jsonDecode(response.body) as List;
  
  // Filter countries with required data
  return data.where((country) {
    return country['name'] != null &&
           country['name']['common'] != null &&
           country['cca2'] != null &&
           country['population'] != null &&
           country['area'] != null;
  }).map((country) => country as Map<String, dynamic>).toList();
}

/// Generate questions by type
Future<List<Map<String, dynamic>>> _generateQuestionsByType({
  required String type,
  required List<Map<String, dynamic>> countries,
  required int count,
  required String difficulty,
  required int startId,
}) async {
  switch (type) {
    case 'flag':
      return _generateFlagQuestions(countries, count: count, startId: startId);
    case 'capital':
      return _generateCapitalQuestions(countries, count: count, startId: startId);
    case 'population':
      return _generatePopulationQuestions(countries, count: count, startId: startId);
    case 'area':
      return _generateAreaQuestions(countries, count: count, startId: startId);
    case 'language':
      return _generateLanguageQuestions(countries, count: count, startId: startId);
    case 'currency':
      return _generateCurrencyQuestions(countries, count: count, startId: startId);
    case 'border':
      return _generateBorderQuestions(countries, count: count, startId: startId);
    case 'region':
      return _generateRegionQuestions(countries, count: count, startId: startId);
    case 'all':
      final allQuestions = <Map<String, dynamic>>[];
      final allTypes = ['flag', 'capital', 'population', 'area', 'language', 'currency', 'border', 'region'];
      int currentId = startId;
      
      for (final t in allTypes) {
        final questions = await _generateQuestionsByType(
          type: t,
          countries: countries,
          count: count ~/ allTypes.length,
          difficulty: difficulty,
          startId: currentId,
        );
        allQuestions.addAll(questions);
        currentId += questions.length;
      }
      return allQuestions;
    default:
      throw Exception('Tipo de pregunta no soportado: $type');
  }
}

/// Generate flag questions
List<Map<String, dynamic>> _generateFlagQuestions(
  List<Map<String, dynamic>> countries, {
  required int count,
  required int startId,
}) {
  final questions = <Map<String, dynamic>>[];
  final random = Random();
  final usedCountries = <String>{};

  // Filter countries with flags
  final flagCountries = countries.where((c) => 
    c['flags'] != null && c['flags']['png'] != null
  ).toList();

  for (int i = 0; i < count && i < flagCountries.length; i++) {
    // Find unused country
    Map<String, dynamic>? country;
    int attempts = 0;
    
    while (country == null && attempts < 100) {
      final index = random.nextInt(flagCountries.length);
      final candidate = flagCountries[index];
      final code = candidate['cca2'];
      
      if (!usedCountries.contains(code)) {
        country = candidate;
        usedCountries.add(code);
      }
      attempts++;
    }
    
    if (country == null) continue;

    final name = country['name']['common'];
    final code = country['cca2'];
    final flagUrl = country['flags']['png'];
    
    // Generate wrong options
    final wrongOptions = _generateWrongOptions(
      countries: countries,
      correctAnswer: name,
      count: 3,
      exclude: usedCountries,
    );

    final allOptions = [name, ...wrongOptions]..shuffle(random);

    // Determine difficulty
    final questionDifficulty = _determineDifficulty(country, 'flag');

    questions.add({
      'id': 'flag_${startId + i}',
      'type': 'flag',
      'difficulty': questionDifficulty,
      'questionText': '¿De qué país es esta bandera?',
      'correctAnswer': name,
      'options': allOptions,
      'imageUrl': flagUrl,
      'extraData': {
        'countryCode': code.toLowerCase(),
        'countryName': name,
      },
    });
  }

  return questions;
}

/// Generate capital questions
List<Map<String, dynamic>> _generateCapitalQuestions(
  List<Map<String, dynamic>> countries, {
  required int count,
  required int startId,
}) {
  final questions = <Map<String, dynamic>>[];
  final random = Random();
  final usedCountries = <String>{};

  // Filter countries with capitals
  final capitalCountries = countries.where((c) => 
    c['capital'] != null && 
    (c['capital'] as List).isNotEmpty &&
    c['capital'][0] != null
  ).toList();

  for (int i = 0; i < count && i < capitalCountries.length; i++) {
    // Find unused country
    Map<String, dynamic>? country;
    int attempts = 0;
    
    while (country == null && attempts < 100) {
      final index = random.nextInt(capitalCountries.length);
      final candidate = capitalCountries[index];
      final code = candidate['cca2'];
      
      if (!usedCountries.contains(code)) {
        country = candidate;
        usedCountries.add(code);
      }
      attempts++;
    }
    
    if (country == null) continue;

    final name = country['name']['common'];
    final capital = (country['capital'] as List)[0];
    
    // Generate wrong options (other capitals)
    final wrongOptions = _generateWrongCapitals(
      countries: countries,
      correctCapital: capital,
      count: 3,
    );

    final allOptions = [capital, ...wrongOptions]..shuffle(random);

    // Determine difficulty
    final questionDifficulty = _determineDifficulty(country, 'capital');

    questions.add({
      'id': 'capital_${startId + i}',
      'type': 'capital',
      'difficulty': questionDifficulty,
      'questionText': '¿Cuál es la capital de $name?',
      'correctAnswer': capital,
      'options': allOptions,
      'extraData': {
        'countryCode': country['cca2'].toLowerCase(),
        'countryName': name,
      },
    });
  }

  return questions;
}

/// Generate population comparison questions
List<Map<String, dynamic>> _generatePopulationQuestions(
  List<Map<String, dynamic>> countries, {
  required int count,
  required int startId,
}) {
  final questions = <Map<String, dynamic>>[];
  final random = Random();
  final usedPairs = <String>{};

  // Sort by population for meaningful comparisons
  final sortedCountries = List<Map<String, dynamic>>.from(countries)
    ..sort((a, b) => (b['population'] as int).compareTo(a['population'] as int));

  for (int i = 0; i < count; i++) {
    // Find two countries with significant population difference
    int attempts = 0;
    Map<String, dynamic>? country1, country2;
    
    while ((country1 == null || country2 == null) && attempts < 100) {
      final idx1 = random.nextInt(sortedCountries.length ~/ 2); // First half (more populated)
      final idx2 = sortedCountries.length ~/ 2 + random.nextInt(sortedCountries.length ~/ 2); // Second half (less populated)
      
      final c1 = sortedCountries[idx1];
      final c2 = sortedCountries[idx2];
      
      final pairKey = '${c1['cca2']}-${c2['cca2']}';
      final reverseKey = '${c2['cca2']}-${c1['cca2']}';
      
      if (!usedPairs.contains(pairKey) && !usedPairs.contains(reverseKey)) {
        country1 = c1;
        country2 = c2;
        usedPairs.add(pairKey);
      }
      attempts++;
    }
    
    if (country1 == null || country2 == null) continue;

    final name1 = country1['name']['common'];
    final name2 = country2['name']['common'];
    final pop1 = country1['population'] as int;
    final pop2 = country2['population'] as int;

    // Determine which has larger population
    final correctAnswer = pop1 > pop2 ? name1 : name2;
    final questionText = '¿Qué país tiene más población?';

    // Determine difficulty
    final diff1 = _determineDifficulty(country1, 'population');
    final diff2 = _determineDifficulty(country2, 'population');
    final questionDifficulty = _combineDifficulty(diff1, diff2);

    questions.add({
      'id': 'population_${startId + i}',
      'type': 'population',
      'difficulty': questionDifficulty,
      'questionText': questionText,
      'correctAnswer': correctAnswer,
      'options': [name1, name2],
      'extraData': {
        'countries': [name1, name2],
        'population1': pop1,
        'population2': pop2,
      },
    });
  }

  return questions;
}

/// Generate area comparison questions
List<Map<String, dynamic>> _generateAreaQuestions(
  List<Map<String, dynamic>> countries, {
  required int count,
  required int startId,
}) {
  final questions = <Map<String, dynamic>>[];
  final random = Random();
  final usedPairs = <String>{};

  // Sort by area for meaningful comparisons
  final sortedCountries = List<Map<String, dynamic>>.from(countries)
    ..sort((a, b) => (b['area'] as double).compareTo(a['area'] as double));

  for (int i = 0; i < count; i++) {
    // Find two countries with significant area difference
    int attempts = 0;
    Map<String, dynamic>? country1, country2;
    
    while ((country1 == null || country2 == null) && attempts < 100) {
      final idx1 = random.nextInt(sortedCountries.length ~/ 2); // First half (larger)
      final idx2 = sortedCountries.length ~/ 2 + random.nextInt(sortedCountries.length ~/ 2); // Second half (smaller)
      
      final c1 = sortedCountries[idx1];
      final c2 = sortedCountries[idx2];
      
      final pairKey = '${c1['cca2']}-${c2['cca2']}';
      final reverseKey = '${c2['cca2']}-${c1['cca2']}';
      
      if (!usedPairs.contains(pairKey) && !usedPairs.contains(reverseKey)) {
        country1 = c1;
        country2 = c2;
        usedPairs.add(pairKey);
      }
      attempts++;
    }
    
    if (country1 == null || country2 == null) continue;

    final name1 = country1['name']['common'];
    final name2 = country2['name']['common'];
    final area1 = country1['area'] as double;
    final area2 = country2['area'] as double;

    // Determine which is larger
    final correctAnswer = area1 > area2 ? name1 : name2;
    final questionText = '¿Qué país es más extenso?';

    // Determine difficulty
    final diff1 = _determineDifficulty(country1, 'area');
    final diff2 = _determineDifficulty(country2, 'area');
    final questionDifficulty = _combineDifficulty(diff1, diff2);

    questions.add({
      'id': 'area_${startId + i}',
      'type': 'area',
      'difficulty': questionDifficulty,
      'questionText': questionText,
      'correctAnswer': correctAnswer,
      'options': [name1, name2],
      'extraData': {
        'countries': [name1, name2],
        'area1': area1,
        'area2': area2,
      },
    });
  }

  return questions;
}

/// Generate language questions
List<Map<String, dynamic>> _generateLanguageQuestions(
  List<Map<String, dynamic>> countries, {
  required int count,
  required int startId,
}) {
  final questions = <Map<String, dynamic>>[];
  final random = Random();
  final usedCountries = <String>{};

  // Filter countries with language data
  final languageCountries = countries.where((c) => 
    c['languages'] != null && 
    (c['languages'] as Map).isNotEmpty
  ).toList();

  for (int i = 0; i < count && i < languageCountries.length; i++) {
    // Find unused country
    Map<String, dynamic>? country;
    int attempts = 0;
    
    while (country == null && attempts < 100) {
      final index = random.nextInt(languageCountries.length);
      final candidate = languageCountries[index];
      final code = candidate['cca2'];
      
      if (!usedCountries.contains(code)) {
        country = candidate;
        usedCountries.add(code);
      }
      attempts++;
    }
    
    if (country == null) continue;

    final name = country['name']['common'];
    final languages = country['languages'] as Map<String, dynamic>;
    
    // Get primary language (first one)
    final languageEntry = languages.entries.first;
    final languageName = languageEntry.value;
    
    // Generate wrong options (other languages)
    final wrongOptions = _generateWrongLanguages(
      countries: countries,
      correctLanguage: languageName,
      count: 3,
    );

    final allOptions = [languageName, ...wrongOptions]..shuffle(random);

    // Determine difficulty
    final questionDifficulty = _determineDifficulty(country, 'language');

    questions.add({
      'id': 'language_${startId + i}',
      'type': 'language',
      'difficulty': questionDifficulty,
      'questionText': '¿Cuál es el idioma oficial de $name?',
      'correctAnswer': languageName,
      'options': allOptions,
      'extraData': {
        'countryCode': country['cca2'].toLowerCase(),
        'countryName': name,
        'languageCode': languageEntry.key,
      },
    });
  }

  return questions;
}

/// Generate currency questions
List<Map<String, dynamic>> _generateCurrencyQuestions(
  List<Map<String, dynamic>> countries, {
  required int count,
  required int startId,
}) {
  final questions = <Map<String, dynamic>>[];
  final random = Random();
  final usedCountries = <String>{};

  // Filter countries with currency data
  final currencyCountries = countries.where((c) => 
    c['currencies'] != null && 
    (c['currencies'] as Map).isNotEmpty
  ).toList();

  for (int i = 0; i < count && i < currencyCountries.length; i++) {
    // Find unused country
    Map<String, dynamic>? country;
    int attempts = 0;
    
    while (country == null && attempts < 100) {
      final index = random.nextInt(currencyCountries.length);
      final candidate = currencyCountries[index];
      final code = candidate['cca2'];
      
      if (!usedCountries.contains(code)) {
        country = candidate;
        usedCountries.add(code);
      }
      attempts++;
    }
    
    if (country == null) continue;

    final name = country['name']['common'];
    final currencies = country['currencies'] as Map<String, dynamic>;
    
    // Get primary currency (first one)
    final currencyEntry = currencies.entries.first;
    final currencyData = currencyEntry.value as Map<String, dynamic>;
    final currencyName = currencyData['name'];
    
    // Generate wrong options (other currencies)
    final wrongOptions = _generateWrongCurrencies(
      countries: countries,
      correctCurrency: currencyName,
      count: 3,
    );

    final allOptions = [currencyName, ...wrongOptions]..shuffle(random);

    // Determine difficulty
    final questionDifficulty = _determineDifficulty(country, 'currency');

    questions.add({
      'id': 'currency_${startId + i}',
      'type': 'currency',
      'difficulty': questionDifficulty,
      'questionText': '¿Cuál es la moneda de $name?',
      'correctAnswer': currencyName,
      'options': allOptions,
      'extraData': {
        'countryCode': country['cca2'].toLowerCase(),
        'countryName': name,
        'currencyCode': currencyEntry.key,
      },
    });
  }

  return questions;
}

/// Generate border questions
List<Map<String, dynamic>> _generateBorderQuestions(
  List<Map<String, dynamic>> countries, {
  required int count,
  required int startId,
}) {
  final questions = <Map<String, dynamic>>[];
  final random = Random();
  final usedCountries = <String>{};

  // Filter countries with border data
  final borderCountries = countries.where((c) => 
    c['borders'] != null && 
    (c['borders'] as List).isNotEmpty
  ).toList();

  for (int i = 0; i < count && i < borderCountries.length; i++) {
    // Find unused country
    Map<String, dynamic>? country;
    int attempts = 0;
    
    while (country == null && attempts < 100) {
      final index = random.nextInt(borderCountries.length);
      final candidate = borderCountries[index];
      final code = candidate['cca2'];
      
      if (!usedCountries.contains(code)) {
        country = candidate;
        usedCountries.add(code);
      }
      attempts++;
    }
    
    if (country == null) continue;

    final name = country['name']['common'];
    final borders = country['borders'] as List<dynamic>;
    
    // Find a bordering country that exists in our data
    final borderCodes = borders.map((b) => b.toString()).toList();
    final borderingCountries = countries.where((c) => 
      borderCodes.contains(c['cca3']) || borderCodes.contains(c['cca2'])
    ).toList();

    if (borderingCountries.isEmpty) continue;

    // Select a random bordering country
    final borderCountry = borderingCountries[random.nextInt(borderingCountries.length)];
    final borderName = borderCountry['name']['common'];
    
    // Generate wrong options (non-bordering countries)
    final wrongOptions = _generateWrongOptions(
      countries: countries,
      correctAnswer: borderName,
      count: 3,
      exclude: {country['cca2'], borderCountry['cca2']},
    );

    final allOptions = [borderName, ...wrongOptions]..shuffle(random);

    // Determine difficulty
    final questionDifficulty = _determineDifficulty(country, 'border');

    questions.add({
      'id': 'border_${startId + i}',
      'type': 'border',
      'difficulty': questionDifficulty,
      'questionText': '¿Con qué país limita $name?',
      'correctAnswer': borderName,
      'options': allOptions,
      'extraData': {
        'countryCode': country['cca2'].toLowerCase(),
        'countryName': name,
        'borderCountryCode': borderCountry['cca2'].toLowerCase(),
      },
    });
  }

  return questions;
}

/// Generate region questions
List<Map<String, dynamic>> _generateRegionQuestions(
  List<Map<String, dynamic>> countries, {
  required int count,
  required int startId,
}) {
  final questions = <Map<String, dynamic>>[];
  final random = Random();
  final usedCountries = <String>{};

  // Filter countries with region data
  final regionCountries = countries.where((c) => 
    c['region'] != null && c['region'].toString().isNotEmpty
  ).toList();

  // Define region translations
  final regionTranslations = {
    'Europe': 'Europa',
    'Americas': 'América',
    'Asia': 'Asia',
    'Africa': 'África',
    'Oceania': 'Oceanía',
    'Antarctic': 'Antártida',
  };

  for (int i = 0; i < count && i < regionCountries.length; i++) {
    // Find unused country
    Map<String, dynamic>? country;
    int attempts = 0;
    
    while (country == null && attempts < 100) {
      final index = random.nextInt(regionCountries.length);
      final candidate = regionCountries[index];
      final code = candidate['cca2'];
      
      if (!usedCountries.contains(code)) {
        country = candidate;
        usedCountries.add(code);
      }
      attempts++;
    }
    
    if (country == null) continue;

    final name = country['name']['common'];
    final region = country['region'].toString();
    final regionSpanish = regionTranslations[region] ?? region;
    
    // Generate wrong options (other regions)
    final wrongOptions = _generateWrongRegions(
      regions: regionTranslations.values.toList(),
      correctRegion: regionSpanish,
      count: 3,
    );

    final allOptions = [regionSpanish, ...wrongOptions]..shuffle(random);

    // Determine difficulty
    final questionDifficulty = _determineDifficulty(country, 'region');

    questions.add({
      'id': 'region_${startId + i}',
      'type': 'region',
      'difficulty': questionDifficulty,
      'questionText': '¿En qué región se encuentra $name?',
      'correctAnswer': regionSpanish,
      'options': allOptions,
      'extraData': {
        'countryCode': country['cca2'].toLowerCase(),
        'countryName': name,
        'region': region,
        'regionSpanish': regionSpanish,
      },
    });
  }

  return questions;
}
/// Generate wrong options for country questions
List<String> _generateWrongOptions({
  required List<Map<String, dynamic>> countries,
  required String correctAnswer,
  required int count,
  Set<String>? exclude,
}) {
  final wrongOptions = <String>[];
  final random = Random();
  final excluded = exclude ?? <String>{};
  excluded.add(correctAnswer);

  while (wrongOptions.length < count) {
    final index = random.nextInt(countries.length);
    final country = countries[index];
    final name = country['name']['common'].toString();
    
    if (!excluded.contains(name)) {
      wrongOptions.add(name);
      excluded.add(name);
    }
  }

  return wrongOptions;
}

/// Generate wrong capital options
List<String> _generateWrongCapitals({
  required List<Map<String, dynamic>> countries,
  required String correctCapital,
  required int count,
}) {
  final wrongOptions = <String>[];
  final random = Random();
  final excluded = <String>{correctCapital};

  while (wrongOptions.length < count) {
    final index = random.nextInt(countries.length);
    final country = countries[index];
    final capital = country['capital'] != null && (country['capital'] as List).isNotEmpty
        ? (country['capital'] as List)[0].toString()
        : null;
    
    if (capital != null && !excluded.contains(capital)) {
      wrongOptions.add(capital);
      excluded.add(capital);
    }
  }

  return wrongOptions;
}

/// Generate wrong language options
List<String> _generateWrongLanguages({
  required List<Map<String, dynamic>> countries,
  required String correctLanguage,
  required int count,
}) {
  final wrongOptions = <String>[];
  final random = Random();
  final excluded = <String>{correctLanguage};

  while (wrongOptions.length < count) {
    final index = random.nextInt(countries.length);
    final country = countries[index];
    final languages = country['languages'] as Map<String, dynamic>?;
    
    if (languages != null && languages.isNotEmpty) {
      final language = languages.entries.first.value.toString();
      if (!excluded.contains(language)) {
        wrongOptions.add(language);
        excluded.add(language);
      }
    }
  }

  return wrongOptions;
}

/// Generate wrong currency options
List<String> _generateWrongCurrencies({
  required List<Map<String, dynamic>> countries,
  required String correctCurrency,
  required int count,
}) {
  final wrongOptions = <String>[];
  final random = Random();
  final excluded = <String>{correctCurrency};

  while (wrongOptions.length < count) {
    final index = random.nextInt(countries.length);
    final country = countries[index];
    final currencies = country['currencies'] as Map<String, dynamic>?;
    
    if (currencies != null && currencies.isNotEmpty) {
      final currencyData = currencies.entries.first.value as Map<String, dynamic>;
      final currencyName = currencyData['name'].toString();
      if (!excluded.contains(currencyName)) {
        wrongOptions.add(currencyName);
        excluded.add(currencyName);
      }
    }
  }

  return wrongOptions;
}

/// Generate wrong region options
List<String> _generateWrongRegions({
  required List<String> regions,
  required String correctRegion,
  required int count,
}) {
  final wrongOptions = <String>[];
  final random = Random();
  final excluded = <String>{correctRegion};

  while (wrongOptions.length < count) {
    final index = random.nextInt(regions.length);
    final region = regions[index];
    
    if (!excluded.contains(region)) {
      wrongOptions.add(region);
      excluded.add(region);
    }
  }

  return wrongOptions;
}

/// Determine question difficulty based on country and question type
String _determineDifficulty(Map<String, dynamic> country, String type) {
  final name = country['name']['common'].toString().toLowerCase();
  final population = country['population'] as int? ?? 0;
  final area = country['area'] as double? ?? 0.0;
  final region = country['region']?.toString().toLowerCase() ?? '';

  // Common well-known countries
  final wellKnownCountries = {
    'spain', 'france', 'germany', 'italy', 'united kingdom', 'united states',
    'canada', 'mexico', 'brazil', 'argentina', 'china', 'japan', 'india',
    'australia', 'russia', 'portugal', 'netherlands', 'belgium', 'switzerland'
  };

  // Common well-known capitals
  final wellKnownCapitals = {
    'madrid', 'paris', 'london', 'berlin', 'rome', 'washington', 'ottawa',
    'mexico city', 'brasilia', 'buenos aires', 'beijing', 'tokyo', 'new delhi',
    'canberra', 'moscow', 'lisbon', 'amsterdam', 'brussels', 'bern'
  };

  // Determine difficulty based on type
  switch (type) {
    case 'flag':
    case 'capital':
      if (wellKnownCountries.contains(name) || 
          (type == 'capital' && wellKnownCapitals.contains(name))) {
        return 'easy';
      } else if (population > 10000000 || area > 1000000) {
        return 'medium';
      } else {
        return 'hard';
      }
    
    case 'population':
    case 'area':
      if (population > 100000000 || area > 5000000) {
        return 'easy';
      } else if (population > 10000000 || area > 500000) {
        return 'medium';
      } else {
        return 'hard';
      }
    
    case 'language':
    case 'currency':
      if (wellKnownCountries.contains(name)) {
        return 'easy';
      } else if (region == 'europe' || region == 'americas') {
        return 'medium';
      } else {
        return 'hard';
      }
    
    case 'border':
    case 'region':
      if (wellKnownCountries.contains(name)) {
        return 'easy';
      } else if (population > 50000000) {
        return 'medium';
      } else {
        return 'hard';
      }
    
    default:
      return 'medium';
  }
}

/// Combine difficulties from two countries
String _combineDifficulty(String diff1, String diff2) {
  final difficulties = {'easy': 1, 'medium': 2, 'hard': 3};
  final avg = (difficulties[diff1]! + difficulties[diff2]!) / 2;
  
  if (avg <= 1.5) return 'easy';
  if (avg <= 2.5) return 'medium';
  return 'hard';
}

/// Print statistics about generated questions
void _printStatistics(List<Map<String, dynamic>> questions) {
  final byType = <String, int>{};
  final byDifficulty = <String, int>{};
  
  for (final q in questions) {
    final type = q['type'].toString();
    final difficulty = q['difficulty'].toString();
    
    byType[type] = (byType[type] ?? 0) + 1;
    byDifficulty[difficulty] = (byDifficulty[difficulty] ?? 0) + 1;
  }
  
  print('📊 Estadísticas de preguntas generadas:');
  print('   • Total: ${questions.length} preguntas');
  
  print('\n📊 Por tipo:');
  byType.forEach((type, count) {
    print('   • $type: $count');
  });
  
  print('\n📊 Por dificultad:');
  byDifficulty.forEach((difficulty, count) {
    print('   • $difficulty: $count');
  });
  
  // Calculate average options per question
  final avgOptions = questions.fold(0, (sum, q) => sum + (q['options'] as List).length) / questions.length;
  print('\n📊 Promedio de opciones por pregunta: ${avgOptions.toStringAsFixed(1)}');
  
  // Count questions with images
  final withImages = questions.where((q) => q['imageUrl'] != null).length;
  print('📊 Con imágenes: $withImages/${questions.length} (${(withImages/questions.length*100).toStringAsFixed(1)}%)');
}