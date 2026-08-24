import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService;

  User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  AuthProvider(this._authService) {
    _authService.authStateChanges().listen((User? user) {
      _user = user;
      notifyListeners();
    });
  }

  Future<bool> signInWithEmailAndPassword(String email, String password) {
    return _authenticate(
      () => _authService.signInWithEmailAndPassword(email, password),
    );
  }

  Future<bool> registerWithEmailAndPassword(String email, String password) {
    return _authenticate(
      () => _authService.registerWithEmailAndPassword(email, password),
    );
  }

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

  Future<void> signOut() async {
    _errorMessage = await _authService.signOut();
    notifyListeners();
  }

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }
}
