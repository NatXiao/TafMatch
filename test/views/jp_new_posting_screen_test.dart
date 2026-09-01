import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:taf_match/providers/auth_provider.dart';
import 'package:taf_match/providers/job_provider.dart';
import 'package:taf_match/utils/theme.dart';
import 'package:taf_match/views/jp_new_posting_screen.dart';

import '../fakes.dart';

void main() {
  late FakeJobRepository jobRepository;
  late FakeAuthService authService;
  late FakeUserRepository userRepository;
  late JobProvider jobProvider;
  late AuthProvider authProvider;

  setUp(() {
    jobRepository = FakeJobRepository();
    authService = FakeAuthService();
    userRepository = FakeUserRepository();

    jobProvider = JobProvider(jobRepository);
    authProvider = AuthProvider(authService, userRepository);
  });

  tearDown(() {
    jobProvider.dispose();
    authProvider.dispose();
    jobRepository.dispose();
    authService.dispose();
    userRepository.dispose();
  });

  Future<void> signInAsEmployer(WidgetTester tester) async {
    authService.emitUser(FakeUser('employer-1'));
    await tester.pump();
  }

  // Wraps NewPostingScreen behind a button so that Navigator.pop() (called
  // after a successful publish) has a route to return to. The surface is
  // made tall enough that the whole scrollable form is built at once:
  // ListView only builds children near the viewport (Flutter's Sliver
  // virtualization applies even to a plain, non-.builder ListView), so
  // fields further down the form would not exist yet in the widget tree
  // and could not be found, filled, or validated otherwise.
  Future<void> pumpNewPostingScreen(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 2200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<JobProvider>.value(value: jobProvider),
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ],
        child: MaterialApp(
          theme: buildThemeData(),
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const NewPostingScreen()),
                ),
                child: const Text('Open new posting'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open new posting'));
    await tester.pumpAndSettle();
  }

  Future<void> selectDropdownOption(
    WidgetTester tester,
    int dropdownIndex,
    String option,
  ) async {
    final dropdownFinder = find
        .byType(DropdownButtonFormField<String>)
        .at(dropdownIndex);
    await tester.tap(dropdownFinder);
    await tester.pumpAndSettle();
    await tester.tap(find.text(option).last);
    await tester.pumpAndSettle();
  }

  testWidgets('renders all the posting form fields', (tester) async {
    await signInAsEmployer(tester);
    await pumpNewPostingScreen(tester);

    expect(find.text('New posting'), findsOneWidget);
    expect(find.text('Job title'), findsOneWidget);
    expect(find.text('Description'), findsOneWidget);
    expect(find.text('Location'), findsOneWidget);
    expect(find.text('End date'), findsOneWidget);
    expect(find.text('Language'), findsOneWidget);
    expect(find.text('Domain'), findsOneWidget);
    expect(find.text('Degree'), findsOneWidget);
    expect(find.text('Salary (CHF/h)'), findsOneWidget);
    expect(find.text('Work time (%)'), findsOneWidget);
    expect(find.text('AI salary estimate'), findsOneWidget);
    expect(find.text('PHOTOS'), findsOneWidget);
    expect(
      find.widgetWithText(ElevatedButton, 'Publish posting'),
      findsOneWidget,
    );
  });

  testWidgets('shows Required errors when submitting an empty form', (
    tester,
  ) async {
    await signInAsEmployer(tester);
    await pumpNewPostingScreen(tester);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Publish posting'));
    await tester.pump();

    // Title, Location, Domain, Degree, Salary and Work time are required.
    expect(find.text('Required'), findsNWidgets(6));
    expect(jobRepository.createCallCount, 0);
  });

  testWidgets('shows Invalid for a non-positive or malformed number', (
    tester,
  ) async {
    await signInAsEmployer(tester);
    await pumpNewPostingScreen(tester);

    final numberFields = find.byType(TextFormField);
    // Order in the form: title, description, address, endDateField, salary,
    // workTime.
    await tester.enterText(numberFields.at(4), '0');
    await tester.enterText(numberFields.at(5), 'abc');

    await tester.tap(find.widgetWithText(ElevatedButton, 'Publish posting'));
    await tester.pump();

    expect(find.text('Invalid'), findsNWidgets(2));
  });

  testWidgets('publishes the job with the entered data and pops on success', (
    tester,
  ) async {
    await signInAsEmployer(tester);
    await pumpNewPostingScreen(tester);

    final textFields = find.byType(TextFormField);
    await tester.enterText(textFields.at(0), 'Event waiter'); // title
    await tester.enterText(
      textFields.at(1),
      'Serve drinks during the event.',
    ); // description
    await tester.enterText(textFields.at(2), 'Sion'); // address
    await tester.enterText(textFields.at(4), '22'); // salary
    await tester.enterText(textFields.at(5), '40'); // work time

    await selectDropdownOption(tester, 0, 'Finance'); // domain
    await selectDropdownOption(tester, 1, 'Bachelor'); // degree

    await tester.tap(find.widgetWithText(ElevatedButton, 'Publish posting'));
    await tester.pumpAndSettle();

    expect(jobRepository.createCallCount, 1);
    final created = jobRepository.lastCreatedJob;
    expect(created, isNotNull);
    expect(created!.employerId, 'employer-1');
    expect(created.title, 'Event waiter');
    expect(created.description, 'Serve drinks during the event.');
    expect(created.address, 'Sion');
    expect(created.domainName, 'Finance');
    expect(created.degree, 'Bachelor');
    expect(created.salaryChfPerHour, 22);
    expect(created.status, 'live');

    // The screen was popped back to the button page.
    expect(find.byType(NewPostingScreen), findsNothing);
  });

  testWidgets('shows an error snackbar when publishing fails', (
    tester,
  ) async {
    jobRepository.createError = Exception('Network error');

    await signInAsEmployer(tester);
    await pumpNewPostingScreen(tester);

    final textFields = find.byType(TextFormField);
    await tester.enterText(textFields.at(0), 'Event waiter');
    await tester.enterText(textFields.at(2), 'Sion');
    await tester.enterText(textFields.at(4), '22');
    await tester.enterText(textFields.at(5), '40');

    await selectDropdownOption(tester, 0, 'Finance');
    await selectDropdownOption(tester, 1, 'Bachelor');

    await tester.tap(find.widgetWithText(ElevatedButton, 'Publish posting'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Could not publish:'), findsOneWidget);
    // The form remains visible: nothing was popped.
    expect(find.byType(NewPostingScreen), findsOneWidget);
  });
}
