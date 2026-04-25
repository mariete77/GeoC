import 'package:equatable/equatable.dart';

/// Status of a friend request
enum FriendRequestStatus {
  pending,
  accepted,
  rejected,
}

/// Friend request entity
class FriendRequest extends Equatable {
  final String id;
  final String fromUserId;
  final String toUserId;
  final FriendRequestStatus status;
  final DateTime createdAt;

  const FriendRequest({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.status,
    required this.createdAt,
  });

  /// Whether this request was sent by the current user
  bool get isSent => true; // Context-dependent, determined by provider

  @override
  List<Object?> get props => [id, fromUserId, toUserId, status, createdAt];
}
