import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/app_theme.dart';
import '../services/auth_service.dart';

// ─── Design tokens ────────────────────────────────────────────────────────────
class _D {
  static const bg       = Color(0xFF080B12);
  static const card     = Color(0xFF121826);
  static const cardBord = Color(0xFF1E2A3A);
  static const gold     = Color(0xFFF5A623);
  static const goldDark = Color(0xFFE08800);
  static const electric = Color(0xFF00D4FF);
  static const textHi   = Color(0xFFF0F4FF);
  static const textMid  = Color(0xFF8899BB);
  static const textLow  = Color(0xFF3D4F6B);
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  late final AnimationController _orbitCtrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 18),
  )..repeat();

  late final AnimationController _entryCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..forward();

  late final Animation<double> _fadeIn = CurvedAnimation(
    parent: _entryCtrl,
    curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
  );
  late final Animation<double> _slideUp = CurvedAnimation(
    parent: _entryCtrl,
    curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
  );

  bool _googleLoading = false;
  bool _guestLoading  = false;

  @override
  void dispose() {
    _orbitCtrl.dispose();
    _entryCtrl.dispose();
    super.dispose();
  }

  Future<void> _signInGoogle(AuthService auth) async {
    setState(() => _googleLoading = true);
    try {
      await auth.signInWithGoogle();
      if (mounted) Navigator.of(context).pushReplacementNamed('/home');
    } catch (e) {
      if (mounted) _toast('Sign-in failed: $e');
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  Future<void> _signInGuest(AuthService auth) async {
    setState(() => _guestLoading = true);
    try {
      await auth.signInAnonymously();
      if (mounted) Navigator.of(context).pushReplacementNamed('/home');
    } catch (e) {
      if (mounted) _toast('Could not continue as guest: $e');
    } finally {
      if (mounted) setState(() => _guestLoading = false);
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: _D.textHi)),
      backgroundColor: _D.card,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: _D.cardBord),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    return Scaffold(
      backgroundColor: _D.bg,
      body: Stack(
        children: [
          // ── Orbiting particle rings ─────────────────────────────────────
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _orbitCtrl,
              builder: (_, __) => CustomPaint(
                painter: _OrbitPainter(_orbitCtrl.value),
              ),
            ),
          ),

          // ── Ambient blobs ───────────────────────────────────────────────
          Positioned(
            top: -100,
            left: -80,
            child: _Blob(color: _D.gold.withValues(alpha: 0.07), size: 380),
          ),
          Positioned(
            bottom: 0,
            right: -100,
            child: _Blob(color: _D.electric.withValues(alpha: 0.05), size: 300),
          ),

          // ── Main content ────────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: AnimatedBuilder(
                animation: _entryCtrl,
                builder: (_, __) => Opacity(
                  opacity: _fadeIn.value,
                  child: Transform.translate(
                    offset: Offset(0, 40 * (1 - _slideUp.value)),
                    child: Column(
                      children: [
                        const Spacer(flex: 3),

                        // ── Logo ──────────────────────────────────────────
                        _AnimatedLogo(orbit: _orbitCtrl),
                        const SizedBox(height: 28),

                        // ── Headline ──────────────────────────────────────
                        const Text(
                          'CRYPTOMINER',
                          style: TextStyle(
                            color: _D.gold,
                            fontFamily: AppTheme.fontFamily,
                            fontWeight: FontWeight.w900,
                            fontSize: 28,
                            letterSpacing: 5,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Build your mining empire.',
                          style: TextStyle(
                            color: _D.textMid,
                            fontSize: 15,
                            letterSpacing: 0.3,
                          ),
                        ),

                        const Spacer(flex: 3),

                        // ── Buttons ───────────────────────────────────────
                        _GoogleBtn(
                          loading: _googleLoading,
                          disabled: _guestLoading,
                          onTap: () => _signInGoogle(auth),
                        ),
                        const SizedBox(height: 14),
                        _GuestBtn(
                          loading: _guestLoading,
                          disabled: _googleLoading,
                          onTap: () => _signInGuest(auth),
                        ),

                        const SizedBox(height: 32),

                        // ── Fine print ────────────────────────────────────
                        const Text(
                          'By continuing you agree to our Terms & Privacy Policy',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: _D.textLow, fontSize: 11),
                        ),

                        const Spacer(flex: 1),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Animated logo ────────────────────────────────────────────────────────────
class _AnimatedLogo extends StatelessWidget {
  final AnimationController orbit;
  const _AnimatedLogo({required this.orbit});

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: orbit,
    builder: (_, __) {
      final glow = 0.4 + 0.3 * math.sin(orbit.value * math.pi * 2);
      return Stack(
        alignment: Alignment.center,
        children: [
          // Outer glow ring
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _D.gold.withValues(alpha: glow * 0.5),
                  blurRadius: 50 + 20 * glow,
                  spreadRadius: 4,
                ),
              ],
            ),
          ),
          // Outer ring
          Container(
            width: 104,
            height: 104,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(
                transform: GradientRotation(orbit.value * math.pi * 2),
                colors: [
                  _D.gold.withValues(alpha: 0.0),
                  _D.gold.withValues(alpha: 0.5),
                  _D.gold.withValues(alpha: 0.0),
                ],
              ),
              border: Border.all(
                color: _D.gold.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
          ),
          // Icon circle
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                _D.gold.withValues(alpha: 0.25),
                _D.card,
              ]),
              border: Border.all(color: _D.gold.withValues(alpha: 0.4), width: 1.5),
            ),
            child: const Icon(
              Icons.currency_bitcoin,
              color: _D.gold,
              size: 46,
            ),
          ),
        ],
      );
    },
  );
}

