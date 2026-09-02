 import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:taf_match/providers/auth_provider.dart';
import 'package:taf_match/providers/review_provider.dart';
import 'package:taf_match/providers/skill_provider.dart';
import 'package:taf_match/providers/user_provider.dart';
import 'package:taf_match/utils/theme.dart';

import '../fakes.dart'; // FakeAuthService, FakeUserRepository, FakeReviewRepository, FakeSkillRepository, ...

/// Wraps [child] with MaterialApp + the real AppColors theme extension +
/// all providers the two screens under test depend on.
///
/// IMPORTANT: UserProvider does not listen to auth changes on its own —
/// something in main.dart must be calling `userProvider.updateAuthProvider(authProvider)`
/// whenever the logged-in user changes (that's the only thing that triggers
/// `loadProfile()`). We reproduce that wiring here with a
/// ChangeNotifierProxyProvider; without it, UserProvider.profile stays null
/// forever in tests, which is what caused the pre-fill / selected-skill /
/// unsaved-changes failures.
Widget buildHarness({
  required Widget child,
  required FakeAuthService authService,
  required FakeUserRepository userRepository,
  required FakeReviewRepository reviewRepository,
  required FakeSkillRepository skillRepository,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>(
        create: (_) => AuthProvider(authService, userRepository),
      ),
      ChangeNotifierProxyProvider<AuthProvider, UserProvider>(
        create: (_) => UserProvider(userRepository),
        update: (_, auth, previous) {
          final up = previous ?? UserProvider(userRepository);
          up.updateAuthProvider(auth);
          return up;
        },
      ),
      ChangeNotifierProvider<ReviewProvider>(
        create: (_) => ReviewProvider(reviewRepository),
      ),
      ChangeNotifierProvider<SkillProvider>(
        create: (_) => SkillProvider(skillRepository),
      ),
      Provider<FakeUserRepository>.value(value: userRepository),
    ],
    child: MaterialApp(
      theme: ThemeData(
        extensions: const [
          AppColors(
            text: Colors.black,
            muted: Colors.grey,
            accent: Colors.blue,
            softAccent: Color(0xFFEFF3FF),
            border: Colors.black12,
            avatar: Colors.grey,
            field: Colors.white,
            danger: Colors.red,
            softDanger: Colors.red,
          ),
        ],
      ),
      home: child,
    ),
  );
}

/// Grows the test surface so the whole EditProfileScreen/ProfileScreen fits
/// without scrolling, avoiding "offset outside the render tree" tap failures.
/// Call this at the top of each test that pumps one of these screens; the
/// teardown is auto-registered so later tests in the same file aren't affected.
Future<void> useTallSurface(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(400, 2000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}