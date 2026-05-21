import 'package:cloud_firestore/cloud_firestore.dart';

class ActivityLog {
  final String id;
  final String userId;
  final String action; // 'login', 'logout', 'add_product', 'edit_product', 'delete_product', 'add_transaction', 'return_transaction', 'open_cash', 'close_cash'
  final String? description;
  final Map<String, dynamic>? metadata; // additional data
  final DateTime createdAt;

  ActivityLog({
    required this.id,
    required this.userId,
    required this.action,
    this.description,
    this.metadata,
    required this.createdAt,
  });

  factory ActivityLog.fromMap(Map<String, dynamic> map, String id) {
    return ActivityLog(
      id: id,
      userId: map['userId'] ?? '',
      action: map['action'] ?? '',
      description: map['description'],
      metadata: map['metadata'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'action': action,
      'description': description,
      'metadata': metadata,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
