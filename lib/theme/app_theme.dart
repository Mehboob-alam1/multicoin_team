import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primary = Color(0xFFF59E0B);
  static const Color primaryDark = Color(0xFFD97706);
  static const Color surface = Color(0xFFF7F8FA);
  static const Color surfaceVariant = Color(0xFFF2F4F8);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color btcGold = Color(0xFFF59E0B);

  static const String fontFamily = 'Space Grotesk';

  static const Color textPrimary = Color(0xFF0D0F12);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color border = Color(0xFFE2E8F0);

  static TextTheme get lightTextTheme =>
      GoogleFonts.spaceGroteskTextTheme(ThemeData.light().textTheme);
  /// Alias for light theme (app uses whitish theme everywhere).
  static TextTheme get darkTextTheme => lightTextTheme;

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: GoogleFonts.spaceGrotesk().fontFamily,
      textTheme: GoogleFonts.spaceGroteskTextTheme(
        ThemeData.light().textTheme.copyWith(
          bodyLarge: TextStyle(color: textPrimary),
          bodyMedium: TextStyle(color: textPrimary),
          titleLarge: TextStyle(color: textPrimary),
          titleMedium: TextStyle(color: textPrimary),
        ),
      ),
      colorScheme: ColorScheme.light(
        primary: primary,
        onPrimary: Colors.white,
        surface: surface,
        onSurface: textPrimary,
        surfaceContainerHighest: surfaceVariant,
      ),
      scaffoldBackgroundColor: surface,
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.spaceGrotesk(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),
      cardTheme: CardThemeData(
        color: cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: cardBg,
        selectedItemColor: primary,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
      ),
      dividerColor: border,
    );
  }

  /// Legacy dark theme (kept for reference).
  static ThemeData get dark => light;
}
