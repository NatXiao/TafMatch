import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:taf_match/models/user_model.dart';
import 'package:taf_match/providers/auth_provider.dart';
import 'package:taf_match/providers/user_provider.dart';
import 'package:taf_match/utils/theme.dart';
import 'package:taf_match/views/admin_dashboard.dart';
import 'package:network_image_mock/network_image_mock.dart';
import '../fakes.dart';

UserModel createUser({
  required String id,
  required String name,
  required String email,
  required String role,
}) {
  return UserModel(
    uid: id,
    fullName: name,
    email: email,
    role: role,
    address: 'Test address',
    profilePictureUrl: '', // force the null-avatar branch
  );
}

void main() {
  late FakeUserRepository repository;
  late FakeAuthService authService;
  late AuthProvider authProvider;
  late UserProvider userProvider;

  setUp(() {
    repository = FakeUserRepository();
    authService = FakeAuthService();

    authProvider = AuthProvider(
      authService,
      repository,
    );

    userProvider = UserProvider(repository);
  });

  tearDown(() {
    userProvider.dispose();
    authProvider.dispose();
    authService.dispose();
    repository.dispose();
  });

Future<void> signInAsAdmin() async {
  final admin = UserModel(
    uid: 'admin-id',
    fullName: 'Administrator',
    email: 'admin@unit.ch',
    role: 'admin',
    address: 'Admin street',
  );

  await repository.createProfile(admin);

  // Load the profile directly.
  await userProvider.loadProfile('admin-id');

  expect(userProvider.isAdmin, isTrue);
}

  Widget buildTestWidget() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<UserProvider>.value(
          value: userProvider,
        ),
        ChangeNotifierProvider<AuthProvider>.value(
          value: authProvider,
        ),
      ],
      child: MaterialApp(
        theme: buildThemeData(),
        home: AdminDashboardScreen(),
      ),
    );
  }

  testWidgets('shows Access denied when user is not admin',
      (tester) async {
    await tester.pumpWidget(buildTestWidget());

    await tester.pump();

    expect(find.text('Access denied'), findsOneWidget);
  });

  testWidgets('displays users and statistics for admin',
    (tester) async {
      await mockNetworkImagesFor(() async {
    repository.usersToReturn = [
      createUser(
        id: '1',
        name: 'John Doe',
        email: 'john@test.com',
        role: 'user',
      ),
      createUser(
        id: '2',
        name: 'Company SA',
        email: 'company@test.com',
        role: 'employer',
      ),
      createUser(
        id: '3',
        name: 'Jane Doe',
        email: 'jane@test.com',
        role: 'user',
      ),
    ];

    await signInAsAdmin();

    await tester.pumpWidget(buildTestWidget());

    // Execute the addPostFrameCallback from initState.
    await tester.pump();

    // Wait for loadUsers() to complete.
    await tester.pump();

    expect(find.text('Job seekers'), findsOneWidget);
    expect(find.text('Job providers'), findsOneWidget);
    expect(find.text('All users'), findsOneWidget);

    // 2 users with the user role.
    expect(find.text('2'), findsOneWidget);

    // 1 employer
    expect(find.text('1'), findsOneWidget);

    // 3 utilisateurs au total
    expect(find.text('3'), findsOneWidget);

    expect(find.text('John Doe'), findsOneWidget);
    expect(find.text('Company SA'), findsOneWidget);
    expect(find.text('Jane Doe'), findsOneWidget);
      });
  });
  testWidgets('filters users by full name', (tester) async {
    repository.usersToReturn = [
      createUser(
        id: '1',
        name: 'John Doe',
        email: 'john@test.com',
        role: 'user',
      ),
      createUser(
        id: '2',
        name: 'Jane Smith',
        email: 'jane@test.com',
        role: 'employer',
      ),
    ];

    await signInAsAdmin();

    await tester.pumpWidget(buildTestWidget());

    await tester.pump();
    await tester.pump();

    expect(find.text('John Doe'), findsOneWidget);
    expect(find.text('Jane Smith'), findsOneWidget);

    await tester.enterText(
      find.byType(TextField),
      'john',
    );

    await tester.pump();

    expect(find.text('John Doe'), findsOneWidget);
    expect(find.text('Jane Smith'), findsNothing);
  });
  testWidgets('filters users by email', (tester) async {
    repository.usersToReturn = [
      createUser(
        id: '1',
        name: 'John Doe',
        email: 'john@test.com',
        role: 'user',
      ),
      createUser(
        id: '2',
        name: 'Jane Smith',
        email: 'jane@test.com',
        role: 'employer',
      ),
    ];

    await signInAsAdmin();

    await tester.pumpWidget(buildTestWidget());

    await tester.pump();
    await tester.pump();

    await tester.enterText(
      find.byType(TextField),
      'jane@test.com',
    );

    await tester.pump();

    expect(find.text('Jane Smith'), findsOneWidget);
    expect(find.text('John Doe'), findsNothing);
  });
  testWidgets('filters users by uid', (tester) async {
    repository.usersToReturn = [
      createUser(
        id: 'uuid-123',
        name: 'John Doe',
        email: 'john@test.com',
        role: 'user',
      ),
      createUser(
        id: 'uuid-456',
        name: 'Jane Smith',
        email: 'jane@test.com',
        role: 'employer',
      ),
    ];

    await signInAsAdmin();

    await tester.pumpWidget(buildTestWidget());

    await tester.pump();
    await tester.pump();

    await tester.enterText(
      find.byType(TextField),
      'uuid-456',
    );

    await tester.pump();

    expect(find.text('Jane Smith'), findsOneWidget);
    expect(find.text('John Doe'), findsNothing);
  });
  testWidgets('shows No users found when search has no result',
      (tester) async {
    repository.usersToReturn = [
      createUser(
        id: '1',
        name: 'John Doe',
        email: 'john@test.com',
        role: 'user',
      ),
    ];

    await signInAsAdmin();

    await tester.pumpWidget(buildTestWidget());

    await tester.pump();
    await tester.pump();

    await tester.enterText(
      find.byType(TextField),
      'unknown-user',
    );

    await tester.pump();

    expect(find.text('No users found.'), findsOneWidget);
  });
  testWidgets('shows error message when loadUsers fails',
    (tester) async {
    repository.getUsersError =
        Exception('Database connection failed');

    await signInAsAdmin();

    await tester.pumpWidget(buildTestWidget());

    await tester.pump();
    await tester.pump();

    expect(
      find.textContaining('Database connection failed'),
      findsOneWidget,
    );
  });
  testWidgets('shows loading indicator while users are loading',
    (tester) async {
  repository.getUsersGate = Completer<List<UserModel>>();

  await signInAsAdmin();

  await tester.pumpWidget(buildTestWidget());

  // Déclenche addPostFrameCallback et loadUsers
  await tester.pump();

  expect(
    find.byType(CircularProgressIndicator),
    findsOneWidget,
  );

  repository.getUsersGate!.complete([
    createUser(
      id: '1',
      name: 'John Doe',
      email: 'john@test.com',
      role: 'user',
    ),
  ]);

  await tester.pump();
  await tester.pump();

  expect(
    find.byType(CircularProgressIndicator),
    findsNothing,
  );

  expect(find.text('John Doe'), findsOneWidget);
});
}