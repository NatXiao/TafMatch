import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:taf_match/models/job_model.dart';
import 'package:taf_match/providers/auth_provider.dart';
import 'package:taf_match/providers/job_provider.dart';
import 'package:taf_match/utils/theme.dart';
import 'package:taf_match/views/jp_my_posting_screen.dart';
import 'package:taf_match/views/jp_new_posting_screen.dart';

import '../fakes.dart';

void main() {
  late FakeJobRepository jobRepository;
  late FakeApplicationRepository applicationRepository;
  late FakeAuthService authService;
  late FakeUserRepository userRepository;
  late JobProvider jobProvider;
  late AuthProvider authProvider;

  setUp(() {
    jobRepository = FakeJobRepository();
    applicationRepository = FakeApplicationRepository();
    authService = FakeAuthService();
    userRepository = FakeUserRepository();

    jobProvider = JobProvider(jobRepository);
    authProvider = AuthProvider(authService, userRepository);
  });

  tearDown(() {
    jobProvider.dispose();
    authProvider.dispose();
    jobRepository.dispose();
    applicationRepository.dispose();
    authService.dispose();
    userRepository.dispose();
  });

  Future<void> signInAsEmployer(WidgetTester tester) async {
    authService.emitUser(FakeUser('employer-1'));
    await tester.pump();
  }

  Widget buildTestWidget() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<JobProvider>.value(value: jobProvider),
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
      ],
      child: MaterialApp(
        theme: buildThemeData(),
        home: MyPostingsScreen(
          // Fake only: avoids touching real Firestore in widget tests.
          applicationRepository: applicationRepository,
        ),
      ),
    );
  }

  /// Une annonce vivante par defaut: sans date de fin, `isLive` est vrai.
  /// Passer une `endDate` passee pour obtenir une annonce fermee.
  Job makeJob({
    required String id,
    required String title,
    String address = '',
    double? salary,
    DateTime? endDate,
  }) {
    return Job(
      id: id,
      employerId: 'employer-1',
      title: title,
      address: address,
      salaryChfPerHour: salary,
      endDate: endDate,
    );
  }

  DateTime yesterday() => DateTime.now().subtract(const Duration(days: 1));

  testWidgets('shows the empty state when there are no postings', (
    tester,
  ) async {
    await signInAsEmployer(tester);
    await tester.pumpWidget(buildTestWidget());
    await tester.pump();

    expect(find.text('My postings'), findsOneWidget);
    expect(find.text('No postings yet.'), findsOneWidget);
  });

  testWidgets('shows the list of postings streamed from the provider', (
    tester,
  ) async {
    await signInAsEmployer(tester);
    await tester.pumpWidget(buildTestWidget());
    await tester.pump();

    jobRepository.emit([
      makeJob(id: '1', title: 'Barista', address: 'Sion', salary: 24),
      makeJob(id: '2', title: 'Waiter', address: 'Sierre', endDate: yesterday()),
    ]);
    // A stream event needs more than a single pump to be delivered and
    // rebuild the widget: pumpAndSettle waits until the tree is stable.
    await tester.pumpAndSettle();

    expect(find.text('Barista'), findsOneWidget);
    expect(find.text('Waiter'), findsOneWidget);
    expect(find.text('No postings yet.'), findsNothing);
  });

  testWidgets('the badge follows the deadline, not a stored status', (
    tester,
  ) async {
    await signInAsEmployer(tester);
    await tester.pumpWidget(buildTestWidget());
    await tester.pump();

    jobRepository.emit([
      // Pas de date de fin: l'annonce reste ouverte.
      makeJob(id: '1', title: 'Barista'),
      // Deadline depassee: l'annonce est fermee, meme si l'employeur n'a rien
      // fait pour la retirer.
      makeJob(id: '2', title: 'Waiter', endDate: yesterday()),
    ]);
    await tester.pumpAndSettle();

    expect(find.text('Live'), findsOneWidget);
    expect(find.text('Closed'), findsOneWidget);
  });

  testWidgets('tapping New posting opens the new posting screen', (
    tester,
  ) async {
    await signInAsEmployer(tester);
    await tester.pumpWidget(buildTestWidget());
    await tester.pump();

    await tester.tap(find.widgetWithText(ElevatedButton, 'New posting'));
    await tester.pumpAndSettle();

    expect(find.byType(NewPostingScreen), findsOneWidget);
  });

  testWidgets('deleting a posting asks for confirmation before removing it', (
    tester,
  ) async {
    await signInAsEmployer(tester);
    await tester.pumpWidget(buildTestWidget());
    await tester.pump();

    jobRepository.emit([makeJob(id: '1', title: 'Barista')]);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(OutlinedButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Delete posting?'), findsOneWidget);

    // Dismissing with "Cancel" does not delete the posting.
    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();

    expect(jobRepository.lastDeletedId, isNull);
    expect(find.text('Barista'), findsOneWidget);

    // Confirming with "Delete" removes it through the JobProvider.
    await tester.tap(find.widgetWithText(OutlinedButton, 'Delete'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(jobRepository.lastDeletedId, '1');
  });

  testWidgets('tapping the logout icon signs the user out', (tester) async {
    await signInAsEmployer(tester);
    await tester.pumpWidget(buildTestWidget());
    await tester.pump();

    await tester.tap(find.byIcon(Icons.logout));
    await tester.pump();

    expect(authService.signOutCallCount, 1);
  });
}