/// Script para generar preguntas incluyendo datos manuales (ríos)
///
/// Uso:
/// dart scripts/generate_questions_with_manual.dart
///
/// Este script genera todos los tipos de preguntas, incluyendo ríos
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'rivers_manual.dart';

void main() async {
  print('🌍 Generando TODAS las preguntas para GeoQuiz Battle...\n');

  final questions = <Map<String, dynamic>>[];

  try {
    // Obtener datos de REST Countries
    print('📡 Obteniendo datos de REST Countries API...');
    final response =
        await http.get(Uri.parse('https://restcountries.com/v3.1/all'));
    final countries = jsonDecode(response.body) as List;

    print('✅ ${countries.length} países obtenidos\n');

    // Filtrar países válidos
    final validCountries = countries.where((country) {
      return country['name']['common'] != null &&
          country['cca2'] != null &&
          country['population'] != null &&
          country['area'] != null;
    }).toList();

    print('✅ ${validCountries.length} países válidos\n');

    int questionId = 0;

    // Generar preguntas de cada tipo
    print('🏳️ Generando preguntas de banderas...');
    final flagQuestions = _generateFlagQuestions(validCountries, ref: questionId);
    questions.addAll(flagQuestions);
    questionId += flagQuestions.length;

    print('🏛️ Generando preguntas de capitales...');
    final capitalQuestions = _generateCapitalQuestions(validCountries, ref: questionId);
    questions.addAll(capitalQuestions);
    questionId += capitalQuestions.length;

    print('👥 Generando preguntas de población...');
    final populationQuestions = _generatePopulationQuestions(validCountries, ref: questionId);
    questions.addAll(populationQuestions);
    questionId += populationQuestions.length;

    print('📏 Generando preguntas de extensión...');
    final areaQuestions = _generateAreaQuestions(validCountries, ref: questionId);
    questions.addAll(areaQuestions);
    questionId += areaQuestions.length;

    print('🌊 Generando preguntas de ríos (datos manuales)...');
    final riverQuestions = generateRiverQuestions(ref: questionId);
    questions.addAll(riverQuestions);

    // Mezclar para aleatoriedad
    questions.shuffle();

    // Guardar en archivo JSON
    final output = const JsonEncoder.withIndent('  ').convert(questions);
    final outputFile = File('scripts/questions_full.json');
    await outputFile.writeAsString(output);

    print('\n✅ ¡Éxito!');
    print('📊 Total de preguntas generadas: ${questions.length}');
    print('💾 Guardado en: ${outputFile.path}\n');

    // Estadísticas
    _printStats(questions);

    print('\n💡 Para importar a Firestore:');
    print('   dart scripts/import_questions_firestore.dart');

  } catch (e) {
    print('❌ Error: $e');
    exit(1);
  }
}

/// Generar preguntas de banderas
List<Map<String, dynamic>> _generateFlagQuestions(List countries, {required int ref}) {
  final questions = <Map<String, dynamic>>[];
  final usedCountries = <String>{};

  for (final country in countries) {
    if (usedCountries.contains(country['cca2'])) continue;
    if (usedCountries.length >= 100) break;

    final name = country['name']['common'];
    final cca2 = country['cca2'];

    final options = _generateOptions(countries, name, 3);
    final allOptions = [name, ...options]..shuffle();

    questions.add({
      'id': 'flag_${ref + questions.length}',
      'type': 'flag',
      'difficulty': 'easy',
      'extraData': {'countryCode': cca2.toLowerCase()},
      'correctAnswer': name,
      'options': allOptions,
    });

    usedCountries.add(cca2);
  }

  return questions;
}

/// Generar preguntas de capitales
List<Map<String, dynamic>> _generateCapitalQuestions(List countries, {required int ref}) {
  final questions = <Map<String, dynamic>>[];
  final usedCountries = <String>{};

  for (final country in countries) {
    if (usedCountries.contains(country['cca2'])) continue;
    if (usedCountries.length >= 100) break;

    final name = country['name']['common'];
    final capital = country['capital'];

    if (capital == null || capital.isEmpty) continue;

    final options = _generateCapitalOptions(countries, capital[0], 3);
    final allOptions = [capital[0], ...options]..shuffle();

    questions.add({
      'id': 'capital_${ref + questions.length}',
      'type': 'capital',
      'difficulty': 'medium',
      'questionText': '¿Cuál es la capital de $name?',
      'correctAnswer': capital[0],
      'options': allOptions,
    });

    usedCountries.add(country['cca2']);
  }

  return questions;
}

