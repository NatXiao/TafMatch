import 'package:flutter/material.dart';
import '../models/skill_model.dart';
import '../repositories/firestore_skill_repository.dart';

class SkillProvider with ChangeNotifier {
  final FirestoreSkillRepository _repository;

  SkillProvider(this._repository);

  List<Skill> _skills = [];
  bool _isLoading = false;

  List<Skill> get skills => _skills;
  bool get isLoading => _isLoading;

  Future<void> loadSkills() async {
    _isLoading = true;
    notifyListeners();
    _skills = await _repository.getAll();
    _isLoading = false;
    notifyListeners();
  }
}