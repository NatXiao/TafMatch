import 'dart:async';
import 'package:flutter/material.dart';
import '../models/job_model.dart';
import '../repositories/firestore_job_repository.dart';

class JobProvider with ChangeNotifier {
  final FirestoreJobRepository _repository;

  JobProvider(this._repository);

  List<Job> _jobs = [];
  StreamSubscription? _subscription;

  List<Job> get jobs => _jobs;

  // Listen to open job postings (student side)
  void listenToLiveJobs() {
    _subscription?.cancel();
    _subscription = _repository.watchLiveJobs().listen((jobs) {
      _jobs = jobs;
      notifyListeners();
    });
  }

  // Listen to an employer's job postings
  void listenToEmployerJobs(String employerId) {
    _subscription?.cancel();
    _subscription = _repository.watchByEmployer(employerId).listen((jobs) {
      _jobs = jobs;
      notifyListeners();
    });
  }

  Future<String> createJob(Job job) => _repository.create(job);

  Future<void> updateJob(String id, Map<String, dynamic> fields) =>
      _repository.update(id, fields);

  Future<void> deleteJob(String id) => _repository.delete(id);

  @override
  void dispose() {
    _subscription?.cancel(); // on coupe l'abonnement
    super.dispose();
  }
}