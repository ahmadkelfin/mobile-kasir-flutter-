// Tambahkan method-method ini ke class AuthProvider yang sudah ada
// File: lib/providers/auth_provider.dart

// ─────────────────────────────────────────────────────────────────────────────
// COPY method-method di bawah ini ke dalam class AuthProvider Anda
// ─────────────────────────────────────────────────────────────────────────────

/*

  // Update nama user di Firestore dan Firebase Auth
  Future<void> updateUserName(String newName) async {
    try {
      // Update di Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_userModel!.uid)
          .update({'name': newName});

      // Update di Firebase Auth display name
      await FirebaseAuth.instance.currentUser?.updateDisplayName(newName);

      // Update local state
      _userModel = UserModel(
        uid: _userModel!.uid,
        name: newName,
        email: _userModel!.email,
        role: _userModel!.role,
        phone: _userModel!.phone,
      );
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  // Update nomor telepon user di Firestore
  Future<void> updateUserPhone(String newPhone) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_userModel!.uid)
          .update({'phone': newPhone});

      // Update local state
      _userModel = UserModel(
        uid: _userModel!.uid,
        name: _userModel!.name,
        email: _userModel!.email,
        role: _userModel!.role,
        phone: newPhone,
      );
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

*/

// ─────────────────────────────────────────────────────────────────────────────
// Pastikan UserModel punya field phone. Jika belum ada, tambahkan:
// ─────────────────────────────────────────────────────────────────────────────

/*
// Di models/user_model.dart, pastikan ada field phone:

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String role;
  final String? phone;   // ← Tambahkan ini jika belum ada

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
    uid: map['uid'] ?? '',
    name: map['name'] ?? '',
    email: map['email'] ?? '',
    role: map['role'] ?? 'karyawan',
    phone: map['phone'],           // ← Tambahkan ini
  );

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'name': name,
    'email': email,
    'role': role,
    'phone': phone,                // ← Tambahkan ini
  };
}
*/
