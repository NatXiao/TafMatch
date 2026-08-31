import 'package:flutter/material.dart';
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
/// NOTE: Adjust the provider constructor calls below if your real
/// AuthProvider / ReviewProvider / UserProvider signatures differ. They are
/// inferred from usage in profile_screen.dart / edit_profile_screen.dart.
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
        create: (_) => AuthProvider(authService, userRepository), // adjust args if needed
      ),
      ChangeNotifierProvider<UserProvider>(
        create: (_) => UserProvider(userRepository), // adjust args if needed
      ),
      ChangeNotifierProvider<ReviewProvider>(
        create: (_) => ReviewProvider(reviewRepository), // adjust args if needed
      ),
      ChangeNotifierProvider<SkillProvider>(
        create: (_) => SkillProvider(skillRepository),
      ),
      Provider<FakeUserRepository>.value(value: userRepository),
    ],
    child: MaterialApp(
      // TODO: swap this for your app's real theme (the one that registers
      // the AppColors ThemeExtension in main.dart / utils/theme.dart), e.g.:
      // theme: AppTheme.light,
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