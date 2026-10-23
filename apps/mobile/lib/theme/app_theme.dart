import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Warm, premium palette matching the reference: cream background,
/// near-black headers / highlight cards, white cards, a red voice button,
/// and a soft blue bottom navigation.
class AppColors {
  static const seed = Color(0xFF2E6FB7); // calm blue accent
  static const bg = Color(0xFFF4EFE8); // cream
  static const surface = Colors.white;
  static const ink = Color(0xFF111111); // headers, highlight cards, text
  static const red = Color(0xFFD23B3B); // voice / record button

  static const navBg = Color(0xFFDCE6EC); // bottom nav background
  static const navPill = Color(0xFFBBD7EC); // selected pill
  static const tag = Color(0xFFE9E5DE); // grey pill tags

  static const slate = Color(0xFF6B7280); // muted text
  static const income = Color(0xFF2BB673);
  static const expense = Color(0xFFD23B3B);
  static const violet = Color(0xFF7C5CFC);
  static const teal = Color(0xFF17887F);
  static const amber = Color(0xFFE08A00);

  static const categoryColors = <String, Color>{
    'Food': Color(0xFFE2703A),
    'Fuel': Color(0xFF2E6FB7),
    'Bills': Color(0xFF7C5CFC),
    'Shopping': Color(0xFFD1569B),
    'Groceries': Color(0xFF2BB673),
    'Transport': Color(0xFF17887F),
    'Entertainment': Color(0xFFE08A00),
    'Health': Color(0xFFD23B3B),
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
        backgroundColor: AppColors.ink,
        surfaceTintColor: AppColors.ink,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 26,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: 0.06),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        margin: EdgeInsets.zero,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.navBg,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.navPill,
        elevation: 0,
        height: 72,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            color: AppColors.ink,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? AppColors.ink
                : const Color(0xFF55606B),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.ink,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: AppColors.tag,
        selectedColor: AppColors.ink,
        side: BorderSide.none,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  static const radius = 22.0;
  static const pagePad = EdgeInsets.fromLTRB(16, 16, 16, 24);
}
