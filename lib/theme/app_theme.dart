import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Dark Palette ───────────────────────────────────────────────
  static const Color background = Color(0xFF0F1115);
  static const Color surface = Color(0xFF1A1D21);
  static const Color surfaceHigh = Color(0xFF22262C);
  static const Color accent = Color(0xFF4A6BF3);
  static const Color success = Color(0xFF22C55E);
  static const Color danger = Color(0xFFEF4444);
  static const Color amber = Color(0xFFF59E0B);

  static const Color textPrimary = Color(0xFFF0F2F5);
  static const Color textSecondary = Color(0xFF8B9099);
  static const Color textMuted = Color(0xFF4A4F5A);
  static const Color border = Color(0xFF252930);

  // ── Light Palette ──────────────────────────────────────────────
  static const Color lightBackground = Color(0xFFF5F6FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceHigh = Color(0xFFEEF0F6);
  static const Color lightBorder = Color(0xFFE2E5EE);

  static const Color lightTextPrimary = Color(0xFF0F1115);
  static const Color lightTextSecondary = Color(0xFF6B7280);
  static const Color lightTextMuted = Color(0xFFB0B7C3);

  // ── Operator Colors ───────────────────────────────────────────
  static const Color opAdd = Color(0xFF4A6BF3);
  static const Color opSub = Color(0xFFEC4899);
  static const Color opMul = Color(0xFFF59E0B);
  static const Color opDiv = Color(0xFF10B981);
  static const Color opSq = Color(0xFF8B5CF6);
  static const Color opExp = Color(0xFFEF4444);
  static const Color opRoot = Color(0xFF06B6D4);

  // ── Font Helpers ──────────────────────────────────────────────
  static TextStyle geist({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    Color color = textPrimary,
    double letterSpacing = 0,
    double height = 1.4,
  }) {
    return GoogleFonts.dmSans(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  static TextStyle mono({
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.w700,
    Color color = textPrimary,
    double letterSpacing = 0,
  }) {
    return GoogleFonts.spaceMono(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
    );
  }

  // ── Dark Theme ─────────────────────────────────────────────────
  static ThemeData get darkTheme {
    final base = ThemeData.dark();
    return base.copyWith(
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        surface: surface,
        primary: accent,
        secondary: amber,
        error: danger,
        onSurface: textPrimary,
      ),
      textTheme: GoogleFonts.dmSansTextTheme(base.textTheme).apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: textPrimary),
        titleTextStyle: GoogleFonts.dmSans(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: -0.3,
        ),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: background,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: GoogleFonts.dmSans(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(color: border, thickness: 1),
      dialogBackgroundColor: surface,
    );
  }

  // ── Light Theme ────────────────────────────────────────────────
  static ThemeData get lightTheme {
    final base = ThemeData.light();
    return base.copyWith(
      scaffoldBackgroundColor: lightBackground,
      colorScheme: const ColorScheme.light(
        surface: lightSurface,
        primary: accent,
        secondary: amber,
        error: danger,
        onSurface: lightTextPrimary,
      ),
      textTheme: GoogleFonts.dmSansTextTheme(base.textTheme).apply(
        bodyColor: lightTextPrimary,
        displayColor: lightTextPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: lightBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: lightTextPrimary),
        titleTextStyle: GoogleFonts.dmSans(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: lightTextPrimary,
          letterSpacing: -0.3,
        ),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: lightBackground,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: GoogleFonts.dmSans(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(color: lightBorder, thickness: 1),
      dialogBackgroundColor: lightSurface,
    );
  }
}
