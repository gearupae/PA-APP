import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Light, airy palette in the reference style — black header, white cards,
/// grey pill tags, a soft pastel bottom bar and a red voice button — but in a
/// fresh soft-lilac/violet colour family instead of blue.
class AppColors {
  // Matched to the reference screenshots: warm off-white, black header/hero,
  // white cards, grey pill tags, soft-blue bottom bar, red mic.
  static const seed = Color(0xFF3E6FB0); // reference blue — drives M3 widgets
  static const bg = Color(0xFFF4F1EC); // warm off-white canvas
  static const surface = Colors.white;
  static const surfaceAlt = Color(0xFFEFEBE4); // tiles, inputs, chips, ring
  static const ink = Color(0xFF141414); // black header, hero, text, buttons
  static const inkSoft = Color(0xFF262626);

  static const accent = Color(0xFF3E6FB0); // reference blue (single accent)
  static const accentSoft = Color(0xFFDCE4EC); // reference blue tint
  static const red = Color(0xFFC0392B); // brick red mic / record (reference)

  static const navBg = Color(0xFFDCE4EC); // soft blue bottom bar (reference)
  static const navPill = Color(0xFFBDD7EC); // blue selected pill (reference)
  static const tag = Color(0xFFE8E6E2); // grey pill tags (reference)
  static const line = Color(0xFFEBE7E0); // light hairline

  // Only the reference palette: black, greys, soft blue, brick red.
  static const slate = Color(0xFF6E6E76); // muted text
  static const income = Color(0xFF3E6FB0); // blue (positive)
  static const expense = Color(0xFFC0392B); // red
  static const violet = Color(0xFF3E6FB0); // remapped -> blue
  static const teal = Color(0xFF5B6B78); // remapped -> slate
  static const amber = Color(0xFFC0392B); // remapped -> red (highlight)

  // Spending categories as a blue ramp + red + greys (reference palette).
  static const categoryColors = <String, Color>{
    'Food': Color(0xFFC0392B),
    'Fuel': Color(0xFF3E6FB0),
    'Bills': Color(0xFF27496D),
    'Shopping': Color(0xFF6E89B8),
    'Groceries': Color(0xFF5B6B78),
    'Transport': Color(0xFF93A6C2),
    'Entertainment': Color(0xFFA7B4C6),
    'Health': Color(0xFF8A3028),
    'Transfers': Color(0xFF9199A6),
    'Other': Color(0xFFB8BEC6),
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
                : const Color(0xFF5B6B78),
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 26,
            color: states.contains(WidgetState.selected)
                ? AppColors.ink
                : const Color(0xFF5B6B78),
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
