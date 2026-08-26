import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../repositories/firestore_user_repository.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService;
  final FirestoreUserRepository _userRepository;

  User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  AuthProvider(this._authService, this._userRepository) {
    _authService.authStateChanges().listen((User? user) {
      _user = user;
      notifyListeners();
    });
  }

  // CONNEXION
  Future<bool> signInWithEmailAndPassword(String email, String password) {
    return _authenticate(
      () => _authService.signInWithEmailAndPassword(email, password),
    );
  }

  // INSCRIPTION
  Future<bool> register(
    String email,
    String password,
    String fullName,
    String role,
    String address,
    {String profilePictureUrl = ''}
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Firebase crée le compte et renvoie l'uid
      final uid = await _authService.register(email, password);

      if (uid == null) {
        _errorMessage = "Échec de la création du compte";
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Construction du profil
      final newUser = UserModel(
        uid: uid,
        email: email,
        fullName: fullName,
        role: role,
        address: address,
        profilePictureUrl: profilePictureUrl,
      );

      // Ecriture dans firestore
      await _userRepository.createProfile(newUser);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // DÉCONNEXION
  Future<void> signOut() async {
    _errorMessage = await _authService.signOut();
    notifyListeners();
  }

  // Efface le message d'erreur affiché
  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  // Helper loading
  Future<bool> _authenticate(Future<String?> Function() action) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final error = await action();

    _isLoading = false;
    _errorMessage = error;
    notifyListeners();

    return error == null;
  }
}