/// Generar preguntas de población
List<Map<String, dynamic>> _generatePopulationQuestions(List countries, {required int ref}) {
  final questions = <Map<String, dynamic>>();

  for (int i = 0; i < 50; i++) {
    final index1 = (i * 2) % countries.length;
    final index2 = (i * 2 + 1) % countries.length;

    final country1 = countries[index1];
    final country2 = countries[index2];

    final name1 = country1['name']['common'];
    final name2 = country2['name']['common'];
    final population1 = country1['population'];
    final population2 = country2['population'];

    final correctAnswer = population1 > population2 ? name1 : name2;

    questions.add({
      'id': 'population_${ref + i}',
      'type': 'population',
      'difficulty': 'hard',
      'questionText': '¿Qué país tiene más habitantes?',
      'extraData': {
        'countries': [name1, name2],
        'data': {name1: population1, name2: population2},
      },
      'correctAnswer': correctAnswer,
      'options': [name1, name2],
    });
  }

  return questions;
}

/// Generar preguntas de extensión
List<Map<String, dynamic>> _generateAreaQuestions(List countries, {required int ref}) {
  final questions = <Map<String, dynamic>>();

  for (int i = 0; i < 50; i++) {
    final index1 = (i * 2 + 100) % countries.length;
    final index2 = (i * 2 + 101) % countries.length;

    final country1 = countries[index1];
    final country2 = countries[index2];

    final name1 = country1['name']['common'];
    final name2 = country2['name']['common'];
    final area1 = country1['area'];
    final area2 = country2['area'];

    final correctAnswer = area1 > area2 ? name1 : name2;

    questions.add({
      'id': 'area_${ref + i}',
      'type': 'area',
      'difficulty': 'hard',
      'questionText': '¿Qué país es más extenso?',
      'extraData': {
        'countries': [name1, name2],
        'data': {name1: area1, name2: area2},
      },
      'correctAnswer': correctAnswer,
      'options': [name1, name2],
    });
  }

  return questions;
}

List<String> _generateOptions(List countries, String exclude, int count) {
  final options = <String>[];
  final usedNames = <String>{exclude};

  final random = DateTime.now().millisecondsSinceEpoch;

  while (options.length < count) {
    final index = (random + options.length) % countries.length;
    final country = countries[index];
    final name = country['name']['common'];

    if (!usedNames.contains(name)) {
      options.add(name);
      usedNames.add(name);
    }
  }

  return options;
}

List<String> _generateCapitalOptions(List countries, String exclude, int count) {
  final options = <String>[];
  final usedCapitals = <String>{exclude};

  final random = DateTime.now().millisecondsSinceEpoch;

  while (options.length < count) {
    final index = (random + options.length) % countries.length;
    final country = countries[index];
    final capital = country['capital'];

    if (capital != null && capital.isNotEmpty && !usedCapitals.contains(capital[0])) {
      options.add(capital[0]);
      usedCapitals.add(capital[0]);
    }
  }

  return options;
}

void _printStats(List<Map<String, dynamic>> questions) {
  final byType = <String, int>{};

  for (final q in questions) {
    final type = q['type'];
    byType[type] = (byType[type] ?? 0) + 1;
  }

  print('📊 Distribución por tipo:');
  byType.forEach((type, count) {
    print('   $type: $count');
  });

  print('\n📊 Distribución por dificultad:');
  final byDifficulty = <String, int>{};

  for (final q in questions) {
    final difficulty = q['difficulty'];
    byDifficulty[difficulty] = (byDifficulty[difficulty] ?? 0) + 1;
  }

  byDifficulty.forEach((difficulty, count) {
    print('   $difficulty: $count');
  });
}
