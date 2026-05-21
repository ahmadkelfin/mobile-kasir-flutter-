import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final String category;
  final int stock;
  final int minimumStock;
  final String? imageUrl;
  final String barcode;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.stock,
    this.minimumStock = 5,
    this.imageUrl,
    required this.barcode,
    this.isActive = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // ─── fromMap (Firestore) ──────────────────────────────────────────────────
  factory Product.fromMap(Map<String, dynamic> map, [String? id]) {
    return Product(
      id: id ?? map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      category: map['category'] ?? 'Umum',
      stock: (map['stock'] ?? 0).toInt(),
      minimumStock: (map['minimumStock'] ?? 5).toInt(),
      imageUrl: map['imageUrl'] as String?,
      barcode: map['barcode'] ?? '',
      isActive: map['isActive'] ?? true,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  // ─── fromFirestore (pakai DocumentSnapshot langsung) ─────────────────────
  factory Product.fromFirestore(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>;
    return Product.fromMap(map, doc.id);
  }

  // ─── toMap (Firestore) ────────────────────────────────────────────────────
  Map<String, dynamic> toMap() {
    final map = {
      'name': name,
      'description': description,
      'price': price,
      'category': category,
      'stock': stock,
      'minimumStock': minimumStock,
      'imageUrl': imageUrl,   // null akan tersimpan sebagai null di Firestore
      'barcode': barcode,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
    debugPrint('[Product.toMap] imageUrl: ${map['imageUrl']}');
    return map;
  }

  // ─── copyWith ─────────────────────────────────────────────────────────────
  // Pakai Object? agar imageUrl bisa di-set null secara eksplisit
  static const _remove = Object();

  Product copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    String? category,
    int? stock,
    int? minimumStock,
    Object? imageUrl = _remove,  // ← trick: bisa null atau dihapus
    String? barcode,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      category: category ?? this.category,
      stock: stock ?? this.stock,
      minimumStock: minimumStock ?? this.minimumStock,
      // Kalau imageUrl tidak diisi → pakai lama
      // Kalau imageUrl diisi null → simpan null (hapus foto)
      // Kalau imageUrl diisi string → pakai string baru
      imageUrl: identical(imageUrl, _remove)
          ? this.imageUrl
          : imageUrl as String?,
      barcode: barcode ?? this.barcode,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ─── fromJson / toJson (legacy API lama) ─────────────────────────────────
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id']?.toString() ?? '',
      name: json['nama'] ?? '',
      description: '',
      price: (json['harga'] ?? 0).toDouble(),
      category: 'Umum',
      stock: 0,
      barcode: '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': int.tryParse(id) ?? 0,
      'nama': name,
      'harga': price.toInt(),
    };
  }

  // ─── toString (untuk debug) ───────────────────────────────────────────────
  @override
  String toString() {
    return 'Product(id: $id, name: $name, price: $price, '
        'stock: $stock, category: $category, imageUrl: $imageUrl)';
  }

  // ─── equality ─────────────────────────────────────────────────────────────
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Product && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}