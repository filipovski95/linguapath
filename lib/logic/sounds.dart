import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Short feedback sounds. Failing to play is never an error for the learner.
class Sounds {
  Sounds._();
  static final instance = Sounds._();

  /// The learner's setting.
  bool enabled = true;

  /// Turns sound off entirely, e.g. in widget tests where there is no audio plugin.
  @visibleForTesting
  bool forceOff = false;

  AudioPlayer? _player;

  Future<void> correct() => _play('sounds/correct.wav');
  Future<void> wrong() => _play('sounds/wrong.wav');
  Future<void> complete() => _play('sounds/complete.wav');

  Future<void> _play(String asset) async {
    if (!enabled || forceOff) return;
    try {
      final p = _player ??= AudioPlayer();
      await p.stop();
      await p.play(AssetSource(asset), mode: PlayerMode.lowLatency);
    } catch (e) {
      debugPrint('Sound unavailable: $e');
    }
  }
}
