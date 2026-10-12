import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../services/game_state_service.dart';
import '../services/mini_game_service.dart';
import '../theme/app_theme.dart';

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

  @override
  void initState() {
    super.initState();
    _punch = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
      lowerBound: 0,
      upperBound: 1,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _punch.dispose();
    super.dispose();
  }

  double get _timeLeft =>
      (MiniGameService.tapTimeSec - _elapsedMs / 1000).clamp(0, MiniGameService.tapTimeSec.toDouble());

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
      await context.read<GameStateService>().grantDirectBtc(MiniGameService.rewardBtc);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Block found · +${MiniGameService.rewardBtc.toStringAsFixed(8)} BTC'),
          backgroundColor: const Color(0xFF16A34A),
        ));
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
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text('Hash burst'),
        backgroundColor: const Color(0xFFF4F6F8),
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            children: [
              Text(
                'Push a short hash burst: land ${MiniGameService.tapTarget} hashes '
                'before the ${MiniGameService.tapTimeSec}s window closes.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 6),
              Text(
                '${mini.playsLeft} burst${mini.playsLeft == 1 ? '' : 's'} left today',
                style: TextStyle(color: AppTheme.textSecondary.withValues(alpha: 0.8), fontSize: 12),
              ),
              const SizedBox(height: 18),
              _StatRow(
                hashes: _taps,
                target: MiniGameService.tapTarget,
                hashRate: _playing || _finished ? _hashRate : 0,
                timeLeft: _playing ? _timeLeft : MiniGameService.tapTimeSec.toDouble(),
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: _hashFrac,
                  minHeight: 8,
                  backgroundColor: const Color(0xFFE2E8F0),
                  color: won ? const Color(0xFF22C55E) : const Color(0xFFF59E0B),
                ),
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Block progress  ${(_hashFrac * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                ),
              ),
              const Spacer(),
              if (!_playing && !_finished)
                _StartPanel(canPlay: mini.canPlay, onStart: _start),
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
                  onAgain: mini.canPlay ? _start : () => Navigator.pop(context),
                ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

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
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatChip(label: 'HASHES', value: '$hashes / $target'),
        const SizedBox(width: 8),
        _StatChip(label: 'H/s', value: hashRate.toStringAsFixed(1)),
        const SizedBox(width: 8),
        _StatChip(label: 'WINDOW', value: '${timeLeft.toStringAsFixed(1)}s'),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: Color(0xFF9CA3AF),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: Color(0xFF0D0F12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StartPanel extends StatelessWidget {
  final bool canPlay;
  final VoidCallback onStart;
  const _StartPanel({required this.canPlay, required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
            border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.35)),
          ),
          child: const Icon(Icons.memory_rounded, color: Color(0xFFD97706), size: 40),
        ),
        const SizedBox(height: 16),
        const Text(
          'ASIC burst window',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF0D0F12)),
        ),
        const SizedBox(height: 6),
        const Text(
          'Tap the core as it clocks. Miss the window and the nonce expires.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, height: 1.35, color: Color(0xFF6B7280)),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: 200,
          height: 48,
          child: FilledButton(
            onPressed: canPlay ? onStart : null,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFF59E0B),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text(
              canPlay ? 'Start burst' : 'No bursts left',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ],
    );
  }
}

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
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => onTap(),
      child: SizedBox(
        width: 220,
        height: 220,
        child: AnimatedBuilder(
          animation: punch,
          builder: (_, __) {
            final scale = 1.0 - punch.value * 0.08;
            return CustomPaint(
              painter: _RingPainter(progress: 1 - timeFrac),
              child: Center(
                child: Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 148,
                    height: 148,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const RadialGradient(
                        colors: [Color(0xFFFBBF24), Color(0xFFD97706)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                          blurRadius: 22,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.bolt_rounded, color: Colors.white, size: 36),
                          SizedBox(height: 4),
                          Text(
                            'HASH',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.4,
                              fontSize: 13,
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
}

class _RingPainter extends CustomPainter {
  final double progress;
  const _RingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 8;
    final bg = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    final fg = Paint()
      ..color = const Color(0xFFF59E0B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(c, r, bg);
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      -math.pi / 2,
      2 * math.pi * progress.clamp(0.0, 1.0),
      false,
      fg,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}

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
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          won ? Icons.check_circle_rounded : Icons.hourglass_disabled_rounded,
          color: won ? const Color(0xFF22C55E) : const Color(0xFFF97316),
          size: 52,
        ),
        const SizedBox(height: 10),
        Text(
          won ? 'Block found' : 'Nonce expired',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: won ? const Color(0xFF16A34A) : const Color(0xFFEA580C),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          won
              ? 'Burst held at ${hashRate.toStringAsFixed(1)} H/s · $taps hashes accepted'
              : 'Only $taps / ${MiniGameService.tapTarget} hashes landed in the window',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
        ),
        const SizedBox(height: 18),
        TextButton(
          onPressed: onAgain,
          child: Text(canPlay ? 'Run another burst' : 'Back to rewards'),
        ),
      ],
    );
  }
}
