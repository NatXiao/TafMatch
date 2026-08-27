import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:taf_match/models/task_model.dart';
import 'package:taf_match/repositories/task_repository.dart';
import 'package:taf_match/services/auth_service.dart';

class FakeUser implements User {
  @override
  final String uid;

  FakeUser(this.uid);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

class FakeAuthService implements AuthService {
  final StreamController<User?> _controller = StreamController<User?>();
  User? _currentUser;

  String? signInError;
  String? registerError;
  String? signOutError;

  Completer<void>? gate;

  @override
  User? get currentUser => _currentUser;

  @override
  Stream<User?> authStateChanges() => _controller.stream;

  void emitUser(User? user) {
    _currentUser = user;
    _controller.add(user);
  }

  @override
  Future<String?> signInWithEmailAndPassword(String email, String password) async {
    if (gate != null) await gate!.future;
    return signInError;
  }

  @override
  Future<String?> registerWithEmailAndPassword(String email, String password) async {
    if (gate != null) await gate!.future;
    return registerError;
  }

  @override
  Future<String?> signOut() async => signOutError;

  void dispose() => _controller.close();
}

class FakeTaskRepository implements TaskRepository {
  final Map<String, StreamController<List<Task>>> _controllers = {};

  Task? lastAddedTask;
  Task? lastUpdatedTask;
  String? lastDeletedTaskId;
  String? lastUserId;

  StreamController<List<Task>> _controllerFor(String userId) =>
      _controllers.putIfAbsent(
        userId,
        () => StreamController<List<Task>>.broadcast(),
      );

  void emitTasks(String userId, List<Task> tasks) =>
      _controllerFor(userId).add(tasks);

  @override
  Stream<List<Task>> watchTasks(String userId) => _controllerFor(userId).stream;

  @override
  Future<void> addTask(Task task, String userId) async {
    lastAddedTask = task;
    lastUserId = userId;
  }

  @override
  Future<void> updateTask(Task task, String userId) async {
    lastUpdatedTask = task;
    lastUserId = userId;
  }

  @override
  Future<void> deleteTask(String taskId, String userId) async {
    lastDeletedTaskId = taskId;
    lastUserId = userId;
  }

  @override
  Future<List<UserModel>> getUsers() {
    // TODO: implement getUsers
    throw UnimplementedError();
  }

  void dispose() {
    for (final controller in _controllers.values) {
      controller.close();
    }
  }
}
