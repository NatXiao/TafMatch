import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:taf_match/providers/auth_provider.dart';
import 'package:taf_match/providers/user_provider.dart';
import 'package:taf_match/utils/theme.dart';
import 'package:taf_match/views/face_login_screen.dart';

import '../fakes.dart';
import 'face_login_screen_test.mocks.dart';
import 'test_helpers.dart';

@GenerateMocks([AuthProvider])
void main() {
  late MockAuthProvider mockAuthProvider;

  setUp(() {
    mockAuthProvider = MockAuthProvider();

    when(mockAuthProvider.isLoading).thenReturn(false);
    when(mockAuthProvider.errorMessage).thenReturn(null);
  });

  Widget createTestWidget() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
        ChangeNotifierProvider<UserProvider>(
          create: (_) => UserProvider(FakeUserRepository()),
        ),
      ],
      child: MaterialApp(
        theme: buildThemeData(),
        home: FaceLoginScreen(cameraService: FakeCameraService()),
      ),
    );
  }

  testWidgets('FaceLoginScreen displays correctly', (tester) async {
    await tester.pumpWidget(createTestWidget());

    expect(find.text('Log in with a photo'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Log in'), findsOneWidget);
    expect(find.text('Detect'), findsOneWidget);
    expect(find.text('About developers - v1.0'), findsOneWidget);
  });

  testWidgets('shows password validation error when empty', (tester) async {
    await useTallSurface(tester);
    await tester.pumpWidget(createTestWidget());

    await tester.tap(find.text('Log in'));
    await tester.pump();

    expect(find.text('Please enter a password'), findsOneWidget);
  });
}