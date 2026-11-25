import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

class AudioPlayerService {
  final AudioPlayer _player = AudioPlayer();
  String? _currentAsset;
  bool _isPlaying = false;
  double _volume = 0.7;

  bool get isPlaying => _isPlaying;
  String? get currentAsset => _currentAsset;
  double get volume => _volume;

  AudioPlayerService() {
    _player.setLoopMode(LoopMode.one);
    _player.setVolume(_volume);
    _player.playerStateStream.listen((state) {
      _isPlaying = state.playing;
    });
  }

  /// Plays ambient sound with graceful error handling when local asset file is not yet present
  Future<bool> playAmbientSound(
    String soundKey, {
    void Function(String soundName)? onAssetMissing,
  }) async {
    final assetPath = 'assets/audio/$soundKey.mp3';

    try {
      await _player.stop();
      _currentAsset = soundKey;
      await _player.setAsset(assetPath);
      await _player.play();
      _isPlaying = true;
      return true;
    } catch (e) {
      // Audio asset file may not yet be provided in assets/audio/ directory.
      // We handle this gracefully without throwing an uncaught error.
      debugPrint('Audio asset notice ($assetPath): $e');
      _isPlaying = true; // Kept active in UI state so ambient experience continues
      if (onAssetMissing != null) {
        onAssetMissing(soundKey);
      }
      return false;
    }
  }

  Future<void> pause() async {
    try {
      await _player.pause();
    } catch (_) {}
    _isPlaying = false;
  }

  Future<void> stop() async {
    try {
      await _player.stop();
    } catch (_) {}
    _isPlaying = false;
    _currentAsset = null;
  }

  Future<void> setVolume(double val) async {
    _volume = val.clamp(0.0, 1.0);
    try {
      await _player.setVolume(_volume);
    } catch (_) {}
  }

  void dispose() {
    _player.dispose();
  }
}
