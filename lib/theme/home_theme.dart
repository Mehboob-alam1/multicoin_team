import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'solana.dart';

class HomeTheme {
  HomeTheme._();

  static const Color limeBase = Solana.bg;
  static const Color lime = Solana.green;
  static const Color limeDark = Solana.purple;
  static const Color limeTextHigh = Solana.textHi;
  static const Color limeTextMid = Solana.textMid;
  static const Color limeTextLow = Solana.textLow;
  static const Color limeSurface = Solana.surfaceRaised;
  static const Color limeInput = Solana.input;
  static const Color limeBorderFaint = Solana.border;
  static const Color limeBorderSubtle = Solana.borderStrong;
  static const Color limeTint = Color(0xFF16121F);
  static const Color limeSuccess = Solana.green;
  static const Color limeSuccessTint = Color(0x2214F195);
  static const Color limeDanger = Solana.danger;
  static const Color limeDangerTint = Solana.dangerBg;
  static const Color limeWarning = Solana.purple;
  static const Color limeTextOnLime = Color(0xFF052E1C);

  static const Color cardLight = Solana.surfaceRaised;
  static const Color cardLightTextHigh = Solana.textHi;
  static const Color cardLightTextMid = Solana.textMid;
  static const Color cardLightBorder = Solana.border;

  static const List<Color> limeCardGradient = [
    Color(0xFF16121F),
    Color(0xFF0C1210),
  ];
  static const List<Color> limePrimaryGradient = [
    Solana.purple,
    Solana.green,
  ];

  static const double lg = 20;
  static const double md = 14;
  static const double sm = 8;
  static const double cardRadius = 24;

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
