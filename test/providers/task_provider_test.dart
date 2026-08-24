import 'package:flutter_test/flutter_test.dart';
import 'package:taf_match/models/task_model.dart';
import 'package:taf_match/providers/auth_provider.dart';
import 'package:taf_match/providers/task_provider.dart';

import '../fakes.dart';

Task _task(String id) =>
    Task(id: id, title: 'T$id', description: 'D$id', isCompleted: false);

void main() {
  late FakeTaskRepository repository;
  late FakeAuthService authService;
  late AuthProvider authProvider;
  late TaskProvider provider;

  setUp(() {
    repository = FakeTaskRepository();
    authService = FakeAuthService();
    authProvider = AuthProvider(authService);
    provider = TaskProvider(repository);
  });

  tearDown(() {
    provider.dispose();
    authProvider.dispose();
    authService.dispose();
    repository.dispose();
  });

  Future<void> signInAs(String uid) async {
    authService.emitUser(FakeUser(uid));
    await Future<void>.delayed(Duration.zero);
    provider.updateAuthProvider(authProvider);
  }

  test('starts empty and not loading', () {
    expect(provider.tasks, isEmpty);
    expect(provider.isLoading, isFalse);
  });

  test('is loading after subscribing until the first emission', () async {
    await signInAs('u1');
    expect(provider.isLoading, isTrue);

    repository.emitTasks('u1', [_task('1')]);
    await Future<void>.delayed(Duration.zero);

    expect(provider.isLoading, isFalse);
    expect(provider.tasks, hasLength(1));
  });

  test('reflects tasks emitted by the repository', () async {
    await signInAs('u1');

    repository.emitTasks('u1', [_task('1'), _task('2')]);
    await Future<void>.delayed(Duration.zero);

    expect(provider.tasks.map((t) => t.id), ['1', '2']);
  });

  test('clears tasks when there is no user', () async {
    await signInAs('u1');
    repository.emitTasks('u1', [_task('1')]);
    await Future<void>.delayed(Duration.zero);

    authService.emitUser(null);
    await Future<void>.delayed(Duration.zero);
    provider.updateAuthProvider(authProvider);

    expect(provider.tasks, isEmpty);
    expect(provider.isLoading, isFalse);
  });

  test('addTask forwards the task and user id to the repository', () async {
    await signInAs('u1');

    await provider.addTask(_task('new'));

    expect(repository.lastAddedTask?.id, 'new');
    expect(repository.lastUserId, 'u1');
  });

  test('updateTask forwards to the repository', () async {
    await signInAs('u1');

    await provider.updateTask(_task('e'));

    expect(repository.lastUpdatedTask?.id, 'e');
    expect(repository.lastUserId, 'u1');
  });

  test('deleteTask forwards to the repository', () async {
    await signInAs('u1');

    await provider.deleteTask('d');

    expect(repository.lastDeletedTaskId, 'd');
    expect(repository.lastUserId, 'u1');
  });

  test('does nothing when adding without a signed-in user', () async {
    await provider.addTask(_task('x'));

    expect(repository.lastAddedTask, isNull);
  });
}
