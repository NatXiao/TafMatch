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
  String nameForId(String id) {
    final match = _skills.where((s) => s.id == id);
    return match.isNotEmpty ? match.first.name : id;
  }

  List<String> namesForIds(Iterable<String> ids) =>
      ids.map(nameForId).toList();
}