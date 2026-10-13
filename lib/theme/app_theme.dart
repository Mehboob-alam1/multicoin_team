import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'solana.dart';

class AppTheme {
  static const Color primary = Solana.purple;
  static const Color primaryDark = Color(0xFF7A2FE0);
  static const Color accent = Solana.green;
  static const Color surface = Solana.bg;
  static const Color surfaceVariant = Solana.surface;
  static const Color cardBg = Solana.surfaceRaised;
  static const Color btcGold = Solana.purple;

  static const String fontFamily = 'Space Grotesk';

  static const Color textPrimary = Solana.textHi;
  static const Color textSecondary = Solana.textMid;
  static const Color border = Solana.border;

  static const double pagePaddingH = 20;
  static const double pagePaddingV = 16;
  static const double sectionSpacing = 20;
  static const double cardSpacing = 12;
  static const double cardRadius = 24;
  static const double bottomNavHeight = 76;
  static const double bannerAdHeight = 50;
  static const ScrollPhysics pageScroll = AlwaysScrollableScrollPhysics();

  static double pageBottomPadding(BuildContext context) =>
      bottomNavHeight +
      bannerAdHeight +
      MediaQuery.of(context).padding.bottom +
      8;
  static EdgeInsets pagePadding(BuildContext context) => EdgeInsets.fromLTRB(
    pagePaddingH,
    pagePaddingV,
    pagePaddingH,
    pageBottomPadding(context),
  );
  static EdgeInsets pagePaddingNoBottom(BuildContext context) =>
      EdgeInsets.fromLTRB(pagePaddingH, pagePaddingV, pagePaddingH, pagePaddingV);

  static TextTheme get lightTextTheme =>
      GoogleFonts.spaceGroteskTextTheme(ThemeData.dark().textTheme);
  static TextTheme get darkTextTheme => lightTextTheme;

  static ThemeData get light {
    final textTheme = GoogleFonts.spaceGroteskTextTheme(
      ThemeData.dark().textTheme.copyWith(
        bodyLarge: const TextStyle(color: textPrimary),
        bodyMedium: const TextStyle(color: textPrimary),
        titleLarge: const TextStyle(color: textPrimary),
        titleMedium: const TextStyle(color: textPrimary),
      ),
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
      fontFamily: GoogleFonts.spaceGrotesk().fontFamily,
      textTheme: textTheme,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        onPrimary: Colors.white,
        secondary: accent,
        onSecondary: Color(0xFF052E1C),
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
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: GoogleFonts.spaceGrotesk(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: textPrimary),
      ),
      cardTheme: CardThemeData(
        color: cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(cardRadius)),
        margin: EdgeInsets.zero,
        shadowColor: Solana.purple.withValues(alpha: 0.12),
        clipBehavior: Clip.antiAlias,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: cardBg,
        selectedItemColor: primary,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
      ),
      dividerColor: border,
      snackBarTheme: SnackBarThemeData(
        backgroundColor: cardBg,
        contentTextStyle: const TextStyle(color: textPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: border),
        ),
      ),
    );
  }

  static ThemeData get dark => light;
}
