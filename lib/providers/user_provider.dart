import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../repositories/firestore_user_repository.dart';

class UserProvider with ChangeNotifier {
  final FirestoreUserRepository _repository;

  UserProvider(this._repository);

  UserModel? _profile;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

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
    notifyListeners();
  }
}