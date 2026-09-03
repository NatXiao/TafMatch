import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:taf_match/providers/auth_provider.dart';
import 'package:taf_match/providers/chat_provider.dart';
import 'package:taf_match/repositories/firestore_chat_repository.dart';
import 'package:taf_match/utils/theme.dart';
import 'package:taf_match/views/jp_main_screen.dart';

/// Three distinct substitutes, each with its own key.
///
/// `const Placeholder()` is canonicalized by Dart: the tabs would share
/// the same instance and `find.byWidget` would find multiple matches.
const _postingsScreen = SizedBox(key: Key('postings_screen'));
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
          home: const JpMainScreen(
            // The real screens access Firebase (MyPostingsScreen creates a
            // FirestoreApplicationRepository in initState) and require
            // plusieurs providers (ProfileScreen). IndexedStack construit tous
            // its children during the first build, even those it does not paint.
            postingsScreen: _postingsScreen,
            chatScreen: _chatScreen,
            profileScreen: _profileScreen,
          ),
        ),
      ),
    );
  }

  /// L'onglet reellement affiche.
  int visibleTab(WidgetTester tester) =>
      tester.widget<IndexedStack>(find.byType(IndexedStack)).index!;

  testWidgets('displays the three navigation tabs and opens on Postings', (
    tester,
  ) async {
    await pumpMainScreen(tester);

    expect(find.byKey(const Key('postings_tab')), findsOneWidget);
    expect(find.byKey(const Key('messages_tab')), findsOneWidget);
    expect(find.byKey(const Key('profile_tab')), findsOneWidget);

    expect(visibleTab(tester), 0);
  });

  testWidgets('switches to the Messages tab', (tester) async {
    await pumpMainScreen(tester);

    await tester.tap(find.byKey(const Key('messages_tab')));
    await tester.pump();

    expect(visibleTab(tester), 1);
  });

  testWidgets('switches to the Profile tab', (tester) async {
    await pumpMainScreen(tester);

    await tester.tap(find.byKey(const Key('profile_tab')));
    await tester.pump();

    expect(visibleTab(tester), 2);
  });

  testWidgets('goes back to the Postings tab', (tester) async {
    await pumpMainScreen(tester);

    await tester.tap(find.byKey(const Key('profile_tab')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('postings_tab')));
    await tester.pump();

    expect(visibleTab(tester), 0);
  });

  testWidgets('keeps every tab mounted so their state survives a switch', (
    tester,
  ) async {
    await pumpMainScreen(tester);

    // skipOffstage: false is essential: IndexedStack wraps children in
    // Offstage, and finders ignore them by
    // default. This is exactly what we want to verify: mounted but hidden.
    expect(
      find.byKey(const Key('postings_screen'), skipOffstage: false),
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