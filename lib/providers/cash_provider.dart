import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/cash_session.dart';
import '../models/cash_transaction.dart';
import '../services/firestore_service.dart';

class CashProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  CashSession? _currentSession;
  List<CashSession> _sessionHistory = [];
  List<CashTransaction> _transactions = [];
  bool _isLoading = false;
  bool _isCashOpen = false;
  String? _errorMessage;

  CashSession? get currentSession => _currentSession;
  List<CashSession> get sessionHistory => _sessionHistory;
  List<CashTransaction> get transactions => _transactions;
  bool get isLoading => _isLoading;
  bool get isCashOpen => _isCashOpen;
  String? get errorMessage => _errorMessage;

  double get totalCashIn => _transactions
      .where((t) => t.isCashIn)
      .fold(0, (total, t) => total + t.amount);

  double get totalCashOut => _transactions
      .where((t) => !t.isCashIn)
      .fold(0, (total, t) => total + t.amount);

  double get netCashFlow => totalCashIn - totalCashOut;

  // Listen to current session changes
  void listenToCurrentSession(String userId) {
    _firestoreService.getCurrentCashSession(userId).listen((session) {
      _currentSession = session;
      _isCashOpen = session != null && session.status == 'open';
      notifyListeners();
    });
  }

  // Listen to session history
  void listenToSessionHistory(String userId) {
    _firestoreService.getCashSessionsByUser(userId).listen((sessions) {
      _sessionHistory = sessions;
      notifyListeners();
    });
  }

  // Listen to transactions for current session
  void listenToTransactions(String sessionId) {
    _firestoreService
        .getCashTransactionsBySession(sessionId)
        .listen((transactions) {
      _transactions = transactions;
      notifyListeners();
    });
  }

  List<CashTransaction> get cashTransactions => _transactions;

  Future<bool> openCashSession({
    required double initialBalance,
    String? notes,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _errorMessage = 'User not authenticated';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    try {
      final session = CashSession(
        id: '',
        userId: user.uid,
        userName: user.displayName ?? user.email ?? user.uid,
        initialBalance: initialBalance,
        status: 'open',
        openedAt: DateTime.now(),
        notes: notes,
      );

      await _firestoreService.openCashSession(session);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> closeCashSession({
    required double finalBalance,
    required double totalSales,
    String? notes,
  }) async {
    if (_currentSession == null) {
      _errorMessage = 'No active cash session';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final expectedBalance = _currentSession!.initialBalance +
          totalSales +
          totalCashIn -
          totalCashOut;
      final difference = finalBalance - expectedBalance;

      final closedSession = _currentSession!.copyWith(
        finalBalance: finalBalance,
        totalSales: totalSales,
        totalCashIn: totalCashIn,
        totalCashOut: totalCashOut,
        difference: difference,
        status: 'closed',
        closedAt: DateTime.now(),
        notes: notes,
      );

      await _firestoreService.closeCashSession(
          _currentSession!.id, closedSession);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addCashTransaction({
    required String type,
    required double amount,
    required String description,
    String? category,
  }) async {
    if (_currentSession == null) {
      _errorMessage = 'No active cash session';
      notifyListeners();
      return false;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _errorMessage = 'User not authenticated';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final transaction = CashTransaction(
        id: '',
        sessionId: _currentSession!.id,
        userId: user.uid,
        type: type,
        amount: amount,
        description: description,
        category: category,
        createdAt: DateTime.now(),
      );

      await _firestoreService.addCashTransaction(transaction);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearData() {
    _currentSession = null;
    _sessionHistory = [];
    _transactions = [];
    _isCashOpen = false;
    _errorMessage = null;
    notifyListeners();
  }
}