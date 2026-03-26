/// 📊 Importador Avanzado de Preguntas desde CSV/Excel/Google Sheets
///
/// Uso:
/// dart scripts/question_csv_importer.dart --input=ruta.csv --format=csv
/// dart scripts/question_csv_importer.dart --input=questions.xlsx --format=excel
/// 
/// Formatos soportados:
/// - CSV (comma, semicolon, tab separated)
/// - Excel (.xlsx, .xls)
/// - Google Sheets (exportado como CSV)
/// - JSON (para conversión directa)

import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';

void main(List<String> args) async {
  print('📊 GeoQuiz Battle - Importador Avanzado de Preguntas\n');

  // Parse arguments
  final argsMap = _parseArguments(args);
  
  if (argsMap.containsKey('help') || args.isEmpty) {
    _printHelp();
    return;
  }

  final inputFile = argsMap['input'] ?? 'questions.csv';
  final format = argsMap['format'] ?? 'csv';
  final outputFile = argsMap['output'] ?? 'scripts/questions_imported.json';
  final delimiter = argsMap['delimiter'] ?? ',';
  final hasHeader = argsMap['no-header'] == null;

  try {
    print('📖 Leyendo archivo: $inputFile');
    print('📋 Formato: $format');
    print('📁 Salida: $outputFile\n');

    // Read and parse file
    final questions = await _parseFile(inputFile, format, delimiter, hasHeader);
    
    print('✅ ${questions.length} preguntas parseadas\n');

    // Validate questions
    final validation = _validateQuestions(questions);
    if (!validation.isValid) {
      print('❌ Errores de validación encontrados:');
      for (final error in validation.errors) {
        print('   • $error');
      }
      print('\n💡 Corrige los errores y vuelve a intentar.');
      exit(1);
    }

    // Generate JSON
    final jsonQuestions = _convertToFirestoreFormat(questions);
    final output = const JsonEncoder.withIndent('  ').convert(jsonQuestions);
    
    await File(outputFile).writeAsString(output);
    
    print('🎉 ¡Importación exitosa!');
    print('📊 Estadísticas:');
    print('   • Total preguntas: ${questions.length}');
    print('   • Tipos: ${_countByType(questions)}');
    print('   • Dificultades: ${_countByDifficulty(questions)}');
    print('\n💾 Guardado en: $outputFile');
    print('\n📤 Para importar a Firestore:');
    print('   dart scripts/import_questions_firestore.dart');
    print('\n🔍 Vista previa de la primera pregunta:');
    _printQuestionPreview(jsonQuestions.first);

  } catch (e) {
    print('❌ Error: $e');
    print('\n💡 Asegúrate de que:');
    print('   1. El archivo existe y es accesible');
    print('   2. El formato es correcto ($format)');
    print('   3. Las columnas tienen los nombres esperados');
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
  dart scripts/question_csv_importer.dart [OPCIONES]

📋 OPCIONES:
  --input=RUTA       Archivo de entrada (default: questions.csv)
  --format=FORMATO   csv, excel, json (default: csv)
  --output=RUTA      Archivo JSON de salida (default: scripts/questions_imported.json)
  --delimiter=CHAR   Delimitador CSV: , ; \\t (default: ,)
  --no-header        El archivo NO tiene encabezado
  -h, --help         Muestra esta ayuda

📝 FORMATO CSV ESPERADO (con encabezado):
  type,question,correct,option1,option2,option3,difficulty,imageUrl,extraData
  
📝 EJEMPLO CSV:
  type,question,correct,option1,option2,option3,difficulty,imageUrl
  flag,¿De qué país es esta bandera?,España,Francia,Italia,Portugal,easy,https://flagcdn.com/es.svg
  capital,¿Cuál es la capital de Francia?,París,Londres,Berlín,Madrid,medium,
  river,¿Cuál es el río más largo de España?,Tajo,Ebro,Duero,Guadalquivir,medium,

🎯 TIPOS SOPORTADOS:
  flag, capital, population, area, river, silhouette, city_photo

🎯 DIFICULTADES:
  easy, medium, hard

💡 CONSEJOS:
  1. Puedes exportar desde Google Sheets como CSV
  2. Usa comillas si los valores contienen comas: "París, Francia"
  3. imageUrl es opcional
  4. extraData es JSON opcional: {"countryCode": "es"}
  ''');
}

/// Parse file based on format
Future<List<Map<String, dynamic>>> _parseFile(
  String filePath, 
  String format, 
  String delimiter,
  bool hasHeader,
) async {
  final file = File(filePath);
  if (!file.existsSync()) {
    throw Exception('Archivo no encontrado: $filePath');
  }

  switch (format.toLowerCase()) {
    case 'csv':
      return _parseCsv(file, delimiter, hasHeader);
    case 'json':
      return _parseJson(file);
    default:
      throw Exception('Formato no soportado: $format. Usa: csv, json');
  }
}

/// Parse CSV file
List<Map<String, dynamic>> _parseCsv(File file, String delimiter, bool hasHeader) {
  final content = file.readAsStringSync();
  final csvDelimiter = delimiter == '\\t' ? '\t' : delimiter;
  
  final rows = const CsvToListConverter(
    fieldDelimiter: csvDelimiter,
    shouldParseNumbers: false,
  ).convert(content, eol: '\n');

  if (rows.isEmpty) {
    throw Exception('CSV vacío o mal formado');
  }

  final headers = hasHeader 
      ? (rows.first as List).cast<String>()
      : ['type', 'question', 'correct', 'option1', 'option2', 'option3', 'difficulty', 'imageUrl', 'extraData'];
  
  final startIndex = hasHeader ? 1 : 0;
  final questions = <Map<String, dynamic>>[];

  for (int i = startIndex; i < rows.length; i++) {
    final row = rows[i] as List;
    final question = <String, dynamic>{};

    for (int j = 0; j < headers.length && j < row.length; j++) {
      final value = row[j];
      if (value != null && value.toString().trim().isNotEmpty) {
        question[headers[j]] = value;
      }
    }

    // Ensure required fields
    if (question.containsKey('type') && question.containsKey('correct')) {
      questions.add(question);
    }
  }

  return questions;
}

/// Parse JSON file
List<Map<String, dynamic>> _parseJson(File file) {
  final content = file.readAsStringSync();
  final data = jsonDecode(content);
  
  if (data is List) {
    return data.cast<Map<String, dynamic>>();
  } else if (data is Map) {
    return [data.cast<String, dynamic>()];
  } else {
    throw Exception('Formato JSON no válido');
  }
}

/// Question validation result
class ValidationResult {
  final bool isValid;
  final List<String> errors;

  ValidationResult(this.isValid, this.errors);
}

/// Validate questions
ValidationResult _validateQuestions(List<Map<String, dynamic>> questions) {
  final errors = <String>[];
  final validTypes = {'flag', 'capital', 'population', 'area', 'river', 'silhouette', 'city_photo'};
  final validDifficulties = {'easy', 'medium', 'hard'};

  for (int i = 0; i < questions.length; i++) {
    final q = questions[i];
    final line = i + 1;

    // Check required fields
    if (!q.containsKey('type')) {
      errors.add('Línea $line: Falta campo "type"');
    } else if (!validTypes.contains(q['type'].toString().toLowerCase())) {
      errors.add('Línea $line: Tipo inválido "${q['type']}". Válidos: ${validTypes.join(', ')}');
    }

    if (!q.containsKey('correct')) {
      errors.add('Línea $line: Falta campo "correct" (respuesta correcta)');
    }

    // Check difficulty
    if (!q.containsKey('difficulty')) {
      q['difficulty'] = 'medium'; // Default
    } else if (!validDifficulties.contains(q['difficulty'].toString().toLowerCase())) {
      errors.add('Línea $line: Dificultad inválida "${q['difficulty']}". Válidas: ${validDifficulties.join(', ')}');
    }

    // Check options
    final options = <String>[];
    for (int j = 1; j <= 3; j++) {
      final key = 'option$j';
      if (q.containsKey(key) && q[key].toString().trim().isNotEmpty) {
        options.add(q[key].toString());
      }
    }

    // Ensure at least 3 options total (including correct)
    if (options.length < 3) {
      // Add dummy options if missing
      while (options.length < 3) {
        options.add('Opción ${options.length + 1}');
      }
    }

    // Add correct answer to options if not already there
    final correct = q['correct'].toString();
    if (!options.contains(correct)) {
      options.add(correct);
    }

    // Shuffle options
    options.shuffle();
    q['options'] = options;
  }

  return ValidationResult(errors.isEmpty, errors);
}

/// Convert to Firestore format
List<Map<String, dynamic>> _convertToFirestoreFormat(List<Map<String, dynamic>> questions) {
  final firestoreQuestions = <Map<String, dynamic>>[];
  final random = Random();

  for (int i = 0; i < questions.length; i++) {
    final q = questions[i];
    
    final question = {
      'id': 'imported_${DateTime.now().millisecondsSinceEpoch}_$i',
      'type': q['type'].toString().toLowerCase(),
      'difficulty': q['difficulty'].toString().toLowerCase(),
      'correctAnswer': q['correct'].toString(),
      'options': (q['options'] as List).cast<String>(),
      'questionText': q.containsKey('question') ? q['question'].toString() : null,
      'imageUrl': q.containsKey('imageUrl') ? q['imageUrl'].toString() : null,
      'extraData': _parseExtraData(q),
    };

    firestoreQuestions.add(question);
  }

  return firestoreQuestions;
}

/// Parse extra data field
Map<String, dynamic>? _parseExtraData(Map<String, dynamic> question) {
  if (!question.containsKey('extraData')) return null;

  try {
    final extra = question['extraData'].toString();
    if (extra.startsWith('{') && extra.endsWith('}')) {
      return jsonDecode(extra) as Map<String, dynamic>;
    }
  } catch (e) {
    // Ignore parse errors
  }

  return null;
}

/// Count questions by type
String _countByType(List<Map<String, dynamic>> questions) {
  final counts = <String, int>{};
  
  for (final q in questions) {
    final type = q['type'].toString().toLowerCase();
    counts[type] = (counts[type] ?? 0) + 1;
  }
  
  return counts.entries.map((e) => '${e.key}: ${e.value}').join(', ');
}

/// Count questions by difficulty
String _countByDifficulty(List<Map<String, dynamic>> questions) {
  final counts = <String, int>{};
  
  for (final q in questions) {
    final diff = q['difficulty'].toString().toLowerCase();
    counts[diff] = (counts[diff] ?? 0) + 1;
  }
  
  return counts.entries.map((e) => '${e.key}: ${e.value}').join(', ');
}

/// Print question preview
void _printQuestionPreview(Map<String, dynamic> question) {
  print('''
  🔍 ID: ${question['id']}
  🎯 Tipo: ${question['type']}
  📊 Dificultad: ${question['difficulty']}
  ❓ Pregunta: ${question['questionText'] ?? '---'}
  ✅ Correcta: ${question['correctAnswer']}
  📝 Opciones: ${(question['options'] as List).join(', ')}
  🖼️  Imagen: ${question['imageUrl'] ?? 'No'}
  📁 Extra: ${question['extraData'] ?? 'No'}
  ''');
}