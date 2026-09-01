import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:taf_match/models/job_model.dart';
import 'package:taf_match/providers/auth_provider.dart';
import 'package:taf_match/providers/job_provider.dart';
import 'package:taf_match/utils/theme.dart';
import 'package:taf_match/views/js_job_list_screen.dart';

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

  Widget buildTestWidget() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<JobProvider>.value(value: jobProvider),
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
      ],
      child: MaterialApp(theme: buildThemeData(), home: const JobListScreen()),
    );
  }

  Job makeJob({
    required String id,
    required String title,
    String address = '',
    double? salary,
    String domainName = '',
    int? workPercentage,
  }) {
    return Job(
      id: id,
      employerId: 'employer-1',
      title: title,
      address: address,
      salaryChfPerHour: salary,
      domainName: domainName,
      workPercentage: workPercentage,
    );
  }

  testWidgets('shows the empty state when there are no jobs', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestWidget());

    // Executes the addPostFrameCallback that starts listening to live jobs.
    await tester.pump();

    expect(find.text('Jobs'), findsOneWidget);
    expect(find.text('No jobs found.'), findsOneWidget);
  });

  testWidgets('displays jobs streamed from the provider', (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pump();

    jobRepository.emit([
      makeJob(id: '1', title: 'Barista', address: 'Sion', salary: 24),
      makeJob(id: '2', title: 'Waiter', address: 'Sierre', salary: 22),
    ]);
    // A stream event needs more than a single pump to be delivered and
    // rebuild the widget: pumpAndSettle waits until the tree is stable.
    await tester.pumpAndSettle();

    expect(find.text('Barista'), findsOneWidget);
    expect(find.text('Waiter'), findsOneWidget);
    expect(find.text('No jobs found.'), findsNothing);
  });

  testWidgets('search filters jobs by title and address', (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pump();

    jobRepository.emit([
      makeJob(id: '1', title: 'Barista', address: 'Sion'),
      makeJob(id: '2', title: 'Waiter', address: 'Sierre'),
    ]);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'barista');
    await tester.pump();

    expect(find.text('Barista'), findsOneWidget);
    expect(find.text('Waiter'), findsNothing);

    await tester.enterText(find.byType(TextField), 'sierre');
    await tester.pump();

    expect(find.text('Waiter'), findsOneWidget);
    expect(find.text('Barista'), findsNothing);

    await tester.enterText(find.byType(TextField), 'nothing-matches');
    await tester.pump();

    expect(find.text('No jobs found.'), findsOneWidget);
  });

  testWidgets('opening the filters sheet shows the filter controls', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pump();

    expect(find.text('Filters'), findsOneWidget);

    await tester.tap(find.text('Filters'));
    await tester.pumpAndSettle();

    // The bottom sheet is now visible with its own "Filters" title.
    expect(find.text('Filters'), findsNWidgets(2));
    expect(find.textContaining('Salary (CHF/h):'), findsOneWidget);
    expect(find.textContaining('Work percentage:'), findsOneWidget);
    expect(find.text('Categories'), findsOneWidget);
    expect(find.text('Apply filters'), findsOneWidget);

    await tester.ensureVisible(find.text('Apply filters'));
    await tester.tap(find.text('Apply filters'));
    await tester.pumpAndSettle();

    // The sheet is dismissed, back to a single "Filters" button.
    expect(find.text('Filters'), findsOneWidget);
  });

  testWidgets('selecting a category filter narrows down the job list', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pump();

    jobRepository.emit([
      makeJob(id: '1', title: 'Barista', domainName: 'Hospitality'),
      makeJob(id: '2', title: 'Accountant', domainName: 'Finance'),
    ]);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Filters'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Finance'));
    await tester.tap(find.text('Finance'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Apply filters'));
    await tester.tap(find.text('Apply filters'));
    await tester.pumpAndSettle();

    expect(find.text('Accountant'), findsOneWidget);
    expect(find.text('Barista'), findsNothing);
    expect(find.textContaining('Filters ('), findsOneWidget);
  });

  testWidgets('tapping the logout icon signs the user out', (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pump();

    await tester.tap(find.byIcon(Icons.logout));
    await tester.pump();

    expect(authService.signOutCallCount, 1);
  });
}
