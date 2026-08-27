// Example widget test.
//
// This file is intentionally kept as a single, well-documented example to show
// how to test a screen in this project: wrap it in its providers but inject the
// fakes from test/fakes.dart instead of real Firebase, then drive the UI with
// the WidgetTester and assert on what the user sees. Use it as a template for
// further widget tests (TaskListScreen, TaskForm, ...).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:taf_match/providers/auth_provider.dart';
import 'package:taf_match/utils/theme.dart';
import 'package:taf_match/views/login_screen.dart';

import '../fakes.dart';

void main() {
  testWidgets('shows the auth error returned by the service', (tester) async {
    final authService = FakeAuthService();
    authService.signInError = 'Wrong password provided for that user.';

    final userRepository = FakeUserRepository();

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthProvider(authService, userRepository),
        child: MaterialApp(theme: buildThemeData(), home: LoginScreen()),
      ),
    );

    await tester.enterText(find.byType(TextFormField).at(0), 'user@example.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'secret123');

    await tester.tap(find.widgetWithText(ElevatedButton, 'Log in'));
    await tester.pumpAndSettle();

    expect(find.text('The supplied auth credential is incorrect, malformed or has expired.'), findsOneWidget);

    authService.dispose();
  });
}
