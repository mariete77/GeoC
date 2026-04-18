/// 🎨 Generador de Preguntas con Variedad de Formulaciones
///
/// Este script genera preguntas geográficas usando MÚLTIPLES plantillas
/// para evitar que se sientan repetitivas.
///
/// Uso:
/// dart scripts/generate_varied_questions.dart [opciones]

import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:http/http.dart' as http;

// ========================================
// 📋 PLANTILLAS DE PREGUNTAS VARIADAS
// ========================================

/// Plantillas para preguntas de CAPITALES
final List<String> capitalTemplates = [
  '¿Cuál es la capital de {country}?',
  '¿En qué ciudad se encuentra el gobierno de {country}?',
  '¿Qué ciudad es la sede administrativa de {country}?',
  '¿{capital} es la capital de qué país?',
  '¿Dónde está la capital de {country}?',
  '¿Cuál es la ciudad principal de {country}?',
  '¿La capital de {country} se llama...?',
  '¿Qué ciudad es el centro político de {country}?',
];

/// Plantillas para preguntas de MONEDAS
final List<String> currencyTemplates = [
  '¿Cuál es la moneda de {country}?',
  '¿Qué moneda se usa en {country}?',
  '¿La moneda oficial de {country} es...?',
  '¿En {country} se usa qué moneda?',
  '¿Cuál es la divisa de {country}?',
  '¿Qué currency tienen en {country}?',
  '¿Qué billetes y monedas circulan en {country}?',
];

/// Plantillas para preguntas de IDIOMAS
final List<String> languageTemplates = [
  '¿Cuál es el idioma oficial de {country}?',
  '¿Qué idioma se habla en {country}?',
  '¿El idioma principal de {country} es...?',
  '¿En {country} qué idioma se usa?',
  '¿Cuál es la lengua oficial de {country}?',
  '¿Qué idioma predomina en {country}?',
  '¿Los habitantes de {country} hablan principalmente...?',
];

/// Plantillas para preguntas de REGIONES
final List<String> regionTemplates = [
  '¿En qué región se encuentra {country}?',
  '¿{country} está ubicado en qué región?',
  '¿A qué región pertenece {country}?',
  '¿En qué continente está {country}?',
  '¿{country} es un país de qué región?',
  '¿En qué parte del mundo está {country}?',
  '¿{country} se ubica en...?',
];

/// Plantillas para preguntas de FRONTERAS
final List<String> borderTemplates = [
  '¿Con qué país limita {country} al norte?',
  '¿Con qué país limita {country} al sur?',
  '¿Con qué país limita {country} al este?',
  '¿Con qué país limita {country} al oeste?',
  '¿{country} comparte frontera con qué país?',
  '¿Qué país es vecino de {country}?',
  '¿Con qué país hace frontera {country}?',
];

/// Plantillas para preguntas de POBLACIÓN
final List<String> populationTemplates = [
  '¿Qué país tiene más población, {country1} o {country2}?',
  '¿Entre {country1} y {country2}, cuál tiene más habitantes?',
  '¿Cuál de estos países es más poblado: {country1} o {country2}?',
  '¿Qué nación tiene mayor población, {country1} o {country2}?',
];

/// Plantillas para preguntas de ÁREA
final List<String> areaTemplates = [
  '¿Qué país es más extenso, {country1} o {country2}?',
  '¿Entre {country1} y {country2}, cuál tiene mayor superficie?',
  '¿Cuál de estos países ocupa más territorio: {country1} o {country2}?',
  '¿Qué nación es más grande en extensión, {country1} o {country2}?',
];

// ========================================
// 🎲 SISTEMA DE SELECCIÓN DE PLANTILLAS
// ========================================

/// Selecciona una plantilla aleatoria de la lista proporcionada
String _selectRandomTemplate(List<String> templates) {
  final random = Random();
  return templates[random.nextInt(templates.length)];
}

/// Reemplaza los marcadores en la plantilla con los valores reales
String _fillTemplate(String template, Map<String, String> replacements) {
  String result = template;
  replacements.forEach((key, value) {
    result = result.replaceAll('{$key}', value);
  });
  return result;
}

/// Selecciona y rellena una plantilla aleatoria
String _generateQuestionText(
  List<String> templates,
  Map<String, String> replacements,
) {
  final template = _selectRandomTemplate(templates);
  return _fillTemplate(template, replacements);
}

