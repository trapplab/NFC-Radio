import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

enum PlayerState { idle, playing, paused, stopped }

class MusicPlayer with ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  PlayerState _currentState = PlayerState.idle;
  String? _currentMusicFilePath;
  String? _currentSongTitle;
  Duration _savedPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;

  PlayerState get currentState => _currentState;
  bool get isPlaying => _currentState == PlayerState.playing;
  bool get isPaused => _currentState == PlayerState.paused;
  bool get isStopped => _currentState == PlayerState.stopped;
  String? get currentMusicFilePath => _currentMusicFilePath;
  String? get currentSongTitle => _currentSongTitle;
  Duration get savedPosition => _savedPosition;
  Duration get totalDuration => _totalDuration;

  MusicPlayer() {
    _setupAudioPlayerListeners();
  }

  void _setupAudioPlayerListeners() {
    _audioPlayer.onPlayerComplete.listen((_) {
      _currentState = PlayerState.stopped;
      _savedPosition = Duration.zero;
      notifyListeners();
    });

    _audioPlayer.onDurationChanged.listen((duration) {
      _totalDuration = duration;
      notifyListeners();
    });

    _audioPlayer.onPositionChanged.listen((position) {
      if (_currentState == PlayerState.playing) {
        _savedPosition = position;
        notifyListeners();
      }
    });
  }

  Future<void> playMusic(String musicFilePath, {String? songTitle}) async {
    debugPrint('🎵 ===== MUSIC PLAYBACK STARTED =====');
    debugPrint('🎵 Target file: $musicFilePath');
    debugPrint('🎵 Song title: $songTitle');
    debugPrint('🎵 Current path: $_currentMusicFilePath');
    debugPrint('🎵 Current state: $_currentState');
    debugPrint('🎵 Timestamp: ${DateTime.now()}');
    
    // Validate file path
    if (musicFilePath.isEmpty) {
      debugPrint('❌ ERROR: Empty file path provided');
      _currentState = PlayerState.idle;
      notifyListeners();
      return;
    }
    
    // Check if already playing this song
    if (_currentMusicFilePath == musicFilePath && _currentState == PlayerState.playing) {
      debugPrint('⏭️ Already playing this song, skipping');
      return;
    }

    // Check if file exists (basic check)
    // Note: In a real app, you might want to do more robust file checking
    debugPrint('🔍 File path validation: $musicFilePath');
    
    // Update current music path and title
    _currentMusicFilePath = musicFilePath;
    _currentSongTitle = songTitle;
    debugPrint('📍 Updated current path to: $musicFilePath');
    
    // Stop any current playback with error handling
    if (_currentState != PlayerState.idle) {
      try {
        debugPrint('🛑 Stopping current playback...');
        await _audioPlayer.stop();
        debugPrint('✅ Successfully stopped previous playback');
      } catch (e) {
        debugPrint('⚠️ Warning while stopping previous playback: $e');
        // Continue anyway, don't let stop failure prevent new playback
      }
    }
    
    // Reset position when starting new song
    _savedPosition = Duration.zero;
    debugPrint('🔄 Reset playback position to zero');
    
    // Attempt to play with retry mechanism
    try {
      debugPrint('▶️ Starting audio playback...');
      if (musicFilePath.startsWith('content://') || musicFilePath.startsWith('http')) {
        debugPrint('📱 Using UrlSource for: $musicFilePath');
        await _audioPlayer.play(UrlSource(musicFilePath));
      } else {
        debugPrint('📱 Using DeviceFileSource for: $musicFilePath');
        await _audioPlayer.play(DeviceFileSource(musicFilePath));
      }
      _currentState = PlayerState.playing;
      debugPrint('✅ SUCCESS: Started playing $musicFilePath');
      debugPrint('📊 New player state: $_currentState');
      
    } catch (e, stackTrace) {
      debugPrint('❌ CRITICAL ERROR playing music: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      debugPrint('❌ File path that failed: $musicFilePath');
      
      // Set to idle state on failure
      _currentState = PlayerState.idle;
      _currentMusicFilePath = null;
      
      // Provide specific error messages based on common issues
      if (e.toString().contains('Permission') || e.toString().contains('permission')) {
        debugPrint('🚨 PERMISSION ERROR: App may not have file access permissions');
      } else if (e.toString().contains('not found') || e.toString().contains('No such file')) {
        debugPrint('🚨 FILE ERROR: Audio file not found or inaccessible');
      } else if (e.toString().contains('format') || e.toString().contains('codec')) {
        debugPrint('🚨 FORMAT ERROR: Audio file format may not be supported');
      } else {
        debugPrint('🚨 UNKNOWN ERROR: $e');
      }
    }
    
    debugPrint('🎵 ===== MUSIC PLAYBACK COMPLETED =====');
    notifyListeners();
  }

  Future<void> resumeMusic() async {
    debugPrint('▶️ ===== MUSIC RESUME STARTED =====');
    debugPrint('▶️ Current path: $_currentMusicFilePath');
    debugPrint('▶️ Current state: $_currentState');
    debugPrint('▶️ Saved position: $_savedPosition');
    debugPrint('▶️ Timestamp: ${DateTime.now()}');
    
    if (_currentMusicFilePath == null) {
      debugPrint('❌ ERROR: No current music to resume');
      return;
    }

    if (_currentState != PlayerState.paused) {
      debugPrint('⚠️ WARNING: Expected paused state, but got $_currentState');
      debugPrint('⚠️ This might indicate a state synchronization issue');
    }

    try {
      debugPrint('🔍 Seeking to saved position: $_savedPosition');
      await _audioPlayer.seek(_savedPosition);
      debugPrint('✅ Successfully seeked to position');
      
      debugPrint('▶️ Resuming audio playback...');
      await _audioPlayer.resume();
      _currentState = PlayerState.playing;
      
      debugPrint('✅ SUCCESS: Resumed playback from $_savedPosition');
      debugPrint('📊 New player state: $_currentState');
      
    } catch (e, stackTrace) {
      debugPrint('❌ CRITICAL ERROR resuming music: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      debugPrint('❌ Current path: $_currentMusicFilePath');
      debugPrint('❌ Attempted position: $_savedPosition');
      
      // Set to paused state on failure (safer than idle)
      _currentState = PlayerState.paused;
      
      // Provide specific error messages
      if (e.toString().contains('not prepared')) {
        debugPrint('🚨 PREPARATION ERROR: Audio player not prepared for this file');
      } else if (e.toString().contains('permission') || e.toString().contains('Permission')) {
        debugPrint('🚨 PERMISSION ERROR: App may not have file access permissions');
      } else {
        debugPrint('🚨 UNKNOWN ERROR: $e');
      }
    }
    
    debugPrint('▶️ ===== MUSIC RESUME COMPLETED =====');
    notifyListeners();
  }

  Future<void> pauseMusic() async {
    debugPrint('⏸️ ===== MUSIC PAUSE STARTED =====');
    debugPrint('⏸️ Current state: $_currentState');
    debugPrint('⏸️ Current path: $_currentMusicFilePath');
    debugPrint('⏸️ Timestamp: ${DateTime.now()}');
    
    if (_currentState != PlayerState.playing) {
      debugPrint('⚠️ WARNING: Expected playing state, but got $_currentState');
      debugPrint('⚠️ This might indicate a state synchronization issue');
    }

    try {
      // Get current position before pausing
      debugPrint('🔍 Getting current playback position...');
      final currentPosition = await _audioPlayer.getCurrentPosition();
      if (currentPosition != null) {
        _savedPosition = currentPosition;
        debugPrint('💾 Saved position: $_savedPosition');
      } else {
        debugPrint('⚠️ Warning: Could not get current position, using saved position: $_savedPosition');
      }
      
      debugPrint('⏸️ Pausing audio playback...');
      await _audioPlayer.pause();
      _currentState = PlayerState.paused;
      
      debugPrint('✅ SUCCESS: Paused playback at $_savedPosition');
      debugPrint('📊 New player state: $_currentState');
      
    } catch (e, stackTrace) {
      debugPrint('❌ CRITICAL ERROR pausing music: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      debugPrint('❌ Current path: $_currentMusicFilePath');
      
      // Keep current state on pause failure (don't change state if pause fails)
      debugPrint('⚠️ Keeping current state $_currentState due to pause failure');
      
      if (e.toString().contains('not playing')) {
        debugPrint('🚨 STATE ERROR: Audio player was not in playing state');
      } else {
        debugPrint('🚨 UNKNOWN ERROR: $e');
      }
    }
    
    debugPrint('⏸️ ===== MUSIC PAUSE COMPLETED =====');
    notifyListeners();
  }

  Future<void> stopMusic() async {
    try {
      await _audioPlayer.stop();
      _currentState = PlayerState.stopped;
      _currentMusicFilePath = null;
      _currentSongTitle = null;
      _savedPosition = Duration.zero;
      debugPrint('MusicPlayer: Stopped playback and cleared state');
    } catch (e) {
      debugPrint('MusicPlayer: Error stopping: $e');
    }
    notifyListeners();
  }

  Future<void> togglePlayPause() async {
    debugPrint('🔄 ===== MUSIC TOGGLE STARTED =====');
    debugPrint('🔄 Current state: $_currentState');
    debugPrint('🔄 Current path: $_currentMusicFilePath');
    debugPrint('🔄 Saved position: $_savedPosition');
    debugPrint('🔄 Timestamp: ${DateTime.now()}');
    
    try {
      if (_currentState == PlayerState.playing) {
        debugPrint('🔄 Action: PAUSE (currently playing)');
        await pauseMusic();
      } else if (_currentState == PlayerState.paused) {
        debugPrint('🔄 Action: RESUME (currently paused)');
        await resumeMusic();
      } else if (_currentState == PlayerState.stopped && _currentMusicFilePath != null) {
        debugPrint('🔄 Action: RESTART (currently stopped, have file)');
        await playMusic(_currentMusicFilePath!, songTitle: _currentSongTitle);
      } else if (_currentState == PlayerState.idle && _currentMusicFilePath != null) {
        debugPrint('🔄 Action: PLAY (currently idle, have file)');
        await playMusic(_currentMusicFilePath!, songTitle: _currentSongTitle);
      } else {
        debugPrint('❌ No current music to play/resume');
        debugPrint('❌ State: $_currentState, Path: $_currentMusicFilePath');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ CRITICAL ERROR in togglePlayPause: $e');
      debugPrint('❌ Stack trace: $stackTrace');
    }
    
    debugPrint('🔄 ===== MUSIC TOGGLE COMPLETED =====');
  }

  // Enhanced debug method to get comprehensive player status
  Map<String, dynamic> getDetailedStatus() {
    return {
      'currentState': _currentState.toString(),
      'currentMusicFilePath': _currentMusicFilePath,
      'isPlaying': isPlaying,
      'isPaused': isPaused,
      'isStopped': isStopped,
      'savedPosition': _savedPosition.toString(),
      'totalDuration': _totalDuration.toString(),
      'audioPlayerState': _audioPlayer.state.toString(),
      'timestamp': DateTime.now().toString(),
    };
  }

  // Test method to simulate different states
  void simulateStateTest() {
    debugPrint('🧪 ===== MUSIC PLAYER STATE TEST =====');
    debugPrint('🧪 Current detailed status: ${getDetailedStatus()}');
    debugPrint('🧪 Test scenarios:');
    debugPrint('🧪 - Is song playing (null path): ${isSongPlaying('null')}');
    debugPrint('🧪 - Is song paused (null path): ${isSongPaused('null')}');
    debugPrint('🧪 - Is song stopped (null path): ${isSongStopped('null')}');
    if (_currentMusicFilePath != null) {
      debugPrint('🧪 - Is current song playing: ${isSongPlaying(_currentMusicFilePath!)}');
      debugPrint('🧪 - Is current song paused: ${isSongPaused(_currentMusicFilePath!)}');
      debugPrint('🧪 - Is current song stopped: ${isSongStopped(_currentMusicFilePath!)}');
    }
    debugPrint('🧪 ===== END STATE TEST =====');
  }

  bool isSongPlaying(String songFilePath) {
    return _currentState == PlayerState.playing && _currentMusicFilePath == songFilePath;
  }

  bool isSongPaused(String songFilePath) {
    return _currentState == PlayerState.paused && _currentMusicFilePath == songFilePath;
  }

  bool isSongStopped(String songFilePath) {
    return (_currentState == PlayerState.stopped || _currentState == PlayerState.idle) && 
           _currentMusicFilePath == songFilePath;
  }

  // Get formatted duration string
  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    
    if (duration.inHours > 0) {
      return '$hours:$minutes:$seconds';
    } else {
      return '$minutes:$seconds';
    }
  }

  // Get current position as formatted string
  String getCurrentPositionString() {
    return formatDuration(_savedPosition);
  }

  // Get total duration as formatted string
  String getTotalDurationString() {
    return formatDuration(_totalDuration);
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  // Seek to specific position
  Future<void> seekTo(Duration position) async {
    try {
      await _audioPlayer.seek(position);
      _savedPosition = position;
      debugPrint('MusicPlayer: Seeked to position $position');
      notifyListeners();
    } catch (e) {
      debugPrint('MusicPlayer: Error seeking: $e');
    }
  }

  // Get current playback position
  Future<Duration?> getCurrentPosition() async {
    try {
      return await _audioPlayer.getCurrentPosition();
    } catch (e) {
      debugPrint('MusicPlayer: Error getting position: $e');
      return null;
    }
  }
}