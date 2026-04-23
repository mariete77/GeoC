import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geoquiz_battle/data/repositories/quiz_attempt_repository_impl.dart';
import 'package:geoquiz_battle/domain/repositories/quiz_attempt_repository.dart';

/// Provider para FirebaseFirestore
final firestoreProvider = Provider<FirebaseDatabase>((ref) {
  return FirebaseDatabase();
});

/// Wrapper para FirebaseFirestore
class FirebaseDatabase {
  final FirebaseFirestore instance;

  FirebaseDatabase({FirebaseFirestore? firestore}) : instance = firestore ?? FirebaseFirestore.instance;
}

/// Provider para el repositorio de tracking de respuestas
final quizAttemptRepositoryProvider = Provider<QuizAttemptRepository>((ref) {
  final firestore = ref.watch(firestoreProvider).instance;
  return QuizAttemptRepositoryImpl(firestore: firestore);
});
