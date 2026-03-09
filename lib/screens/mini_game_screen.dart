import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/game_state_service.dart';
import '../services/mini_game_service.dart';
import '../theme/app_theme.dart';

class MiniGameScreen extends StatefulWidget {
  const MiniGameScreen({super.key});

  @override
  State<MiniGameScreen> createState() => _MiniGameScreenState();
}

class _MiniGameScreenState extends State<MiniGameScreen> {
  int _taps = 0;
  int _elapsedMs = 0;
  bool _playing = false;
  bool _finished = false;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    if (!context.read<MiniGameService>().canPlay) return;
    setState(() {
      _taps = 0;
      _elapsedMs = 0;
      _playing = true;
      _finished = false;
    });
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!mounted) return;
      setState(() {
        _elapsedMs += 100;
        if (_elapsedMs >= MiniGameService.tapTimeSec * 1000) _endGame();
      });
    });
  }

  Future<void> _endGame() async {
    _timer?.cancel();
    _timer = null;
    setState(() { _playing = false; _finished = true; });
    final mini = context.read<MiniGameService>();
    final won = await mini.recordPlay(taps: _taps, elapsedMs: _elapsedMs);
    if (!mounted) return;
    if (won) {
      await context.read<GameStateService>().grantDirectBtc(MiniGameService.rewardBtc);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('+${MiniGameService.rewardBtc.toStringAsFixed(5)} BTC!'), backgroundColor: Colors.green),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mini = context.watch<MiniGameService>();
    final game = context.watch<GameStateService>();
    return Scaffold(
      backgroundColor: const Color(0xFF080B12),
      appBar: AppBar(
        title: const Text('Tap challenge'),
        backgroundColor: const Color(0xFF0E1420),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Text(
                'Tap the coin ${MiniGameService.tapTarget} times in ${MiniGameService.tapTimeSec} seconds!',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Plays left today: ${mini.playsLeft}',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
              const Spacer(),
              if (!_playing && !_finished)
                GestureDetector(
                  onTap: mini.canPlay ? _start : null,
                  child: Container(
                    width: 120,
                    height: 48,
                    decoration: BoxDecoration(
                      color: mini.canPlay ? Colors.amber : Colors.grey,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Center(
                      child: Text(
                        mini.canPlay ? 'Start' : 'No plays left',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
              if (_playing) ...[
                Text(
                  '$_taps / ${MiniGameService.tapTarget}',
                  style: const TextStyle(color: Colors.amber, fontSize: 32, fontWeight: FontWeight.w900),
                ),
                Text(
                  '${(MiniGameService.tapTimeSec - _elapsedMs / 1000).ceil()}s',
                  style: const TextStyle(color: Colors.white54, fontSize: 18),
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: () => setState(() => _taps++),
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [Color(0xFFF5A623), Color(0xFFE08800)],
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        '₿',
                        style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                ),
              ],
              if (_finished) ...[
                Text(
                  _taps >= MiniGameService.tapTarget ? 'You won!' : 'Time up',
                  style: TextStyle(
                    color: _taps >= MiniGameService.tapTarget ? Colors.green : Colors.orange,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: mini.canPlay ? _start : () => Navigator.pop(context),
                  child: Text(mini.canPlay ? 'Play again' : 'Back'),
                ),
              ],
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
