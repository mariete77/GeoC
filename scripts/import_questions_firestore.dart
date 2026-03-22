/// Script para importar preguntas a Firestore
///
/// Uso:
/// dart scripts/import_questions_firestore.dart
///
/// Este script lee questions.json y lo importa a Firestore
///
/// Requisitos:
/// - Archivo firebase_options.dart en lib/
/// - Ejecutar: dart run build_runner build

import 'dart:io';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart' as options;

Future<void> main() async {
  print('🔥 Importando preguntas a Firestore...\n');

  try {
    // Inicializar Firebase
    await Firebase.initializeApp(
      options: options.DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase inicializado\n');

    final firestore = FirebaseFirestore.instance;

    // Leer archivo de preguntas
    print('📖 Leyendo questions.json...');
    final file = File('scripts/questions.json');

    if (!file.existsSync()) {
      print('❌ Error: No se encontró questions.json');
      print('💡 Ejecuta primero: dart scripts/generate_questions.dart');
      exit(1);
    }

    final content = await file.readAsString();
    final questions = jsonDecode(content) as List;

    print('✅ ${questions.length} preguntas leídas\n');

    // Confirmar importación
    print('⚠️  Esto importará ${questions.length} preguntas a Firestore');
    print('⚠️  ¿Continuar? (y/N)');
    final input = stdin.readLineSync();

    if (input?.toLowerCase() != 'y') {
      print('❌ Importación cancelada');
      exit(0);
    }

    print('\n📤 Importando preguntas...');

    // Importar en batches de 500
    final batchSize = 500;
    int imported = 0;
    int failed = 0;

    for (int i = 0; i < questions.length; i += batchSize) {
      final batch = firestore.batch();
      final end = (i + batchSize).clamp(0, questions.length);

      for (int j = i; j < end; j++) {
        final question = questions[j] as Map<String, dynamic>;
        final docRef = firestore.collection('questions').doc(question['id']);
        batch.set(docRef, question);
      }

      try {
        await batch.commit();
        imported += (end - i);
        print('   📦 Progreso: $imported/${questions.length}');
      } catch (e) {
        failed += (end - i);
        print('   ❌ Error en batch $i-$end: $e');
      }
    }

    print('\n✅ ¡Importación completada!');
    print('📊 Importadas: $imported');
    print('❌ Fallidas: $failed');

    // Verificar importación
    print('\n📊 Verificando importación...');
    final snapshot = await firestore.collection('questions').limit(1).get();

    if (snapshot.docs.isNotEmpty) {
      print('✅ Las preguntas están en Firestore');
      print('🔍 Ejemplo de pregunta:');
      final sample = snapshot.docs.first.data();
      print(jsonEncode(sample));
    } else {
      print('❌ No se encontraron preguntas en Firestore');
    }

  } catch (e) {
    print('❌ Error: $e');
    exit(1);
  }
}
