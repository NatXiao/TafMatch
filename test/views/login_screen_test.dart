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
import 'package:taf_match/models/notification_model.dart';
import 'package:taf_match/providers/auth_provider.dart';
import 'package:taf_match/providers/notification_provider.dart';
import 'package:taf_match/repositories/firestore_notification_repository.dart';
import 'package:taf_match/utils/theme.dart';
import 'package:taf_match/views/login_screen.dart';

import '../fakes.dart';

class FakeNotificationRepository implements NotificationRepository {
  final List<AppNotification> notifications;

  FakeNotificationRepository(this.notifications);

  @override
  Stream<List<AppNotification>> watchForUser(String userId) =>
      Stream.value(notifications);

  @override
  Future<void> create({
    required String userId,
    required String title,
    required String message,
    required String type,
    String? jobId,
    String? applicationId,
  }) async {}

  @override
  Future<void> markAsRead(String notificationId) async {}

  @override
  Future<void> markAllAsRead(String userId) async {}
}

void main() {
  testWidgets('shows the auth error returned by the service', (tester) async {
    final authService = FakeAuthService();
    authService.signInError = 'The supplied auth credential is incorrect, malformed or has expired.';

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

  testWidgets('shows a popup when unread notifications exist after login', (tester) async {
    final authService = FakeAuthService();
    final userRepository = FakeUserRepository();
    final notificationRepository = FakeNotificationRepository([
      AppNotification(
        id: 'n1',
        userId: 'u-1',
        title: 'Application status',
        message: 'Your application was updated.',
        type: 'application_accepted',
        isRead: false,
        createdAt: DateTime.now(),
      ),
    ]);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => AuthProvider(authService, userRepository),
          ),
          ChangeNotifierProvider(
            create: (_) => NotificationProvider(
              repository: notificationRepository,
            ),
          ),
        ],
        child: MaterialApp(theme: buildThemeData(), home: LoginScreen()),
      ),
    );

    await tester.enterText(find.byType(TextFormField).at(0), 'user@example.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'secret123');

    authService.emitUser(FakeUser('u-1'));
    await tester.pump();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Log in'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('You have 1 new notification in your profile.'), findsOneWidget);

    authService.dispose();
  });
}
