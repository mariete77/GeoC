import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/user.dart';
import '../../data/models/user_model.dart';

/// Provider to fetch a single user by ID.
/// Use this to display friend details (name, elo, photo) given a userId.
final friendUserProvider =
    FutureProvider.family.autoDispose<User?, String>((ref, userId) async {
  if (userId.isEmpty) return null;

  final doc =
      await FirebaseFirestore.instance.collection('users').doc(userId).get();

  if (!doc.exists) return null;
  return UserModel.fromFirestore(doc).toDomain();
});
