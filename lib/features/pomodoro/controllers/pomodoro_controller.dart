import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/services/audio_player_service.dart';
import '../models/pomodoro_state.dart';

class PomodoroController extends ChangeNotifier {
  final AudioPlayerService _audioPlayer;

  PomodoroTimerMode _mode = PomodoroTimerMode.mode25_5;
  PomodoroPhase _phase = PomodoroPhase.focus;

  late int _remainingSeconds;
  late int _totalSeconds;

  bool _isRunning = false;
  bool _isPaused = false;
  Timer? _ticker;

  int _targetSessions = 4;
  int _completedSessions = 0;

  // Callbacks
  Function(String title, String message)? onNotification;
  Function(String soundKey)? onAssetMissingNotice;

  PomodoroController(this._audioPlayer) {
    _resetToCurrentMode();
    _audioPlayer.addListener(_onAudioServiceUpdate);
  }

  void _onAudioServiceUpdate() {
    notifyListeners();
  }

  // Pre-load all 7 audio tracks asynchronously
  Future<void> preloadSounds() async {
    await _audioPlayer.preloadAll(AmbientSound.values);
  }

  // Getters
  PomodoroTimerMode get mode => _mode;
  PomodoroPhase get phase => _phase;
  int get remainingSeconds => _remainingSeconds;
  int get totalSeconds => _totalSeconds;
  bool get isRunning => _isRunning;
  bool get isPaused => _isPaused;
  int get targetSessions => _targetSessions;
  int get completedSessions => _completedSessions;

  Set<AmbientSound> get activeSounds => AmbientSound.values
      .where((sound) => _audioPlayer.isSoundActive(sound.keyName))
      .toSet();

  double get volume => _audioPlayer.volume;
  bool get isPreloaded => _audioPlayer.isPreloaded;

  bool isSoundActive(AmbientSound sound) =>
      _audioPlayer.isSoundActive(sound.keyName);

  bool isSoundBuffering(AmbientSound sound) =>
      _audioPlayer.isSoundBuffering(sound.keyName);

  double get progress {
    if (_totalSeconds == 0) return 0.0;
    return (_totalSeconds - _remainingSeconds) / _totalSeconds;
  }

  String get formattedTime {
    final minutes = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _resetToCurrentMode() {
    _totalSeconds = _phase == PomodoroPhase.focus
        ? _mode.focusSeconds
        : _mode.breakSeconds;
    _remainingSeconds = _totalSeconds;
  }

  void setMode(PomodoroTimerMode newMode) {
    if (_mode == newMode) return;
    _mode = newMode;
    // Hard-stop all audio when mode changes (25+5 <-> 50+10)
    _audioPlayer.stopAll();
    if (!_isRunning) {
      _resetToCurrentMode();
    }
    notifyListeners();
  }

  void setTargetSessions(int sessions) {
    if (sessions < 1) return;
    _targetSessions = sessions;
    if (_completedSessions > _targetSessions) {
      _completedSessions = _targetSessions;
    }
    notifyListeners();
  }

  void start() {
    if (_isRunning && !_isPaused) return;

    _isRunning = true;
    _isPaused = false;
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), _onTick);

    // Resume or start active ambient audio if in focus phase
    if (_phase == PomodoroPhase.focus && _audioPlayer.hasActiveSounds) {
      _audioPlayer.resumeAll();
    }

    notifyListeners();
  }

  void pause() {
    if (!_isRunning || _isPaused) return;
    _isPaused = true;
    _ticker?.cancel();

    // Pause all ambient sounds in sync with timer
    _audioPlayer.pauseAll();

    notifyListeners();
  }

  void resume() {
    if (!_isRunning || !_isPaused) return;
    _isPaused = false;
    _ticker = Timer.periodic(const Duration(seconds: 1), _onTick);

    // Resume ambient sounds in sync with timer
    if (_phase == PomodoroPhase.focus && _audioPlayer.hasActiveSounds) {
      _audioPlayer.resumeAll();
    }

    notifyListeners();
  }

  void reset() {
    _ticker?.cancel();
    _isRunning = false;
    _isPaused = false;
    _phase = PomodoroPhase.focus;
    _resetToCurrentMode();

    // Stop and clear audio on timer reset
    _audioPlayer.stopAll();

    notifyListeners();
  }

  void _onTick(Timer timer) {
    if (_remainingSeconds > 0) {
      _remainingSeconds--;
      notifyListeners();
    } else {
      _handlePhaseComplete();
    }
  }

  void _handlePhaseComplete() {
    _ticker?.cancel();

    // The exact second focus session hits 00:00, immediately stop audio
    // preventing any sound from playing longer than the chosen 25m or 50m session.
    _audioPlayer.stopAll();

    if (_phase == PomodoroPhase.focus) {
      _completedSessions++;
      if (_completedSessions >= _targetSessions) {
        // All sessions completed
        _isRunning = false;
        _isPaused = false;
        _phase = PomodoroPhase.focus;
        _resetToCurrentMode();
        notifyListeners();
        if (onNotification != null) {
          onNotification!('all_sessions_done', 'all_sessions_done');
        }
        return;
      }

      // Switch to break
      _phase = PomodoroPhase.breakTime;
      _resetToCurrentMode();
      _isRunning = true;
      _isPaused = false;
      _ticker = Timer.periodic(const Duration(seconds: 1), _onTick);
      notifyListeners();

      if (onNotification != null) {
        onNotification!('session_complete_title', 'session_complete_msg');
      }
    } else {
      // Break is done, switch to next focus session
      _phase = PomodoroPhase.focus;
      _resetToCurrentMode();
      _isRunning = true;
      _isPaused = false;
      _ticker = Timer.periodic(const Duration(seconds: 1), _onTick);
      notifyListeners();
    }
  }

  // Multi-sound Ambient Audio Controls (Instant Zero-Lag Playback)
  Future<void> toggleAmbientSound(AmbientSound sound) async {
    if (_audioPlayer.isSoundActive(sound.keyName)) {
      await _audioPlayer.pauseSound(sound.keyName);
      return;
    }

    final success = await _audioPlayer.playSound(
      sound.keyName,
      assetPath: sound.assetPath,
      onAssetMissing: (soundKey) {
        if (onAssetMissingNotice != null) {
          onAssetMissingNotice!(soundKey);
        }
      },
    );

    // Only auto-pause if currently in break phase; during focus phase play immediately
    if (_phase != PomodoroPhase.focus) {
      await _audioPlayer.pauseAll();
    }

    if (!success && onAssetMissingNotice != null) {
      onAssetMissingNotice!(sound.keyName);
    }
  }

  Future<void> clearAllSounds() async {
    await _audioPlayer.stopAll();
  }

  Future<void> setVolume(double val) async {
    await _audioPlayer.setVolume(val);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _audioPlayer.removeListener(_onAudioServiceUpdate);
    _audioPlayer.stopAll();
    super.dispose();
  }
}
