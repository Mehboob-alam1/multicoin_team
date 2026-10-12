import 'package:flutter/material.dart';

/// Official Solana Mining Tycoon mark. Use [size] to match splash, home, login.
class AppBrandLogo extends StatelessWidget {
  const AppBrandLogo({
    super.key,
    this.size = 48,
    this.radius,
    this.hero = false,
    this.plain = false,
    this.circular = false,
  });

  final double size;
  final double? radius;
  final bool hero;
  final bool plain;
  final bool circular;

  static const assetPath = 'assets/branding/app_logo.png';

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      assetPath,
      width: size,
      height: size,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.medium,
      gaplessPlayback: true,
    );
    if (circular) {
      return Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(shape: BoxShape.circle),
        clipBehavior: Clip.antiAlias,
        child: image,
      );
    }
    if (plain) return image;
    final r = radius ?? (hero ? size * 0.22 : size * 0.28);
    return ClipRRect(
      borderRadius: BorderRadius.circular(r),
      child: image,
    );
  }
}
