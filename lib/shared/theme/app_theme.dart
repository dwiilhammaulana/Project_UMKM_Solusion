import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color midnight = Color(0xFF0F2D33);
  static const Color deepTeal = Color(0xFF18464E);
  static const Color teal = Color(0xFF2E7B83);
  static const Color mint = Color(0xFF78D4CA);
  static const Color foam = Color(0xFFDDF6F2);
  static const Color cloud = Color(0xFFF4F7F8);
  static const Color card = Color(0xFFFFFFFF);
  static const Color ink = Color(0xFF132126);
  static const Color subtext = Color(0xFF5F7176);
  static const Color success = Color(0xFF2F9F76);
  static const Color warning = Color(0xFFE2A84A);
  static const Color danger = Color(0xFFD56A6A);
  static const Color info = Color(0xFF5D8CB0);

  static const LinearGradient pageGradient = LinearGradient(
    colors: [Color(0xFFF5F7F8), Color(0xFFE9F3F2), Color(0xFFF7FBFB)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static BoxDecoration frostedDecoration({
    Color? tint,
    double radius = 30,
    Border? border,
  }) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      gradient: LinearGradient(
        colors: [
          (tint ?? Colors.white).withValues(alpha: 0.92),
          Colors.white.withValues(alpha: 0.84),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      border: border ??
          Border.all(
            color: Colors.white.withValues(alpha: 0.58),
          ),
      boxShadow: [
        BoxShadow(
          color: midnight.withValues(alpha: 0.08),
          blurRadius: 34,
          offset: const Offset(0, 18),
        ),
      ],
    );
  }

  static ThemeData get lightTheme {
    final scheme = ColorScheme.fromSeed(
      seedColor: deepTeal,
      brightness: Brightness.light,
    ).copyWith(
      primary: deepTeal,
      secondary: mint,
      surface: card,
      onPrimary: Colors.white,
      onSecondary: midnight,
      onSurface: ink,
      error: danger,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: cloud,
      canvasColor: Colors.transparent,
      splashFactory: InkSparkle.splashFactory,
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: ink,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.88),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        hintStyle: const TextStyle(color: subtext),
        prefixIconColor: deepTeal,
        suffixIconColor: subtext,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide(color: deepTeal.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(color: deepTeal, width: 1.3),
        ),
      ),
      dividerColor: deepTeal.withValues(alpha: 0.08),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: midnight,
        contentTextStyle: const TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: deepTeal,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: deepTeal,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 0,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: deepTeal,
          minimumSize: const Size.fromHeight(54),
          side: BorderSide(color: deepTeal.withValues(alpha: 0.12)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        backgroundColor: Colors.white.withValues(alpha: 0.82),
        selectedColor: deepTeal,
        secondarySelectedColor: deepTeal,
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        labelStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white.withValues(alpha: 0.95),
        surfaceTintColor: Colors.transparent,
        height: 74,
        indicatorColor: foam,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return TextStyle(
            color: states.contains(WidgetState.selected) ? deepTeal : subtext,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          );
        }),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      tabBarTheme: TabBarThemeData(
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          color: deepTeal,
          borderRadius: BorderRadius.circular(999),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: subtext,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
      iconTheme: const IconThemeData(color: deepTeal),
    );

    final textTheme = GoogleFonts.manropeTextTheme(base.textTheme);
    return base.copyWith(
      textTheme: textTheme.copyWith(
        headlineLarge: GoogleFonts.sora(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: ink,
          height: 1.12,
        ),
        headlineMedium: GoogleFonts.sora(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          color: ink,
          height: 1.14,
        ),
        headlineSmall: GoogleFonts.sora(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: ink,
          height: 1.16,
        ),
        titleLarge: textTheme.titleLarge?.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: ink,
        ),
        titleMedium: textTheme.titleMedium?.copyWith(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: ink,
        ),
        bodyLarge: textTheme.bodyLarge?.copyWith(
          fontSize: 15,
          color: ink,
          fontWeight: FontWeight.w600,
        ),
        bodyMedium: textTheme.bodyMedium?.copyWith(
          fontSize: 13,
          color: subtext,
          height: 1.45,
          fontWeight: FontWeight.w600,
        ),
        bodySmall: textTheme.bodySmall?.copyWith(
          fontSize: 12,
          color: subtext,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
