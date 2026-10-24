import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Light, airy palette in the reference style — black header, white cards,
/// grey pill tags, a soft pastel bottom bar and a red voice button — but in a
/// fresh soft-lilac/violet colour family instead of blue.
class AppColors {
  static const seed = Color(0xFF2E9D94); // calm teal — drives M3 widgets
  static const bg = Color(0xFFF2F5F4); // cool off-white canvas
  static const surface = Colors.white;
  static const surfaceAlt = Color(0xFFEDF1F0); // tiles, inputs, chips, ring
  static const ink = Color(0xFF17201F); // header, hero, text, buttons
  static const inkSoft = Color(0xFF2A3331);

  static const accent = Color(0xFF2E9D94); // calm teal (single accent)
  static const accentSoft = Color(0xFFE2F0EE); // teal tint surface
  static const red = Color(0xFFD2473D); // voice / record

  static const navBg = Color(0xFFDBEDEA); // soft teal bottom bar
  static const navPill = Color(0xFFBFE2DC); // teal selected pill
  static const tag = Color(0xFFECEAE6); // warm grey pill tags
  static const line = Color(0xFFECE9E4); // light hairline

  static const slate = Color(0xFF6E6E76); // muted text
  static const income = Color(0xFF2E9E73);
  static const expense = Color(0xFFD2473D);
  static const violet = Color(0xFF6E5FC6);
  static const teal = Color(0xFF2E9393);
  static const amber = Color(0xFFBF8A2E);

  static const categoryColors = <String, Color>{
    'Food': Color(0xFFD9733F),
    'Fuel': Color(0xFF5A7FC2),
    'Bills': Color(0xFF6E5FC6),
    'Shopping': Color(0xFFC24E86),
    'Groceries': Color(0xFF2E9E73),
    'Transport': Color(0xFF2E9393),
    'Entertainment': Color(0xFFBF8A2E),
    'Health': Color(0xFFCF5450),
    'Transfers': Color(0xFF8A8A92),
    'Other': Color(0xFFABABA2),
  };

  static Color forCategory(String c) =>
      categoryColors[c] ?? categoryColors['Other']!;
}

class AppTheme {
  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.seed,
      brightness: Brightness.light,
    ).copyWith(surface: AppColors.surface, primary: AppColors.accent);

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.bg,
      fontFamily: 'Roboto',
    );

    final text = base.textTheme.copyWith(
      headlineMedium: const TextStyle(
          fontWeight: FontWeight.w800, letterSpacing: -0.6, color: AppColors.ink),
      titleLarge: const TextStyle(
          fontWeight: FontWeight.w700, letterSpacing: -0.3, color: AppColors.ink),
      titleMedium:
          const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink),
      bodyMedium: const TextStyle(color: AppColors.ink, height: 1.4),
      bodySmall: const TextStyle(color: AppColors.slate),
    );

    return base.copyWith(
      textTheme: text,
      // Black header, like the reference.
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.ink,
        surfaceTintColor: AppColors.ink,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 27,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 6,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(26),
        ),
        margin: EdgeInsets.zero,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.navBg,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.navPill,
        elevation: 0,
        height: 76,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? AppColors.ink
                : const Color(0xFF5E6F6C),
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 26,
            color: states.contains(WidgetState.selected)
                ? AppColors.ink
                : const Color(0xFF5E6F6C),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.ink,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: AppColors.surfaceAlt,
        selectedColor: AppColors.accent,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  static const radius = 26.0;
  static const pagePad = EdgeInsets.fromLTRB(16, 8, 16, 24);

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.07),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];
}
