import 'dart:async';
import 'package:flutter/material.dart';
import '../models/application_model.dart';
import '../repositories/firestore_application_repository.dart';

class ApplicationProvider with ChangeNotifier {
  final FirestoreApplicationRepository _repository;

  ApplicationProvider(this._repository);

  List<Application> _applications = [];
  StreamSubscription? _subscription;

  List<Application> get applications => _applications;

  // A student's applications
  void listenToStudentApplications(String studentId) {
    _subscription?.cancel();
    _subscription =
        _repository.watchByStudent(studentId).listen((apps) {
      _applications = apps;
      notifyListeners();
    });
  }

  // Applicants for a job posting (employer side)
  void listenToJobApplications(String jobId) {
    _subscription?.cancel();
    _subscription = _repository.watchByJob(jobId).listen((apps) {
      _applications = apps;
      notifyListeners();
    });
  }

  Future<void> apply(Application application) =>
      _repository.apply(application);

  Future<void> cancel(String applicationId) =>
      _repository.cancel(applicationId);

  Future<void> updateStatus(String applicationId, String status) =>
      _repository.updateStatus(applicationId, status);

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}