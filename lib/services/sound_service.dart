import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

/// Short UI sound effects for rewards, achievements, and mining sessions.
class SoundService {
  SoundService._();
  static final SoundService instance = SoundService._();

  final AudioPlayer _player = AudioPlayer();
  bool _ready = false;

  Future<void> init() async {
    if (_ready) return;
    try {
      await _player.setPlayerMode(PlayerMode.lowLatency);
      await _player.setReleaseMode(ReleaseMode.stop);
    } catch (_) {}
    _ready = true;
  }

  Future<void> reward() => _play('sfx/reward.wav');
  Future<void> achievement() => _play('sfx/achievement.wav');
  Future<void> miningStart() => _play('sfx/mining_start.wav');
  Future<void> miningStop() => _play('sfx/mining_stop.wav');

  Future<void> _play(String asset) async {
    try {
      await init();
      HapticFeedback.lightImpact();
      await _player.stop();
      await _player.play(AssetSource(asset));
    } catch (_) {}
  }
}
