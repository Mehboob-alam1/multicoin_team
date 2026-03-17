import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ad_remote_config_service.dart';
import '../services/game_state_service.dart';
import '../services/analytics_service.dart';
import '../services/lucky_spin_service.dart';
import '../services/notification_service.dart';
import '../services/smart_ad_manager.dart';
import '../theme/app_theme.dart';

class LuckySpinScreen extends StatefulWidget {
  const LuckySpinScreen({super.key});

  @override
  State<LuckySpinScreen> createState() => _LuckySpinScreenState();
}

class _LuckySpinScreenState extends State<LuckySpinScreen>
    with SingleTickerProviderStateMixin {
  static const int _segmentCount = 5;
  static const List<String> _segmentLabels = [
    'BTC',
    'Big BTC',
    'Boost',
    'GPU',
    'Rare',
  ];
  static const List<Color> _segmentColors = [
    Color(0xFFF5A623),
    Color(0xFFE08800),
    Color(0xFF00D4FF),
    Color(0xFFB06EFF),
    Color(0xFFFF6B9D),
  ];

  late AnimationController _controller;
  SpinResult? _result;
  bool _spinning = false;
  bool _hasSpun = false;

  static int _resultToSegmentIndex(SpinResult r) {
    switch (r.type) {
      case 'btc_small': return 0;
      case 'btc_big': return 1;
      case 'boost': return 2;
      case 'gpu': return 3;
      case 'rare': return 4;
      default: return 0;
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && _result != null) {
        _applyResultAndPop();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _applyResultAndPop() async {
    final result = _result!;
    final game = context.read<GameStateService>();
    if (result.btc > 0) await game.grantDirectBtc(result.btc);
    if (result.rigId != null) await game.grantRig(result.rigId!);
    if (result.boost != null) await game.activateBoost(duration: result.boost!);
    if (!mounted) return;
    setState(() {
      _spinning = false;
      _hasSpun = true;
    });
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceVariant,
        title: Row(
          children: [
            Icon(Icons.celebration, color: AppTheme.btcGold),
            const SizedBox(width: 8),
            const Text('You won!'),
          ],
        ),
        content: Text(
          result.label,
          style: const TextStyle(fontSize: 18),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    if (mounted) context.read<NotificationService>().scheduleSpinReminder();
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _onSpin() async {
    final spin = context.read<LuckySpinService>();
    if (!spin.canSpin || _spinning) return;

    final adCfg = context.read<AdRemoteConfigService>();
    final ads = context.read<SmartAdManager>();
    if (adCfg.adsEnabled) {
      try {
        await ads.showInterstitial();
      } catch (_) {}
    }
    if (!mounted) return;

    final result = await spin.spin();
    if (result == null) return;

    if (mounted) context.read<AnalyticsService>().logLuckySpin(rewardType: result.type);

    _result = result;
    setState(() => _spinning = true);

    _controller.reset();
    _controller.duration = const Duration(seconds: 4);
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    final spin = context.watch<LuckySpinService>();
    final canSpin = spin.canSpin && !_spinning && !_hasSpun;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lucky Spin Wheel'),
        backgroundColor: AppTheme.surface,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            Text(
              'Spin to win BTC, boosts, or rigs!',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 280,
              height: 280,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      double angle = 0;
                      if (_result != null &&
                          (_controller.isAnimating || _controller.isCompleted)) {
                        final segmentIndex = _resultToSegmentIndex(_result!);
                        const segmentAngle = 360.0 / _segmentCount;
                        final endDegrees = 360.0 * 5 +
                            (segmentIndex * segmentAngle + segmentAngle / 2);
                        final endRad = endDegrees * math.pi / 180.0;
                        angle = endRad * _controller.value;
                      }
                      return Transform.rotate(
                        angle: angle,
                        child: CustomPaint(
                          size: const Size(280, 280),
                          painter: _WheelPainter(
                            segments: _segmentLabels,
                            colors: _segmentColors,
                          ),
                        ),
                      );
                    },
                  ),
                  CustomPaint(
                    size: const Size(40, 50),
                    painter: _PointerPainter(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            FilledButton.icon(
              onPressed: canSpin ? _onSpin : null,
              icon: _spinning
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.casino_rounded),
              label: Text(
                _spinning
                    ? 'Spinning...'
                    : _hasSpun
                        ? 'Come back in 24h'
                        : 'Spin!',
              ),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                backgroundColor: AppTheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WheelPainter extends CustomPainter {
  final List<String> segments;
  final List<Color> colors;

  _WheelPainter({required this.segments, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    final sweepAngle = 2 * math.pi / segments.length;

    for (int i = 0; i < segments.length; i++) {
      final paint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.fill;
      final startAngle = -math.pi / 2 + i * sweepAngle;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );
      final borderPaint = Paint()
        ..color = Colors.black12
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        borderPaint,
      );

      final textAngle = startAngle + sweepAngle / 2;
      final textRadius = radius * 0.65;
      final tx = center.dx + textRadius * math.cos(textAngle);
      final ty = center.dy + textRadius * math.sin(textAngle);
      canvas.save();
      canvas.translate(tx, ty);
      canvas.rotate(textAngle + math.pi / 2);
      final text = segments[i];
      final textPainter = TextPainter(
        text: TextSpan(
          text: text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        Offset(-textPainter.width / 2, -textPainter.height / 2),
      );
      canvas.restore();
    }

    final centerPaint = Paint()
      ..color = AppTheme.surfaceVariant
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 24, centerPaint);
    final centerBorder = Paint()
      ..color = AppTheme.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawCircle(center, 24, centerBorder);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PointerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.primary
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, paint);
    final border = Paint()
      ..color = Colors.black12
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawPath(path, border);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
