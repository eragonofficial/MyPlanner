import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../../features/pomodoro/models/pomodoro_state.dart';

/// Audio player service supporting instant pre-buffering, multi-ambient sound mixing,
/// master volume control, and zero-lag playback synchronized with Pomodoro focus sessions.
class AudioPlayerService extends ChangeNotifier {
  final Map<String, AudioPlayer> _players = {};
  final Map<String, bool> _bufferingStates = {};
  final Set<String> _activeSoundKeys = {};

  double _volume = 0.7;
  bool _isPaused = false;
  bool _isPreloading = false;
  bool _isPreloaded = false;

  double get volume => _volume;
  bool get hasActiveSounds => _activeSoundKeys.isNotEmpty;
  Set<String> get activeSoundKeys => Set.unmodifiable(_activeSoundKeys);
  bool get isPaused => _isPaused;
  bool get isPreloaded => _isPreloaded;

  bool isSoundActive(String soundKey) => _activeSoundKeys.contains(soundKey);

  bool isSoundBuffering(String soundKey) => _bufferingStates[soundKey] == true;

  /// Pre-buffers all 7 ambient audio tracks asynchronously on screen init
  /// so tapping any sound icon triggers instant playback with zero decoding delay.
  Future<void> preloadAll(List<AmbientSound> sounds) async {
    if (_isPreloaded || _isPreloading) return;
    _isPreloading = true;

    for (final sound in sounds) {
      if (_players.containsKey(sound.keyName)) continue;

      try {
        final player = AudioPlayer();
        _players[sound.keyName] = player;
        _bufferingStates[sound.keyName] = true;

        player.playerStateStream.listen((playerState) {
          final isBuffering =
              playerState.processingState == ProcessingState.buffering ||
                  playerState.processingState == ProcessingState.loading;
          if (_bufferingStates[sound.keyName] != isBuffering) {
            _bufferingStates[sound.keyName] = isBuffering;
            notifyListeners();
          }
        });

        await player.setLoopMode(LoopMode.one);
        await player.setVolume(_volume);
        // Preload asset immediately into memory/decoder
        await player.setAsset(sound.assetPath, preload: true);
        _bufferingStates[sound.keyName] = false;
      } catch (e) {
        debugPrint('Audio preload notice (${sound.keyName}): $e');
        _bufferingStates[sound.keyName] = false;
      }
    }

    _isPreloaded = true;
    _isPreloading = false;
    notifyListeners();
  }

  /// Plays a preloaded ambient sound track with ZERO latency.
  Future<bool> playSound(
    String soundKey, {
    String? assetPath,
    void Function(String soundName)? onAssetMissing,
  }) async {
    AudioPlayer? player = _players[soundKey];

    // Fallback if not yet preloaded
    if (player == null) {
      if (assetPath == null) return false;
      try {
        player = AudioPlayer();
        _players[soundKey] = player;
        _bufferingStates[soundKey] = true;

        player.playerStateStream.listen((playerState) {
          final isBuffering =
              playerState.processingState == ProcessingState.buffering ||
                  playerState.processingState == ProcessingState.loading;
          if (_bufferingStates[soundKey] != isBuffering) {
            _bufferingStates[soundKey] = isBuffering;
            notifyListeners();
          }
        });

        await player.setLoopMode(LoopMode.one);
        await player.setVolume(_volume);
        await player.setAsset(assetPath, preload: true);
        _bufferingStates[soundKey] = false;
      } catch (e) {
        debugPrint('Audio asset notice ($assetPath): $e');
        _bufferingStates[soundKey] = false;
        if (onAssetMissing != null) {
          onAssetMissing(soundKey);
        }
        return false;
      }
    }

    _activeSoundKeys.add(soundKey);
    _isPaused = false;
    notifyListeners();

    try {
      await player.play();
      return true;
    } catch (e) {
      debugPrint('Audio play error ($soundKey): $e');
      return false;
    }
  }

  /// Pauses a specific ambient sound track without disposing the preloaded player.
  Future<void> pauseSound(String soundKey) async {
    _activeSoundKeys.remove(soundKey);
    notifyListeners();

    final player = _players[soundKey];
    if (player != null) {
      try {
        await player.pause();
        await player.seek(Duration.zero);
      } catch (_) {}
    }
  }

  /// Pauses all currently active sound tracks in sync with Pomodoro timer pause.
  Future<void> pauseAll() async {
    _isPaused = true;
    notifyListeners();

    for (final soundKey in _activeSoundKeys) {
      final player = _players[soundKey];
      if (player != null) {
        try {
          await player.pause();
        } catch (_) {}
      }
    }
  }

  /// Resumes all currently active sound tracks in sync with Pomodoro timer resume.
  Future<void> resumeAll() async {
    _isPaused = false;
    notifyListeners();

    for (final soundKey in _activeSoundKeys) {
      final player = _players[soundKey];
      if (player != null) {
        try {
          await player.play();
        } catch (_) {}
      }
    }
  }

  /// Stops all active sound tracks immediately (focus countdown hits 00:00,
  /// mode switches between 25+5 and 50+10, or timer is reset).
  Future<void> stopAll() async {
    _isPaused = false;
    final keys = List<String>.from(_activeSoundKeys);
    _activeSoundKeys.clear();
    notifyListeners();

    for (final soundKey in keys) {
      final player = _players[soundKey];
      if (player != null) {
        try {
          await player.pause();
          await player.seek(Duration.zero);
        } catch (_) {}
      }
    }
  }

  /// Sets master volume for all preloaded players.
  Future<void> setVolume(double val) async {
    _volume = val.clamp(0.0, 1.0);
    for (final player in _players.values) {
      try {
        await player.setVolume(_volume);
      } catch (_) {}
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _activeSoundKeys.clear();
    for (final player in _players.values) {
      try {
        player.dispose();
      } catch (_) {}
    }
    _players.clear();
    super.dispose();
  }
}
