import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taf_match/models/review_model.dart';
import 'package:taf_match/models/user_model.dart';
import 'package:taf_match/views/profile_screen.dart';

import '../fakes.dart';
import 'test_helpers.dart';

UserModel _makeUser({
  required String uid,
  String fullName = 'Marie Rossier',
  String email = 'marie@edu.hes-so.ch',
  String role = 'Student',
  String address = 'Route de la gare 1',
  String profilePictureUrl = '',
  List<String> skills = const [],
}) {
  // Adjust field names/positional vs named args to match your real UserModel.
  return UserModel(
    uid: uid,
    fullName: fullName,
    email: email,
    role: role,
    address: address,
    profilePictureUrl: profilePictureUrl,
    skills: skills,
  );
}

void main() {
  late FakeAuthService authService;
  late FakeUserRepository userRepository;
  late FakeReviewRepository reviewRepository;
  late FakeSkillRepository skillRepository;

  setUp(() {
    authService = FakeAuthService();
    userRepository = FakeUserRepository();
    reviewRepository = FakeReviewRepository();
    skillRepository = FakeSkillRepository();
  });

  tearDown(() {
    authService.dispose();
    userRepository.dispose();
    reviewRepository.dispose();
  });

  Future<void> pumpProfile(
    WidgetTester tester, {
    String? userId,
  }) async {
    await tester.pumpWidget(
      buildHarness(
        authService: authService,
        userRepository: userRepository,
        reviewRepository: reviewRepository,
        skillRepository: skillRepository,
        child: ProfileScreen(userId: userId),
      ),
    );
      await tester.pump();
  }

  group('ProfileScreen - own profile', () {
    testWidgets('shows logout button and hides the rating card', (tester) async {
      final me = _makeUser(uid: 'me-1');
      authService.emitUser(FakeUser('me-1'));
      await userRepository.createProfile(me);

      await pumpProfile(tester); // no userId -> own profile

      expect(find.byIcon(Icons.logout), findsOneWidget);
      expect(find.text('Rate this person'), findsNothing);
    });

    testWidgets('shows "No skills added yet" when profile has no skills', (tester) async {
      final me = _makeUser(uid: 'me-1', skills: const []);
      authService.emitUser(FakeUser('me-1'));
      await userRepository.createProfile(me);

      await pumpProfile(tester);

      expect(find.text('No skills added yet'), findsOneWidget);
    });

    testWidgets('shows "No reviews yet" when there are no reviews', (tester) async {
      final me = _makeUser(uid: 'me-1');
      authService.emitUser(FakeUser('me-1'));
      await userRepository.createProfile(me);

      await pumpProfile(tester);
      reviewRepository.emit([]);
      await tester.pump();

      expect(find.text('No reviews yet'), findsOneWidget);
    });
  });

  group('ProfileScreen - viewing another user', () {
    testWidgets('hides logout button and shows the rating card', (tester) async {
      authService.emitUser(FakeUser('me-1'));
      await userRepository.createProfile(_makeUser(uid: 'me-1'));
      await userRepository.createProfile(_makeUser(uid: 'other-1', fullName: 'John Doe'));

      await pumpProfile(tester, userId: 'other-1');

      expect(find.byIcon(Icons.logout), findsNothing);
      expect(find.text('Rate this person'), findsOneWidget);
      expect(find.text('John Doe'), findsOneWidget);
    });

    testWidgets('tapping a star sets the rating visually', (tester) async {
      authService.emitUser(FakeUser('me-1'));
      await userRepository.createProfile(_makeUser(uid: 'me-1'));
      await userRepository.createProfile(_makeUser(uid: 'other-1'));

      await pumpProfile(tester, userId: 'other-1');

      final starButtons = find.byIcon(Icons.star_border);
      expect(starButtons, findsNWidgets(5));

      // Tap the 3rd star.
      await tester.tap(starButtons.at(2));
      await tester.pump();

      expect(find.byIcon(Icons.star), findsNWidgets(3));
      expect(find.byIcon(Icons.star_border), findsNWidgets(2));
    });

    testWidgets('submitting without a rating shows a snackbar and does not call addReview',
        (tester) async {
      authService.emitUser(FakeUser('me-1'));
      await userRepository.createProfile(_makeUser(uid: 'me-1'));
      await userRepository.createProfile(_makeUser(uid: 'other-1'));

      await pumpProfile(tester, userId: 'other-1');

      await tester.tap(find.text('Submit rating'));
      await tester.pump();

      expect(find.text('Please select a star rating'), findsOneWidget);
      expect(reviewRepository.createCallCount, 0);
    });

    testWidgets('submitting with a rating but empty comment shows a form validation error',
        (tester) async {
      authService.emitUser(FakeUser('me-1'));
      await userRepository.createProfile(_makeUser(uid: 'me-1'));
      await userRepository.createProfile(_makeUser(uid: 'other-1'));

      await pumpProfile(tester, userId: 'other-1');

      final starButtons = find.byIcon(Icons.star_border);
      expect(starButtons, findsNWidgets(5));

      await tester.tap(find.byIcon(Icons.star_border).first);
      await tester.pump();

      await tester.tap(find.text('Submit rating'));
      await tester.pump();

      expect(find.text('Please enter a review'), findsOneWidget);
      expect(reviewRepository.createCallCount, 0);
    });

    testWidgets('successful publish calls addReview with correct fields and pops the screen',
        (tester) async {
      authService.emitUser(FakeUser('me-1'));
      await userRepository.createProfile(_makeUser(uid: 'me-1'));
      await userRepository.createProfile(_makeUser(uid: 'other-1'));

      await tester.pumpWidget(
        buildHarness(
          authService: authService,
          userRepository: userRepository,
          reviewRepository: reviewRepository,
          skillRepository: skillRepository,
          child: Navigator(
            onGenerateRoute: (settings) => MaterialPageRoute(
              builder: (_) => const ProfileScreen(userId: 'other-1'),
            ),
          ),
        ),
      );
      await tester.pump();
      final starButtons = find.byIcon(Icons.star_border);
      expect(starButtons, findsNWidgets(5));

      await tester.tap(find.byIcon(Icons.star_border).at(4)); // 5 stars
      await tester.pump();

      await tester.enterText(find.byType(TextFormField).last, 'Great to work with!');
      await tester.tap(find.text('Submit rating'));
      await tester.pump(); // start the async publish
      await tester.pumpAndSettle();

      expect(reviewRepository.createCallCount, 1);
      expect(reviewRepository.lastCreatedReview?.targetUserId, 'other-1');
      expect(reviewRepository.lastCreatedReview?.rating, 5);
      expect(reviewRepository.lastCreatedReview?.comment, 'Great to work with!');
      // ProfileScreen should have been popped off the Navigator.
      expect(find.byType(ProfileScreen), findsNothing);
    });

    testWidgets('failed publish shows an error snackbar and re-enables the button',
        (tester) async {
      authService.emitUser(FakeUser('me-1'));
      await userRepository.createProfile(_makeUser(uid: 'me-1'));
      await userRepository.createProfile(_makeUser(uid: 'other-1'));

      reviewRepository.createError = Exception('network error');

      await pumpProfile(tester, userId: 'other-1');

      final starButtons = find.byIcon(Icons.star_border);
      expect(starButtons, findsNWidgets(5));

      await tester.tap(find.byIcon(Icons.star_border).first);
      await tester.pump();
      await tester.enterText(find.byType(TextFormField).last, 'Nice!');

      await tester.tap(find.text('Submit rating'));
      await tester.pump();
      await tester.pump();

      expect(find.textContaining('Could not publish review'), findsOneWidget);
      // Button should be tappable again (spinner gone).
      expect(find.text('Submit rating'), findsOneWidget);
    });

    testWidgets('displays average rating and review count', (tester) async {
      authService.emitUser(FakeUser('me-1'));
      await userRepository.createProfile(_makeUser(uid: 'me-1'));
      await userRepository.createProfile(_makeUser(uid: 'other-1'));

      await pumpProfile(tester, userId: 'other-1');

      // Adjust Review(...) constructor args to match your real model.
      reviewRepository.emit([
        Review(id: 'r1', authorId: 'me-1', targetUserId: 'other-1', rating: 4, comment: 'Good'),
        Review(id: 'r2', authorId: 'me-2', targetUserId: 'other-1', rating: 2, comment: 'Meh'),
      ]);
      await tester.pump();

      expect(find.text('3.0'), findsOneWidget);
      expect(find.text('  ·  2 reviews'), findsOneWidget);
    });
  });
}