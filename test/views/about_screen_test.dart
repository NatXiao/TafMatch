import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:taf_match/utils/theme.dart';
import 'package:taf_match/views/about_screen.dart';

void main() {
  testWidgets('AboutScreen builds', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildThemeData(),
        home: const AboutScreen(),
      ),
    );

    expect(find.byType(AboutScreen), findsOneWidget);
  });
}