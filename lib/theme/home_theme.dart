import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Lime-style theme for the home/dashboard (reference design).
class HomeTheme {
  HomeTheme._();

  // ─── Colors (whitish theme, lime/green accent) ───────────────────────────
  static const Color limeBase = Color(0xFFF7F8FA);
  static const Color lime = Color(0xFF84CC16);
  static const Color limeDark = Color(0xFF65A30D);
  static const Color limeTextHigh = Color(0xFF0D0F12);
  static const Color limeTextMid = Color(0xFF6B7280);
  static const Color limeTextLow = Color(0xFF9CA3AF);
  static const Color limeSurface = Color(0xFFFFFFFF);
  static const Color limeInput = Color(0xFFF2F4F8);
  static const Color limeBorderFaint = Color(0xFFE2E8F0);
  static const Color limeBorderSubtle = Color(0xFFCBD5E1);
  static const Color limeTint = Color(0xFFECFDF5);
  static const Color limeSuccess = Color(0xFF22C55E);
  static const Color limeSuccessTint = Color(0xFFDCFCE7);
  static const Color limeDanger = Color(0xFFEF4444);
  static const Color limeDangerTint = Color(0xFFFEE2E2);
  static const Color limeWarning = Color(0xFFF59E0B);
  static const Color limeTextOnLime = Color(0xFF0D0F12);

  /// Whitish background for info cards.
  static const Color cardLight = Color(0xFFF2F4F8);
  static const Color cardLightTextHigh = Color(0xFF1E293B);
  static const Color cardLightTextMid = Color(0xFF475569);
  static const Color cardLightBorder = Color(0xFFE2E8F0);

  static const List<Color> limeCardGradient = [
    Color(0xFFF8FAFC),
    Color(0xFFF1F5F9),
  ];
  static const List<Color> limePrimaryGradient = [
    Color(0xFFA3E635),
    Color(0xFF84CC16),
  ];

  // ─── Sizes ─────────────────────────────────────────────────────────────────
  static const double lg = 20;
  static const double md = 14;
  static const double sm = 8;
  static const double cardRadius = 16;

  // ─── Mono number style ─────────────────────────────────────────────────────
  static TextStyle monoNumber({
    double fontSize = 14,
    FontWeight weight = FontWeight.w600,
  }) {
    return GoogleFonts.spaceMono(
      fontSize: fontSize,
      fontWeight: weight,
      letterSpacing: -0.3,
    );
  }
}
