import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/solana.dart';

class UserCircleAvatar extends StatelessWidget {
  const UserCircleAvatar({
    super.key,
    required this.name,
    this.photoUrl,
    this.size = 42,
    this.ring = true,
  });

  final String name;
  final String? photoUrl;
  final double size;
  final bool ring;

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return 'M';
    String firstChar(String s) => s.substring(0, 1).toUpperCase();
    if (parts.length == 1) return firstChar(parts.first);
    return firstChar(parts.first) + firstChar(parts.last);
  }

  @override
  Widget build(BuildContext context) {
    final url = photoUrl?.trim();
    final hasPhoto = url != null && url.isNotEmpty;
    final inner = size - (ring ? 6 : 0);

    Widget face = CircleAvatar(
      radius: inner / 2,
      backgroundColor: const Color(0xFF18181C),
      backgroundImage: hasPhoto ? NetworkImage(url) : null,
      onBackgroundImageError: hasPhoto ? (_, __) {} : null,
      child: hasPhoto
          ? null
          : Text(
              _initials,
              style: GoogleFonts.spaceGrotesk(
                fontSize: inner * 0.36,
                fontWeight: FontWeight.w700,
                color: Solana.green,
              ),
            ),
    );

    if (!ring) return SizedBox(width: size, height: size, child: face);

    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: Solana.brand,
      ),
      alignment: Alignment.center,
      child: Container(
        width: inner,
        height: inner,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFF08080A),
        ),
        clipBehavior: Clip.antiAlias,
        child: face,
      ),
    );
  }
}
