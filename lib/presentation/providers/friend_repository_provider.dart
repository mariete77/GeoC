import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/friend_repository_impl.dart';
import '../../domain/repositories/friend_repository.dart';

final friendRepositoryProvider = Provider<FriendRepository>(
  (ref) {
    // This would normally be injected with the actual implementation,
    // but we provide a mock placeholder for now.
    throw UnimplementedError('FriendRepository must be provided with actual implementation');
  },
);