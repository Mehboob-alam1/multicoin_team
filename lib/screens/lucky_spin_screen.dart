import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../services/game_state_service.dart';
import '../services/analytics_service.dart';
import '../services/lucky_spin_service.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../utils/smart_ads.dart';
import '../widgets/screen_ad_slot.dart';

// ─── Design Tokens ────────────────────────────────────────────────────────────
class _D {
  static const bg = Color(0xFF08080A);
  static const surface = Color(0xFF18181C);
  static const card = Color(0xFF18181C);
  static const glassBorder = Color(0x2DFFFFFF);
  static const textHi = Color(0xFFF4F4F5);
  static const textMid = Color(0xFFA1A1AA);
  static const textLow = Color(0xFF71717A);

  static const purple = Color(0xFF9945FF);
  static const green = Color(0xFF14F195);
  static const blue = Color(0xFF38BDF8);
  static const violet = Color(0xFFA78BFA);
  static const pink = Color(0xFFF472B6);
}

// ─── Typography ───────────────────────────────────────────────────────────────
TextStyle _label({
  double size = 13,
  FontWeight weight = FontWeight.w400,
  Color color = _D.textHi,
  double? letterSpacing,
}) => GoogleFonts.spaceGrotesk(
  fontSize: size,
  fontWeight: weight,
  color: color,
  letterSpacing: letterSpacing ?? -0.2,
);

// ─── Segment Config ───────────────────────────────────────────────────────────
class _Segment {
  final String label;
  final Color color;
  final IconData icon;

  const _Segment({
    required this.label,
    required this.color,
    required this.icon,
  });
}

// ✅ Fixed: Changed Icons.crown_rounded to Icons.star_rounded
final List<_Segment> _segments = [
  _Segment(label: 'SOL', color: _D.purple, icon: Icons.currency_bitcoin),
  _Segment(label: 'Big SOL', color: _D.green, icon: Icons.diamond),
  _Segment(label: 'Boost', color: _D.blue, icon: Icons.bolt_rounded),
  _Segment(label: 'GPU', color: _D.violet, icon: Icons.memory_rounded),
  _Segment(label: 'Rare', color: _D.pink, icon: Icons.star_rounded),
];

// ─── Main Screen ──────────────────────────────────────────────────────────────
class LuckySpinScreen extends StatefulWidget {
  const LuckySpinScreen({super.key});

  @override
  State<LuckySpinScreen> createState() => _LuckySpinScreenState();
}

