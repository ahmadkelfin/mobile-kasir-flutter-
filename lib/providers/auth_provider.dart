import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  User? _user;
  UserModel? _userModel;
  bool _userDataMissing = false;
  bool _isLoading = false;

  User? get user => _user;
  UserModel? get userModel => _userModel;
  bool get userDataMissing => _userDataMissing;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    _init();
  }

  void _init() {
    _authService.authStateChanges.listen(_onAuthStateChanged);
  }

  void _onAuthStateChanged(User? user) async {
    _user = user;
    if (user != null) {
      _userModel = await _authService.getUserData(user.uid);
      _userDataMissing = _userModel == null;
    } else {
      _userModel = null;
      _userDataMissing = false;
    }
    notifyListeners();
  }

  Future<void> completeProfile(String name, String phone, String role) async {
    if (_user == null) {
      throw Exception('No authenticated user found');
    }

    _isLoading = true;
    notifyListeners();
    try {
      final data = {
        'uid': _user!.uid,
        'name': name,
        'email': _user!.email ?? '',
        'phone': phone,
        'role': role,
        'status': 'active',
      };
      await _authService.createUserData(_user!.uid, data);
      _userModel = UserModel.fromMap(data);
      _userDataMissing = false;
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signIn(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _authService.signInWithEmailAndPassword(email, password);
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> register(String email, String password, String name, String phone, String role) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _authService.registerWithEmailAndPassword(email, password, name, phone, role);
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    if (_user != null) {
      await _authService.updateUserData(_user!.uid, data);
      _userModel = await _authService.getUserData(_user!.uid);
      notifyListeners();
    }
  }

  Future<void> changePassword(String newPassword) async {
    await _authService.changePassword(newPassword);
  }

  Future<bool> verifyPassword(String password) async {
    return await _authService.verifyPassword(password);
  }

  Future<void> updateEmail(String newEmail) async {
    await _authService.updateEmail(newEmail);
    if (_user != null) {
      _userModel = await _authService.getUserData(_user!.uid);
      notifyListeners();
    }
  }
}