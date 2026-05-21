import 'package:cloud_firestore/cloud_firestore.dart';

class CashSession {
  final String id;
  final String userId;
  final String userName;
  final double initialBalance; // modal awal
  final double? finalBalance; // uang fisik saat tutup kas
  final double? totalSales; // total penjualan hari itu
  final double? totalCashIn; // kas masuk non-penjualan
  final double? totalCashOut; // kas keluar
  final double? difference; // selisih (fisik - ekspektasi)
  final String status; // 'open' | 'closed'
  final DateTime openedAt;
  final DateTime? closedAt;
  final String? notes;

  CashSession({
    required this.id,
    required this.userId,
    required this.userName,
    required this.initialBalance,
    this.finalBalance,
    this.totalSales,
    this.totalCashIn,
    this.totalCashOut,
    this.difference,
    required this.status,
    required this.openedAt,
    this.closedAt,
    this.notes,
  });

  /// Ekspektasi saldo akhir = modal awal + penjualan + kas masuk - kas keluar
  double get expectedBalance =>
      initialBalance +
      (totalSales ?? 0) +
      (totalCashIn ?? 0) -
      (totalCashOut ?? 0);

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'initialBalance': initialBalance,
      'finalBalance': finalBalance,
      'totalSales': totalSales,
      'totalCashIn': totalCashIn,
      'totalCashOut': totalCashOut,
      'difference': difference,
      'status': status,
      'openedAt': Timestamp.fromDate(openedAt),
      'closedAt': closedAt != null ? Timestamp.fromDate(closedAt!) : null,
      'notes': notes,
    };
  }

  factory CashSession.fromMap(Map<String, dynamic> map, String id) {
    return CashSession(
      id: id,
      userId: map['userId'] as String? ?? '',
      userName: map['userName'] as String? ?? '',
      initialBalance: (map['initialBalance'] as num?)?.toDouble() ?? 0,
      finalBalance: (map['finalBalance'] as num?)?.toDouble(),
      totalSales: (map['totalSales'] as num?)?.toDouble(),
      totalCashIn: (map['totalCashIn'] as num?)?.toDouble(),
      totalCashOut: (map['totalCashOut'] as num?)?.toDouble(),
      difference: (map['difference'] as num?)?.toDouble(),
      status: map['status'] as String? ?? 'open',
      openedAt: (map['openedAt'] as Timestamp).toDate(),
      closedAt: (map['closedAt'] as Timestamp?)?.toDate(),
      notes: map['notes'] as String?,
    );
  }

  CashSession copyWith({
    double? finalBalance,
    double? totalSales,
    double? totalCashIn,
    double? totalCashOut,
    double? difference,
    String? status,
    DateTime? closedAt,
    String? notes,
  }) {
    return CashSession(
      id: id,
      userId: userId,
      userName: userName,
      initialBalance: initialBalance,
      finalBalance: finalBalance ?? this.finalBalance,
      totalSales: totalSales ?? this.totalSales,
      totalCashIn: totalCashIn ?? this.totalCashIn,
      totalCashOut: totalCashOut ?? this.totalCashOut,
      difference: difference ?? this.difference,
      status: status ?? this.status,
      openedAt: openedAt,
      closedAt: closedAt ?? this.closedAt,
      notes: notes ?? this.notes,
    );
  }
}