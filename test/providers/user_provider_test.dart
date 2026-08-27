import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:taf_match/models/user_model.dart';
import 'package:taf_match/providers/auth_provider.dart';
import 'package:taf_match/providers/user_provider.dart';

import '../fakes.dart';

UserModel _user(String id) =>
    UserModel(uid: id, fullName: 'N$id', email: 'mail$id@unit.ch', role: 'user', address: 'Rue $id');

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

  // The provider starts with no profile and not loading.
  test('starts empty and not loading', () {
    expect(provider.profile, isNull);
    expect(provider.isLoading, isFalse);
  });

  // register() stores the new user through the repository with all its fields.
  test('register stores the user data', () async {
    final user = _user('1234');
    authService.stringGate = Completer<String?>();

    final future =
        authProvider.register(user.email, '1234', user.fullName, user.role, user.address);
    await Future<void>.delayed(Duration.zero);

    expect(authProvider.errorMessage, isNull);

    authService.stringGate!.complete('uuid');
    await future;

    expect(repository.lastAddedUser?.email, user.email);
    expect(repository.lastAddedUser?.fullName, user.fullName);
    expect(repository.lastAddedUser?.address, user.address);
    expect(repository.lastAddedUser?.role, user.role);
  });

  // Signing in loads the matching profile into the provider.
  test('signing in loads the user profile', () async {
    final user = _user('1234');
    authService.stringGate = Completer<String?>();

    final future =
        authProvider.register(user.email, '1234', user.fullName, user.role, user.address);
    await Future<void>.delayed(Duration.zero);
    authService.stringGate!.complete('uuid');
    await future;

    provider.updateAuthProvider(authProvider);
    await signInAs('uuid');
    await Future<void>.delayed(Duration.zero);

    expect(provider.profile?.email, user.email);
  });

  // loadProfile stores the profile returned by the repository.
  test('loadProfile stores the profile', () async {
    final user = _user('42');
    await repository.createProfile(user); // seed the fake

    await provider.loadProfile('42');

    expect(provider.profile?.uid, '42');
    expect(provider.errorMessage, isNull);
    expect(provider.isLoading, isFalse);
  });

  // isAdmin is true only when the loaded profile has the admin role.
  test('isAdmin reflects the profile role', () async {
    final admin = UserModel(
        uid: 'a1', fullName: 'Admin', email: 'admin@unit.ch', role: 'admin', address: 'Rue A');
    await repository.createProfile(admin);

    await provider.loadProfile('a1');

    expect(provider.isAdmin, isTrue);
  });

  // loadUsers stores every user returned by the repository.
  test('loadUsers stores the loaded users', () async {
    repository.usersToReturn = [_user('1'), _user('2'), _user('3')];

    await provider.loadUsers();

    expect(provider.users, hasLength(3));
    expect(provider.users.map((u) => u.uid), containsAll(['1', '2', '3']));
    expect(provider.errorMessage, isNull);
    expect(provider.isLoading, isFalse);
  });

  // loadUsers calls the repository once and keeps mixed roles.
  test('loadUsers calls the repository once with mixed roles', () async {
    final student = _user('1');
    final employer = UserModel(
        uid: '2', fullName: 'Employer', email: 'employer@unit.ch', role: 'employer', address: 'Rue 2');
    repository.usersToReturn = [student, employer];

    await provider.loadUsers();

    expect(repository.getUsersCallCount, 1);
    expect(provider.users, hasLength(2));
    expect(provider.users[1].role, 'employer');
  });

  // isLoading is true while the users are being loaded.
  test('loadUsers sets isLoading to true while loading', () async {
    repository.getUsersGate = Completer<List<UserModel>>();

    final future = provider.loadUsers();
    await Future<void>.delayed(Duration.zero);

    expect(provider.isLoading, isTrue);

    repository.getUsersGate!.complete([_user('1')]);
    await future;

    expect(provider.isLoading, isFalse);
  });

  // loadUsers stores the error message when the repository throws.
  test('loadUsers stores error message when repository throws', () async {
    repository.getUsersError = Exception('Unable to load users');

    await provider.loadUsers();

    expect(provider.errorMessage, contains('Unable to load users'));
    expect(provider.isLoading, isFalse);
  });

  // A successful load clears an error left by a previous failed load.
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

  // clear() resets the profile and the users list.
  test('clear resets profile and users', () async {
    repository.usersToReturn = [_user('1'), _user('2')];
    await provider.loadUsers();
    expect(provider.users, isNotEmpty);

    provider.clear();

    expect(provider.users, isEmpty);
    expect(provider.profile, isNull);
  });
}