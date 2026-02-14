import 'dart:async';
import 'package:flutter/material.dart';
import 'music_player.dart';

class SleepTimerService with ChangeNotifier {
  Timer? _timer;
  Duration _remainingDuration = Duration.zero;
  bool _isActive = false;
  MusicPlayer? _musicPlayer;

  bool get isActive => _isActive;
  Duration get remainingDuration => _remainingDuration;

  void setMusicPlayer(MusicPlayer player) {
    _musicPlayer = player;
  }

  void start(Duration duration) {
    cancel();
    _remainingDuration = duration;
    _isActive = true;
    debugPrint('😴 Sleep timer started: ${duration.inMinutes} minutes');
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _remainingDuration -= const Duration(seconds: 1);
      if (_remainingDuration <= Duration.zero) {
        _onTimerComplete();
      } else {
        notifyListeners();
      }
    });
    notifyListeners();
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
    if (_isActive) {
      debugPrint('😴 Sleep timer cancelled');
    }
    _isActive = false;
    _remainingDuration = Duration.zero;
    notifyListeners();
  }

  void pause() {
    _timer?.cancel();
    _timer = null;
    debugPrint('😴 Sleep timer paused with ${_remainingDuration.inSeconds}s remaining');
    // Keep _isActive true and _remainingDuration intact so we can resume
  }

  void resume() {
    if (!_isActive || _remainingDuration <= Duration.zero || _timer != null) return;
    debugPrint('😴 Sleep timer resumed with ${_remainingDuration.inSeconds}s remaining');
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _remainingDuration -= const Duration(seconds: 1);
      if (_remainingDuration <= Duration.zero) {
        _onTimerComplete();
      } else {
        notifyListeners();
      }
    });
  }

  void _onTimerComplete() {
    debugPrint('😴 Sleep timer completed - pausing music');
    _timer?.cancel();
    _timer = null;
    _isActive = false;
    _remainingDuration = Duration.zero;
    _musicPlayer?.pauseMusic();
    notifyListeners();
  }

  String formatRemaining() {
    final minutes = _remainingDuration.inMinutes;
    final seconds = _remainingDuration.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Check if auto sleep timer should activate based on settings.
  bool shouldAutoEnable({
    required bool autoEnabled,
    required bool restrictHours,
    required int startHour,
    required int endHour,
  }) {
    if (!autoEnabled) return false;
    if (!restrictHours) return true;

    final currentHour = DateTime.now().hour;
    if (startHour > endHour) {
      // Crosses midnight (e.g., 19-6 means 7PM to 6AM)
      return currentHour >= startHour || currentHour < endHour;
    } else {
      // Same day range (e.g., 22-23)
      return currentHour >= startHour && currentHour < endHour;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
