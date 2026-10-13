import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import '../theme/solana.dart';

/// Slow-moving purple/green mesh that matches Solana brand art.
class SolanaMeshBackground extends StatefulWidget {
  const SolanaMeshBackground({super.key, this.intensity = 0.22});

  final double intensity;

  @override
  State<SolanaMeshBackground> createState() => _SolanaMeshBackgroundState();
}

class _SolanaMeshBackgroundState extends State<SolanaMeshBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 14),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        final t = _c.value * math.pi * 2;
        return Stack(
          children: [
            const ColoredBox(color: Solana.bg, child: SizedBox.expand()),
            _orb(
              alignment: Alignment(-0.95 + 0.08 * math.sin(t), -1.05 + 0.06 * math.cos(t)),
              color: Solana.purple.withValues(alpha: widget.intensity),
              size: 340,
            ),
            _orb(
              alignment: Alignment(1.05 + 0.06 * math.cos(t * 0.8), 0.95 + 0.08 * math.sin(t * 0.8)),
              color: Solana.green.withValues(alpha: widget.intensity * 0.85),
              size: 320,
            ),
            _orb(
              alignment: Alignment(0.85, -0.7 + 0.05 * math.sin(t * 1.3)),
              color: Solana.purple.withValues(alpha: widget.intensity * 0.35),
              size: 180,
            ),
          ],
        );
      },
    );
  }

  Widget _orb({required Alignment alignment, required Color color, required double size}) {
    return Align(
      alignment: alignment,
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 64, sigmaY: 64),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
      ),
    );
  }
}

class SolanaGradientText extends StatelessWidget {
  const SolanaGradientText(
      this.text, {
        super.key,
        this.style,
        this.textAlign,
      });

  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (rect) => Solana.brandH.createShader(rect),
      child: Text(
        text,
        textAlign: textAlign,
        style: (style ?? const TextStyle()).copyWith(color: Colors.white),
      ),
    );
  }
}

class SolanaMark extends StatelessWidget {
  const SolanaMark({
    super.key,
    this.size = 88,
    this.icon = Icons.hexagon_rounded,
    this.pulse = 0,
  });

  final double size;
  final IconData icon;
  final double pulse;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: Solana.brand,
        boxShadow: [
          BoxShadow(
            color: Solana.purple.withValues(alpha: 0.38 + 0.18 * pulse),
            blurRadius: 28 + 12 * pulse,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Solana.green.withValues(alpha: 0.22 + 0.1 * pulse),
            blurRadius: 24 + 10 * pulse,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: size * 0.48),
    );
  }
}

/// 1px official gradient frame around a dark card.
class SolanaGlassCard extends StatelessWidget {
  const SolanaGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.radius = Solana.radiusLg,
    this.glow = false,
  });

  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: glow
            ? Solana.dualGlow()
            : [
                BoxShadow(
                  color: Solana.purple.withValues(alpha: 0.10),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Stack(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Solana.glassTop, Solana.glassBot],
                ),
                borderRadius: BorderRadius.circular(radius),
                border: Border.all(color: Solana.hairline, width: 0.8),
              ),
              child: Padding(padding: padding, child: child),
            ),
            const Positioned(
              top: 0,
              left: 18,
              right: 18,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0x00FFFFFF),
                        Color(0x38FFFFFF),
                        Color(0x00FFFFFF),
                      ],
                    ),
                  ),
                  child: SizedBox(height: 1),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SolanaGradientButton extends StatefulWidget {
  const SolanaGradientButton({
    super.key,
    required this.label,
    required this.onTap,
    this.loading = false,
    this.enabled = true,
    this.icon,
    this.height = 54,
  });

  final String label;
  final VoidCallback onTap;
  final bool loading;
  final bool enabled;
  final IconData? icon;
  final double height;

  @override
  State<SolanaGradientButton> createState() => _SolanaGradientButtonState();
}

class _SolanaGradientButtonState extends State<SolanaGradientButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.enabled && !widget.loading;
    return GestureDetector(
      onTapDown: active ? (_) => setState(() => _pressed = true) : null,
      onTapUp: active
          ? (_) {
        setState(() => _pressed = false);
        HapticFeedback.lightImpact();
        widget.onTap();
      }
          : null,
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.975 : 1,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 160),
          opacity: widget.enabled ? 1 : 0.45,
          child: Container(
            width: double.infinity,
            height: widget.height,
            decoration: BoxDecoration(
              gradient: Solana.brandH,
              borderRadius: BorderRadius.circular(Solana.radiusMd),
              boxShadow: active ? Solana.dualGlow() : null,
            ),
            child: widget.loading
                ? const Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
              ),
            )
                : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, color: Colors.white, size: 22),
                  const SizedBox(width: 10),
                ],
                Text(
                  widget.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    letterSpacing: 0.2,
                    fontFamily: AppTheme.fontFamily,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SolanaOutlineButton extends StatefulWidget {
  const SolanaOutlineButton({
    super.key,
    required this.label,
    required this.onTap,
    this.loading = false,
    this.enabled = true,
    this.icon,
    this.height = 54,
  });

  final String label;
  final VoidCallback onTap;
  final bool loading;
  final bool enabled;
  final IconData? icon;
  final double height;

  @override
  State<SolanaOutlineButton> createState() => _SolanaOutlineButtonState();
}

class _SolanaOutlineButtonState extends State<SolanaOutlineButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.enabled && !widget.loading;
    return GestureDetector(
      onTapDown: active ? (_) => setState(() => _pressed = true) : null,
      onTapUp: active
          ? (_) {
        setState(() => _pressed = false);
        widget.onTap();
      }
          : null,
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.975 : 1,
        duration: const Duration(milliseconds: 110),
        child: Container(
          width: double.infinity,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Solana.radiusMd),
            gradient: Solana.brand,
          ),
          padding: const EdgeInsets.all(1.1),
          child: Container(
            decoration: BoxDecoration(
              color: Solana.surface,
              borderRadius: BorderRadius.circular(Solana.radiusMd - 1),
            ),
            child: widget.loading
                ? const Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.4, color: Solana.green),
              ),
            )
                : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, color: Solana.textMid, size: 20),
                  const SizedBox(width: 10),
                ],
                Text(
                  widget.label,
                  style: TextStyle(
                    color: active ? Solana.textHi : Solana.textLow,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    fontFamily: AppTheme.fontFamily,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SolanaShimmerBar extends StatefulWidget {
  const SolanaShimmerBar({super.key, this.width = 140});
  final double width;

  @override
  State<SolanaShimmerBar> createState() => _SolanaShimmerBarState();
}

class _SolanaShimmerBarState extends State<SolanaShimmerBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: SizedBox(
            width: widget.width,
            height: 3,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment(-1.5 + 3 * _c.value, 0),
                  end: Alignment(-0.5 + 3 * _c.value, 0),
                  colors: const [
                    Color(0x229945FF),
                    Solana.purple,
                    Solana.green,
                    Color(0x2214F195),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
