import 'package:firebase_auth/firebase_auth.dart';

abstract class AuthService {
  User? get currentUser;
  Stream<User?> authStateChanges();
  Future<String?> signInWithEmailAndPassword(String email, String password);

  // Renvoie l'uid du nouvel utilisateur, ou null si échec
  Future<String?> register(String email, String password);

  Future<String?> signOut();
}