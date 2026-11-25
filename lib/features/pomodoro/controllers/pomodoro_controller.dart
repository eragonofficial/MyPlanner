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

  AmbientSound _activeSound = AmbientSound.none;

  // Callbacks
  Function(String title, String message)? onNotification;
  Function(String soundKey)? onAssetMissingNotice;

  PomodoroController(this._audioPlayer) {
    _resetToCurrentMode();
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
  AmbientSound get activeSound => _activeSound;
  double get volume => _audioPlayer.volume;

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
    notifyListeners();
  }

  void pause() {
    if (!_isRunning || _isPaused) return;
    _isPaused = true;
    _ticker?.cancel();
    notifyListeners();
  }

  void resume() {
    if (!_isRunning || !_isPaused) return;
    _isPaused = false;
    _ticker = Timer.periodic(const Duration(seconds: 1), _onTick);
    notifyListeners();
  }

  void reset() {
    _ticker?.cancel();
    _isRunning = false;
    _isPaused = false;
    _phase = PomodoroPhase.focus;
    _resetToCurrentMode();
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

  // Ambient Audio
  Future<void> setAmbientSound(AmbientSound sound) async {
    if (_activeSound == sound) {
      // Tapping active sound toggles off
      _activeSound = AmbientSound.none;
      await _audioPlayer.stop();
      notifyListeners();
      return;
    }

    _activeSound = sound;
    notifyListeners();

    if (sound == AmbientSound.none) {
      await _audioPlayer.stop();
    } else {
      await _audioPlayer.playAmbientSound(
        sound.keyName,
        onAssetMissing: (soundKey) {
          if (onAssetMissingNotice != null) {
            onAssetMissingNotice!(soundKey);
          }
        },
      );
    }
    notifyListeners();
  }

  Future<void> setVolume(double val) async {
    await _audioPlayer.setVolume(val);
    notifyListeners();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }
}
