import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:taf_match/models/application_model.dart';
import 'package:taf_match/models/job_model.dart';
import 'package:taf_match/providers/application_provider.dart';
import 'package:taf_match/providers/auth_provider.dart';
import 'package:taf_match/providers/review_provider.dart';
import 'package:taf_match/providers/skill_provider.dart';
import 'package:taf_match/providers/user_provider.dart';
import 'package:taf_match/utils/theme.dart';
import 'package:taf_match/views/js_job_details_screen.dart';
import 'package:taf_match/views/profile_screen.dart';
import 'package:taf_match/providers/notification_provider.dart'; 
import 'package:mockito/annotations.dart';
import 'package:taf_match/repositories/firestore_notification_repository.dart';
import 'js_job_details_screen_test.mocks.dart';

import '../fakes.dart';

@GenerateMocks([FirestoreNotificationRepository])
void main() {
  late FakeApplicationRepository applicationRepository;
  late FakeAuthService authService;
  late FakeUserRepository userRepository;
  late FakeReviewRepository reviewRepository;
  late ApplicationProvider applicationProvider;
  late AuthProvider authProvider;
  late UserProvider userProvider;
  late ReviewProvider reviewProvider;
  late SkillProvider skillProvider;
  late FakeSkillRepository skillRepository;
  late NotificationProvider notificationProvider; 

  final job = Job(
    id: 'job-1',
    employerId: 'employer-1',
    title: 'Waiter',
    address: 'Sion',
    salaryChfPerHour: 25,
  );

  setUp(() {
    applicationRepository = FakeApplicationRepository();
    authService = FakeAuthService();
    userRepository = FakeUserRepository();
    reviewRepository = FakeReviewRepository();
    skillRepository = FakeSkillRepository();

  
    final mockFirestoreNotificationRepository = MockFirestoreNotificationRepository();

    
    notificationProvider = NotificationProvider(
      repository: mockFirestoreNotificationRepository,
    );

    applicationProvider = ApplicationProvider(applicationRepository);
    authProvider = AuthProvider(authService, userRepository);
    userProvider = UserProvider(userRepository);
    reviewProvider = ReviewProvider(reviewRepository);

    skillProvider = SkillProvider(skillRepository);
  });

  tearDown(() {
    applicationProvider.dispose();
    authProvider.dispose();
    userProvider.dispose();
    reviewProvider.dispose();
    skillProvider.dispose();
    applicationRepository.dispose();
    authService.dispose();
    userRepository.dispose();
    reviewRepository.dispose();
    notificationProvider.dispose();
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
        ChangeNotifierProvider<NotificationProvider>.value(
          value: notificationProvider,
        ),
        ChangeNotifierProvider<UserProvider>.value(value: userProvider),
        ChangeNotifierProvider<ReviewProvider>.value(value: reviewProvider),
        ChangeNotifierProvider<SkillProvider>.value(value: skillProvider),
      ],
      child: MaterialApp(
        theme: buildThemeData(),
        home: JobDetailScreen(
          job: job,
          // Fakes only: avoids touching real Firestore in widget tests.
          userRepository: userRepository,
          reviewRepository: reviewRepository,
        ),
      ),
    );
  }

  testWidgets(
    'shows job info and an Apply button when the student has not applied',
    (tester) async {
      await signInAsStudent(tester);
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.text('Job details'), findsOneWidget);
      expect(find.text('Waiter'), findsOneWidget);
      expect(find.textContaining('Sion'), findsOneWidget);
      expect(find.text('25 CHF/h'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Apply'), findsOneWidget);
      expect(find.text('Cancel'), findsNothing);
    },
  );

  testWidgets('tapping Apply submits an application for the current job', (
    tester,
  ) async {
    await signInAsStudent(tester);
    await tester.pumpWidget(buildTestWidget());
    await tester.pump();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Apply'));
    await tester.pump();
    await tester.pump();

    expect(applicationRepository.applyCallCount, 1);
    expect(applicationRepository.lastAppliedApplication?.jobId, 'job-1');
    expect(
      applicationRepository.lastAppliedApplication?.studentId,
      'student-1',
    );
  });

  testWidgets(
    'shows the application status and a Cancel button once applied',
    (tester) async {
      await signInAsStudent(tester);
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      applicationRepository.emit([
        Application(id: 'app-1', jobId: 'job-1', studentId: 'student-1'),
      ]);
      // A stream event needs more than a single pump to be delivered and
      // rebuild the widget: pumpAndSettle waits until the tree is stable.
      await tester.pumpAndSettle();

      expect(find.text('Submitted'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Apply'), findsNothing);
    },
  );

  testWidgets('does not show a Cancel button for a rejected application', (
    tester,
  ) async {
    await signInAsStudent(tester);
    await tester.pumpWidget(buildTestWidget());
    await tester.pump();

    applicationRepository.emit([
      Application(
        id: 'app-1',
        jobId: 'job-1',
        studentId: 'student-1',
        status: 'rejected',
      ),
    ]);
    await tester.pumpAndSettle();

    expect(find.text('Rejected'), findsOneWidget);
    expect(find.text('Cancel'), findsNothing);
  });

  testWidgets('cancelling the application asks for confirmation', (
    tester,
  ) async {
    await signInAsStudent(tester);
    await tester.pumpWidget(buildTestWidget());
    await tester.pump();

    applicationRepository.emit([
      Application(id: 'app-1', jobId: 'job-1', studentId: 'student-1'),
    ]);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Cancel application?'), findsOneWidget);

    // Dismissing with "Keep" does not cancel the application.
    await tester.tap(find.text('Keep'));
    await tester.pumpAndSettle();

    expect(applicationRepository.cancelCallCount, 0);
    expect(find.text('Submitted'), findsOneWidget);
  });

  testWidgets('confirming the cancellation cancels the application', (
    tester,
  ) async {
    await signInAsStudent(tester);
    await tester.pumpWidget(buildTestWidget());
    await tester.pump();

    applicationRepository.emit([
      Application(id: 'app-1', jobId: 'job-1', studentId: 'student-1'),
    ]);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancel it'));
    await tester.pumpAndSettle();

    expect(applicationRepository.cancelCallCount, 1);
    expect(applicationRepository.lastCancelledId, 'app-1');
  });

  testWidgets('tapping the employer card opens the employer profile', (
    tester,
  ) async {
    await signInAsStudent(tester);
    await tester.pumpWidget(buildTestWidget());
    await tester.pump();

    await tester.tap(find.text('View profile'));
    await tester.pumpAndSettle();

    expect(find.byType(ProfileScreen), findsOneWidget);
  });
}