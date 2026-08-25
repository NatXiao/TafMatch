import 'dart:async';
import 'package:flutter/material.dart';
import '../models/work_experience_model.dart';
import '../repositories/firestore_work_experience_repository.dart';

class WorkExperienceProvider with ChangeNotifier {
  final FirestoreWorkExperienceRepository _repository;

  WorkExperienceProvider(this._repository);

  List<WorkExperience> _experiences = [];
  StreamSubscription? _subscription;

  List<WorkExperience> get experiences => _experiences;

  void listenToUserExperiences(String uid) {
    _subscription?.cancel();
    _subscription =
        _repository.watchForUser(uid).listen((experiences) {
      _experiences = experiences;
      notifyListeners();
    });
  }

  Future<void> addExperience(String uid, WorkExperience exp) =>
      _repository.add(uid, exp);

  Future<void> deleteExperience(String uid, String experienceId) =>
      _repository.delete(uid, experienceId);

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}