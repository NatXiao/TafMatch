import 'package:firebase_auth/firebase_auth.dart';

abstract class AuthService {
  User? get currentUser;
  Stream<User?> authStateChanges();
  Future<String?> signInWithEmailAndPassword(String email, String password);

  // Returns the new user's uid, or null on failure.
  Future<String?> register(String email, String password);

  Future<String?> signOut();
}