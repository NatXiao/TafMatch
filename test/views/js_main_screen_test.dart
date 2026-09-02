import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taf_match/utils/theme.dart';
import 'package:taf_match/views/js_main_screen.dart';

/// Trois substituts distincts, chacun avec sa cle.
///
/// `const Placeholder()` etait canonicalise par Dart: les trois onglets
/// partageaient la meme instance, et `find.byWidget` en trouvait trois au lieu
/// d'un. Des cles differentes suffisent a les distinguer.
const _jobsScreen = SizedBox(key: Key('jobs_screen'));
const _applicationsScreen = SizedBox(key: Key('applications_screen'));
const _profileScreen = SizedBox(key: Key('profile_screen'));

void main() {
  Future<void> pumpMainScreen(WidgetTester tester) {
    return tester.pumpWidget(
      MaterialApp(
        theme: buildThemeData(),
        home: const JeMainScreen(
          jobsScreen: _jobsScreen,
          applicationsScreen: _applicationsScreen,
          // Substitut aussi pour le profil: le vrai ProfileScreen reclame
          // quatre providers, et IndexedStack construit ses trois enfants des
          // le premier build, meme ceux qu'il ne peint pas.
          profileScreen: _profileScreen,
        ),
      ),
    );
  }

  /// L'onglet reellement affiche.
  ///
  /// On ne peut pas s'appuyer sur la presence des enfants: IndexedStack les
  /// monte tous les trois et se contente de n'en peindre qu'un.
  int visibleTab(WidgetTester tester) =>
      tester.widget<IndexedStack>(find.byType(IndexedStack)).index!;

  testWidgets('displays the three navigation tabs and opens on Jobs', (
    tester,
  ) async {
    await pumpMainScreen(tester);

    expect(find.byKey(const Key('jobs_tab')), findsOneWidget);
    expect(find.byKey(const Key('applications_tab')), findsOneWidget);
    expect(find.byKey(const Key('profile_tab')), findsOneWidget);

    expect(visibleTab(tester), 0);
  });

  testWidgets('switches to the Applications tab', (tester) async {
    await pumpMainScreen(tester);

    await tester.tap(find.byKey(const Key('applications_tab')));
    await tester.pump();

    expect(visibleTab(tester), 1);
  });

  testWidgets('switches to the Profile tab', (tester) async {
    await pumpMainScreen(tester);

    await tester.tap(find.byKey(const Key('profile_tab')));
    await tester.pump();

    expect(visibleTab(tester), 2);
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

    // C'est l'interet d'IndexedStack par rapport a un simple switch: les trois
    // ecrans restent montes, donc leur scroll et leurs abonnements survivent.
    //
    // skipOffstage: false est indispensable — IndexedStack enveloppe dans un
    // Offstage les enfants qu'il ne peint pas, et les finders les ignorent par
    // defaut. C'est justement ce qu'on veut verifier ici: montes, mais caches.
    expect(
      find.byKey(const Key('jobs_screen'), skipOffstage: false),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('applications_screen'), skipOffstage: false),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('profile_screen'), skipOffstage: false),
      findsOneWidget,
    );
  });
}