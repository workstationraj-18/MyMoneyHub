import 'package:firebase_auth/firebase_auth.dart';
import '../database/firebase_service.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _firebaseService = FirebaseService();

  // 🔹 Register new user with email/password + save profile to Firestore
  Future<User?> registerUser({
    required String email,
    required String password,
    required Map<String, dynamic> userData,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = cred.user;
    if (user != null) {
      await _firebaseService.createUser(user.uid, userData);
    }
    return user;
  }

  // 🔹 Login user with email/password
  Future<User?> loginUser({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return cred.user;
  }

  // 🔹 Logout user
  Future<void> logout() async {
    await _auth.signOut();
  }
}
