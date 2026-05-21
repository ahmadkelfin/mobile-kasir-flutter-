import 'package:cloud_firestore/cloud_firestore.dart';

class Purchase {
  final String id;
  final String supplierId;
  final DateTime purchaseDate;
  final List<PurchaseItem> items;
  final double subtotal;
  final double? tax;
  final double? discount;
  final double total;
  final String status; // 'draft', 'completed', 'delivered'
  final String? notes;
  final DateTime createdAt;

  Purchase({
    required this.id,
    required this.supplierId,
    required this.purchaseDate,
    required this.items,
    required this.subtotal,
    this.tax,
    this.discount,
    required this.total,
    required this.status,
    this.notes,
    required this.createdAt,
  });

  factory Purchase.fromMap(Map<String, dynamic> map, String id) {
    return Purchase(
      id: id,
      supplierId: map['supplierId'] ?? '',
      purchaseDate: (map['purchaseDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      items: map['items'] != null
          ? (map['items'] as List).map((item) => PurchaseItem.fromMap(item)).toList()
          : [],
      subtotal: (map['subtotal'] ?? 0.0).toDouble(),
      tax: map['tax']?.toDouble(),
      discount: map['discount']?.toDouble(),
      total: (map['total'] ?? 0.0).toDouble(),
      status: map['status'] ?? 'draft',
      notes: map['notes'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'supplierId': supplierId,
      'purchaseDate': Timestamp.fromDate(purchaseDate),
      'items': items.map((item) => item.toMap()).toList(),
      'subtotal': subtotal,
      'tax': tax,
      'discount': discount,
      'total': total,
      'status': status,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

class PurchaseItem {
  final String productId;
  final String productName;
  final int quantity;
  final double price;
  final double total;

  PurchaseItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
    required this.total,
  });

  factory PurchaseItem.fromMap(Map<String, dynamic> map) {
    return PurchaseItem(
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      quantity: map['quantity'] ?? 1,
      price: (map['price'] ?? 0.0).toDouble(),
      total: (map['total'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'price': price,
      'total': total,
    };
  }
}
