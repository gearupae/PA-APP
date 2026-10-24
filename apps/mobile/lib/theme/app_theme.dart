import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Warm, premium palette: soft paper background, warm-charcoal ink, a single
/// red accent for voice, and a calm blue bottom bar. Tuned for a quiet,
/// high-end feel that's easy to stay in.
class AppColors {
  static const seed = Color(0xFF2E6FB7);
  static const bg = Color(0xFFF4F1EA); // warm paper
  static const surface = Colors.white;
  static const ink = Color(0xFF1A1813); // warm charcoal (headers, text)
  static const inkSoft = Color(0xFF2E2A22); // for gradients
  static const red = Color(0xFFD2473D); // voice / record

  static const navBg = Color(0xFFDEE7ED);
  static const navPill = Color(0xFFC3DCEF);
  static const tag = Color(0xFFEBE5D9); // warm grey pill
  static const line = Color(0xFFE7E1D6); // hairline borders

  static const slate = Color(0xFF807868); // warm muted text
  static const income = Color(0xFF1FA971);
  static const expense = Color(0xFFD2473D);
  static const violet = Color(0xFF7A5AF0);
  static const teal = Color(0xFF0FA3A3);
  static const amber = Color(0xFFD98E00);

  static const categoryColors = <String, Color>{
    'Food': Color(0xFFE8763A),
    'Fuel': Color(0xFF3E6DD6),
    'Bills': Color(0xFF7A5AF0),
    'Shopping': Color(0xFFD14D8E),
    'Groceries': Color(0xFF1FA971),
    'Transport': Color(0xFF0FA3A3),
    'Entertainment': Color(0xFFD98E00),
    'Health': Color(0xFFE0524E),
    'Transfers': Color(0xFF7A8699),
    'Other': Color(0xFFA8A090),
  };

  static Color forCategory(String c) =>
      categoryColors[c] ?? categoryColors['Other']!;

  static const actionGradient =
      LinearGradient(colors: [Color(0xFF211E18), Color(0xFF3A352B)]);
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
            color: AppColors.ink,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 26,
            color: states.contains(WidgetState.selected)
                ? AppColors.ink
                : const Color(0xFF6A6456),
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
