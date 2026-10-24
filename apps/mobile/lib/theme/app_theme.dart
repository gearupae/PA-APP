import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Warm, premium palette: soft paper background, warm-charcoal ink, a single
/// red accent for voice, and a calm blue bottom bar. Tuned for a quiet,
/// high-end feel that's easy to stay in.
class AppColors {
  static const seed = Color(0xFF3B3D44);
  static const bg = Color(0xFFF2F2F0); // soft neutral light
  static const surface = Colors.white;
  static const ink = Color(0xFF17181C); // cool near-black (headers, text)
  static const inkSoft = Color(0xFF2B2D34); // for gradients
  static const red = Color(0xFFD2473D); // voice / record only

  // Dark graphite menu bar — the one strong surface, no colour.
  static const navBg = Color(0xFF1E1F24);
  static const navPill = Color(0xFF34363E);
  static const tag = Color(0xFFECECEA); // neutral grey pill
  static const line = Color(0xFFE6E6E3); // hairline borders

  static const slate = Color(0xFF6E7078); // neutral muted text
  static const income = Color(0xFF2E9E73);
  static const expense = Color(0xFFD2473D);
  static const violet = Color(0xFF6E63C6);
  static const teal = Color(0xFF2E9393);
  static const amber = Color(0xFFC2891A);

  // Chart categories keep colour (needed to tell series apart), but muted.
  static const categoryColors = <String, Color>{
    'Food': Color(0xFFD9733F),
    'Fuel': Color(0xFF4169C9),
    'Bills': Color(0xFF6E55D6),
    'Shopping': Color(0xFFC24E86),
    'Groceries': Color(0xFF2E9E73),
    'Transport': Color(0xFF2E9393),
    'Entertainment': Color(0xFFC2891A),
    'Health': Color(0xFFCF5450),
    'Transfers': Color(0xFF7A8290),
    'Other': Color(0xFFA3A199),
  };

  static Color forCategory(String c) =>
      categoryColors[c] ?? categoryColors['Other']!;

  static const actionGradient =
      LinearGradient(colors: [Color(0xFF1E1F24), Color(0xFF34363E)]);
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

    final text = base.textTheme.copyWith(
      headlineMedium: const TextStyle(
          fontWeight: FontWeight.w800, letterSpacing: -0.5, color: AppColors.ink),
      titleLarge: const TextStyle(
          fontWeight: FontWeight.w700, letterSpacing: -0.3, color: AppColors.ink),
      titleMedium: const TextStyle(
          fontWeight: FontWeight.w700, color: AppColors.ink),
      bodyMedium: const TextStyle(color: AppColors.ink, height: 1.4),
      bodySmall: const TextStyle(color: AppColors.slate),
    );

    return base.copyWith(
      textTheme: text,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.ink,
        surfaceTintColor: AppColors.ink,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 25,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 6,
        shadowColor: Colors.black.withValues(alpha: 0.10),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        margin: EdgeInsets.zero,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.navBg,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.navPill,
        elevation: 0,
        height: 74,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? Colors.white
                : const Color(0xFF9A9CA3),
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 26,
            color: states.contains(WidgetState.selected)
                ? Colors.white
                : const Color(0xFF9A9CA3),
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
        selectedColor: AppColors.ink,
        side: BorderSide.none,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  static const radius = 24.0;
  static const pagePad = EdgeInsets.fromLTRB(16, 18, 16, 24);

  /// Soft shadow for raised white cards.
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ];
}
