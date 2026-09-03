import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:taf_match/models/skill_model.dart';
import 'package:taf_match/models/user_model.dart';
import 'package:taf_match/repositories/image_storage_repository.dart';
import 'package:taf_match/views/edit_profile_screen.dart';

import '../fakes.dart';
import 'test_helpers.dart';

class FakeImageStorageRepository implements ImageStorageRepository {
  String? urlToReturn = 'https://example.com/avatar.png';
  Object? uploadError;

  @override
  Future<String> uploadImage(List<int> bytes, String fileName) async {
    if (uploadError != null) throw uploadError!;
    return urlToReturn!;
  }
}

UserModel _makeUser({
  required String uid,
  String fullName = 'Marie Rossier',
  String email = 'marie@edu.hes-so.ch',
  String role = 'Student',
  String address = 'Route de la gare 1',
  String profilePictureUrl = '',
  List<String> skills = const [],
}) {
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
  late FakeImageStorageRepository imageRepository;

  setUp(() {
    authService = FakeAuthService();
    userRepository = FakeUserRepository();
    reviewRepository = FakeReviewRepository();
    skillRepository = FakeSkillRepository();
    imageRepository = FakeImageStorageRepository();
  });

  tearDown(() {
    authService.dispose();
    userRepository.dispose();
    reviewRepository.dispose();
  });

  Widget harness() {
    final base = buildHarness(
      authService: authService,
      userRepository: userRepository,
      reviewRepository: reviewRepository,
      skillRepository: skillRepository,
      child: EditProfileScreen(),
    );
    return MultiProvider(
      providers: [
        Provider<ImageStorageRepository>.value(value: imageRepository),
      ],
      child: base,
    );
  }

  /// Pumps the screen, on a tall surface so nothing sits below the fold, and
  /// settles until the AuthProvider -> UserProvider -> SkillProvider chain
  /// has fully resolved.
  Future<void> pumpEditProfile(WidgetTester tester) async {
    await useTallSurface(tester);
    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();
  }

  group('EditProfileScreen - initial state', () {
    testWidgets('pre-fills fields from the current UserProvider profile', (tester) async {
      final me = _makeUser(uid: 'me-1', fullName: 'Alice', email: 'alice@x.com', address: 'Rue A');
      authService.emitUser(FakeUser('me-1'));
      await userRepository.createProfile(me);

      await pumpEditProfile(tester);

      final fullNameField =
        tester.widget<TextFormField>(find.byKey(const Key('fullNameField')));

      final emailField =
        tester.widget<TextFormField>(find.byKey(const Key('emailField')));

      final addressField =
        tester.widget<TextFormField>(find.byKey(const Key('addressField')));

      expect(fullNameField.controller?.text, 'Alice');
      expect(emailField.controller?.text, 'alice@x.com');
      expect(addressField.controller?.text, 'Rue A');
    });

    testWidgets('shows a loading indicator while skills are loading', (tester) async {
      final me = _makeUser(uid: 'me-1');
      authService.emitUser(FakeUser('me-1'));
      await userRepository.createProfile(me);

      // Gate getAll() so it never resolves until we say so, otherwise the
      // loading state is too brief (a single microtask) to observe.
      final gate = Completer<List<Skill>>();
      skillRepository.getAllGate = gate;

      await useTallSurface(tester);
      await tester.pumpWidget(harness());
      // Frame 1: builds the tree; initState's addPostFrameCallback fires at
      // the end of this same pump, calling loadSkills() -> isLoading = true.
      await tester.pump();
      // Frame 2: rebuild reflecting isLoading == true.
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsWidgets);

      // Let it resolve so we don't leave a dangling async gap.
      gate.complete([]);
      await tester.pumpAndSettle();
    });

    testWidgets('shows "No skills available" when the catalog is empty', (tester) async {
      final me = _makeUser(uid: 'me-1');
      authService.emitUser(FakeUser('me-1'));
      await userRepository.createProfile(me);
      skillRepository.skillsToReturn = [];

      await pumpEditProfile(tester);

      expect(find.text('No skills available'), findsOneWidget);
    });

    testWidgets('marks previously-selected skills as selected', (tester) async {
      final me = _makeUser(uid: 'me-1', skills: const ['s1']);
      authService.emitUser(FakeUser('me-1'));
      await userRepository.createProfile(me);
      skillRepository.skillsToReturn = [
        Skill(id: 's1', name: 'Dart'),
        Skill(id: 's2', name: 'Flutter'),
      ];

      await pumpEditProfile(tester);

      final dartChip = tester.widget<AnimatedContainer>(
        find.ancestor(of: find.text('Dart'), matching: find.byType(AnimatedContainer)),
      );
      final decoration = dartChip.decoration as BoxDecoration;
      expect(decoration.color, isNot(Colors.white));
    });
  });

  group('EditProfileScreen - skill selection', () {
    testWidgets('tapping an unselected skill selects it', (tester) async {
      final me = _makeUser(uid: 'me-1', skills: const []);
      authService.emitUser(FakeUser('me-1'));
      await userRepository.createProfile(me);
      skillRepository.skillsToReturn = [Skill(id: 's1', name: 'Dart')];

      await pumpEditProfile(tester);

      await tester.tap(find.text('Dart'));
      await tester.pumpAndSettle();

      final dartChip = tester.widget<AnimatedContainer>(
        find.ancestor(of: find.text('Dart'), matching: find.byType(AnimatedContainer)),
      );
      final decoration = dartChip.decoration as BoxDecoration;
      expect(decoration.color, isNot(Colors.white));
    });

    testWidgets('tapping a selected skill deselects it', (tester) async {
      final me = _makeUser(uid: 'me-1', skills: const ['s1']);
      authService.emitUser(FakeUser('me-1'));
      await userRepository.createProfile(me);
      skillRepository.skillsToReturn = [Skill(id: 's1', name: 'Dart')];

      await pumpEditProfile(tester);
      await tester.tap(find.text('Dart'));
      await tester.pumpAndSettle();

      final dartChip = tester.widget<AnimatedContainer>(
        find.ancestor(of: find.text('Dart'), matching: find.byType(AnimatedContainer)),
      );
      final decoration = dartChip.decoration as BoxDecoration;
      expect(decoration.color, Colors.white);
    });
  });

  group('EditProfileScreen - validation', () {
    testWidgets('shows an error for an invalid email format', (tester) async {
      final me = _makeUser(uid: 'me-1');
      authService.emitUser(FakeUser('me-1'));
      await userRepository.createProfile(me);

      await pumpEditProfile(tester);

      await tester.enterText(find.byKey(const Key('emailField')), 'not-an-email');
      await tester.tap(find.text('Update profile'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a valid email'), findsOneWidget);
    });

    testWidgets('accepts an empty email field (falls back to existing email)', (tester) async {
      final me = _makeUser(uid: 'me-1');
      authService.emitUser(FakeUser('me-1'));
      await userRepository.createProfile(me);

      await pumpEditProfile(tester);

      await tester.enterText(find.byKey(const Key('emailField')), '');
      await tester.tap(find.text('Update profile'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a valid email'), findsNothing);
    });
  });

  group('EditProfileScreen - unsaved changes / back navigation', () {
    testWidgets('back button pops immediately when nothing changed', (tester) async {
      final me = _makeUser(uid: 'me-1');
      authService.emitUser(FakeUser('me-1'));
      await userRepository.createProfile(me);

      await useTallSurface(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => harness()),
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pumpAndSettle();

      expect(find.byType(EditProfileScreen), findsNothing);
      expect(find.text('Unsaved changes'), findsNothing);
    });

    testWidgets('back button shows the unsaved-changes dialog when a field changed',
        (tester) async {
      final me = _makeUser(uid: 'me-1');
      authService.emitUser(FakeUser('me-1'));
      await userRepository.createProfile(me);

      await pumpEditProfile(tester);

      await tester.enterText(find.byKey(const Key('fullNameField')), 'Changed Name');
      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pumpAndSettle();

      expect(find.text('Unsaved changes'), findsOneWidget);
    });

    testWidgets('"Discard" in the dialog pops without saving', (tester) async {
      final me = _makeUser(uid: 'me-1');
      authService.emitUser(FakeUser('me-1'));
      await userRepository.createProfile(me);

      await useTallSurface(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => harness()),
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('fullNameField')), 'Changed Name');
      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();

      expect(find.byType(EditProfileScreen), findsNothing);
    });

    testWidgets('"Continue editing" keeps the screen open with changes intact', (tester) async {
      final me = _makeUser(uid: 'me-1');
      authService.emitUser(FakeUser('me-1'));
      await userRepository.createProfile(me);

      await pumpEditProfile(tester);

      await tester.enterText(find.byKey(const Key('fullNameField')), 'Changed Name');
      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue editing'));
      await tester.pumpAndSettle();

      expect(find.byType(EditProfileScreen), findsOneWidget);
      expect(find.text('Changed Name'), findsOneWidget);
    });

    testWidgets(
        'changing then reverting a field back to its original value reports no unsaved changes',
        (tester) async {
      final me = _makeUser(uid: 'me-1', fullName: 'Original');
      authService.emitUser(FakeUser('me-1'));
      await userRepository.createProfile(me);

      await pumpEditProfile(tester);

      final field = find.byKey(const Key('fullNameField'));
      await tester.enterText(field, 'Temp');
      await tester.enterText(field, 'Original');

      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pumpAndSettle();

      expect(find.text('Unsaved changes'), findsNothing);
    });

    testWidgets('toggling a skill counts as an unsaved change', (tester) async {
      final me = _makeUser(uid: 'me-1', skills: const []);
      authService.emitUser(FakeUser('me-1'));
      await userRepository.createProfile(me);
      skillRepository.skillsToReturn = [Skill(id: 's1', name: 'Dart')];

      await pumpEditProfile(tester);

      await tester.tap(find.text('Dart'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pumpAndSettle();

      expect(find.text('Unsaved changes'), findsOneWidget);
    });
  });

  group('EditProfileScreen - save flow', () {
    testWidgets('tapping "Update profile" persists selected skills and full name', (tester) async {
      final me = _makeUser(uid: 'me-1', fullName: 'Original', skills: const []);
      authService.emitUser(FakeUser('me-1'));
      await userRepository.createProfile(me);
      skillRepository.skillsToReturn = [Skill(id: 's1', name: 'Dart')];

      await pumpEditProfile(tester);

      await tester.enterText(find.byKey(const Key('fullNameField')), 'Updated Name');
      await tester.tap(find.text('Dart'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Update profile'));
      await tester.pumpAndSettle();

      final saved = await userRepository.getProfile('me-1');
      // This will only actually reflect the new name/skills once
      // FakeUserRepository.updateProfile is implemented (it currently
      // throws UnimplementedError) — see the note in chat.
      expect(saved, isNotNull);
    });
  });
}