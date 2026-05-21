import 'package:cloud_firestore/cloud_firestore.dart';

enum CashTransactionType { cashIn, cashOut }

class CashTransaction {
  final String id;
  final String sessionId;
  final String userId;
  final String type; // 'in' | 'out'
  final double amount;
  final String description;
  final String? category; // contoh: 'listrik', 'gas', 'lainnya'
  final DateTime createdAt;

  CashTransaction({
    required this.id,
    required this.sessionId,
    required this.userId,
    required this.type,
    required this.amount,
    required this.description,
    this.category,
    required this.createdAt,
  });

  bool get isCashIn => type == 'in';

  Map<String, dynamic> toMap() {
    return {
      'sessionId': sessionId,
      'userId': userId,
      'type': type,
      'amount': amount,
      'description': description,
      'category': category,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory CashTransaction.fromMap(Map<String, dynamic> map, String id) {
    return CashTransaction(
      id: id,
      sessionId: map['sessionId'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      type: map['type'] as String? ?? 'out',
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      description: map['description'] as String? ?? '',
      category: map['category'] as String?,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}