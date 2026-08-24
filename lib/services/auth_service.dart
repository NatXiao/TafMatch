import 'package:firebase_auth/firebase_auth.dart';

abstract class AuthService {
  User? get currentUser;
  Stream<User?> authStateChanges();
  Future<String?> signInWithEmailAndPassword(String email, String password);
  Future<String?> registerWithEmailAndPassword(String email, String password);
  Future<String?> signOut();
}
