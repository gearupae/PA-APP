import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Calm, airy "soft-UI" palette: near-white canvas, large rounded white cards,
/// one subtle sage-green accent, muted coral reserved for recording. Tuned for
/// a low-stress, high-end finance feel.
class AppColors {
  static const seed = Color(0xFF5F8575); // sage — drives M3 widgets
  static const bg = Color(0xFFF6F7F4); // near-white canvas
  static const surface = Colors.white;
  static const ink = Color(0xFF1F2328); // soft near-black
  static const inkSoft = Color(0xFF2E343A);

  static const accent = Color(0xFF5F8575); // sage (single accent)
  static const accentSoft = Color(0xFFE8EFEA); // sage tint surface
  static const red = Color(0xFFCC6B5A); // muted coral — record only

  static const navBg = Colors.white;
  static const navPill = Color(0xFFE8EFEA);
  static const tag = Color(0xFFEDEFEB);
  static const line = Color(0xFFEAECE7);

  static const slate = Color(0xFF727B7A);
  static const income = Color(0xFF5F8575);
  static const expense = Color(0xFFCC6B5A);
  static const violet = Color(0xFF6E63C6);
  static const teal = Color(0xFF2E9393);
  static const amber = Color(0xFFBF8A2E);

  // Chart categories keep colour (needed to separate series), gently muted.
  static const categoryColors = <String, Color>{
    'Food': Color(0xFFD08A4F),
    'Fuel': Color(0xFF5A7FC2),
    'Bills': Color(0xFF8A7BC8),
    'Shopping': Color(0xFFC77BA0),
    'Groceries': Color(0xFF5F8575),
    'Transport': Color(0xFF4E9A9A),
    'Entertainment': Color(0xFFC2993E),
    'Health': Color(0xFFCE7369),
    'Transfers': Color(0xFF8A9199),
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
      // Airy light header — part of the canvas, dark status icons.
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bg,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
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
        elevation: 7,
        shadowColor: Colors.black.withValues(alpha: 0.07),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        margin: EdgeInsets.zero,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.navBg,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.navPill,
        elevation: 10,
        shadowColor: Colors.black.withValues(alpha: 0.06),
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
          backgroundColor: AppColors.ink,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: AppColors.tag,
        selectedColor: AppColors.accent,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  static const radius = 28.0;
  static const pagePad = EdgeInsets.fromLTRB(16, 8, 16, 24);

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];
}
