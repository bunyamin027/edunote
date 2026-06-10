import 'package:flutter/material.dart';

/// EduNoteAI Design System — Color Palette
///
/// Eğitim odaklı, profesyonel ve modern renk paleti.
/// Indigo + Teal ağırlıklı, premium his veren tonlar.
class AppColors {
  AppColors._();

  // ─── Primary (Indigo) ─────────────────────────────────
  static const Color primary = Color(0xFF4F46E5);
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color primaryDark = Color(0xFF3730A3);
  static const Color primarySurface = Color(0xFFEEF2FF);

  // ─── Secondary (Teal) ─────────────────────────────────
  static const Color secondary = Color(0xFF0D9488);
  static const Color secondaryLight = Color(0xFF5EEAD4);
  static const Color secondaryDark = Color(0xFF0F766E);
  static const Color secondarySurface = Color(0xFFF0FDFA);

  // ─── Accent (Amber) ──────────────────────────────────
  static const Color accent = Color(0xFFF59E0B);
  static const Color accentLight = Color(0xFFFCD34D);
  static const Color accentDark = Color(0xFFD97706);

  // ─── Semantic ─────────────────────────────────────────
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // ─── Neutral (Light Theme) ────────────────────────────
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color dividerLight = Color(0xFFE2E8F0);
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF475569);
  static const Color textTertiaryLight = Color(0xFF94A3B8);

  // ─── Neutral (Dark Theme) ─────────────────────────────
  static const Color backgroundDark = Color(0xFF0F172A);
  static const Color surfaceDark = Color(0xFF1E293B);
  static const Color cardDark = Color(0xFF1E293B);
  static const Color dividerDark = Color(0xFF334155);
  static const Color textPrimaryDark = Color(0xFFF1F5F9);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color textTertiaryDark = Color(0xFF64748B);

  // ─── Canvas Pen Colors ────────────────────────────────
  static const List<Color> penColors = [
    Color(0xFF0F172A), // Black
    Color(0xFF1E3A5F), // Dark Blue
    Color(0xFF4F46E5), // Indigo (Primary)
    Color(0xFF3B82F6), // Blue
    Color(0xFF0D9488), // Teal
    Color(0xFF10B981), // Green
    Color(0xFFF59E0B), // Amber
    Color(0xFFF97316), // Orange
    Color(0xFFEF4444), // Red
    Color(0xFFEC4899), // Pink
    Color(0xFF8B5CF6), // Purple
    Color(0xFF6B7280), // Gray
  ];

  // ─── Notebook Cover Gradients ─────────────────────────
  static const List<List<Color>> coverGradients = [
    [Color(0xFF667EEA), Color(0xFF764BA2)], // Indigo → Purple
    [Color(0xFF0D9488), Color(0xFF059669)], // Teal → Emerald
    [Color(0xFFF093FB), Color(0xFFF5576C)], // Pink → Rose
    [Color(0xFF4FACFE), Color(0xFF00F2FE)], // Blue → Cyan
    [Color(0xFF43E97B), Color(0xFF38F9D7)], // Green → Mint
    [Color(0xFFFA709A), Color(0xFFFEE140)], // Pink → Yellow
    [Color(0xFFA18CD1), Color(0xFFFBC2EB)], // Lavender → Light Pink
    [Color(0xFF30CFD0), Color(0xFF330867)], // Cyan → Dark Purple
    [Color(0xFFFF9A9E), Color(0xFFFECFEF)], // Salmon → Light Pink
    [Color(0xFF667EEA), Color(0xFF00D2FF)], // Indigo → Sky
    [Color(0xFFFDCB6E), Color(0xFFE17055)], // Gold → Coral
    [Color(0xFF6C5CE7), Color(0xFFA29BFE)], // Purple → Light Purple
  ];
}
