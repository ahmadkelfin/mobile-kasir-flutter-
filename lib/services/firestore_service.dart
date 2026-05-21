import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/transaction_model.dart';
import '../models/user_model.dart';
import '../models/product.dart';
import '../models/cash_session.dart';
import '../models/cash_transaction.dart';
import '../models/supplier.dart';
import '../models/purchase.dart';
import '../models/customer.dart';
import '../models/activity_log.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ─── HELPER ────────────────────────────────────────────────────────────────

  String _getCurrentUserId() {
    return _auth.currentUser?.uid ?? 'unknown';
  }

  // ─── TRANSACTIONS ──────────────────────────────────────────────────────────

  Future<void> addTransaction(TransactionModel transaction) async {
    await _firestore.collection('transactions').add(transaction.toMap());
    await logActivity('add_transaction', 'Tambah transaksi baru');
  }

  Stream<List<TransactionModel>> getUserTransactions(String userId) {
    return _firestore
        .collection('transactions')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final transactions = snapshot.docs.map((doc) {
        return TransactionModel.fromMap(doc.data(), doc.id);
      }).toList();
      transactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return transactions;
    });
  }

  Stream<List<TransactionModel>> getAllTransactions() {
    return _firestore
        .collection('transactions')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return TransactionModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // ─── RETUR TRANSAKSI ───────────────────────────────────────────────────────

  Future<void> returnTransaction(String transactionId, String reason) async {
    await _firestore.collection('transactions').doc(transactionId).update({
      'status': 'returned',
      'returnReason': reason,
      'returnedAt': Timestamp.now(),
    });

    // Kembalikan stok
    final doc =
        await _firestore.collection('transactions').doc(transactionId).get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      if (data['items'] != null) {
        for (var item in data['items']) {
          final product =
              await getProductById(item['productId'] as String);
          if (product != null) {
            await updateProductStock(
              product.id,
              product.stock + (item['quantity'] as num).toInt(),
            );
          }
        }
      }
    }

    await logActivity(
      'return_transaction',
      'Retur transaksi: $reason',
      metadata: {'transactionId': transactionId},
    );
  }

  // ─── VOID TRANSAKSI ────────────────────────────────────────────────────────

  Future<void> voidTransaction(String transactionId, String reason) async {
    await _firestore.collection('transactions').doc(transactionId).update({
      'status': 'void',
      'voidReason': reason,
      'voidedAt': Timestamp.now(),
    });

    // Kembalikan stok
    final doc =
        await _firestore.collection('transactions').doc(transactionId).get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      if (data['items'] != null) {
        for (var item in data['items']) {
          final product =
              await getProductById(item['productId'] as String);
          if (product != null) {
            await updateProductStock(
              product.id,
              product.stock + (item['quantity'] as num).toInt(),
            );
          }
        }
      }
    }

    await logActivity(
      'void_transaction',
      'Void transaksi: $reason',
      metadata: {'transactionId': transactionId},
    );
  }

  // ─── USERS ─────────────────────────────────────────────────────────────────

  Stream<List<UserModel>> getAllUsers() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return UserModel.fromMap(doc.data());
      }).toList();
    });
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(uid).update(data);
    await logActivity('edit_user', 'Update user: $uid');
  }

  Future<void> deleteUser(String uid) async {
    await _firestore.collection('users').doc(uid).delete();
    await logActivity('delete_user', 'Hapus user: $uid');
  }

  // ─── DASHBOARD ─────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getDashboardData(
      String userId, String role) async {
    if (role == 'owner') {
      final snapshot =
          await _firestore.collection('transactions').get();
      final transactions = snapshot.docs
          .map((doc) =>
              TransactionModel.fromMap(doc.data(), doc.id))
          .toList();

      double totalIncome = 0;
      double totalExpense = 0;
      for (var t in transactions) {
        if (t.type == 'income') {
          totalIncome += t.amount;
        } else {
          totalExpense += t.amount;
        }
      }

      return {
        'totalTransactions': transactions.length,
        'totalProfit': totalIncome - totalExpense,
        'totalIncome': totalIncome,
        'totalExpense': totalExpense,
      };
    } else {
      final snapshot = await _firestore
          .collection('transactions')
          .where('userId', isEqualTo: userId)
          .get();
      final transactions = snapshot.docs
          .map((doc) =>
              TransactionModel.fromMap(doc.data(), doc.id))
          .toList();

      double totalAmount = 0;
      for (var t in transactions) {
        totalAmount += t.amount;
      }

      return {
        'totalTransactions': transactions.length,
        'totalAmount': totalAmount,
      };
    }
  }

  // ─── PRODUCTS ──────────────────────────────────────────────────────────────

  Future<DocumentReference> addProduct(Product product) async {
    final ref =
        await _firestore.collection('products').add(product.toMap());
    await logActivity('add_product', 'Tambah produk: ${product.name}');
    return ref;
  }

  Future<void> updateProductImageUrl(
      String productId, String imageUrl) async {
    debugPrint('[FirestoreService] Updating product $productId with imageUrl: $imageUrl');
    try {
      await _firestore.collection('products').doc(productId).update({
        'imageUrl': imageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('[FirestoreService] Product $productId updated successfully');
    } catch (e) {
      debugPrint('[FirestoreService] Error updating product: $e');
      rethrow;
    }
  }

  Future<void> updateProduct(String productId, Product product) async {
    debugPrint('[FirestoreService] Updating product $productId with: ${product.toMap()}');
    try {
      await _firestore
          .collection('products')
          .doc(productId)
          .update(product.toMap());
      debugPrint('[FirestoreService] Product $productId updated successfully');
      await logActivity('edit_product', 'Edit produk: ${product.name}');
    } catch (e) {
      debugPrint('[FirestoreService] Error updating product: $e');
      rethrow;
    }
  }

  Future<void> deleteProduct(String productId) async {
    await _firestore.collection('products').doc(productId).delete();
    await logActivity('delete_product', 'Hapus produk ID: $productId');
  }

  Stream<List<Product>> getAllProducts() {
    return _firestore
        .collection('products')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      final products = snapshot.docs
          .map((doc) => Product.fromMap(doc.data(), doc.id))
          .toList();
      products.sort((a, b) => a.name.compareTo(b.name));
      return products;
    });
  }

  Stream<List<Product>> getProductsByCategory(String category) {
    return _firestore
        .collection('products')
        .where('category', isEqualTo: category)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      final products = snapshot.docs
          .map((doc) => Product.fromMap(doc.data(), doc.id))
          .toList();
      products.sort((a, b) => a.name.compareTo(b.name));
      return products;
    });
  }

  Future<List<String>> getProductCategories() async {
    final snapshot = await _firestore
        .collection('products')
        .where('isActive', isEqualTo: true)
        .get();

    final categories = <String>{};
    for (var doc in snapshot.docs) {
      final data = doc.data();
      categories.add(data['category'] as String? ?? 'Umum');
    }
    return categories.toList()..sort();
  }

  Future<void> updateProductStock(String productId, int newStock) async {
    await _firestore.collection('products').doc(productId).update({
      'stock': newStock,
      'updatedAt': Timestamp.now(),
    });
  }

  Future<Product?> getProductById(String productId) async {
    final doc = await _firestore
        .collection('products')
        .doc(productId)
        .get();
    if (doc.exists) {
      return Product.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }
    return null;
  }

  Future<Product?> getProductByBarcode(String barcode) async {
    final snapshot = await _firestore
        .collection('products')
        .where('barcode', isEqualTo: barcode)
        .where('isActive', isEqualTo: true)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return Product.fromMap(
        snapshot.docs.first.data(),
        snapshot.docs.first.id,
      );
    }
    return null;
  }

  /// Produk dengan stok <= minimumStock
  Future<List<Product>> getLowStockProducts() async {
    final snapshot = await _firestore
        .collection('products')
        .where('isActive', isEqualTo: true)
        .get();

    final products = snapshot.docs
        .map((doc) => Product.fromMap(doc.data(), doc.id))
        .where((p) => p.stock <= p.minimumStock)
        .toList();

    products.sort((a, b) => a.stock.compareTo(b.stock));
    return products;
  }

  // ─── CASH SESSIONS ─────────────────────────────────────────────────────────

  Future<DocumentReference> openCashSession(CashSession session) async {
    final ref = await _firestore
        .collection('cash_sessions')
        .add(session.toMap());
    await logActivity('open_cash', 'Buka kas baru');
    return ref;
  }

  Future<void> closeCashSession(
      String sessionId, CashSession closedSession) async {
    await _firestore
        .collection('cash_sessions')
        .doc(sessionId)
        .update(closedSession.toMap());
    await logActivity('close_cash', 'Tutup kas untuk session $sessionId');
  }

  Stream<CashSession?> getCurrentCashSession(String userId) {
    return _firestore
        .collection('cash_sessions')
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'open')
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return CashSession.fromMap(
          snapshot.docs.first.data(), snapshot.docs.first.id);
    });
  }

  Stream<List<CashSession>> getCashSessionsByUser(String userId) {
    return _firestore
        .collection('cash_sessions')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => CashSession.fromMap(doc.data(), doc.id))
          .toList()
        ..sort((a, b) => b.openedAt.compareTo(a.openedAt));
    });
  }

  /// Semua session (untuk owner)
  Stream<List<CashSession>> getAllCashSessions() {
    return _firestore
        .collection('cash_sessions')
        .orderBy('openedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => CashSession.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // ─── CASH TRANSACTIONS ─────────────────────────────────────────────────────

  Future<DocumentReference> addCashTransaction(
      CashTransaction transaction) async {
    final ref = await _firestore
        .collection('cash_transactions')
        .add(transaction.toMap());
    await logActivity(
      'cash_transaction',
      '${transaction.type == 'in' ? 'Kas masuk' : 'Kas keluar'}: ${transaction.description}',
    );
    return ref;
  }

  Stream<List<CashTransaction>> getCashTransactionsBySession(
      String sessionId) {
    return _firestore
        .collection('cash_transactions')
        .where('sessionId', isEqualTo: sessionId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => CashTransaction.fromMap(doc.data(), doc.id))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });
  }

  // ─── SUPPLIERS ─────────────────────────────────────────────────────────────

  Future<DocumentReference> addSupplier(Supplier supplier) async {
    final ref =
        await _firestore.collection('suppliers').add(supplier.toMap());
    await logActivity('add_supplier', 'Tambah supplier: ${supplier.name}');
    return ref;
  }

  Future<void> updateSupplier(String supplierId, Supplier supplier) async {
    await _firestore
        .collection('suppliers')
        .doc(supplierId)
        .update(supplier.toMap());
    await logActivity('edit_supplier', 'Edit supplier: ${supplier.name}');
  }

  Future<void> deleteSupplier(String supplierId) async {
    await _firestore.collection('suppliers').doc(supplierId).delete();
    await logActivity(
        'delete_supplier', 'Hapus supplier ID: $supplierId');
  }

  Stream<List<Supplier>> getAllSuppliers() {
    return _firestore
        .collection('suppliers')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Supplier.fromMap(doc.data(), doc.id))
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));
    });
  }

  Future<Supplier?> getSupplierById(String supplierId) async {
    final doc = await _firestore
        .collection('suppliers')
        .doc(supplierId)
        .get();
    if (doc.exists) {
      return Supplier.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }
    return null;
  }

  // ─── PURCHASES ─────────────────────────────────────────────────────────────

  Future<DocumentReference> addPurchase(Purchase purchase) async {
    final ref =
        await _firestore.collection('purchases').add(purchase.toMap());

    // Update stok produk
    for (var item in purchase.items) {
      final product = await getProductById(item.productId);
      if (product != null) {
        await updateProductStock(
          item.productId,
          product.stock + item.quantity,
        );
      }
    }

    await logActivity(
      'add_purchase',
      'Tambah pembelian dengan ${purchase.items.length} produk',
    );
    return ref;
  }

  Stream<List<Purchase>> getAllPurchases() {
    return _firestore
        .collection('purchases')
        .orderBy('purchaseDate', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Purchase.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Stream<List<Purchase>> getPurchasesBySupplier(String supplierId) {
    return _firestore
        .collection('purchases')
        .where('supplierId', isEqualTo: supplierId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Purchase.fromMap(doc.data(), doc.id))
          .toList()
        ..sort((a, b) => b.purchaseDate.compareTo(a.purchaseDate));
    });
  }

  // ─── CUSTOMERS ─────────────────────────────────────────────────────────────

  Future<DocumentReference> addCustomer(Customer customer) async {
    final ref =
        await _firestore.collection('customers').add(customer.toMap());
    await logActivity('add_customer', 'Tambah customer: ${customer.name}');
    return ref;
  }

  Future<void> updateCustomer(
      String customerId, Customer customer) async {
    await _firestore
        .collection('customers')
        .doc(customerId)
        .update(customer.toMap());
    await logActivity('edit_customer', 'Edit customer: ${customer.name}');
  }

  Future<void> deleteCustomer(String customerId) async {
    await _firestore.collection('customers').doc(customerId).delete();
    await logActivity(
        'delete_customer', 'Hapus customer ID: $customerId');
  }

  Stream<List<Customer>> getAllCustomers() {
    return _firestore
        .collection('customers')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Customer.fromMap(doc.data(), doc.id))
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));
    });
  }

  Future<Customer?> getCustomerById(String customerId) async {
    final doc = await _firestore
        .collection('customers')
        .doc(customerId)
        .get();
    if (doc.exists) {
      return Customer.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }
    return null;
  }

  Future<void> updateCustomerPurchaseStats(
      String customerId, double amount) async {
    final customer = await getCustomerById(customerId);
    if (customer != null) {
      await _firestore
          .collection('customers')
          .doc(customerId)
          .update({
        'totalPurchased': customer.totalPurchased + amount,
        'totalTransactions': customer.totalTransactions + 1,
        'lastPurchase': Timestamp.now(),
      });
    }
  }

  /// Riwayat transaksi milik customer tertentu
  Stream<List<TransactionModel>> getTransactionsByCustomer(
      String customerId) {
    return _firestore
        .collection('transactions')
        .where('customerId', isEqualTo: customerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => TransactionModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // ─── RECEIPT / STRUK ───────────────────────────────────────────────────────

  /// Ambil detail transaksi lengkap (untuk generate struk)
  Future<TransactionModel?> getTransactionById(
      String transactionId) async {
    final doc = await _firestore
        .collection('transactions')
        .doc(transactionId)
        .get();
    if (doc.exists) {
      return TransactionModel.fromMap(
          doc.data() as Map<String, dynamic>, doc.id);
    }
    return null;
  }

  // ─── DELETE ALL DATA ──────────────────────────────────────────────────────

  Future<void> deleteAllData() async {
    final batch = _firestore.batch();

    // Delete all products
    final products = await _firestore.collection('products').get();
    for (var doc in products.docs) {
      batch.delete(doc.reference);
    }

    // Delete all transactions
    final transactions = await _firestore.collection('transactions').get();
    for (var doc in transactions.docs) {
      batch.delete(doc.reference);
    }

    // Delete other collections if needed
    final suppliers = await _firestore.collection('suppliers').get();
    for (var doc in suppliers.docs) {
      batch.delete(doc.reference);
    }

    final purchases = await _firestore.collection('purchases').get();
    for (var doc in purchases.docs) {
      batch.delete(doc.reference);
    }

    final customers = await _firestore.collection('customers').get();
    for (var doc in customers.docs) {
      batch.delete(doc.reference);
    }

    final cashSessions = await _firestore.collection('cash_sessions').get();
    for (var doc in cashSessions.docs) {
      batch.delete(doc.reference);
    }

    final cashTransactions = await _firestore.collection('cash_transactions').get();
    for (var doc in cashTransactions.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
    await logActivity('delete_all_data', 'Hapus semua data aplikasi');
  }

  // ─── ACTIVITY LOGS ─────────────────────────────────────────────────────────

  Future<void> logActivity(
    String action,
    String? description, {
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final log = ActivityLog(
        id: '',
        userId: _getCurrentUserId(),
        action: action,
        description: description,
        metadata: metadata,
        createdAt: DateTime.now(),
      );
      await _firestore.collection('activity_logs').add(log.toMap());
    } catch (e) {
      // Jangan interrupt alur utama, cukup cetak di debug
      debugPrint('Activity logging error: $e');
    }
  }

  Stream<List<ActivityLog>> getActivityLogs({int limit = 100}) {
    return _firestore
        .collection('activity_logs')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ActivityLog.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  /// Log aktivitas login — panggil dari AuthService setelah berhasil login
  Future<void> logLogin() async {
    await logActivity('login', 'User login ke aplikasi');
  }
}