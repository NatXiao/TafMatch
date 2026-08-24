import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:taf_match/providers/auth_provider.dart';

import '../fakes.dart';

void main() {
  late FakeAuthService authService;
  late AuthProvider provider;

  setUp(() {
    authService = FakeAuthService();
    provider = AuthProvider(authService);
  });

  tearDown(() {
    provider.dispose();
    authService.dispose();
  });

  test('starts without user, loading or error', () {
    expect(provider.user, isNull);
    expect(provider.isLoading, isFalse);
    expect(provider.errorMessage, isNull);
  });

  test('updates user when auth state changes', () async {
    final user = FakeUser('abc');
    authService.emitUser(user);
    await Future<void>.delayed(Duration.zero);

    expect(provider.user, same(user));
  });

  test('successful sign in returns true and clears error', () async {
    authService.signInError = null;

    final result = await provider.signInWithEmailAndPassword('a@b.c', 'pw');

    expect(result, isTrue);
    expect(provider.errorMessage, isNull);
    expect(provider.isLoading, isFalse);
  });

  test('failed sign in returns false and exposes the error', () async {
    authService.signInError = 'Wrong password provided for that user.';

    final result = await provider.signInWithEmailAndPassword('a@b.c', 'pw');

    expect(result, isFalse);
    expect(provider.errorMessage, 'Wrong password provided for that user.');
    expect(provider.isLoading, isFalse);
  });

  test('isLoading is true while authenticating', () async {
    authService.gate = Completer<void>();

    final future = provider.registerWithEmailAndPassword('a@b.c', 'pw');
    await Future<void>.delayed(Duration.zero);

    expect(provider.isLoading, isTrue);

    authService.gate!.complete();
    await future;

    expect(provider.isLoading, isFalse);
  });

  test('clearError resets the error message', () async {
    authService.signInError = 'boom';
    await provider.signInWithEmailAndPassword('a@b.c', 'pw');
    expect(provider.errorMessage, 'boom');

    provider.clearError();

    expect(provider.errorMessage, isNull);
  });
}
