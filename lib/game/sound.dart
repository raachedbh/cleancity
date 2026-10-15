import 'dart:async';
import 'package:audioplayers/audioplayers.dart';

class GameSound {
  final _pickup = AudioPlayer();
  final _reward = AudioPlayer();
  bool _disposed = false;
  void play(String name, {required bool enabled}) {
    if (!enabled || _disposed) return;
    unawaited(_play(name));
  }

  Future<void> _play(String name) async {
    try {
      final player = name == 'pickup' ? _pickup : _reward;
      await player.play(AssetSource('audio/$name.wav'), volume: .35);
    } catch (_) {
      // Audio must never block offline play or collection.
    }
  }

  Future<void> dispose() async {
    _disposed = true;
    await Future.wait([_pickup.dispose(), _reward.dispose()]);
  }
}
