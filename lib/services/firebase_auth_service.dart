import 'dart:developer' as dev;

import 'package:firebase_auth/firebase_auth.dart';

import 'auth_service.dart';

class FirebaseAuthService implements AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  User? get currentUser => _auth.currentUser;

  @override
  Stream<User?> authStateChanges() {
    return _auth.authStateChanges();
  }

  @override
  Future<String?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return null;
    } on FirebaseAuthException catch (e) {
      return _handleAuthException(e);
    } catch (e) {
      return e.toString();
    }
  }

  // Crée le compte et renvoie l'uid (ou null si échec).
  // Le profil Firestore est créé par le repository, pas ici.
  @override
  Future<String?> register(String email, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final uid = credential.user?.uid;

      dev.log(
        'Firebase Auth user created: $uid',
        name: 'FirebaseAuthService',
      );

      return uid;   // ← l'uid attendu par AuthProvider
    } on FirebaseAuthException catch (e) {
      dev.log('Auth error: ${e.code}', name: 'FirebaseAuthService');
      return null;  // échec → AuthProvider affichera l'erreur
    } catch (e) {
      dev.log('Unknown error: $e', name: 'FirebaseAuthService');
      return null;
    }
  }

  @override
  Future<String?> signOut() async {
    try {
      await _auth.signOut();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Wrong password provided for that user.';
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'The account already exists for that email.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      default:
        return e.message ?? 'An unknown error occurred.';
    }
  }
}