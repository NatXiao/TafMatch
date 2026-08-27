import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:taf_match/models/application_model.dart';
import 'package:taf_match/models/job_model.dart';
import 'package:taf_match/models/user_model.dart';
import 'package:taf_match/providers/application_provider.dart';
import 'package:taf_match/providers/auth_provider.dart';
import 'package:taf_match/utils/theme.dart';
import 'package:taf_match/views/js_applications_screen.dart';

import '../fakes.dart';

void main() {
  late FakeApplicationRepository applicationRepository;
  late FakeAuthService authService;
  late FakeUserRepository userRepository;
  late FakeJobRepository jobRepository;
  late ApplicationProvider applicationProvider;
  late AuthProvider authProvider;

  setUp(() {
    applicationRepository = FakeApplicationRepository();
    authService = FakeAuthService();
    userRepository = FakeUserRepository();
    jobRepository = FakeJobRepository();

    applicationProvider = ApplicationProvider(applicationRepository);
    authProvider = AuthProvider(authService, userRepository);
  });

  tearDown(() {
    applicationProvider.dispose();
    authProvider.dispose();
    applicationRepository.dispose();
    authService.dispose();
    userRepository.dispose();
  });

  Future<void> signInAsStudent(WidgetTester tester) async {
    authService.emitUser(FakeUser('student-1'));
    await tester.pump();
  }

  Widget buildTestWidget() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ApplicationProvider>.value(
          value: applicationProvider,
        ),
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
      ],
      child: MaterialApp(
        theme: buildThemeData(),
        home: ApplicationsScreen(
          // Fakes only: avoids touching real Firestore in widget tests.
          jobRepository: jobRepository,
          userRepository: userRepository,
        ),
      ),
    );
  }

  testWidgets('shows the empty state when there are no applications', (
    tester,
  ) async {
    await signInAsStudent(tester);
    await tester.pumpWidget(buildTestWidget());
    await tester.pump();

    expect(find.text('My applications'), findsOneWidget);
    expect(find.text('No applications yet.'), findsOneWidget);
  });

  testWidgets('shows a status badge for each application', (tester) async {
    await signInAsStudent(tester);
    await tester.pumpWidget(buildTestWidget());
    await tester.pump();

    applicationRepository.emit([
      Application(id: 'a1', jobId: 'job-1', studentId: 'student-1'),
      Application(
        id: 'a2',
        jobId: 'job-2',
        studentId: 'student-1',
        status: 'accepted',
      ),
      Application(
        id: 'a3',
        jobId: 'job-3',
        studentId: 'student-1',
        status: 'rejected',
      ),
      Application(
        id: 'a4',
        jobId: 'job-4',
        studentId: 'student-1',
        status: 'reviewed',
      ),
    ]);
    // A stream event needs more than a single pump to be delivered and
    // rebuild the widget: pumpAndSettle waits until the tree is stable.
    await tester.pumpAndSettle();

    expect(find.text('Submitted'), findsOneWidget);
    expect(find.text('Accepted'), findsOneWidget);
    expect(find.text('Rejected'), findsOneWidget);
    expect(find.text('Reviewed'), findsOneWidget);
    expect(find.text('No applications yet.'), findsNothing);
  });

  testWidgets('shows the job title and employer name once loaded', (
    tester,
  ) async {
    jobRepository.jobsById['job-1'] = Job(
      id: 'job-1',
      employerId: 'employer-1',
      title: 'Barista',
    );
    await userRepository.createProfile(
      UserModel(
        uid: 'employer-1',
        email: 'contact@lecafe.ch',
        role: 'employer',
        fullName: 'Le Café SA',
      ),
    );

    await signInAsStudent(tester);
    await tester.pumpWidget(buildTestWidget());
    await tester.pump();

    applicationRepository.emit([
      Application(id: 'a1', jobId: 'job-1', studentId: 'student-1'),
    ]);
    // Two awaits are chained here (job lookup, then employer lookup) on top
    // of the stream delivery itself, so pumpAndSettle is needed rather than
    // a fixed number of pumps.
    await tester.pumpAndSettle();

    expect(find.text('Barista'), findsOneWidget);
    expect(find.text('Le Café SA'), findsOneWidget);
  });

  testWidgets('shows "Unknown job" when the job cannot be found', (
    tester,
  ) async {
    await signInAsStudent(tester);
    await tester.pumpWidget(buildTestWidget());
    await tester.pump();

    applicationRepository.emit([
      Application(id: 'a1', jobId: 'missing-job', studentId: 'student-1'),
    ]);
    await tester.pumpAndSettle();

    expect(find.text('Unknown job'), findsOneWidget);
  });
}
