import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color forest = Color(0xFF153C2E);
  static const Color pine = Color(0xFF245240);
  static const Color moss = Color(0xFF3E6B57);
  static const Color sage = Color(0xFFA6C3B2);
  static const Color mist = Color(0xFFE6F0EA);
  static const Color paper = Color(0xFFF7FBF8);
  static const Color surface = Colors.white;
  static const Color ink = Color(0xFF10251C);
  static const Color success = Color(0xFF2D7A55);
  static const Color warning = Color(0xFFB8872E);
  static const Color danger = Color(0xFFC45A5A);
  static const Color info = Color(0xFF5D7A6E);

  static const Color espresso = forest;
  static const Color moka = pine;
  static const Color cream = mist;
  static const Color caramel = moss;
  static const Color terracotta = warning;
  static const Color olive = success;
  static const Color gold = sage;

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: forest,
      brightness: Brightness.light,
    ).copyWith(
      primary: forest,
      secondary: moss,
      surface: surface,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: ink,
      error: danger,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: paper,
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: paper,
        foregroundColor: ink,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: forest.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: pine, width: 1.4),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: mist,
        selectedColor: forest,
        secondarySelectedColor: forest,
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
      dividerColor: forest.withValues(alpha: 0.08),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: forest,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        behavior: SnackBarBehavior.floating,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: pine,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: forest,
        unselectedLabelColor: info,
        indicator: BoxDecoration(
          color: mist,
          borderRadius: BorderRadius.circular(14),
        ),
        dividerColor: Colors.transparent,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );

    final textTheme = GoogleFonts.dmSansTextTheme(base.textTheme);
    return base.copyWith(
      textTheme: textTheme.copyWith(
        headlineMedium: GoogleFonts.dmSerifDisplay(
          fontSize: 30,
          fontWeight: FontWeight.w400,
          color: forest,
        ),
        headlineSmall: GoogleFonts.dmSerifDisplay(
          fontSize: 24,
          fontWeight: FontWeight.w400,
          color: forest,
        ),
        titleLarge: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: forest,
        ),
        titleMedium: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: forest,
        ),
        bodyLarge: textTheme.bodyLarge?.copyWith(
          color: ink,
          fontWeight: FontWeight.w500,
        ),
        bodyMedium: textTheme.bodyMedium?.copyWith(
          color: ink.withValues(alpha: 0.78),
          height: 1.4,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: forest,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          side: BorderSide(color: forest.withValues(alpha: 0.16)),
          foregroundColor: forest,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      iconTheme: const IconThemeData(color: forest),
    );
  }
}
