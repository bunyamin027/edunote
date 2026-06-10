import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// EduNoteAI Typography System
///
/// NunitoSans (bundled) for UI, Google Fonts fallback.
class AppTypography {
  AppTypography._();

  // ─── Display ──────────────────────────────────────────
  static TextStyle displayLarge = GoogleFonts.nunitoSans(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.25,
    letterSpacing: -0.5,
  );

  static TextStyle displayMedium = GoogleFonts.nunitoSans(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.29,
    letterSpacing: -0.25,
  );

  static TextStyle displaySmall = GoogleFonts.nunitoSans(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.33,
  );

  // ─── Headline ─────────────────────────────────────────
  static TextStyle headlineLarge = GoogleFonts.nunitoSans(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 1.27,
  );

  static TextStyle headlineMedium = GoogleFonts.nunitoSans(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  static TextStyle headlineSmall = GoogleFonts.nunitoSans(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.33,
  );

  // ─── Title ────────────────────────────────────────────
  static TextStyle titleLarge = GoogleFonts.nunitoSans(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.33,
  );

  static TextStyle titleMedium = GoogleFonts.nunitoSans(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.37,
    letterSpacing: 0.15,
  );

  static TextStyle titleSmall = GoogleFonts.nunitoSans(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.43,
    letterSpacing: 0.1,
  );

  // ─── Body ─────────────────────────────────────────────
  static TextStyle bodyLarge = GoogleFonts.nunitoSans(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0.15,
  );

  static TextStyle bodyMedium = GoogleFonts.nunitoSans(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.43,
    letterSpacing: 0.25,
  );

  static TextStyle bodySmall = GoogleFonts.nunitoSans(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.33,
    letterSpacing: 0.4,
  );

  // ─── Label ────────────────────────────────────────────
  static TextStyle labelLarge = GoogleFonts.nunitoSans(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.43,
    letterSpacing: 0.1,
  );

  static TextStyle labelMedium = GoogleFonts.nunitoSans(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.33,
    letterSpacing: 0.5,
  );

  static TextStyle labelSmall = GoogleFonts.nunitoSans(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.45,
    letterSpacing: 0.5,
  );

  /// Creates a complete TextTheme from our typography system.
  static TextTheme get textTheme => TextTheme(
        displayLarge: displayLarge,
        displayMedium: displayMedium,
        displaySmall: displaySmall,
        headlineLarge: headlineLarge,
        headlineMedium: headlineMedium,
        headlineSmall: headlineSmall,
        titleLarge: titleLarge,
        titleMedium: titleMedium,
        titleSmall: titleSmall,
        bodyLarge: bodyLarge,
        bodyMedium: bodyMedium,
        bodySmall: bodySmall,
        labelLarge: labelLarge,
        labelMedium: labelMedium,
        labelSmall: labelSmall,
      );
}
