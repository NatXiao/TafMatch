import 'dart:async';
import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../repositories/task_repository.dart';
import 'auth_provider.dart';

class TaskProvider extends ChangeNotifier {
  final TaskRepository _repository;
  AuthProvider? _authProvider;
  StreamSubscription<List<Task>>? _tasksSubscription;
  String? _currentUserId;

  List<Task> _tasks = [];
  bool _isLoading = false;

  List<Task> get tasks => _tasks;
  bool get isLoading => _isLoading;

  TaskProvider(this._repository);

  void updateAuthProvider(AuthProvider authProvider) {
    _authProvider = authProvider;
    final userId = _authProvider?.user?.uid;

    if (userId == _currentUserId) return;
    _currentUserId = userId;

    _subscribeToTasks(userId);
  }

  void _subscribeToTasks(String? userId) {
    _tasksSubscription?.cancel();
    _tasksSubscription = null;

    if (userId == null) {
      _tasks = [];
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    _tasksSubscription = _repository.watchTasks(userId).listen((tasks) {
      _tasks = tasks;
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> addTask(Task task) async {
    final userId = _authProvider?.user?.uid;
    if (userId == null) return;
    await _repository.addTask(task, userId);
  }

  Future<void> updateTask(Task task) async {
    final userId = _authProvider?.user?.uid;
    if (userId == null) return;
    await _repository.updateTask(task, userId);
  }

  Future<void> deleteTask(String taskId) async {
    final userId = _authProvider?.user?.uid;
    if (userId == null) return;
    await _repository.deleteTask(taskId, userId);
  }

  @override
  void dispose() {
    _tasksSubscription?.cancel();
    super.dispose();
  }
}
