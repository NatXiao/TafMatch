import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:taf_match/providers/auth_provider.dart';

import '../fakes.dart';

void main() {
  late FakeAuthService authService;
  late AuthProvider provider;
  late FakeUserRepository userRepository;

  setUp(() {
    authService = FakeAuthService();
    userRepository = FakeUserRepository();
    provider = AuthProvider(authService, userRepository);
  });

  tearDown(() {
    provider.dispose();
    authService.dispose();
  });

  // The provider starts with no user, not loading and no error.
  test('starts without user, loading or error', () {
    expect(provider.user, isNull);
    expect(provider.isLoading, isFalse);
    expect(provider.errorMessage, isNull);
  });

  // The user is updated when the auth service emits a new auth state.
  test('updates user when auth state changes', () async {
    final user = FakeUser('abc');
    authService.emitUser(user);
    await Future<void>.delayed(Duration.zero);

    expect(provider.user, same(user));
  });

  // A successful sign in returns true and leaves no error.
  test('successful sign in returns true and clears error', () async {
    authService.signInError = null;

    final result = await provider.signInWithEmailAndPassword('a@b.c', 'pw');

    expect(result, isTrue);
    expect(provider.errorMessage, isNull);
    expect(provider.isLoading, isFalse);
  });

  // A failed sign in returns false and exposes the error message.
  test('failed sign in returns false and exposes the error', () async {
    authService.signInError = 'Wrong password provided for that user.';

    final result = await provider.signInWithEmailAndPassword('a@b.c', 'pw');

    expect(result, isFalse);
    expect(provider.errorMessage, 'Wrong password provided for that user.');
    expect(provider.isLoading, isFalse);
  });

  // isLoading is true while an authentication is in progress.
  test('isLoading is true while authenticating', () async {
    authService.stringGate = Completer<String?>();

    final future = provider.register('a@b.c', 'pw', 'abc', 'user', '12 abc');
    await Future<void>.delayed(Duration.zero);

    expect(provider.isLoading, isTrue);

    authService.stringGate!.complete();
    await future;

    expect(provider.isLoading, isFalse);
  });

  // A successful register returns true and stores the created profile.
  test('successful register returns true and stores the profile', () async {
    authService.stringGate = Completer<String?>();

    final future = provider.register('a@b.c', 'pw', 'Alice', 'user', 'Rue 1');
    authService.stringGate!.complete('uuid');
    final result = await future;

    expect(result, isTrue);
    expect(provider.errorMessage, isNull);
    expect(userRepository.lastAddedUser?.uid, 'uuid');
    expect(userRepository.lastAddedUser?.email, 'a@b.c');
    expect(userRepository.lastAddedUser?.fullName, 'Alice');
  });

  // register returns false and sets an error when no uid comes back.
  test('register fails when the auth service returns no uid', () async {
    authService.stringGate = Completer<String?>();

    final future = provider.register('a@b.c', 'pw', 'Alice', 'user', 'Rue 1');
    authService.stringGate!.complete(null); // no uid
    final result = await future;

    expect(result, isFalse);
    expect(provider.errorMessage, isNotNull);
    expect(userRepository.lastAddedUser, isNull); // nothing stored
    expect(provider.isLoading, isFalse);
  });

  // signOut stores the error returned by the auth service (null means success).
  test('signOut clears error on success', () async {
    authService.signOutError = null;

    await provider.signOut();

    expect(provider.errorMessage, isNull);
  });

  // clearError resets a previously set error message.
  test('clearError resets the error message', () async {
    authService.signInError = 'boom';
    await provider.signInWithEmailAndPassword('a@b.c', 'pw');
    expect(provider.errorMessage, 'boom');

    provider.clearError();

    expect(provider.errorMessage, isNull);
  });
}