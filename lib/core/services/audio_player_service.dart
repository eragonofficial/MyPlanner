import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

/// Audio player service supporting multi-ambient sound mixing, volume control,
/// and seamless looping synchronized with Pomodoro focus sessions.
class AudioPlayerService {
  final Map<String, AudioPlayer> _players = {};
  double _volume = 0.7;
  bool _isPaused = false;

  double get volume => _volume;
  bool get hasActiveSounds => _players.isNotEmpty;
  Set<String> get activeSoundKeys => Set.unmodifiable(_players.keys);
  bool get isPaused => _isPaused;

  bool isSoundPlaying(String soundKey) {
    return _players.containsKey(soundKey);
  }

  /// Start playing a specific ambient sound track with seamless looping.
  Future<bool> playSound(
    String soundKey,
    String assetPath, {
    void Function(String soundName)? onAssetMissing,
  }) async {
    // If already playing this sound, nothing to do
    if (_players.containsKey(soundKey)) {
      return true;
    }

    try {
      final player = AudioPlayer();
      await player.setLoopMode(LoopMode.one);
      await player.setVolume(_volume);
      await player.setAsset(assetPath);
      await player.play();

      _players[soundKey] = player;
      _isPaused = false;
      return true;
    } catch (e) {
      debugPrint('Audio asset notice ($assetPath): $e');
      if (onAssetMissing != null) {
        onAssetMissing(soundKey);
      }
      return false;
    }
  }

  /// Stop a specific ambient sound track.
  Future<void> stopSound(String soundKey) async {
    final player = _players.remove(soundKey);
    if (player != null) {
      try {
        await player.stop();
        await player.dispose();
      } catch (_) {}
    }
  }

  /// Pauses all currently active sound tracks (e.g. when Pomodoro timer pauses).
  Future<void> pauseAll() async {
    _isPaused = true;
    for (final player in _players.values) {
      try {
        await player.pause();
      } catch (_) {}
    }
  }

  /// Resumes all currently active sound tracks (e.g. when Pomodoro timer resumes).
  Future<void> resumeAll() async {
    _isPaused = false;
    for (final player in _players.values) {
      try {
        await player.play();
      } catch (_) {}
    }
  }

  /// Stops all active sound tracks immediately (e.g. focus session hits 00:00,
  /// mode switches between 25+5 and 50+10, or timer is reset).
  Future<void> stopAll() async {
    _isPaused = false;
    final players = List<AudioPlayer>.from(_players.values);
    _players.clear();

    for (final player in players) {
      try {
        await player.stop();
        await player.dispose();
      } catch (_) {}
    }
  }

  /// Sets master volume for all active sound tracks.
  Future<void> setVolume(double val) async {
    _volume = val.clamp(0.0, 1.0);
    for (final player in _players.values) {
      try {
        await player.setVolume(_volume);
      } catch (_) {}
    }
  }

  /// Clean up all players on service disposal.
  void dispose() {
    stopAll();
  }
}
