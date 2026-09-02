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

/// Trois substituts distincts, chacun avec sa cle.
///
/// `const Placeholder()` est canonicalise par Dart: les onglets partageraient
/// la meme instance et `find.byWidget` en trouverait plusieurs.
const _postingsScreen = SizedBox(key: Key('postings_screen'));
const _chatScreen = SizedBox(key: Key('chat_screen'));
const _profileScreen = SizedBox(key: Key('profile_screen'));

/// AuthProvider a besoin d'un vrai repository Firestore pour etre construit,
/// donc l'ecran recoit un substitut. Un user null empeche initState de lancer
/// le moindre stream, ce qui suffit a un test de navigation.
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
            // Les vrais ecrans touchent Firebase (MyPostingsScreen cree un
            // FirestoreApplicationRepository dans initState) et reclament
            // plusieurs providers (ProfileScreen). IndexedStack construit tous
            // ses enfants des le premier build, meme ceux qu'il ne peint pas.
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

    // skipOffstage: false est indispensable: IndexedStack enveloppe dans un
    // Offstage les enfants qu'il ne peint pas, et les finders les ignorent par
    // defaut. C'est justement ce qu'on veut verifier: montes, mais caches.
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