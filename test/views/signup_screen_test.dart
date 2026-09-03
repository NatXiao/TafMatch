import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:taf_match/providers/auth_provider.dart';
import 'package:taf_match/utils/constants.dart';
import 'package:taf_match/utils/theme.dart';
import 'package:taf_match/views/signup_screen.dart';

import '../fakes.dart';

void main() {
  late FakeAuthService authService;
  late FakeUserRepository userRepository;
  late AuthProvider authProvider;

  setUp(() {
    authService = FakeAuthService();
    userRepository = FakeUserRepository();
    authProvider = AuthProvider(authService, userRepository);
  });

  tearDown(() {
    authProvider.dispose();
    authService.dispose();
    userRepository.dispose();
  });

  // Wraps SignupScreen behind a button so that Navigator.pop() (called on a
  // successful account creation) has a route to return to, just like in the
  // real app where SignupScreen is pushed from LoginScreen.
  Future<void> pumpSignupScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>.value(
        value: authProvider,
        child: MaterialApp(
          theme: buildThemeData(),
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SignupScreen()),
                ),
                child: const Text('Open signup'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open signup'));
    await tester.pumpAndSettle();
  }

  testWidgets('renders the signup form with Student selected by default', (
    tester,
  ) async {
    await pumpSignupScreen(tester);

    expect(find.byType(SignupScreen), findsOneWidget);
    expect(find.text('Create account'), findsNWidgets(2)); // header + button
    expect(find.text('Student'), findsOneWidget);
    expect(find.text('Employer'), findsOneWidget);
    expect(find.text('Full name'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Address'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Confirm password'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(5));
  });

  testWidgets('shows validation errors when submitting an empty form', (
    tester,
  ) async {
    await pumpSignupScreen(tester);

    await tester.ensureVisible(find.widgetWithText(ElevatedButton, 'Create account'));
    await tester.tap(find.widgetWithText(ElevatedButton, 'Create account'));
    await tester.pump();

    expect(find.text('Please enter your name'), findsOneWidget);
    expect(find.text('Please enter an email'), findsOneWidget);
    expect(find.text('Please enter your address'), findsOneWidget);
    expect(find.text('Please enter a password'), findsOneWidget);
    expect(find.text('Please confirm your password'), findsOneWidget);

    // Nothing should have been submitted to the auth provider.
    expect(userRepository.lastAddedUser, isNull);
  });

  testWidgets('shows an error when the email is not valid', (tester) async {
    await pumpSignupScreen(tester);

    await tester.enterText(find.byType(TextFormField).at(0), 'Marie Rossier');
    await tester.enterText(find.byType(TextFormField).at(1), 'not-an-email');
    await tester.enterText(find.byType(TextFormField).at(2), 'Rue du Rhône 1');
    await tester.enterText(find.byType(TextFormField).at(3), 'secret1');
    await tester.enterText(find.byType(TextFormField).at(4), 'secret1');

    await tester.ensureVisible(find.widgetWithText(ElevatedButton, 'Create account'));
    await tester.tap(find.widgetWithText(ElevatedButton, 'Create account'));
    await tester.pump();

    expect(find.text('Please enter a valid email'), findsOneWidget);
  });

  testWidgets('shows an error when the password is too short', (
    tester,
  ) async {
    await pumpSignupScreen(tester);

    await tester.enterText(find.byType(TextFormField).at(0), 'Marie Rossier');
    await tester.enterText(find.byType(TextFormField).at(1), 'marie@edu.ch');
    await tester.enterText(find.byType(TextFormField).at(2), 'Rue du Rhône 1');
    await tester.enterText(find.byType(TextFormField).at(3), '123');
    await tester.enterText(find.byType(TextFormField).at(4), '123');

    await tester.ensureVisible(find.widgetWithText(ElevatedButton, 'Create account'));
    await tester.tap(find.widgetWithText(ElevatedButton, 'Create account'));
    await tester.pump();

    expect(
      find.text('Password must be at least 6 characters long and contains a least one uppercase letter, lowercase letter, number and special character'),
      findsOneWidget,
    );
  });

  testWidgets(
    'shows an error when the password confirmation does not match',
    (tester) async {
      await pumpSignupScreen(tester);

      await tester.enterText(
        find.byType(TextFormField).at(0),
        'Marie Rossier',
      );
      await tester.enterText(find.byType(TextFormField).at(1), 'marie@edu.ch');
      await tester.enterText(
        find.byType(TextFormField).at(2),
        'Rue du Rhône 1',
      );
      await tester.enterText(find.byType(TextFormField).at(3), 'secret1');
      await tester.enterText(find.byType(TextFormField).at(4), 'secret2');

      await tester.ensureVisible(
        find.widgetWithText(ElevatedButton, 'Create account'),
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'Create account'));
      await tester.pump();

      expect(
        find.text('Confirmation must be equal your password'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'creates the account with the selected role and pops on success',
    (tester) async {
      // Register succeeds and returns a uid.
      authService.registerError = 'new-uid-1';

      await pumpSignupScreen(tester);

      await tester.enterText(
        find.byType(TextFormField).at(0),
        'Marie Rossier',
      );
      await tester.enterText(find.byType(TextFormField).at(1), 'marie@edu.ch');
      await tester.enterText(
        find.byType(TextFormField).at(2),
        'Rue du Rhône 1',
      );
      await tester.enterText(find.byType(TextFormField).at(3), 'Secret123@');
      await tester.enterText(find.byType(TextFormField).at(4), 'Secret123@');

      // Switch role to Employer before submitting.
      await tester.ensureVisible(find.text('Employer'));
      await tester.tap(find.text('Employer'));
      await tester.pump();

      await tester.ensureVisible(
        find.widgetWithText(ElevatedButton, 'Create account'),
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'Create account'));
      await tester.pumpAndSettle();

      expect(userRepository.lastAddedUser, isNotNull);
      expect(userRepository.lastAddedUser!.uid, 'new-uid-1');
      expect(userRepository.lastAddedUser!.fullName, 'Marie Rossier');
      expect(userRepository.lastAddedUser!.email, 'marie@edu.ch');
      expect(userRepository.lastAddedUser!.address, 'Rue du Rhône 1');
      expect(userRepository.lastAddedUser!.role, Constants.roleEmployer);

      // The screen was popped back to the button page.
      expect(find.byType(SignupScreen), findsNothing);
    },
  );

  testWidgets('defaults to the Student role when not changed', (
    tester,
  ) async {
    authService.registerError = 'new-uid-2';

    await pumpSignupScreen(tester);

    await tester.enterText(find.byType(TextFormField).at(0), 'John Doe');
    await tester.enterText(find.byType(TextFormField).at(1), 'john@edu.ch');
    await tester.enterText(find.byType(TextFormField).at(2), 'Rue 2');
    await tester.enterText(find.byType(TextFormField).at(3), 'Secret123@');
    await tester.enterText(find.byType(TextFormField).at(4), 'Secret123@');

    await tester.ensureVisible(find.widgetWithText(ElevatedButton, 'Create account'));
    await tester.tap(find.widgetWithText(ElevatedButton, 'Create account'));
    await tester.pumpAndSettle();

    expect(userRepository.lastAddedUser!.role, Constants.roleStudent);
  });
}
