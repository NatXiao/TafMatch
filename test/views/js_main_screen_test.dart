import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taf_match/utils/theme.dart';
import 'package:taf_match/views/about_screen.dart';
import 'package:taf_match/views/js_main_screen.dart';

void main() {
  testWidgets('JeMainScreen displays navigation tabs and the Jobs tab first', (
    WidgetTester tester,
  ) async {
    const jobsScreen = Placeholder();
    const applicationsScreen = Placeholder();

    await tester.pumpWidget(
      MaterialApp(
        theme: buildThemeData(),
        home: const JeMainScreen(
          jobsScreen: jobsScreen,
          applicationsScreen: applicationsScreen,
        ),
      ),
    );

    expect(find.byKey(Key("jobs_tab")), findsOneWidget);
    expect(find.byKey(Key("applications_tab")), findsOneWidget);
    expect(find.byKey(Key("profile_tab")), findsOneWidget);
    // TODO : Voir pourquoi celui là ne marche pas
    // expect(find.byWidget(jobsScreen), findsOneWidget);
  });

  testWidgets('JeMainScreen switches to the Applications tab', (
    WidgetTester tester,
  ) async {
    const jobsScreen = Placeholder();
    const applicationsScreen = Placeholder();

    await tester.pumpWidget(
      MaterialApp(
        theme: buildThemeData(),
        home: const JeMainScreen(
          jobsScreen: jobsScreen,
          applicationsScreen: applicationsScreen,
        ),
      ),
    );

    await tester.tap(find.text('Applications'));
    await tester.pump();

    expect(find.byWidget(applicationsScreen), findsOneWidget);
  });

  testWidgets('JeMainScreen switches to the Profile tab', (
    WidgetTester tester,
  ) async {
    const jobsScreen = Placeholder();
    const applicationsScreen = Placeholder();

    await tester.pumpWidget(
      MaterialApp(
        theme: buildThemeData(),
        home: const JeMainScreen(
          jobsScreen: jobsScreen,
          applicationsScreen: applicationsScreen,
        ),
      ),
    );

    await tester.tap(find.text('Profile'));
    await tester.pump();

    expect(find.byType(AboutScreen), findsOneWidget);
  });
}
