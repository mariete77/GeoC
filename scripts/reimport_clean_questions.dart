/// Script para reimportar preguntas limpias a Firestore
///
/// Uso: dart run scripts/reimport_clean_questions.dart
///
/// 1. Borra todas las preguntas existentes
/// 2. Importa desde questions_clean.json

import 'dart:io';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../lib/firebase_options.dart' as options;

Future<void> main() async {
  print('🔄 Reimportando preguntas limpias a Firestore...\n');

  try {
    await Firebase.initializeApp(
      options: options.DefaultFirebaseOptions.web,
    );
    print('✅ Firebase inicializado\n');

    final firestore = FirebaseFirestore.instance;

    // 1. Borrar preguntas existentes
    print('🗑️  Borrando preguntas existentes...');
    int deleted = 0;
    bool hasMore = true;
    
    while (hasMore) {
      final snapshot = await firestore.collection('questions').limit(500).get();
      if (snapshot.docs.isEmpty) {
        hasMore = false;
        break;
      }
      
      final batch = firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      deleted += snapshot.docs.length;
      print('   🗑️  Borrados: $deleted');
    }
    
    print('✅ $deleted preguntas borradas\n');

    // 2. Leer questions_clean.json
    print('📖 Leyendo questions_clean.json...');
    final file = File('scripts/questions_clean.json');

    if (!file.existsSync()) {
      print('❌ Error: No se encontró questions_clean.json');
      print('💡 Ejecuta primero: python scripts/fix_and_clean_questions.py');
      exit(1);
    }

    final content = await file.readAsString();
    final questions = jsonDecode(content) as List;
    print('✅ ${questions.length} preguntas leídas\n');

    // 3. Importar en batches de 450
    final batchSize = 450;
    int imported = 0;
    int failed = 0;

    for (int i = 0; i < questions.length; i += batchSize) {
      final batch = firestore.batch();
      final end = (i + batchSize).clamp(0, questions.length);

      for (int j = i; j < end; j++) {
        final question = questions[j] as Map<String, dynamic>;
        // Limpiar campos internos
        question.remove('_source');
        question.remove('_remove');
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

    print('\n✅ ¡Reimportación completada!');
    print('📊 Importadas: $imported');
    print('❌ Fallidas: $failed');

    // Verificar
    print('\n📊 Verificando...');
    final snapshot = await firestore.collection('questions').get();
    print('📋 Total documentos en Firestore: ${snapshot.docs.length}');
    
    // Contar por tipo
    final types = <String, int>{};
    for (final doc in snapshot.docs) {
      final type = doc.data()['type'] as String? ?? 'unknown';
      types[type] = (types[type] ?? 0) + 1;
    }
    print('\nPor tipo:');
    for (final entry in types.entries.toList()..sort((a, b) => b.value.compareTo(a.value))) {
      print('  ${entry.key}: ${entry.value}');
    }

  } catch (e) {
    print('❌ Error: $e');
    exit(1);
  }
}