import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  final String id;
  final String userId;
  final double amount;
  final String type; // 'income' or 'expense'
  final DateTime createdAt;
  final String? description;
  final String? paymentMethod; // 'cash', 'card', 'digital_wallet', etc.
  final String? customerName;
  final List<TransactionItem>? items;
  final double? discount;
  final double? tax;

  TransactionModel({
    required this.id,
    required this.userId,
    required this.amount,
    required this.type,
    required this.createdAt,
    this.description,
    this.paymentMethod,
    this.customerName,
    this.items,
    this.discount,
    this.tax,
  });

  factory TransactionModel.fromMap(Map<String, dynamic> map, String id) {
    return TransactionModel(
      id: id,
      userId: map['userId'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      type: map['type'] ?? 'income',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      description: map['description'],
      paymentMethod: map['paymentMethod'],
      customerName: map['customerName'],
      items: map['items'] != null
          ? (map['items'] as List).map((item) => TransactionItem.fromMap(item)).toList()
          : null,
      discount: map['discount']?.toDouble(),
      tax: map['tax']?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'amount': amount,
      'type': type,
      'createdAt': Timestamp.fromDate(createdAt),
      'description': description,
      'paymentMethod': paymentMethod,
      'customerName': customerName,
      'items': items?.map((item) => item.toMap()).toList(),
      'discount': discount,
      'tax': tax,
    };
  }

  double get subtotal => items?.fold<double>(0.0, (total, item) => total + (item.price * item.quantity)) ?? amount;
  double get totalDiscount => discount ?? 0;
  double get totalTax => tax ?? 0;
}

class TransactionItem {
  final String productId;
  final String productName;
  final double price;
  final int quantity;
  final String? category;

  TransactionItem({
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
    this.category,
  });

  factory TransactionItem.fromMap(Map<String, dynamic> map) {
    return TransactionItem(
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      quantity: map['quantity'] ?? 1,
      category: map['category'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'price': price,
      'quantity': quantity,
      'category': category,
    };
  }

  double get total => price * quantity;
}