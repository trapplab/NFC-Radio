import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

class MusicPlayer with ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  String? _currentMusicFilePath;

  bool get isPlaying => _isPlaying;
  String? get currentMusicFilePath => _currentMusicFilePath;

  Future<void> playMusic(String musicFilePath) async {
    if (_currentMusicFilePath == musicFilePath && _isPlaying) {
      return;
    }

    _currentMusicFilePath = musicFilePath;
    await _audioPlayer.stop();
    await _audioPlayer.play(DeviceFileSource(musicFilePath));
    _isPlaying = true;
    notifyListeners();
  }

  Future<void> pauseMusic() async {
    await _audioPlayer.pause();
    _isPlaying = false;
    notifyListeners();
  }

  Future<void> stopMusic() async {
    await _audioPlayer.stop();
    _isPlaying = false;
    _currentMusicFilePath = null;
    notifyListeners();
  }

  Future<void> togglePlayPause() async {
    if (_isPlaying) {
      await pauseMusic();
    } else {
      if (_currentMusicFilePath != null) {
        await _audioPlayer.resume();
        _isPlaying = true;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}