import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../config/mining_economy.dart';
import '../services/game_state_service.dart';
import '../services/mini_game_service.dart';
import '../theme/app_theme.dart';
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
  static const orange = Color(0xFFF97316);
  static const success = Color(0xFF22C55E);
}

// ─── Typography ───────────────────────────────────────────────────────────────
TextStyle _label({
  double size = 13,
  FontWeight weight = FontWeight.w400,
  Color color = _D.textHi,
  double? letterSpacing,
  double? height,
}) => GoogleFonts.spaceGrotesk(
  fontSize: size,
  fontWeight: weight,
  color: color,
  letterSpacing: letterSpacing ?? -0.2,
  height: height,
);

TextStyle _mono({
  double size = 13,
  FontWeight weight = FontWeight.w400,
  Color color = _D.textHi,
}) => GoogleFonts.spaceMono(
  fontSize: size,
  fontWeight: weight,
  color: color,
  letterSpacing: -0.3,
);

// ─── Main Screen ──────────────────────────────────────────────────────────────
class MiniGameScreen extends StatefulWidget {
  const MiniGameScreen({super.key});

  @override
  State<MiniGameScreen> createState() => _MiniGameScreenState();
}

class _MiniGameScreenState extends State<MiniGameScreen>
    with SingleTickerProviderStateMixin {
  int _taps = 0;
  int _elapsedMs = 0;
  bool _playing = false;
  bool _finished = false;
  Timer? _timer;
  late final AnimationController _punch;
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _punch = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
      lowerBound: 0,
      upperBound: 1,
    );
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _punch.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  double get _timeLeft =>
      (MiniGameService.tapTimeSec - _elapsedMs / 1000)
          .clamp(0, MiniGameService.tapTimeSec.toDouble());

  double get _timeFrac =>
      (_elapsedMs / (MiniGameService.tapTimeSec * 1000)).clamp(0.0, 1.0);

  double get _hashFrac =>
      (_taps / MiniGameService.tapTarget).clamp(0.0, 1.0);

  double get _hashRate {
    if (_elapsedMs <= 0) return 0;
    return _taps / (_elapsedMs / 1000);
  }

  void _start() {
    if (!context.read<MiniGameService>().canPlay) return;
    _timer?.cancel();
    setState(() {
      _taps = 0;
      _elapsedMs = 0;
      _playing = true;
      _finished = false;
    });
    _timer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (!mounted || !_playing) return;
      setState(() => _elapsedMs += 50);
      if (_elapsedMs >= MiniGameService.tapTimeSec * 1000) _endGame();
    });
  }

  void _onHashTap() {
    if (!_playing) return;
    HapticFeedback.selectionClick();
    _punch.forward(from: 0);
    setState(() => _taps++);
    if (_taps >= MiniGameService.tapTarget) _endGame();
  }

  Future<void> _endGame() async {
    if (!_playing) return;
    _timer?.cancel();
    _timer = null;
    setState(() {
      _playing = false;
      _finished = true;
    });
    final mini = context.read<MiniGameService>();
    final won = await mini.recordPlay(taps: _taps, elapsedMs: _elapsedMs);
    if (!mounted) return;
    if (won) {
      HapticFeedback.mediumImpact();
      await context
          .read<GameStateService>()
          .grantDirectBtc(MiniGameService.rewardBtc);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Block found · +${MiningEconomy.toSol(MiniGameService.rewardBtc).toStringAsFixed(6)} SOL',
              style: _label(
                size: 13,
                weight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            backgroundColor: _D.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(
                color: Color(0x2DFFFFFF),
                width: 0.8,
              ),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } else {
      HapticFeedback.heavyImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    final mini = context.watch<MiniGameService>();
    final won = _taps >= MiniGameService.tapTarget;

    return Scaffold(
      backgroundColor: _D.bg,
      body: Stack(
        children: [
          // ── Background gradient ────────────────────────────────────────
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

          // ── Ambient blob ───────────────────────────────────────────────
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
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                children: [
                  // ── Header ────────────────────────────────────────────
                  _Header(
                    bursts: mini.playsLeft,
                    onBack: () => Navigator.pop(context),
                  ),
                  const SizedBox(height: 24),

                  // ── Description ───────────────────────────────────────
                  Text(
                    'Push a short hash burst: land ${MiniGameService.tapTarget} hashes before the ${MiniGameService.tapTimeSec}s window closes.',
                    textAlign: TextAlign.center,
                    style: _label(
                      size: 13,
                      color: _D.textMid,
                      height: 1.5,
                      weight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Stats ─────────────────────────────────────────────
                  _StatRow(
                    hashes: _taps,
                    target: MiniGameService.tapTarget,
                    hashRate: _playing || _finished ? _hashRate : 0,
                    timeLeft: _playing
                        ? _timeLeft
                        : MiniGameService.tapTimeSec.toDouble(),
                  ),
                  const SizedBox(height: 16),

                  // ── Progress bar ──────────────────────────────────────
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: _D.surface.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Stack(
                        children: [
                          Container(
                            width: MediaQuery.of(context).size.width *
                                _hashFrac *
                                0.85,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  won ? _D.success : _D.purple,
                                  won ? _D.success : _D.green,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: (won ? _D.success : _D.purple)
                                      .withOpacity(0.4),
                                  blurRadius: 8,
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Block progress  ${(_hashFrac * 100).toStringAsFixed(0)}%',
                      style: _label(
                        size: 11,
                        color: _D.textLow,
                        weight: FontWeight.w500,
                      ),
                    ),
                  ),

                  const Spacer(),

                  // ── Game panels ───────────────────────────────────────
                  if (!_playing && !_finished)
                    _StartPanel(
                      canPlay: mini.canPlay,
                      onStart: _start,
                      pulseCtrl: _pulseCtrl,
                    ),
                  if (_playing)
                    _HashButton(
                      punch: _punch,
                      timeFrac: _timeFrac,
                      onTap: _onHashTap,
                    ),
                  if (_finished)
                    _ResultPanel(
                      won: won,
                      taps: _taps,
                      hashRate: _hashRate,
                      canPlay: mini.canPlay,
                      onAgain: mini.canPlay
                          ? _start
                          : () => Navigator.pop(context),
                    ),

                  const Spacer(),
                  const ScreenAdSlot(title: 'Hash game offer'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final int bursts;
  final VoidCallback onBack;

  const _Header({required this.bursts, required this.onBack});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      GestureDetector(
        onTap: onBack,
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
                border: Border.all(color: _D.glassBorder, width: 0.8),
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
            ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (r) => const LinearGradient(
                colors: [_D.purple, _D.green],
              ).createShader(r),
              child: Text(
                'Hash Burst',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _label(
                  size: 16,
                  weight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Tap the validator core',
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
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: _D.purple.withOpacity(0.15),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: _D.purple.withOpacity(0.4),
            width: 0.8,
          ),
        ),
        child: Text(
          '$bursts LEFT',
          style: _mono(
            size: 10,
            weight: FontWeight.w700,
            color: _D.purple,
          ).copyWith(letterSpacing: 1.4),
        ),
      ),
    ],
  );
}

// ─── Stat Row ──────────────────────────────────────────────────────────────────
class _StatRow extends StatelessWidget {
  final int hashes;
  final int target;
  final double hashRate;
  final double timeLeft;

  const _StatRow({
    required this.hashes,
    required this.target,
    required this.hashRate,
    required this.timeLeft,
  });

  @override
  Widget build(BuildContext context) => Row(
    children: [
      _StatChip(
        label: 'HASHES',
        value: '$hashes / $target',
        color: _D.purple,
      ),
      const SizedBox(width: 10),
      _StatChip(
        label: 'H/s',
        value: hashRate.toStringAsFixed(1),
        color: _D.green,
      ),
      const SizedBox(width: 10),
      _StatChip(
        label: 'WINDOW',
        value: '${timeLeft.toStringAsFixed(1)}s',
        color: _D.blue,
      ),
    ],
  );
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: Column(
            children: [
              Text(
                label,
                style: _label(
                  size: 9,
                  weight: FontWeight.w700,
                  color: color.withOpacity(0.7),
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                value,
                style: _mono(
                  size: 13,
                  weight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

// ─── Start Panel ───────────────────────────────────────────────────────────────
class _StartPanel extends StatelessWidget {
  final bool canPlay;
  final VoidCallback onStart;
  final AnimationController pulseCtrl;

  const _StartPanel({
    required this.canPlay,
    required this.onStart,
    required this.pulseCtrl,
  });

  @override
  Widget build(BuildContext context) => Column(
    children: [
      // ── Pulsing icon ───────────────────────────────────────────────
      AnimatedBuilder(
        animation: pulseCtrl,
        builder: (_, __) {
          final scale = 1.0 + 0.1 * pulseCtrl.value;
          return Transform.scale(
            scale: scale,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _D.purple.withOpacity(0.12),
                border: Border.all(
                  color: _D.purple.withOpacity(0.4),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _D.purple.withOpacity(0.25 * pulseCtrl.value),
                    blurRadius: 24,
                    spreadRadius: 8,
                  )
                ],
              ),
              child: const Icon(
                Icons.memory_rounded,
                color: _D.purple,
                size: 48,
              ),
            ),
          );
        },
      ),
      const SizedBox(height: 18),

      // ── Title ──────────────────────────────────────────────────────
      Text(
        'Validator Burst Window',
        style: _label(
          size: 18,
          weight: FontWeight.w800,
          color: _D.textHi,
          letterSpacing: -0.3,
        ),
      ),
      const SizedBox(height: 8),

      // ── Subtitle ───────────────────────────────────────────────────
      Text(
        'Tap the core as it clocks. Miss the window and the nonce expires.',
        textAlign: TextAlign.center,
        style: _label(
          size: 12,
          color: _D.textMid,
          height: 1.5,
          weight: FontWeight.w500,
        ),
      ),
      const SizedBox(height: 24),

      // ── Start button ───────────────────────────────────────────────
      _StartButton(
        canPlay: canPlay,
        onStart: onStart,
      ),
    ],
  );
}

class _StartButton extends StatefulWidget {
  final bool canPlay;
  final VoidCallback onStart;

  const _StartButton({required this.canPlay, required this.onStart});

  @override
  State<_StartButton> createState() => _StartButtonState();
}

class _StartButtonState extends State<_StartButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown: widget.canPlay ? (_) => setState(() => _isPressed = true) : null,
    onTapUp: widget.canPlay ? (_) => setState(() => _isPressed = false) : null,
    onTapCancel:
    widget.canPlay ? () => setState(() => _isPressed = false) : null,
    onTap: widget.canPlay ? widget.onStart : null,
    child: Transform.scale(
      scale: _isPressed ? 0.96 : 1.0,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 200,
          height: 52,
          decoration: BoxDecoration(
            gradient: widget.canPlay
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
            borderRadius: BorderRadius.circular(14),
            boxShadow: widget.canPlay
                ? [
              BoxShadow(
                color: _D.purple.withOpacity(0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ]
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.canPlay ? widget.onStart : null,
              splashColor: Colors.white.withOpacity(0.1),
              highlightColor: Colors.white.withOpacity(0.1),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.bolt_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    widget.canPlay ? 'Start burst' : 'No bursts left',
                    style: _label(
                      size: 14,
                      weight: FontWeight.w800,
                      color: Colors.white,
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

// ─── Hash Button ───────────────────────────────────────────────────────────────
class _HashButton extends StatelessWidget {
  final AnimationController punch;
  final double timeFrac;
  final VoidCallback onTap;

  const _HashButton({
    required this.punch,
    required this.timeFrac,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown: (_) => onTap(),
    child: SizedBox(
      width: 240,
      height: 240,
      child: AnimatedBuilder(
        animation: punch,
        builder: (_, __) {
          final scale = 1.0 - punch.value * 0.1;
          return CustomPaint(
            painter: _RingPainter(
              progress: 1 - timeFrac,
              color: _D.purple,
            ),
            child: Center(
              child: Transform.scale(
                scale: scale,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(84),
                  child: Container(
                    width: 168,
                    height: 168,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [_D.green, _D.purple],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _D.purple.withOpacity(0.4),
                          blurRadius: 28,
                          spreadRadius: 2,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.bolt_rounded,
                          color: Colors.white,
                          size: 40,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'HASH',
                          style: _label(
                            size: 13,
                            weight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    ),
  );
}

// ─── Ring Painter ──────────────────────────────────────────────────────────────
class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;

  const _RingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 12;

    // Background ring
    final bgPaint = Paint()
      ..color = color.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(c, r, bgPaint);

    // Progress ring
    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        colors: [
          color.withOpacity(0.6),
          color,
        ],
      ).createShader(Rect.fromCircle(center: c, radius: r));

    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      -math.pi / 2,
      2 * math.pi * progress.clamp(0.0, 1.0),
      false,
      fgPaint,
    );

    // Glow effect
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      -math.pi / 2,
      2 * math.pi * progress.clamp(0.0, 1.0),
      false,
      Paint()
        ..color = color.withOpacity(0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 4),
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color;
}

// ─── Result Panel ──────────────────────────────────────────────────────────────
class _ResultPanel extends StatelessWidget {
  final bool won;
  final int taps;
  final double hashRate;
  final bool canPlay;
  final VoidCallback onAgain;

  const _ResultPanel({
    required this.won,
    required this.taps,
    required this.hashRate,
    required this.canPlay,
    required this.onAgain,
  });

  @override
  Widget build(BuildContext context) => Column(
    children: [
      // ── Result icon ────────────────────────────────────────────────
      Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: (won ? _D.success : _D.orange).withOpacity(0.12),
          border: Border.all(
            color: (won ? _D.success : _D.orange).withOpacity(0.4),
            width: 2,
          ),
        ),
        child: Icon(
          won ? Icons.check_circle_rounded : Icons.hourglass_disabled_rounded,
          color: won ? _D.success : _D.orange,
          size: 40,
        ),
      ),
      const SizedBox(height: 16),

      // ── Result title ───────────────────────────────────────────────
      Text(
        won ? 'Block Found' : 'Nonce Expired',
        style: _label(
          size: 22,
          weight: FontWeight.w800,
          color: won ? _D.success : _D.orange,
          letterSpacing: -0.4,
        ),
      ),
      const SizedBox(height: 8),

      // ── Result details ─────────────────────────────────────────────
      Text(
        won
            ? 'Burst held at ${hashRate.toStringAsFixed(1)} H/s · $taps hashes accepted'
            : 'Only $taps / ${MiniGameService.tapTarget} hashes landed in the window',
        textAlign: TextAlign.center,
        style: _label(
          size: 12,
          color: _D.textMid,
          height: 1.5,
          weight: FontWeight.w500,
        ),
      ),
      const SizedBox(height: 22),

      // ── Action button ──────────────────────────────────────────────
      _ResultButton(
        label: canPlay ? 'Run another burst' : 'Back to rewards',
        onTap: onAgain,
        isPrimary: canPlay,
      ),
    ],
  );
}

class _ResultButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;

  const _ResultButton({
    required this.label,
    required this.onTap,
    required this.isPrimary,
  });

  @override
  State<_ResultButton> createState() => _ResultButtonState();
}

class _ResultButtonState extends State<_ResultButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown: (_) => setState(() => _isPressed = true),
    onTapUp: (_) => setState(() => _isPressed = false),
    onTapCancel: () => setState(() => _isPressed = false),
    onTap: widget.onTap,
    child: Transform.scale(
      scale: _isPressed ? 0.96 : 1.0,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 220,
          height: 48,
          decoration: BoxDecoration(
            gradient: widget.isPrimary
                ? const LinearGradient(
              colors: [_D.purple, _D.green],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
                : LinearGradient(
              colors: [
                _D.surface.withOpacity(0.2),
                _D.surface.withOpacity(0.15),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            border: widget.isPrimary
                ? null
                : Border.all(
              color: _D.glassBorder,
              width: 0.8,
            ),
            boxShadow: widget.isPrimary
                ? [
              BoxShadow(
                color: _D.purple.withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ]
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              splashColor: Colors.white.withOpacity(0.1),
              highlightColor: Colors.white.withOpacity(0.1),
              child: Center(
                child: Text(
                  widget.label,
                  style: _label(
                    size: 14,
                    weight: FontWeight.w700,
                    color: widget.isPrimary ? Colors.white : _D.textMid,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}