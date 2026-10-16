import 'package:flutter/material.dart';

/// LinguaPath's colors. Violet brand, sunny yellow highlights,
/// and one bright color per unit so the course path feels like a journey.
class Palette {
  static const violet = Color(0xFF6C4BF4);
  static const violetDark = Color(0xFF4E30D6);
  static const violetSoft = Color(0xFFEDE8FF);
  static const sun = Color(0xFFFFC531);
  static const sunDark = Color(0xFFE5A400);
  static const green = Color(0xFF2BC48A);
  static const greenDark = Color(0xFF1E9E6E);
  static const greenSoft = Color(0xFFDDF7EC);
  static const coral = Color(0xFFFF5A5F);
  static const coralDark = Color(0xFFD9363C);
  static const coralSoft = Color(0xFFFFE3E4);
  static const ink = Color(0xFF231C47);
  static const inkSoft = Color(0xFF6E6894);
  static const line = Color(0xFFE4E0F5);
  static const locked = Color(0xFFE6E3EF);
  static const lockedDark = Color(0xFFC9C4DA);
  static const background = Color(0xFFFAF9FF);
  static const flame = Color(0xFFFF8A1F);

  /// One color per unit, cycling.
  static const units = [
    (Color(0xFF6C4BF4), Color(0xFF4E30D6)), // violet
    (Color(0xFF1CB0F6), Color(0xFF1290CC)), // sky
    (Color(0xFFFF8A1F), Color(0xFFDB6C00)), // orange
    (Color(0xFFFF5FA2), Color(0xFFD63F81)), // pink
    (Color(0xFF2BC48A), Color(0xFF1E9E6E)), // green
    (Color(0xFF00B8B8), Color(0xFF008F8F)), // teal
    (Color(0xFFE5A400), Color(0xFFB98500)), // gold
    (Color(0xFF8F5BFF), Color(0xFF6A38E0)), // purple
  ];

  static (Color, Color) unit(int index) => units[index % units.length];
}

ThemeData buildTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: Palette.violet,
    brightness: brightness,
    primary: dark ? const Color(0xFF9C85FF) : Palette.violet,
    surface: dark ? const Color(0xFF15122B) : Palette.background,
  );
  final base = ThemeData(colorScheme: scheme, useMaterial3: true, fontFamily: 'Nunito');
  final text = base.textTheme.apply(
    bodyColor: dark ? Colors.white : Palette.ink,
    displayColor: dark ? Colors.white : Palette.ink,
  );
  return base.copyWith(
    scaffoldBackgroundColor: scheme.surface,
    textTheme: text.copyWith(
      headlineMedium: text.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
      headlineSmall: text.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
      titleLarge: text.titleLarge?.copyWith(fontWeight: FontWeight.w800),
      titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w800),
      bodyLarge: text.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
      bodyMedium: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: dark ? const Color(0xFF1C1838) : Colors.white,
      indicatorColor: scheme.primary.withValues(alpha: 0.15),
      surfaceTintColor: Colors.transparent,
      labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: dark ? Colors.white12 : Palette.line, width: 2),
      ),
    ),
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
  );
}
