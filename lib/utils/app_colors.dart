import 'package:flutter/material.dart';

/// App palette. Brand colors stay constant across themes; surface/text colors
/// resolve against [isDark], which `IMKApp` keeps in sync with the active
/// MaterialApp brightness (so 'Sistem' mode works too).
class AppColors {
  /// Set every frame by the root builder from the resolved theme brightness.
  static bool isDark = false;

  // ── Brand (constant in both themes) ──────────────────────
  static const primary = Color(0xFF1A56DB);
  static const chatBg = Color(0xFF1A56DB);
  static const statusBar = Color(0xFF1A56DB);
  static const translateBoxBlue = Color(0xFF1A56DB);
  static const white = Colors.white;

  // ── Theme-dependent ──────────────────────────────────────
  /// Page background (behind cards/lists).
  static Color get scaffoldBg =>
      isDark ? const Color(0xFF0B0F14) : const Color(0xFFF5F5F5);

  /// Card / app-bar / header / input-bar surfaces (was hard-coded white).
  static Color get surface =>
      isDark ? const Color(0xFF161B22) : Colors.white;

  static Color get bottomNavBg => surface;

  static Color get textPrimary =>
      isDark ? const Color(0xFFE5E7EB) : const Color(0xFF111928);

  static Color get textSecondary =>
      isDark ? const Color(0xFF9AA4B2) : const Color(0xFF6B7280);

  static Color get divider =>
      isDark ? const Color(0xFF272D36) : const Color(0xFFE5E7EB);

  static Color get inputBg =>
      isDark ? const Color(0xFF1E242C) : const Color(0xFFF3F4F6);

  static Color get searchBg =>
      isDark ? const Color(0xFF1E242C) : const Color(0xFFF0F2F5);

  static Color get translateBox =>
      isDark ? const Color(0xFF12233A) : const Color(0xFFEBF5FF);
}
