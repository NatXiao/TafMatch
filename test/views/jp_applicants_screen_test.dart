import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:taf_match/models/job_model.dart';
import 'package:taf_match/providers/application_provider.dart';
import 'package:taf_match/repositories/firestore_application_repository.dart';
import 'package:taf_match/repositories/firestore_review_repository.dart';
import 'package:taf_match/repositories/firestore_user_repository.dart';
import 'package:taf_match/utils/theme.dart';
import 'package:taf_match/views/jp_applicants_screen.dart';

import 'jp_applicants_screen_test.mocks.dart';

@GenerateMocks([
  FirestoreApplicationRepository,
  FirestoreUserRepository,
  FirestoreReviewRepository,
])
void main() {
  late MockFirestoreApplicationRepository mockApplicationRepository;
  late MockFirestoreUserRepository mockUserRepository;
  late MockFirestoreReviewRepository mockReviewRepository;
  late ApplicationProvider applicationProvider;

  setUp(() {
    mockApplicationRepository = MockFirestoreApplicationRepository();
    mockUserRepository = MockFirestoreUserRepository();
    mockReviewRepository = MockFirestoreReviewRepository();

    when(
      mockApplicationRepository.watchByJob(any),
    ).thenAnswer((_) => Stream.value([]));

    applicationProvider = ApplicationProvider(
      mockApplicationRepository,
    );
  });

  tearDown(() {
    applicationProvider.dispose();
  });

  testWidgets('Applicants screen displays correctly', (tester) async {
    final job = Job(
      id: 'job-1',
      employerId: 'employer-1',
      title: 'Software Developer',
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<ApplicationProvider>.value(
        value: applicationProvider,
        child: MaterialApp(
          theme: buildThemeData(),
          home: ApplicantsScreen(
            job: job,
            userRepository: mockUserRepository,
            reviewRepository: mockReviewRepository,
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('Applicants'), findsOneWidget);
    expect(
      find.text(
        'Tap an applicant to open their profile and rate them',
      ),
      findsOneWidget,
    );
    expect(find.text('No applicants yet.'), findsOneWidget);

    verify(
      mockApplicationRepository.watchByJob('job-1'),
    ).called(1);
  });
}