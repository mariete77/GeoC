import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geoquiz_battle/core/constants/firebase_constants.dart';

/// Service to report problematic questions
class QuestionReportService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  QuestionReportService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  /// Report a question
  Future<void> reportQuestion({
    required String questionId,
    required String reason,
    String? comment,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    await _firestore.collection(FirebaseConstants.questionReports).add({
      'questionId': questionId,
      'userId': user.uid,
      'reason': reason,
      'comment': comment ?? '',
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'pending', // pending → reviewed → resolved
    });
  }
}