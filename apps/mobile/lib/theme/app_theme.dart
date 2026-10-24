import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Calm, dark "soft-UI" palette: deep near-black canvas, softly raised dark
/// cards, one subtle indigo accent, muted coral reserved for recording.
class AppColors {
  static const seed = Color(0xFF7C8AE0); // soft indigo (bright for dark)
  static const bg = Color(0xFF0F1115); // deep canvas
  static const surface = Color(0xFF181B21); // cards
  static const surfaceAlt = Color(0xFF22262E); // chips, tiles, inputs, panels
  static const ink = Color(0xFFECEDF1); // primary text + icons (light)
  static const inkSoft = Color(0xFFC7CAD2);

  static const accent = Color(0xFF7C8AE0); // soft indigo (single accent)
  static const accentSoft = Color(0xFF242941); // indigo-tinted dark surface
  static const red = Color(0xFFE07A68); // muted coral — record only

  static const navBg = Color(0xFF15181E);
  static const navPill = Color(0xFF2B3150);
  static const tag = Color(0xFF262A32);
  static const line = Color(0xFF2A2E36);

  static const slate = Color(0xFF9A9EA8); // muted light-grey text
  static const income = Color(0xFF5CB894);
  static const expense = Color(0xFFE07A68);
  static const violet = Color(0xFF9B8EE6);
  static const teal = Color(0xFF4FB3B3);
  static const amber = Color(0xFFD9A54A);

  // Chart categories keep colour (needed to separate series), tuned for dark.
  static const categoryColors = <String, Color>{
    'Food': Color(0xFFE59B63),
    'Fuel': Color(0xFF7C8AE0),
    'Bills': Color(0xFF9B8EE6),
    'Shopping': Color(0xFFDE8FB4),
    'Groceries': Color(0xFF5CB894),
    'Transport': Color(0xFF4FB3B3),
    'Entertainment': Color(0xFFD9A54A),
    'Health': Color(0xFFE38578),
    'Transfers': Color(0xFF9199A6),
    'Other': Color(0xFF8A8F99),
  };

  static Color forCategory(String c) =>
      categoryColors[c] ?? categoryColors['Other']!;
}

class AppTheme {
  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.seed,
      brightness: Brightness.dark,
    ).copyWith(
      surface: AppColors.surface,
      primary: AppColors.accent,
      onSurface: AppColors.ink,
    );

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
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bg,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: TextStyle(
          color: AppColors.ink,
          fontSize: 28,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.6,
        ),
        iconTheme: IconThemeData(color: AppColors.ink),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: const BorderSide(color: AppColors.line),
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
                ? AppColors.accent
                : AppColors.slate,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 26,
            color: states.contains(WidgetState.selected)
                ? AppColors.accent
                : AppColors.slate,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.accent,
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
        labelStyle: const TextStyle(color: AppColors.ink),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      switchTheme: base.switchTheme,
    );
  }

  static const radius = 28.0;
  static const pagePad = EdgeInsets.fromLTRB(16, 8, 16, 24);

  static List<BoxShadow> get cardShadow => const [];
}
