import 'package:flutter/material.dart';

/// Official Solana brand tokens.
/// Colors from https://solana.com/branding
/// Gradient: linear-gradient(135deg, #9945FF 0%, #14F195 100%)
class Solana {
  Solana._();

  static const Color purple = Color(0xFF9945FF);
  static const Color green = Color(0xFF14F195);
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);

  /// Near-black used on solana.com (not purple-tinted gray).
  static const Color bg = Color(0xFF08080A);
  static const Color surface = Color(0xFF111114);
  static const Color surfaceRaised = Color(0xFF18181C);
  static const Color input = Color(0xFF1C1C22);

  static const Color textHi = Color(0xF0FFFFFF);
  static const Color textMid = Color(0xB8FFFFFF);
  static const Color textLow = Color(0x73FFFFFF);

  static const Color border = Color(0x1FFFFFFF);
  static const Color borderStrong = Color(0x33FFFFFF);

  static const Color danger = Color(0xFFFF4D6D);
  static const Color dangerBg = Color(0x22FF4D6D);

  /// Official 135° purple → green.
  static const LinearGradient brand = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [purple, green],
  );

  /// Horizontal brand sweep (buttons, bars).
  static const LinearGradient brandH = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [purple, green],
  );

  /// Soft mesh used behind hero surfaces.
  static const LinearGradient cardWash = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF16121F), Color(0xFF0C1210)],
  );

  static const List<Color> brandColors = [purple, green];

  static const double radiusSm = 12;
  static const double radiusMd = 16;
  static const double radiusLg = 22;
  static const double radiusXl = 28;

  static List<BoxShadow> glow({Color color = purple, double alpha = 0.35}) => [
        BoxShadow(
          color: color.withValues(alpha: alpha),
          blurRadius: 28,
          offset: const Offset(0, 10),
        ),
      ];

  static List<BoxShadow> dualGlow() => [
        BoxShadow(
          color: purple.withValues(alpha: 0.28),
          blurRadius: 24,
          offset: const Offset(-6, 8),
        ),
        BoxShadow(
          color: green.withValues(alpha: 0.18),
          blurRadius: 24,
          offset: const Offset(6, 8),
        ),
      ];
}
