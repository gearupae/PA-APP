import 'package:flutter/material.dart';

/// Calm, light, modern palette tuned to feel friendly and keep people in-app.
class AppColors {
  static const seed = Color(0xFF4C6FFF); // soft indigo-blue
  static const bg = Color(0xFFF6F7FB);
  static const surface = Colors.white;

  // Category / accent colors (used for charts and tags).
  static const income = Color(0xFF2BB673);
  static const expense = Color(0xFFFF6B6B);
  static const violet = Color(0xFF7C5CFC);
  static const teal = Color(0xFF17BEBB);
  static const amber = Color(0xFFFFB020);
  static const pink = Color(0xFFFF6FB5);
  static const slate = Color(0xFF64748B);

  static const categoryColors = <String, Color>{
    'Food': Color(0xFFFF8A4C),
    'Fuel': Color(0xFF4C6FFF),
    'Bills': Color(0xFF7C5CFC),
    'Shopping': Color(0xFFFF6FB5),
    'Groceries': Color(0xFF2BB673),
    'Transport': Color(0xFF17BEBB),
    'Entertainment': Color(0xFFFFB020),
    'Health': Color(0xFFEF476F),
    'Transfers': Color(0xFF64748B),
    'Other': Color(0xFF94A3B8),
  };

  static Color forCategory(String c) =>
      categoryColors[c] ?? categoryColors['Other']!;
}

class AppTheme {
  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.seed,
      brightness: Brightness.light,
    ).copyWith(surface: AppColors.surface);

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.bg,
      fontFamily: 'Roboto',
    );

    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Color(0xFF1A1D29),
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(color: Color(0xFF1A1D29)),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        margin: EdgeInsets.zero,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.seed.withValues(alpha: 0.14),
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? AppColors.seed
                : AppColors.slate,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? AppColors.seed
                : AppColors.slate,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
    );
  }

  static const radius = 20.0;
  static const pagePad = EdgeInsets.fromLTRB(16, 8, 16, 24);
}
