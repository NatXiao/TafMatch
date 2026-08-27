import 'package:flutter/material.dart';

@immutable
class AppColors extends ThemeExtension<AppColors> {
  final Color accent;
  final Color softAccent;
  final Color text;
  final Color muted;
  final Color field;
  final Color border;
  final Color avatar;      
  final Color danger;      
  final Color softDanger; 

  const AppColors({
    required this.accent,
    required this.softAccent,
    required this.text,
    required this.muted,
    required this.field,
    required this.border,
    required this.avatar,      
    required this.danger,      
    required this.softDanger, 
  });

  @override
  AppColors copyWith({
    Color? accent,
    Color? softAccent,
    Color? text,
    Color? muted,
    Color? field,
    Color? border,
    Color? avatar,
    Color? danger,
    Color? softDanger,
  }) {
    return AppColors(
      accent: accent ?? this.accent,
      softAccent: softAccent ?? this.softAccent,
      text: text ?? this.text,
      muted: muted ?? this.muted,
      field: field ?? this.field,
      border: border ?? this.border,
      avatar: avatar ?? this.avatar,
      danger: danger ?? this.danger,
      softDanger: softDanger ?? this.softDanger,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      accent: Color.lerp(accent, other.accent, t)!,
      softAccent: Color.lerp(softAccent, other.softAccent, t)!,
      text: Color.lerp(text, other.text, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      field: Color.lerp(field, other.field, t)!,
      border: Color.lerp(border, other.border, t)!,
      avatar: Color.lerp(avatar, other.avatar, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      softDanger: Color.lerp(softDanger, other.softDanger, t)!,
    );
  }
}

// ---------------------------------------------------------------------------
// Thème principal de l'application.
// ---------------------------------------------------------------------------
ThemeData buildThemeData() {
  final base = ThemeData.light();
  const accent = Color(0xFF4D73FF);

  return base.copyWith(
    primaryColor: accent,
    colorScheme: base.colorScheme.copyWith(
      primary: accent,
      secondary: Colors.orange,
      error: Colors.red,
    ),
    scaffoldBackgroundColor: Colors.grey[100],
    textTheme: buildTextTheme(base.textTheme),

    extensions: const [
      AppColors(
        accent: accent,
        softAccent: Color(0xFFE6EDFF),
        text: Color(0xFF1F212E),
        muted: Color(0xFF8A91A3),
        field: Color(0xFFF4F6FB),
        border: Color(0xFFE6EBF5),
        avatar: Color(0xFFCCD9F0),     
        danger: Color(0xFFE5484D),     
        softDanger: Color(0xFFFDEBEC),
      ),
    ],

    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: accent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
    ),

    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: accent,
    ),

    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: accent,
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: accent,
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
