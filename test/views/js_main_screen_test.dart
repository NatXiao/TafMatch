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

/// Four distinct substitutes, each with its own key.
///
/// `const Placeholder()` was canonicalized by Dart: the tabs shared
/// the same instance, and `find.byWidget` found multiple matches instead of one.
/// Different keys are enough to distinguish them.
const _jobsScreen = SizedBox(key: Key('jobs_screen'));
const _applicationsScreen = SizedBox(key: Key('applications_screen'));
const _chatScreen = SizedBox(key: Key('chat_screen'));
const _profileScreen = SizedBox(key: Key('profile_screen'));

/// AuthProvider needs a real Firestore repository to be constructed,
/// so the screen receives a substitute. A null user prevents initState from starting
/// any stream, which is enough for a navigation test.
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

  Future<void> pumpMainScreen(WidgetTester tester) {
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
            jobsScreen: _jobsScreen,
            applicationsScreen: _applicationsScreen,
            chatScreen: _chatScreen,
            // Substitute for the profile as well: the real ProfileScreen requires
            // plusieurs providers, et IndexedStack construit tous ses enfants
            // several providers, and IndexedStack builds all children during the first build, even those it does not paint.
            profileScreen: _profileScreen,
          ),
        ),
      ),
    );
  }

  /// L'onglet reellement affiche.
  ///
  /// We cannot rely on the presence of the children: IndexedStack
  /// mounts all of them and only paints one.
  int visibleTab(WidgetTester tester) =>
      tester.widget<IndexedStack>(find.byType(IndexedStack)).index!;

  testWidgets('displays the four navigation tabs and opens on Jobs', (
    tester,
  ) async {
    await pumpMainScreen(tester);

    expect(find.byKey(const Key('jobs_tab')), findsOneWidget);
    expect(find.byKey(const Key('applications_tab')), findsOneWidget);
    expect(find.byKey(const Key('messages_tab')), findsOneWidget);
    expect(find.byKey(const Key('profile_tab')), findsOneWidget);

    expect(visibleTab(tester), 0);
  });

  testWidgets('switches to the Applications tab', (tester) async {
    await pumpMainScreen(tester);

    await tester.tap(find.byKey(const Key('applications_tab')));
    await tester.pump();

    expect(visibleTab(tester), 1);
  });

  testWidgets('switches to the Messages tab', (tester) async {
    await pumpMainScreen(tester);

    await tester.tap(find.byKey(const Key('messages_tab')));
    await tester.pump();

    expect(visibleTab(tester), 2);
  });

  testWidgets('switches to the Profile tab', (tester) async {
    await pumpMainScreen(tester);

    await tester.tap(find.byKey(const Key('profile_tab')));
    await tester.pump();

    expect(visibleTab(tester), 3);
  });

  testWidgets('goes back to the Jobs tab', (tester) async {
    await pumpMainScreen(tester);

    await tester.tap(find.byKey(const Key('profile_tab')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('jobs_tab')));
    await tester.pump();

    expect(visibleTab(tester), 0);
  });

  testWidgets('keeps every tab mounted so their state survives a switch', (
    tester,
  ) async {
    await pumpMainScreen(tester);

    // This is the benefit of IndexedStack over a simple switch: the
    // screens remain mounted, so their scroll position and subscriptions survive.
    //
    // skipOffstage: false is essential — IndexedStack wraps children in
    // Offstage, and finders ignore them by
    // default. This is exactly what we want to verify: mounted but hidden.
    expect(
      find.byKey(const Key('jobs_screen'), skipOffstage: false),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('applications_screen'), skipOffstage: false),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('chat_screen'), skipOffstage: false),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('profile_screen'), skipOffstage: false),
      findsOneWidget,
    );
  });

  testWidgets('the Messages tab shows no badge when nothing is unread', (
    tester,
  ) async {
    await pumpMainScreen(tester);

    expect(chatProvider.totalUnread, 0);
    expect(find.text('1'), findsNothing);
  });
}