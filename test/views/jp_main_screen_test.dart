import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taf_match/utils/theme.dart';
import 'package:taf_match/views/about_screen.dart';
import 'package:taf_match/views/jp_main_screen.dart';

void main() {
  testWidgets('JpMainScreen displays navigation tabs', (
    WidgetTester tester,
  ) async {
    const postingsScreen = Placeholder();

    await tester.pumpWidget(
      MaterialApp(
        theme: buildThemeData(),
        home: const JpMainScreen(
          postingsScreen: postingsScreen,
        ),
      ),
    );

    expect(find.text('Postings'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
    expect(find.byWidget(postingsScreen), findsOneWidget);
  });

  testWidgets('JpMainScreen switches to Profile tab', (
    WidgetTester tester,
  ) async {
    const postingsScreen = Placeholder();

    await tester.pumpWidget(
      MaterialApp(
        theme: buildThemeData(),
        home: const JpMainScreen(
          postingsScreen: postingsScreen,
        ),
      ),
    );

    expect(find.byWidget(postingsScreen), findsOneWidget);

    await tester.tap(find.text('Profile'));
    await tester.pump();

    expect(find.byType(AboutScreen), findsOneWidget);
  });
}