import 'package:flutter/material.dart';

ThemeData buildThemeData() {
  final base = ThemeData.light();
  return base.copyWith(
    primaryColor: Color.fromARGB(255, 77, 115, 255), // Colors.blue,
    colorScheme: base.colorScheme.copyWith(
      primary: Color.fromARGB(255, 77, 115, 255),
      secondary: Colors.orange,
      error: Colors.red,
    ),
    scaffoldBackgroundColor: Colors.grey[100],
    textTheme: buildTextTheme(base.textTheme),

    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white, backgroundColor: Colors.blue,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
    ),

    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Colors.blue,
    ),

    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        foregroundColor: Colors.white, backgroundColor: Color.fromARGB(255, 77, 115, 255),
        // shape: RoundedRectangleBorder(
        //   borderRadius: BorderRadius.circular(8.0),
        // ),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Color.fromARGB(255, 77, 115, 255),
        // shape: RoundedRectangleBorder(
        //   borderRadius: BorderRadius.circular(8.0),
        // ),
      ),
    ),


  );
}

TextTheme buildTextTheme(TextTheme base) {
  return base
      .copyWith(
    displayLarge: base.displayLarge?.copyWith(fontWeight: FontWeight.bold),
    titleLarge: base.titleLarge?.copyWith(fontSize: 18.0),
    bodyMedium: base.bodyMedium?.copyWith(fontSize: 14.0),
  )
      .apply(
    fontFamily: 'Fredoka',
  );
}
