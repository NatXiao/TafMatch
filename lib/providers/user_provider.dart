import 'package:flutter/material.dart';
import 'package:taf_match/providers/auth_provider.dart';
import '../models/user_model.dart';
import '../repositories/firestore_user_repository.dart';

class UserProvider with ChangeNotifier {
  final FirestoreUserRepository _repository;

  UserProvider(this._repository);

  AuthProvider? _authProvider;
  String? _currentUserId;

  UserModel? _profile;
  List<UserModel> _users = const [];
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get profile => _profile;
  List<UserModel> get users => _users;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAdmin => profile?.role == 'admin';

  Future<void> loadProfile(String uid) async {
    _isLoading = true;
    notifyListeners();
    try {
      _profile = await _repository.getProfile(uid);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadUsers() async {
    _isLoading = true;
    notifyListeners();
    try {
      _users = await _repository.getUsers();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addSkill(String uid, String skill) async {
    await _repository.addSkill(uid, skill);
    await loadProfile(uid); // on recharge pour refléter le changement
  }

  Future<void> removeSkill(String uid, String skill) async {
    await _repository.removeSkill(uid, skill);
    await loadProfile(uid);
  }

  void clear() {
    _profile = null;
    _users = const [];
    notifyListeners();
  }

  void updateAuthProvider(AuthProvider authProvider) {
    _authProvider = authProvider;
    final userId = _authProvider?.user?.uid;

    if (userId == _currentUserId) return;
    _currentUserId = userId;

    if (_currentUserId == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadProfile(_currentUserId!);
    });
  }
}
