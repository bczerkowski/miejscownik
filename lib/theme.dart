import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Paleta i motyw aplikacji – minimalistyczny, ciepły, content-first.
class AppColors {
  static const seed = Color(0xFF12715E); // głęboka zieleń podróżnicza
  static const accent = Color(0xFFE8743B); // ciepły koral (akcent)
  static const bg = Color(0xFFF7F5F1); // ciepła biel
  static const surface = Color(0xFFFFFFFF);
  static const ink = Color(0xFF1C2421); // prawie-czarny zielonkawy
  static const muted = Color(0xFF6B736F);
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.seed,
    primary: AppColors.seed,
    secondary: AppColors.accent,
    surface: AppColors.surface,
    brightness: Brightness.light,
  );

  final textTheme = GoogleFonts.interTextTheme().copyWith(
    displaySmall: GoogleFonts.plusJakartaSans(
        fontWeight: FontWeight.w800, color: AppColors.ink, letterSpacing: -0.5),
    headlineMedium: GoogleFonts.plusJakartaSans(
        fontWeight: FontWeight.w800, color: AppColors.ink, letterSpacing: -0.5),
    headlineSmall: GoogleFonts.plusJakartaSans(
        fontWeight: FontWeight.w700, color: AppColors.ink, letterSpacing: -0.3),
    titleLarge: GoogleFonts.plusJakartaSans(
        fontWeight: FontWeight.w700, color: AppColors.ink),
    titleMedium: GoogleFonts.plusJakartaSans(
        fontWeight: FontWeight.w600, color: AppColors.ink),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.bg,
    textTheme: textTheme.apply(
      bodyColor: AppColors.ink,
      displayColor: AppColors.ink,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bg,
      foregroundColor: AppColors.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.surface,
      side: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
      labelStyle: GoogleFonts.inter(
          fontWeight: FontWeight.w600, color: AppColors.ink, fontSize: 13),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.seed, width: 1.6),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.seed,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        textStyle:
            GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 15),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
  );
}

/// Miękki cień pod kartami.
List<BoxShadow> get softShadow => [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.08),
        blurRadius: 24,
        offset: const Offset(0, 10),
      ),
    ];
