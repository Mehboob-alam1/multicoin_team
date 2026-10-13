import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'legal_document_screen.dart';
import '../theme/app_theme.dart';
import '../theme/solana.dart';
import '../services/auth_service.dart';
import '../services/referral_service.dart';
import '../widgets/app_brand_logo.dart';
import '../widgets/screen_ad_slot.dart';
import '../widgets/solana_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  late final AnimationController _orbitCtrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 16),
  )..repeat();

  late final AnimationController _entryCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..forward();

  late final Animation<double> _fadeIn = CurvedAnimation(
    parent: _entryCtrl,
    curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
  );

  late final Animation<double> _slideUp = CurvedAnimation(
    parent: _entryCtrl,
    curve: const Interval(0.1, 1.0, curve: Curves.easeOutCubic),
  );

  bool _googleLoading = false;
  bool _guestLoading = false;
  final _referralCtrl = TextEditingController();

  @override
  void dispose() {
    _orbitCtrl.dispose();
    _entryCtrl.dispose();
    _referralCtrl.dispose();
    super.dispose();
  }

  Future<void> _stashReferralCode() async {
    final code = _referralCtrl.text.trim();
    if (code.isEmpty) return;
    await context.read<ReferralService>().queueJoinCode(code);
  }

  Future<void> _signInGoogle(AuthService auth) async {
    setState(() => _googleLoading = true);
    try {
      await _stashReferralCode();
      await auth.signInWithGoogle();
      if (mounted) Navigator.of(context).pushReplacementNamed('/premium-offer');
    } catch (e) {
      if (mounted) _toast('Sign-in failed: $e');
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  Future<void> _signInGuest(AuthService auth) async {
    setState(() => _guestLoading = true);
    try {
      await _stashReferralCode();
      await auth.signInAnonymously();
      if (mounted) Navigator.of(context).pushReplacementNamed('/premium-offer');
    } catch (e) {
      if (mounted) _toast('Could not continue as guest: $e');
    } finally {
      if (mounted) setState(() => _guestLoading = false);
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: GoogleFonts.spaceGrotesk(
            color: const Color(0xFFF4F4F5),
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
        ),
        backgroundColor: const Color(0xFF18181C),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(
            color: Color(0x2DFFFFFF),
            width: 0.8,
          ),
        ),
        margin: const EdgeInsets.all(18),
        elevation: 6,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF08080A),
      body: Stack(
        children: [
          // ── Background mesh ───────────────────────────────────────────────
          const SolanaMeshBackground(intensity: 0.24),

          // ── Animated orbits ────────────────────────────────────────────────
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _orbitCtrl,
              builder: (_, __) => CustomPaint(
                painter: _OrbitPainter(_orbitCtrl.value),
              ),
            ),
          ),

          // ── Ambient blobs ──────────────────────────────────────────────────
          Positioned(
            top: -120,
            right: -60,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF9945FF).withOpacity(0.08),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                child: const SizedBox.shrink(),
              ),
            ),
          ),

          Positioned(
            bottom: -80,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF14F195).withOpacity(0.06),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                child: const SizedBox.shrink(),
              ),
            ),
          ),

          // ── Main content ───────────────────────────────────────────────────
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: AnimatedBuilder(
                animation: _entryCtrl,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: SizedBox(
                      height: size.height - 100,
                      child: Column(
                        children: [
                          const Spacer(flex: 2),

                          // ── Logo ───────────────────────────────────────
                          _AnimatedLogo(orbit: _orbitCtrl),
                          const SizedBox(height: 32),

                          // ── Title ──────────────────────────────────────
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [
                                Color(0xFF9945FF),
                                Color(0xFF14F195),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ).createShader(bounds),
                            child: Text(
                              'Solana Mining Tycoon',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.spaceGrotesk(
                                fontWeight: FontWeight.w800,
                                fontSize: 32,
                                letterSpacing: -0.6,
                                color: Colors.white,
                                height: 1.1,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // ── Subtitle ───────────────────────────────────
                          Text(
                            'Stake SOL. Run validators.\nBuild your empire.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.spaceGrotesk(
                              color: const Color(0xFFA1A1AA),
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              height: 1.5,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const Spacer(flex: 2),

                          // ── Referral input ─────────────────────────────
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF18181C).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0x2DFFFFFF),
                                    width: 0.8,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: TextField(
                                  controller: _referralCtrl,
                                  textCapitalization:
                                  TextCapitalization.characters,
                                  textAlign: TextAlign.center,
                                  cursorColor: const Color(0xFF14F195),
                                  decoration: InputDecoration(
                                    hintText: 'Referral code (optional)',
                                    hintStyle: GoogleFonts.spaceGrotesk(
                                      color: const Color(0xFF71717A),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    filled: false,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                      vertical: 16,
                                    ),
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                  ),
                                  style: GoogleFonts.spaceGrotesk(
                                    color: const Color(0xFFF4F4F5),
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.8,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),

                          // ── Google sign-in button ──────────────────────
                          _GradientButton(
                            label: 'Sign in with Google',
                            icon: Icons.g_mobiledata_rounded,
                            loading: _googleLoading,
                            enabled: !_guestLoading,
                            onTap: () => _signInGoogle(auth),
                          ),
                          const SizedBox(height: 13),

                          // ── Guest button ───────────────────────────────
                          _OutlineButton(
                            label: 'Continue as guest',
                            icon: Icons.person_outline_rounded,
                            loading: _guestLoading,
                            enabled: !_googleLoading,
                            onTap: () => _signInGuest(auth),
                          ),
                          const SizedBox(height: 20),
                          const ScreenAdSlot(title: 'Login offer'),
                          const SizedBox(height: 24),

                          // ── Terms text ─────────────────────────────────
                          Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                'By continuing you agree to our ',
                                style: GoogleFonts.spaceGrotesk(
                                  color: const Color(0xFF71717A),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  height: 1.6,
                                  letterSpacing: -0.15,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => LegalDocumentScreen.openTerms(context),
                                child: Text(
                                  'Terms',
                                  style: GoogleFonts.spaceGrotesk(
                                    color: const Color(0xFF14F195),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    height: 1.6,
                                    decoration: TextDecoration.underline,
                                    decorationColor: const Color(0xFF14F195),
                                  ),
                                ),
                              ),
                              Text(
                                ' & ',
                                style: GoogleFonts.spaceGrotesk(
                                  color: const Color(0xFF71717A),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  height: 1.6,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => LegalDocumentScreen.openPrivacy(context),
                                child: Text(
                                  'Privacy Policy',
                                  style: GoogleFonts.spaceGrotesk(
                                    color: const Color(0xFF14F195),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    height: 1.6,
                                    decoration: TextDecoration.underline,
                                    decorationColor: const Color(0xFF14F195),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Spacer(flex: 1),
                        ],
                      ),
                    ),
                  ),
                ),
                builder: (context, child) {
                  if (_entryCtrl.status == AnimationStatus.completed) {
                    return child!;
                  }
                  return Opacity(
                    opacity: _fadeIn.value,
                    child: Transform.translate(
                      offset: Offset(0, 40 * (1 - _slideUp.value)),
                      child: child,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Animated Logo ────────────────────────────────────────────────────────────
class _AnimatedLogo extends StatelessWidget {
  final AnimationController orbit;

  const _AnimatedLogo({required this.orbit});

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: orbit,
    builder: (_, __) {
      final pulse = 0.45 + 0.55 * (0.5 + 0.5 * math.sin(orbit.value * math.pi * 2));

      return Stack(
        alignment: Alignment.center,
        children: [
          // ── Rotating gradient ring ─────────────────────────────────────
          Transform.rotate(
            angle: orbit.value * math.pi * 2,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(
                  colors: [
                    const Color(0xFF9945FF).withOpacity(0),
                    const Color(0xFF9945FF).withOpacity(0.95),
                    const Color(0xFF14F195).withOpacity(0.95),
                    const Color(0xFF14F195).withOpacity(0),
                  ],
                  stops: const [0, 0.35, 0.65, 1.0],
                ),
              ),
            ),
          ),

          // ── Inner circle (glass effect) ────────────────────────────────
          Transform.scale(
            scale: 0.98 + 0.04 * pulse,
            child: const AppBrandLogo(size: 124, hero: true),
          ),
        ],
      );
    },
  );
}

// ─── Orbit Painter ────────────────────────────────────────────────────────────
class _OrbitPainter extends CustomPainter {
  final double t;

  const _OrbitPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.32;

    void drawOrbit(double radius, double speed, double dotSize, Color color,
        int dots) {
      final angle = t * math.pi * 2 * speed;

      // Draw orbit circle
      canvas.drawCircle(
        Offset(cx, cy),
        radius,
        Paint()
          ..color = color.withOpacity(0.08)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );

      // Draw orbiting dots
      for (int i = 0; i < dots; i++) {
        final a = angle + (i / dots) * math.pi * 2;
        final x = cx + radius * math.cos(a);
        final y = cy + radius * math.sin(a);

        // Glow effect
        canvas.drawCircle(
          Offset(x, y),
          dotSize * 1.8,
          Paint()
            ..color = color.withOpacity(0.15)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );

        // Dot
        canvas.drawCircle(
          Offset(x, y),
          dotSize,
          Paint()..color = color.withOpacity(0.85),
        );
      }
    }

    drawOrbit(110, 0.45, 2.8, const Color(0xFF9945FF), 3);
    drawOrbit(160, 0.28, 2.3, const Color(0xFF14F195), 4);
    drawOrbit(206, 0.16, 1.8, const Color(0xFF9945FF), 5);
  }

  @override
  bool shouldRepaint(_OrbitPainter old) => old.t != t;
}

// ─── Gradient Button ──────────────────────────────────────────────────────────
class _GradientButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool loading;
  final bool enabled;
  final VoidCallback onTap;

  const _GradientButton({
    required this.label,
    required this.icon,
    required this.loading,
    required this.enabled,
    required this.onTap,
  });

  @override
  State<_GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<_GradientButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown: widget.enabled ? (_) => setState(() => _isPressed = true) : null,
    onTapUp: widget.enabled
        ? (_) => setState(() => _isPressed = false)
        : null,
    onTapCancel: widget.enabled
        ? () => setState(() => _isPressed = false)
        : null,
    onTap: widget.enabled && !widget.loading ? widget.onTap : null,
    child: AnimatedScale(
      scale: _isPressed ? 0.96 : 1.0,
      duration: const Duration(milliseconds: 110),
      curve: Curves.easeOutBack,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF9945FF), Color(0xFF14F195)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF9945FF).withOpacity(0.35),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: const Color(0xFF14F195).withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.enabled && !widget.loading ? widget.onTap : null,
              splashColor: Colors.white.withOpacity(0.1),
              highlightColor: Colors.white.withOpacity(0.1),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.loading)
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    )
                  else
                    Icon(
                      widget.icon,
                      color: Colors.white.withOpacity(0.95),
                      size: 20,
                    ),
                  const SizedBox(width: 11),
                  Text(
                    widget.label,
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

// ─── Outline Button ───────────────────────────────────────────────────────────
class _OutlineButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool loading;
  final bool enabled;
  final VoidCallback onTap;

  const _OutlineButton({
    required this.label,
    required this.icon,
    required this.loading,
    required this.enabled,
    required this.onTap,
  });

  @override
  State<_OutlineButton> createState() => _OutlineButtonState();
}

class _OutlineButtonState extends State<_OutlineButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown: widget.enabled ? (_) => setState(() => _isPressed = true) : null,
    onTapUp: widget.enabled
        ? (_) => setState(() => _isPressed = false)
        : null,
    onTapCancel: widget.enabled
        ? () => setState(() => _isPressed = false)
        : null,
    onTap: widget.enabled && !widget.loading ? widget.onTap : null,
    child: AnimatedScale(
      scale: _isPressed ? 0.96 : 1.0,
      duration: const Duration(milliseconds: 110),
      curve: Curves.easeOutBack,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFF18181C).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0x2DFFFFFF),
                width: 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.enabled && !widget.loading ? widget.onTap : null,
                splashColor: Colors.white.withOpacity(0.05),
                highlightColor: Colors.white.withOpacity(0.05),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.loading)
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: const Color(0xFFA1A1AA).withOpacity(0.9),
                        ),
                      )
                    else
                      Icon(
                        widget.icon,
                        color: const Color(0xFFA1A1AA).withOpacity(0.9),
                        size: 20,
                      ),
                    const SizedBox(width: 11),
                    Text(
                      widget.label,
                      style: GoogleFonts.spaceGrotesk(
                        color: const Color(0xFFF4F4F5),
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}