// ─── Google sign-in button ────────────────────────────────────────────────────
class _GoogleBtn extends StatefulWidget {
  final bool loading;
  final bool disabled;
  final VoidCallback onTap;
  const _GoogleBtn({required this.loading, required this.disabled, required this.onTap});

  @override
  State<_GoogleBtn> createState() => _GoogleBtnState();
}

class _GoogleBtnState extends State<_GoogleBtn> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final inactive = widget.loading || widget.disabled;
    return GestureDetector(
      onTapDown: inactive ? null : (_) => setState(() => _pressed = true),
      onTapUp: inactive ? null : (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            gradient: inactive
                ? null
                : const LinearGradient(
              colors: [Color(0xFFF5A623), Color(0xFFE08800)],
            ),
            color: inactive ? _D.cardBord : null,
            borderRadius: BorderRadius.circular(14),
            boxShadow: inactive
                ? null
                : [
              BoxShadow(
                color: _D.gold.withValues(alpha: 0.4),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: widget.loading
              ? const Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.black)))
              : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.g_mobiledata_rounded,
                  color: inactive ? _D.textLow : Colors.black,
                  size: 26),
              const SizedBox(width: 10),
              Text(
                'Sign in with Google',
                style: TextStyle(
                  color: inactive ? _D.textLow : Colors.black,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Guest button ─────────────────────────────────────────────────────────────
class _GuestBtn extends StatefulWidget {
  final bool loading;
  final bool disabled;
  final VoidCallback onTap;
  const _GuestBtn({required this.loading, required this.disabled, required this.onTap});

  @override
  State<_GuestBtn> createState() => _GuestBtnState();
}

class _GuestBtnState extends State<_GuestBtn> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final inactive = widget.loading || widget.disabled;
    return GestureDetector(
      onTapDown: inactive ? null : (_) => setState(() => _pressed = true),
      onTapUp: inactive ? null : (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            color: _D.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _D.cardBord, width: 1),
          ),
          child: widget.loading
              ? const Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: _D.textMid)))
              : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_outline_rounded,
                  color: inactive ? _D.textLow : _D.textMid,
                  size: 22),
              const SizedBox(width: 10),
              Text(
                'Continue as guest',
                style: TextStyle(
                  color: inactive ? _D.textLow : _D.textMid,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Orbit painter ────────────────────────────────────────────────────────────
class _OrbitPainter extends CustomPainter {
  final double t;
  const _OrbitPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.38;

    void drawOrbit(double radius, double speed, double dotSize, Color color, int dots) {
      final angle = t * math.pi * 2 * speed;
      // Ring
      canvas.drawCircle(
        Offset(cx, cy),
        radius,
        Paint()
          ..color = color.withValues(alpha: 0.06)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
      // Dots
      for (int i = 0; i < dots; i++) {
        final a = angle + (i / dots) * math.pi * 2;
        final dx = cx + radius * math.cos(a);
        final dy = cy + radius * math.sin(a);
        canvas.drawCircle(
          Offset(dx, dy),
          dotSize,
          Paint()..color = color.withValues(alpha: 0.5),
        );
      }
    }

    drawOrbit(90,  0.4, 2.5, _D.gold,     3);
    drawOrbit(130, 0.25, 2.0, _D.electric, 4);
    drawOrbit(170, 0.15, 1.5, _D.gold,     5);
  }

  @override
  bool shouldRepaint(_OrbitPainter old) => old.t != t;
}

// ─── Ambient blob ─────────────────────────────────────────────────────────────
class _Blob extends StatelessWidget {
  final Color color;
  final double size;
  const _Blob({required this.color, required this.size});

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
      child: const SizedBox.shrink(),
    ),
  );
}