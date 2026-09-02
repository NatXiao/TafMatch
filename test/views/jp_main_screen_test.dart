import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taf_match/utils/theme.dart';
import 'package:taf_match/views/jp_main_screen.dart';

/// Deux substituts distincts, chacun avec sa cle.
///
/// `const Placeholder()` est canonicalise par Dart: les deux onglets
/// partageraient la meme instance et `find.byWidget` en trouverait deux.
const _postingsScreen = SizedBox(key: Key('postings_screen'));
const _profileScreen = SizedBox(key: Key('profile_screen'));

void main() {
  Future<void> pumpMainScreen(WidgetTester tester) {
    return tester.pumpWidget(
      MaterialApp(
        theme: buildThemeData(),
        home: const JpMainScreen(
          // Les vrais ecrans touchent Firebase (MyPostingsScreen cree un
          // FirestoreApplicationRepository dans initState) et reclament quatre
          // providers (ProfileScreen). IndexedStack construit ses deux enfants
          // des le premier build, meme celui qu'il ne peint pas.
          postingsScreen: _postingsScreen,
          profileScreen: _profileScreen,
        ),
      ),
    );
  }

  /// L'onglet reellement affiche.
  int visibleTab(WidgetTester tester) =>
      tester.widget<IndexedStack>(find.byType(IndexedStack)).index!;

  testWidgets('displays the two navigation tabs and opens on Postings', (
    tester,
  ) async {
    await pumpMainScreen(tester);

    expect(find.byKey(const Key('postings_tab')), findsOneWidget);
    expect(find.byKey(const Key('profile_tab')), findsOneWidget);

    expect(visibleTab(tester), 0);
  });

  testWidgets('switches to the Profile tab', (tester) async {
    await pumpMainScreen(tester);

    await tester.tap(find.byKey(const Key('profile_tab')));
    await tester.pump();

    expect(visibleTab(tester), 1);
  });

  testWidgets('goes back to the Postings tab', (tester) async {
    await pumpMainScreen(tester);

    await tester.tap(find.byKey(const Key('profile_tab')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('postings_tab')));
    await tester.pump();

    expect(visibleTab(tester), 0);
  });

  testWidgets('keeps both tabs mounted so their state survives a switch', (
    tester,
  ) async {
    await pumpMainScreen(tester);

    // skipOffstage: false est indispensable: IndexedStack enveloppe dans un
    // Offstage l'enfant qu'il ne peint pas, et les finders l'ignorent par
    // defaut. C'est justement ce qu'on veut verifier: monte, mais cache.
    expect(
      find.byKey(const Key('postings_screen'), skipOffstage: false),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('profile_screen'), skipOffstage: false),
      findsOneWidget,
    );
  });
}