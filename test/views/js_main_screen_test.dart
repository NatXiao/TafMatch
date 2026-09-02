import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:taf_match/providers/auth_provider.dart';
import 'package:taf_match/providers/chat_provider.dart';
import 'package:taf_match/repositories/firestore_chat_repository.dart';
import 'package:taf_match/utils/theme.dart';
import 'package:taf_match/views/js_main_screen.dart';

/// AuthProvider needs a real Firestore repository to be built, so the screen
/// gets a stand-in instead. A null user keeps initState from starting any
/// stream, which is all this navigation test needs.
class _FakeAuthProvider extends ChangeNotifier implements AuthProvider {
  @override
  User? get user => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late ChatProvider chatProvider;

  setUp(() {
    chatProvider = ChatProvider(
      repository: FirestoreChatRepository(firestore: FakeFirebaseFirestore()),
    );
  });

  tearDown(() => chatProvider.dispose());

  /// Mounts JeMainScreen with all four tabs stubbed out, so no tab reaches
  /// Firebase on its own.
  Future<void> pumpScreen(WidgetTester tester) {
    return tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>(
            create: (_) => _FakeAuthProvider(),
          ),
          ChangeNotifierProvider<ChatProvider>.value(value: chatProvider),
        ],
        child: MaterialApp(
          theme: buildThemeData(),
          home: const JeMainScreen(
            jobsScreen: Placeholder(key: Key('jobs')),
            applicationsScreen: Placeholder(key: Key('applications')),
            chatScreen: Placeholder(key: Key('chat')),
            profileScreen: Placeholder(key: Key('profile')),
          ),
        ),
      ),
    );
  }

  int? visibleTab(WidgetTester tester) =>
      tester.widget<IndexedStack>(find.byType(IndexedStack)).index;

  testWidgets('JeMainScreen displays navigation tabs and the Jobs tab first',
      (tester) async {
    await pumpScreen(tester);

    expect(find.byKey(const Key('jobs_tab')), findsOneWidget);
    expect(find.byKey(const Key('applications_tab')), findsOneWidget);
    expect(find.byKey(const Key('messages_tab')), findsOneWidget);
    expect(find.byKey(const Key('profile_tab')), findsOneWidget);
    expect(visibleTab(tester), 0);
  });

  testWidgets('JeMainScreen switches to the Applications tab', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text('Applications'));
    await tester.pump();

    expect(visibleTab(tester), 1);
  });

  testWidgets('JeMainScreen switches to the Messages tab', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text('Messages'));
    await tester.pump();

    expect(visibleTab(tester), 2);
  });

  testWidgets('JeMainScreen switches to the Profile tab', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text('Profile'));
    await tester.pump();

    expect(visibleTab(tester), 3);
  });

  testWidgets('the Messages tab shows no badge when nothing is unread',
      (tester) async {
    await pumpScreen(tester);

    expect(chatProvider.totalUnread, 0);
    expect(find.text('1'), findsNothing);
  });
}
