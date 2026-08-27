import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:taf_match/models/user_model.dart';
import 'package:taf_match/providers/auth_provider.dart';
import 'package:taf_match/providers/user_provider.dart';

import '../fakes.dart';

UserModel _user(String id) =>
    UserModel(uid: id, fullName: 'N$id', email: 'mail$id@unit.ch', role: "user", address: 'Rue $id');

void main() {
  late FakeUserRepository repository;
  late FakeAuthService authService;
  late AuthProvider authProvider;
  late UserProvider provider;

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    repository = FakeUserRepository();
    authService = FakeAuthService();
    authProvider = AuthProvider(authService, repository);
    provider = UserProvider(repository);
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
    expect(provider.profile, isNull);
    expect(provider.isLoading, isFalse);
  });

  test('Store user data', () async {

    UserModel user = _user("1234");

    authService.stringGate = Completer<String?>();

    final future = authProvider.register(user.email, "1234", user.fullName, user.role, user.address);
    await Future<void>.delayed(Duration.zero);

    expect(authProvider.errorMessage, isNull);

    authService.stringGate!.complete("uuid");
    await future;

    expect(repository.lastAddedUser?.email, user.email);
    expect(repository.lastAddedUser?.fullName, user.fullName);
    expect(repository.lastAddedUser?.address, user.address);
    expect(repository.lastAddedUser?.role, user.role);

  });

  test('Connection update user informations', () async {

    // Register user
    UserModel user = _user("1234");
    authService.stringGate = Completer<String?>();

    final future = authProvider.register(user.email, "1234", user.fullName, user.role, user.address);
    await Future<void>.delayed(Duration.zero);

    authService.stringGate!.complete("uuid");
    await future;

    provider.updateAuthProvider(authProvider);

    // Connect user
    await signInAs('uuid');

    await Future<void>.delayed(Duration.zero);
    expect(provider.profile?.email, user.email);
    
  });

  test('loadUsers loads users successfully', () async {
    final users = [
      _user('1'),
      _user('2'),
      _user('3'),
    ];

    repository.usersToReturn = users;

    await provider.loadUsers();

    expect(provider.users.length, 3);
    expect(provider.users[0].uid, '1');
    expect(provider.users[1].uid, '2');
    expect(provider.users[2].uid, '3');

    expect(provider.errorMessage, isNull);
    expect(provider.isLoading, isFalse);
  });

  test('loadUsers loads users successfully', () async {
    final user1 = _user('1');

    final user2 = UserModel(
      uid: '2',
      fullName: 'Employer',
      email: 'employer@unit.ch',
      role: 'employer',
      address: 'Rue 2',
    );

    repository.usersToReturn = [user1, user2];

    await provider.loadUsers();

    expect(repository.getUsersCallCount, 1);

    expect(provider.users.length, 2);
    expect(provider.users[0].uid, '1');
    expect(provider.users[1].uid, '2');

    expect(provider.errorMessage, isNull);
    expect(provider.isLoading, isFalse);
  });

  test('loadUsers sets isLoading to true while loading', () async {
    repository.getUsersGate = Completer<List<UserModel>>();

    final future = provider.loadUsers();

    await Future<void>.delayed(Duration.zero);

    expect(provider.isLoading, isTrue);

    repository.getUsersGate!.complete([
      _user('1'),
    ]);

    await future;

    expect(provider.isLoading, isFalse);
  });

  test('loadUsers stores loaded users', () async {
    repository.usersToReturn = [
      _user('1'),
      _user('2'),
      _user('3'),
    ];

    await provider.loadUsers();

    expect(provider.users, hasLength(3));
    expect(
      provider.users.map((user) => user.uid),
      containsAll(['1', '2', '3']),
    );

    expect(provider.errorMessage, isNull);
    expect(provider.isLoading, isFalse);
  });

  test('loadUsers stores error message when repository throws', () async {
    repository.getUsersError = Exception('Unable to load users');

    await provider.loadUsers();

    expect(provider.errorMessage, contains('Unable to load users'));
    expect(provider.isLoading, isFalse);
  });

  test('loadUsers clears previous error after successful load', () async {
    repository.getUsersError = Exception('First error');

    await provider.loadUsers();

    expect(provider.errorMessage, isNotNull);

    repository.getUsersError = null;
    repository.usersToReturn = [_user('1')];

    await provider.loadUsers();

    expect(provider.errorMessage, isNull);
    expect(provider.users, hasLength(1));
  });
}