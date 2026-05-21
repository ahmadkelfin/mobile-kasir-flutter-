import 'package:cloud_firestore/cloud_firestore.dart';

class Customer {
  final String id;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final double totalPurchased;
  final int totalTransactions;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastPurchase;

  Customer({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.totalPurchased = 0,
    this.totalTransactions = 0,
    this.isActive = true,
    required this.createdAt,
    this.lastPurchase,
  });

  factory Customer.fromMap(Map<String, dynamic> map, String id) {
    return Customer(
      id: id,
      name: map['name'] ?? '',
      phone: map['phone'],
      email: map['email'],
      address: map['address'],
      totalPurchased: (map['totalPurchased'] ?? 0.0).toDouble(),
      totalTransactions: map['totalTransactions'] ?? 0,
      isActive: map['isActive'] ?? true,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastPurchase: (map['lastPurchase'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'totalPurchased': totalPurchased,
      'totalTransactions': totalTransactions,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastPurchase': lastPurchase != null ? Timestamp.fromDate(lastPurchase!) : null,
    };
  }
}