// ========================================
// 🚀 EJECUCIÓN PRINCIPAL
// ========================================

void main(List<String> args) async {
  print('🎨 Generador de Preguntas con Variedad\n');

  // Parse arguments
  final argsMap = _parseArguments(args);

  if (argsMap.containsKey('help') || args.isEmpty) {
    _printHelp();
    return;
  }

  final types = (argsMap['types'] ?? 'capital,currency,language').split(',');
  final countPerType = int.tryParse(argsMap['count'] ?? '25') ?? 25;
  final outputFile = argsMap['output'] ?? 'scripts/questions_varied.json';

  print('🎯 Configuración:');
  print('   • Tipos: ${types.join(', ')}');
  print('   • Cantidad por tipo: $countPerType');
  print('   • Salida: $outputFile\n');

  try {
    // Fetch country data
    final countries = await _fetchCountries();
    if (countries.isEmpty) {
      throw Exception('No se pudieron obtener datos de países');
    }

    print('✅ ${countries.length} países obtenidos de la API\n');

    final questions = <Map<String, dynamic>>[];
    int questionId = 30000;

    // Generate questions for each requested type
    for (final type in types) {
      print('🔧 Generando preguntas de tipo: $type');

      try {
        final typeQuestions = await _generateQuestionsByType(
          type: type,
          countries: countries,
          count: countPerType,
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

  } catch (e) {
    print('❌ Error: $e');
    exit(1);
  }
}

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

void _printHelp() {
  print('''
📚 USO:
  dart scripts/generate_varied_questions.dart [OPCIONES]

🎯 OPCIONES:
  --types=TIPOS      Tipos de preguntas (separados por coma)
                     Valores: flag, capital, currency, language,
                     region, border, population, area
                     Default: capital,currency,language

  --count=NUM        Cantidad de preguntas por tipo (default: 25)
  --output=RUTA      Archivo de salida (default: scripts/questions_varied.json)
  -h, --help         Muestra esta ayuda

💡 CARACTERÍSTICAS:
  • Cada tipo usa 6-8 plantillas diferentes
  • Las plantillas se seleccionan aleatoriamente
  • Las preguntas no se sienten repetitivas

💡 EJEMPLOS:
  # Generar 50 preguntas de capitales y monedas
  dart scripts/generate_varied_questions.dart --types=capital,currency --count=50

  # Generar todos los tipos
  dart scripts/generate_varied_questions.dart --types=all --count=100
  ''');
}

Future<List<Map<String, dynamic>>> _fetchCountries() async {
  print('📡 Conectando a REST Countries API...');

  final response = await http.get(
    Uri.parse('https://restcountries.com/v3.1/all?fields=name,cca2,cca3,capital,population,area,languages,currencies,borders,region,subregion,flags'),
  );

  if (response.statusCode != 200) {
    throw Exception('Error al obtener datos: ${response.statusCode}');
  }

  final data = jsonDecode(response.body) as List;

  return data.where((country) {
    return country['name'] != null &&
           country['name']['common'] != null &&
           country['cca2'] != null;
  }).map((country) => country as Map<String, dynamic>).toList();
}

Future<List<Map<String, dynamic>>> _generateQuestionsByType({
  required String type,
  required List<Map<String, dynamic>> countries,
  required int count,
  required int startId,
}) async {
  switch (type) {
    case 'flag':
      return _generateFlagQuestions(countries, count: count, startId: startId);
    case 'capital':
      return _generateCapitalQuestions(countries, count: count, startId: startId);
    case 'currency':
      return _generateCurrencyQuestions(countries, count: count, startId: startId);
    case 'language':
      return _generateLanguageQuestions(countries, count: count, startId: startId);
    case 'region':
      return _generateRegionQuestions(countries, count: count, startId: startId);
    case 'border':
      return _generateBorderQuestions(countries, count: count, startId: startId);
    case 'population':
      return _generatePopulationQuestions(countries, count: count, startId: startId);
    case 'area':
      return _generateAreaQuestions(countries, count: count, startId: startId);
    case 'all':
      final allQuestions = <Map<String, dynamic>>[];
      final allTypes = ['capital', 'currency', 'language', 'region', 'population', 'area'];
      int currentId = startId;

      for (final t in allTypes) {
        final questions = await _generateQuestionsByType(
          type: t,
          countries: countries,
          count: count ~/ allTypes.length,
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

// ========================================
// 🎨 GENERADORES CON PLANTILLAS VARIADAS
// ========================================

List<Map<String, dynamic>> _generateFlagQuestions(
  List<Map<String, dynamic>> countries, {
  required int count,
  required int startId,
}) {
  final questions = <Map<String, dynamic>>[];
  final random = Random();
  final usedCountries = <String>{};

  final flagCountries = countries.where((c) =>
    c['flags'] != null && c['flags']['png'] != null
  ).toList();

  for (int i = 0; i < count && i < flagCountries.length; i++) {
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

    final wrongOptions = _generateWrongOptions(
      countries: countries,
      correctAnswer: name,
      count: 3,
      exclude: usedCountries,
    );

    final allOptions = [name, ...wrongOptions]..shuffle(random);
    final questionDifficulty = _determineDifficulty(country, 'flag');

    questions.add({
      'id': 'flag_${startId + i}',
      'type': 'flag',
      'difficulty': questionDifficulty,
      'questionText': '¿De qué país es esta bandera?', // Solo una plantilla para flags (son imágenes)
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

List<Map<String, dynamic>> _generateCapitalQuestions(
  List<Map<String, dynamic>> countries, {
  required int count,
  required int startId,
}) {
  final questions = <Map<String, dynamic>>[];
  final random = Random();
  final usedCountries = <String>{};

  final capitalCountries = countries.where((c) =>
    c['capital'] != null &&
    (c['capital'] as List).isNotEmpty &&
    c['capital'][0] != null
  ).toList();

  for (int i = 0; i < count && i < capitalCountries.length; i++) {
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
    final questionDifficulty = _determineDifficulty(country, 'capital');

    // 🎨 USAR PLANTILLA VARIADA
    String questionText;
    String correctAnswer;
    List<String> options;

    // 50% de probabilidad de usar formulación inversa
    if (random.nextBool()) {
      // Formulación inversa: "{capital} es la capital de qué país?"
      questionText = _generateQuestionText(capitalTemplates, {
        'capital': capital,
        'country': name,
      });

      // Para formulación inversa, necesitamos cambiar la lógica
      // La respuesta correcta es el país, no la capital
      final wrongOptions = _generateWrongOptions(
        countries: countries,
        correctAnswer: name,
        count: 3,
        exclude: usedCountries,
      );

      options = [name, ...wrongOptions]..shuffle(random);
      correctAnswer = name;
    } else {
      // Formulación normal: "¿Cuál es la capital de {country}?"
      final wrongOptions = _generateWrongCapitals(
        countries: countries,
        correctCapital: capital,
        count: 3,
      );

      options = [capital, ...wrongOptions]..shuffle(random);
      correctAnswer = capital;
      questionText = _generateQuestionText(capitalTemplates, {
        'capital': capital,
        'country': name,
      });
    }

    questions.add({
      'id': 'capital_${startId + i}',
      'type': 'capital',
      'difficulty': questionDifficulty,
      'questionText': questionText,
      'correctAnswer': correctAnswer,
      'options': options,
      'extraData': {
        'countryCode': country['cca2'].toLowerCase(),
        'countryName': name,
      },
    });
  }

  return questions;
}

List<Map<String, dynamic>> _generateCurrencyQuestions(
  List<Map<String, dynamic>> countries, {
  required int count,
  required int startId,
}) {
  final questions = <Map<String, dynamic>>[];
  final random = Random();
  final usedCountries = <String>{};

  final currencyCountries = countries.where((c) =>
    c['currencies'] != null &&
    (c['currencies'] as Map).isNotEmpty
  ).toList();

  for (int i = 0; i < count && i < currencyCountries.length; i++) {
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
    final currencyEntry = currencies.entries.first;
    final currencyData = currencyEntry.value as Map<String, dynamic>;
    final currencyName = currencyData['name'];

    final questionDifficulty = _determineDifficulty(country, 'currency');

    // 🎨 USAR PLANTILLA VARIADA
    final questionText = _generateQuestionText(currencyTemplates, {
      'country': name,
    });

    final wrongOptions = _generateWrongCurrencies(
      countries: countries,
      correctCurrency: currencyName,
      count: 3,
    );

    final allOptions = [currencyName, ...wrongOptions]..shuffle(random);

    questions.add({
      'id': 'currency_${startId + i}',
      'type': 'currency',
      'difficulty': questionDifficulty,
      'questionText': questionText,
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

List<Map<String, dynamic>> _generateLanguageQuestions(
  List<Map<String, dynamic>> countries, {
  required int count,
  required int startId,
}) {
  final questions = <Map<String, dynamic>>[];
  final random = Random();
  final usedCountries = <String>{};

  final languageCountries = countries.where((c) =>
    c['languages'] != null &&
    (c['languages'] as Map).isNotEmpty
  ).toList();

  for (int i = 0; i < count && i < languageCountries.length; i++) {
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
    final languageEntry = languages.entries.first;
    final languageName = languageEntry.value;

    final questionDifficulty = _determineDifficulty(country, 'language');

    // 🎨 USAR PLANTILLA VARIADA
    final questionText = _generateQuestionText(languageTemplates, {
      'country': name,
    });

    final wrongOptions = _generateWrongLanguages(
      countries: countries,
      correctLanguage: languageName,
      count: 3,
    );

    final allOptions = [languageName, ...wrongOptions]..shuffle(random);

    questions.add({
      'id': 'language_${startId + i}',
      'type': 'language',
      'difficulty': questionDifficulty,
      'questionText': questionText,
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

List<Map<String, dynamic>> _generateRegionQuestions(
  List<Map<String, dynamic>> countries, {
  required int count,
  required int startId,
}) {
  final questions = <Map<String, dynamic>>[];
  final random = Random();
  final usedCountries = <String>{};

  final regionCountries = countries.where((c) =>
    c['region'] != null && c['region'].toString().isNotEmpty
  ).toList();

  final regionTranslations = {
    'Europe': 'Europa',
    'Americas': 'América',
    'Asia': 'Asia',
    'Africa': 'África',
    'Oceania': 'Oceanía',
    'Antarctic': 'Antártida',
  };

  for (int i = 0; i < count && i < regionCountries.length; i++) {
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

    final questionDifficulty = _determineDifficulty(country, 'region');

    // 🎨 USAR PLANTILLA VARIADA
    final questionText = _generateQuestionText(regionTemplates, {
      'country': name,
    });

    final wrongOptions = _generateWrongRegions(
      regions: regionTranslations.values.toList(),
      correctRegion: regionSpanish,
      count: 3,
    );

    final allOptions = [regionSpanish, ...wrongOptions]..shuffle(random);

    questions.add({
      'id': 'region_${startId + i}',
      'type': 'region',
      'difficulty': questionDifficulty,
      'questionText': questionText,
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

List<Map<String, dynamic>> _generateBorderQuestions(
  List<Map<String, dynamic>> countries, {
  required int count,
  required int startId,
}) {
  final questions = <Map<String, dynamic>>[];
  final random = Random();
  final usedCountries = <String>{};

  final borderCountries = countries.where((c) =>
    c['borders'] != null &&
    (c['borders'] as List).isNotEmpty
  ).toList();

  final directions = ['norte', 'sur', 'este', 'oeste'];

  for (int i = 0; i < count && i < borderCountries.length; i++) {
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
    final borderCodes = borders.map((b) => b.toString()).toList();
    final borderingCountries = countries.where((c) =>
      borderCodes.contains(c['cca3']) || borderCodes.contains(c['cca2'])
    ).toList();

    if (borderingCountries.isEmpty) continue;

    final borderCountry = borderingCountries[random.nextInt(borderingCountries.length)];
    final borderName = borderCountry['name']['common'];
    final questionDifficulty = _determineDifficulty(country, 'border');

    // 🎨 USAR PLANTILLA VARIADA
    // Seleccionar dirección aleatoria
    final direction = directions[random.nextInt(directions.length)];

    final questionText = _generateQuestionText(borderTemplates, {
      'country': name,
    });

    final wrongOptions = _generateWrongOptions(
      countries: countries,
      correctAnswer: borderName,
      count: 3,
      exclude: {country['cca2'], borderCountry['cca2']},
    );

    final allOptions = [borderName, ...wrongOptions]..shuffle(random);

    questions.add({
      'id': 'border_${startId + i}',
      'type': 'border',
      'difficulty': questionDifficulty,
      'questionText': questionText,
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

List<Map<String, dynamic>> _generatePopulationQuestions(
  List<Map<String, dynamic>> countries, {
  required int count,
  required int startId,
}) {
  final questions = <Map<String, dynamic>>[];
  final random = Random();
  final usedPairs = <String>{};

  final sortedCountries = List<Map<String, dynamic>>.from(countries)
    ..sort((a, b) => (b['population'] as int).compareTo(a['population'] as int));

  for (int i = 0; i < count; i++) {
    int attempts = 0;
    Map<String, dynamic>? country1, country2;

    while ((country1 == null || country2 == null) && attempts < 100) {
      final idx1 = random.nextInt(sortedCountries.length ~/ 2);
      final idx2 = sortedCountries.length ~/ 2 + random.nextInt(sortedCountries.length ~/ 2);

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

    final correctAnswer = pop1 > pop2 ? name1 : name2;

    final diff1 = _determineDifficulty(country1, 'population');
    final diff2 = _determineDifficulty(country2, 'population');
    final questionDifficulty = _combineDifficulty(diff1, diff2);

    // 🎨 USAR PLANTILLA VARIADA
    // Ordenar los países aleatoriamente en la pregunta
    final orderedCountries = random.nextBool() ? [name1, name2] : [name2, name1];

    final questionText = _generateQuestionText(populationTemplates, {
      'country1': orderedCountries[0],
      'country2': orderedCountries[1],
    });

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

List<Map<String, dynamic>> _generateAreaQuestions(
  List<Map<String, dynamic>> countries, {
  required int count,
  required int startId,
}) {
  final questions = <Map<String, dynamic>>[];
  final random = Random();
  final usedPairs = <String>{};

  final sortedCountries = List<Map<String, dynamic>>.from(countries)
    ..sort((a, b) => (b['area'] as double).compareTo(a['area'] as double));

  for (int i = 0; i < count; i++) {
    int attempts = 0;
    Map<String, dynamic>? country1, country2;

    while ((country1 == null || country2 == null) && attempts < 100) {
      final idx1 = random.nextInt(sortedCountries.length ~/ 2);
      final idx2 = sortedCountries.length ~/ 2 + random.nextInt(sortedCountries.length ~/ 2);

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

    final correctAnswer = area1 > area2 ? name1 : name2;

    final diff1 = _determineDifficulty(country1, 'area');
    final diff2 = _determineDifficulty(country2, 'area');
    final questionDifficulty = _combineDifficulty(diff1, diff2);

    // 🎨 USAR PLANTILLA VARIADA
    final orderedCountries = random.nextBool() ? [name1, name2] : [name2, name1];

    final questionText = _generateQuestionText(areaTemplates, {
      'country1': orderedCountries[0],
      'country2': orderedCountries[1],
    });

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

// ========================================
// 🔧 FUNCIONES AUXILIARES
// ========================================

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

String _determineDifficulty(Map<String, dynamic> country, String type) {
  final name = country['name']['common'].toString().toLowerCase();
  final population = country['population'] as int? ?? 0;
  final area = country['area'] as double? ?? 0.0;
  final region = country['region']?.toString().toLowerCase() ?? '';

  final wellKnownCountries = {
    'spain', 'france', 'germany', 'italy', 'united kingdom', 'united states',
    'canada', 'mexico', 'brazil', 'argentina', 'china', 'japan', 'india',
    'australia', 'russia', 'portugal', 'netherlands', 'belgium', 'switzerland'
  };

  switch (type) {
    case 'flag':
    case 'capital':
      if (wellKnownCountries.contains(name)) {
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

String _combineDifficulty(String diff1, String diff2) {
  final difficulties = {'easy': 1, 'medium': 2, 'hard': 3};
  final avg = (difficulties[diff1]! + difficulties[diff2]!) / 2;

  if (avg <= 1.5) return 'easy';
  if (avg <= 2.5) return 'medium';
  return 'hard';
}

void _printStatistics(List<Map<String, dynamic>> questions) {
  final byType = <String, int>{};
  final byDifficulty = <String, int>{};

  for (final q in questions) {
    final type = q['type'].toString();
    final difficulty = q['difficulty'].toString();

    byType[type] = (byType[type] ?? 0) + 1;
    byDifficulty[difficulty] = (byDifficulty[difficulty] ?? 0) + 1;
  }

  print('📊 Estadísticas:');
  print('   • Total: ${questions.length} preguntas');

  print('\n📊 Por tipo:');
  byType.forEach((type, count) {
    print('   • $type: $count');
  });

  print('\n📊 Por dificultad:');
  byDifficulty.forEach((difficulty, count) {
    print('   • $difficulty: $count');
  });
}