class _LuckySpinScreenState extends State<LuckySpinScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _wheelController;
  late AnimationController _glowController;
  SpinResult? _result;
  bool _spinning = false;
  bool _hasSpun = false;

  static int _resultToSegmentIndex(SpinResult r) {
    switch (r.type) {
      case 'btc_small':
        return 0;
      case 'btc_big':
        return 1;
      case 'boost':
        return 2;
      case 'gpu':
        return 3;
      case 'rare':
        return 4;
      default:
        return 0;
    }
  }

  @override
  void initState() {
    super.initState();
    _wheelController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _wheelController.addStatusListener((status) {
      if (status == AnimationStatus.completed && _result != null) {
        _applyResultAndPop();
      }
    });

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _wheelController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  Future<void> _applyResultAndPop() async {
    final result = _result!;
    final game = context.read<GameStateService>();
    if (result.btc > 0) await game.grantDirectBtc(result.btc);
    if (result.rigId != null) await game.grantRig(result.rigId!);
    if (result.boost != null) {
      await game.activateBoost(duration: result.boost!);
    }
    if (!mounted) return;

    setState(() {
      _spinning = false;
      _hasSpun = true;
    });

    await _showWinDialog(result);
    if (mounted) context.read<NotificationService>().scheduleSpinReminder();
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _showWinDialog(SpinResult result) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: _D.surface.withOpacity(0.1),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: _D.glassBorder, width: 0.8),
                boxShadow: [
                  BoxShadow(
                    color: _D.purple.withOpacity(0.2),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('🎉', style: const TextStyle(fontSize: 64)),
                  const SizedBox(height: 20),
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [_D.purple, _D.green],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(bounds),
                    child: Text(
                      'You Won!',
                      style: _label(
                        size: 28,
                        weight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    result.label,
                    textAlign: TextAlign.center,
                    style: _label(
                      size: 16,
                      weight: FontWeight.w600,
                      color: _D.textMid,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 28),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => Navigator.of(ctx).pop(),
                        splashColor: Colors.white.withOpacity(0.1),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 13,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [_D.purple, _D.green],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: _D.purple.withOpacity(0.4),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Text(
                            'Awesome!',
                            style: _label(
                              size: 14,
                              weight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onSpin() async {
    final spin = context.read<LuckySpinService>();
    if (!spin.canSpin || _spinning) return;

    await SmartAds.maybeInterstitial(context);
    if (!mounted) return;

    final result = await spin.spin();
    if (result == null) return;

    if (mounted) {
      context
          .read<AnalyticsService>()
          .logLuckySpin(rewardType: result.type);
    }

    _result = result;
    setState(() => _spinning = true);

    _wheelController.reset();
    _wheelController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final spin = context.watch<LuckySpinService>();
    final canSpin = spin.canSpin && !_spinning && !_hasSpun;

    return Scaffold(
      backgroundColor: _D.bg,
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topRight,
                  radius: 1.5,
                  colors: [
                    _D.purple.withOpacity(0.08),
                    _D.bg,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: -100,
            right: -60,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _D.purple.withOpacity(0.1),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                child: const SizedBox.shrink(),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: _D.surface.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _D.glassBorder,
                                    width: 0.8,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.arrow_back_rounded,
                                  color: _D.textMid,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Lucky Spin Wheel',
                                style: _label(
                                  size: 16,
                                  weight: FontWeight.w800,
                                  color: _D.textHi,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Win SOL, boosts & rigs',
                                style: _label(
                                  size: 11,
                                  weight: FontWeight.w500,
                                  color: _D.textLow,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: _D.purple.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _D.purple.withOpacity(0.4),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            _hasSpun ? 'Come back soon' : 'Ready!',
                            style: _label(
                              size: 11,
                              weight: FontWeight.w700,
                              color: _hasSpun ? _D.textLow : _D.purple,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: 320,
                    height: 320,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        AnimatedBuilder(
                          animation: _glowController,
                          builder: (_, __) {
                            return Container(
                              width: 320,
                              height: 320,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: _D.purple.withOpacity(0.3 *
                                        _glowController.value),
                                    blurRadius: 40,
                                    spreadRadius: 10,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        AnimatedBuilder(
                          animation: _wheelController,
                          builder: (context, child) {
                            double angle = 0;
                            if (_result != null &&
                                (_wheelController.isAnimating ||
                                    _wheelController.isCompleted)) {
                              final segmentIndex =
                              _resultToSegmentIndex(_result!);
                              const segmentAngle =
                                  360.0 / 5; // Fixed: use 5 instead of _segments.length
                              final easeOutCurve =
                              Curves.easeOutCubic.transform(
                                _wheelController.value,
                              );
                              final endDegrees = 360.0 * 5 +
                                  (segmentIndex * segmentAngle +
                                      segmentAngle / 2);
                              angle = (endDegrees *
                                  math.pi /
                                  180.0) *
                                  easeOutCurve;
                            }
                            return Transform.rotate(
                              angle: angle,
                              child: CustomPaint(
                                size: const Size(320, 320),
                                painter: _WheelPainter(
                                  segments: _segments,
                                ),
                              ),
                            );
                          },
                        ),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(40),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _D.surface.withOpacity(0.2),
                                border: Border.all(
                                  color: _D.glassBorder,
                                  width: 1.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: _D.purple.withOpacity(0.3),
                                    blurRadius: 16,
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.casino_rounded,
                                    color: _D.purple,
                                    size: 32,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Spin',
                                    style: _label(
                                      size: 10,
                                      weight: FontWeight.w700,
                                      color: _D.textLow,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 0,
                          child: CustomPaint(
                            size: const Size(30, 40),
                            painter: _PointerPainter(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _SpinButton(
                      canSpin: canSpin,
                      isSpinning: _spinning,
                      hasSpun: _hasSpun,
                      onTap: _onSpin,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: List.generate(_segments.length, (i) {
                        final segment = _segments[i];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Container(
                                padding: const EdgeInsets.all(13),
                                decoration: BoxDecoration(
                                  color: _D.surface.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: _D.glassBorder,
                                    width: 0.8,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: segment.color.withOpacity(0.15),
                                        borderRadius:
                                        BorderRadius.circular(10),
                                        border: Border.all(
                                          color: segment.color
                                              .withOpacity(0.4),
                                          width: 0.8,
                                        ),
                                      ),
                                      child: Icon(
                                        segment.icon,
                                        color: segment.color,
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        segment.label,
                                        style: _label(
                                          size: 13,
                                          weight: FontWeight.w600,
                                          color: _D.textHi,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: segment.color,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 0, 20, 28),
                    child: Column(
                      children: [
                        ScreenAdSlot(title: 'Lucky spin offer'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Spin Button ───────────────────────────────────────────────────────────────
class _SpinButton extends StatefulWidget {
  final bool canSpin;
  final bool isSpinning;
  final bool hasSpun;
  final VoidCallback onTap;

  const _SpinButton({
    required this.canSpin,
    required this.isSpinning,
    required this.hasSpun,
    required this.onTap,
  });

  @override
  State<_SpinButton> createState() => _SpinButtonState();
}

class _SpinButtonState extends State<_SpinButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown: widget.canSpin ? (_) => setState(() => _isPressed = true) : null,
    onTapUp: widget.canSpin ? (_) => setState(() => _isPressed = false) : null,
    onTapCancel:
    widget.canSpin ? () => setState(() => _isPressed = false) : null,
    onTap: widget.canSpin && !widget.isSpinning ? widget.onTap : null,
    child: Transform.scale(
      scale: _isPressed ? 0.96 : 1.0,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            gradient: widget.canSpin
                ? const LinearGradient(
              colors: [_D.purple, _D.green],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
                : LinearGradient(
              colors: [
                _D.textLow.withOpacity(0.3),
                _D.textLow.withOpacity(0.2),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: widget.canSpin
                ? [
              BoxShadow(
                color: _D.purple.withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: _D.green.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ]
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap:
              widget.canSpin && !widget.isSpinning ? widget.onTap : null,
              splashColor: Colors.white.withOpacity(0.1),
              highlightColor: Colors.white.withOpacity(0.1),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.isSpinning)
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    )
                  else
                    Icon(
                      Icons.casino_rounded,
                      color: Colors.white.withOpacity(0.95),
                      size: 22,
                    ),
                  const SizedBox(width: 12),
                  Text(
                    widget.isSpinning
                        ? 'Spinning...'
                        : widget.hasSpun
                        ? 'Come back in 24h'
                        : 'Spin the Wheel',
                    style: _label(
                      size: 16,
                      weight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.3,
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

// ─── Wheel Painter ────────────────────────────────────────────────────────────
class _WheelPainter extends CustomPainter {
  final List<_Segment> segments;

  _WheelPainter({required this.segments});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;
    final sweepAngle = 2 * math.pi / segments.length;

    for (int i = 0; i < segments.length; i++) {
      final segment = segments[i];
      final startAngle = -math.pi / 2 + i * sweepAngle;

      final segmentPaint = Paint()
        ..color = segment.color
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        segmentPaint,
      );

      final borderPaint = Paint()
        ..color = Colors.white.withOpacity(0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        borderPaint,
      );

      final textAngle = startAngle + sweepAngle / 2;
      final textRadius = radius * 0.68;
      final tx = center.dx + textRadius * math.cos(textAngle);
      final ty = center.dy + textRadius * math.sin(textAngle);

      canvas.save();
      canvas.translate(tx, ty);
      canvas.rotate(textAngle + math.pi / 2);

      // ✅ Fixed: Removed const from TextSpan with fontFamily
      final labelPainter = TextPainter(
        text: TextSpan(
          text: segment.label,
          style: GoogleFonts.spaceGrotesk(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      labelPainter.paint(
        canvas,
        Offset(-labelPainter.width / 2, -labelPainter.height / 2),
      );

      canvas.restore();
    }

    final centerPaint = Paint()
      ..color = _D.surface
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 28, centerPaint);

    final centerBorderPaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, 28, centerBorderPaint);
  }

  @override
  bool shouldRepaint(_WheelPainter oldDelegate) => false;
}

// ─── Pointer Painter ──────────────────────────────────────────────────────────
class _PointerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _D.purple
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, paint);

    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawPath(path, borderPaint);

    canvas.drawPath(
      path,
      Paint()
        ..color = _D.purple.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 4),
    );
  }

  @override
  bool shouldRepaint(_PointerPainter oldDelegate) => false;
}