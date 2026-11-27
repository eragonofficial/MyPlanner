import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../../features/pomodoro/models/pomodoro_state.dart';

/// Audio player service supporting instant pre-buffering, multi-ambient sound mixing,
/// master volume control, and zero-lag playback synchronized with Pomodoro focus sessions.
class AudioPlayerService extends ChangeNotifier {
  final Map<String, AudioPlayer> _players = {};
  final Map<String, bool> _bufferingStates = {};
  final Set<String> _loadedSoundKeys = {};
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

  void _attachStateListener(String soundKey, AudioPlayer player) {
    player.playerStateStream.listen((playerState) {
      final isBuffering =
          playerState.processingState == ProcessingState.buffering ||
              playerState.processingState == ProcessingState.loading;
      if (_bufferingStates[soundKey] != isBuffering) {
        _bufferingStates[soundKey] = isBuffering;
        notifyListeners();
      }
    });
  }

  /// Registers and prepares all 7 ambient audio tracks in parallel on init.
  /// On Web, uses `preload: false` during setup so HTTP connections stay free
  /// and `play()` executes directly inside user tap gestures without autoplay blocking.
  Future<void> preloadAll(List<AmbientSound> sounds) async {
    if (_isPreloaded || _isPreloading) return;
    _isPreloading = true;

    await Future.wait(sounds.map((sound) async {
      if (_players.containsKey(sound.keyName) &&
          _loadedSoundKeys.contains(sound.keyName)) {
        return;
      }

      try {
        final player = _players[sound.keyName] ?? AudioPlayer();
        _players[sound.keyName] = player;
        _bufferingStates[sound.keyName] = !kIsWeb;
        _attachStateListener(sound.keyName, player);

        await player.setAsset(sound.assetPath, preload: !kIsWeb);
        await player.setLoopMode(LoopMode.one);
        await player.setVolume(_volume);
        _loadedSoundKeys.add(sound.keyName);
        _bufferingStates[sound.keyName] = false;
      } catch (e) {
        debugPrint('Audio preload notice (${sound.keyName}): $e');
        _bufferingStates[sound.keyName] = false;
      }
    }));

    _isPreloaded = true;
    _isPreloading = false;
    notifyListeners();
  }

  /// Plays an ambient sound track, calling `player.play()` before any `await`
  /// when pre-registered so Web browsers unlock audio within the user gesture.
  Future<bool> playSound(
    String soundKey, {
    String? assetPath,
    void Function(String soundName)? onAssetMissing,
  }) async {
    AudioPlayer? player = _players[soundKey];

    if (player != null && _loadedSoundKeys.contains(soundKey)) {
      _activeSoundKeys.add(soundKey);
      _isPaused = false;
      try {
        // Trigger play synchronously inside user gesture before any await
        final playFuture = player.play();
        notifyListeners();
        await playFuture;
        return true;
      } catch (e) {
        debugPrint('Audio play error ($soundKey): $e');
        return false;
      }
    }

    if (assetPath == null) return false;

    try {
      player ??= AudioPlayer();
      _players[soundKey] = player;
      _bufferingStates[soundKey] = true;
      _attachStateListener(soundKey, player);

      _activeSoundKeys.add(soundKey);
      _isPaused = false;
      notifyListeners();

      await player.setAsset(assetPath, preload: !kIsWeb);
      await player.setLoopMode(LoopMode.one);
      await player.setVolume(_volume);
      _loadedSoundKeys.add(soundKey);
      _bufferingStates[soundKey] = false;
      await player.play();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Audio asset notice ($assetPath): $e');
      _activeSoundKeys.remove(soundKey);
      _bufferingStates[soundKey] = false;
      notifyListeners();
      if (onAssetMissing != null) {
        onAssetMissing(soundKey);
      }
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
