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

}
