import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'song.dart';

enum PlayerState { idle, playing, paused, stopped }

class MusicPlayer with ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  PlayerState _currentState = PlayerState.idle;
  Song? _currentSong;
  Duration _savedPosition = Duration.zero;
  bool _isSeeking = false;
  Duration _totalDuration = Duration.zero;

  // Callback to notify when position changes (for persisting to song)
  void Function(Duration)? onPositionChangedCallback;

  PlayerState get currentState => _currentState;
  bool get isPlaying => _currentState == PlayerState.playing;
  bool get isPaused => _currentState == PlayerState.paused;
  bool get isStopped => _currentState == PlayerState.stopped;
  bool get isSeeking => _isSeeking;
  String? get currentMusicFilePath => _currentSong?.filePath;
  String? get currentSongTitle => _currentSong?.title;
  Song? get currentSong => _currentSong;
  Duration get savedPosition => _savedPosition;
  Duration get totalDuration => _totalDuration;

  MusicPlayer() {
    _setupAudioPlayerListeners();
  }

  void setSeeking(bool seeking) {
    _isSeeking = seeking;
    if (!seeking) {
      // Small delay after seeking to allow the player to catch up 
      // and avoid jumping back to the old position
      Future.delayed(const Duration(milliseconds: 500), () {
        _isSeeking = false;
        notifyListeners();
      });
    } else {
      notifyListeners();
    }
  }

  void _setupAudioPlayerListeners() {
    _audioPlayer.onPlayerComplete.listen((_) {
      _currentState = PlayerState.stopped;
      _savedPosition = Duration.zero;
      
      // Reset song's saved position when finished
      if (_currentSong != null) {
        _currentSong!.savedPosition = Duration.zero;
        onPositionChangedCallback?.call(Duration.zero);
      }
      
      notifyListeners();
    });

    _audioPlayer.onDurationChanged.listen((duration) {
      _totalDuration = duration;
      notifyListeners();
    });

    _audioPlayer.onPositionChanged.listen((position) {
      // Only update position if not currently seeking to avoid slider jumping
      if (_currentState == PlayerState.playing && !_isSeeking) {
        _savedPosition = position;
        notifyListeners();
      }
    });
  }

  Future<void> playMusic(Song song) async {
    final musicFilePath = song.filePath;
    final songTitle = song.title;
    debugPrint('🎵 ===== MUSIC PLAYBACK STARTED =====');
    debugPrint('🎵 Target file: $musicFilePath');
    debugPrint('🎵 Title: $songTitle');
    debugPrint('🎵 Current path: ${_currentSong?.filePath}');
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
    if (_currentSong?.filePath == musicFilePath && _currentState == PlayerState.playing) {
      debugPrint('⏭️ Already playing this song, skipping');
      return;
    }

    // Save position of previous song if needed before switching
    if (_currentSong != null && _currentState == PlayerState.playing && _currentSong!.rememberPosition) {
      try {
        final pos = await _audioPlayer.getCurrentPosition();
        if (pos != null) {
          _currentSong!.savedPosition = pos;
          onPositionChangedCallback?.call(pos);
          debugPrint('💾 Saved previous song position: $pos');
        }
      } catch (e) {
        debugPrint('⚠️ Failed to save previous song position: $e');
      }
    }

    // Check if file exists (basic check)
    // Note: In a real app, you might want to do more robust file checking
    debugPrint('🔍 File path validation: $musicFilePath');

    // Update current song
    _currentSong = song;
    debugPrint('📍 Updated current song to: $songTitle');
    
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
    
    // Handle position remembering
    if (!song.rememberPosition) {
      _savedPosition = Duration.zero;
      debugPrint('🔄 Reset playback position to zero (position remembering disabled)');
    } else {
      // Use song's saved position if available, otherwise default to zero
      _savedPosition = song.savedPosition ?? Duration.zero;
      debugPrint('🔄 Using saved position: $_savedPosition (from song: ${song.savedPosition != null})');
    }
    
    // Attempt to play with retry mechanism
    try {
      debugPrint('▶️ Starting audio playback...');
      final Source source = musicFilePath.startsWith('content://') || musicFilePath.startsWith('http')
          ? UrlSource(musicFilePath)
          : DeviceFileSource(musicFilePath);
      
      debugPrint('📱 Setting source: $musicFilePath');
      await _audioPlayer.setSource(source);

      // Seek to saved position if needed before starting playback
      if (_savedPosition > Duration.zero) {
        debugPrint('🔍 Seeking to saved position: $_savedPosition');
        await _audioPlayer.seek(_savedPosition);
      }

      debugPrint('▶️ Resuming audio playback...');
      await _audioPlayer.resume();
      _currentState = PlayerState.playing;

      // Set loop mode based on song settings
      final releaseMode = song.isLoopEnabled ? ReleaseMode.loop : ReleaseMode.release;
      await _audioPlayer.setReleaseMode(releaseMode);
      debugPrint('🔄 Set release mode to: $releaseMode');

      debugPrint('✅ SUCCESS: Started playing $musicFilePath');
      debugPrint('📊 New player state: $_currentState');
      
    } catch (e, stackTrace) {
      debugPrint('❌ CRITICAL ERROR playing music: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      debugPrint('❌ File path that failed: $musicFilePath');
      
      // Set to idle state on failure
      _currentState = PlayerState.idle;
      _currentSong = null;
      
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
    debugPrint('▶️ Current path: ${_currentSong?.filePath}');
    debugPrint('▶️ Current state: $_currentState');
    debugPrint('▶️ Saved position: $_savedPosition');
    debugPrint('▶️ Timestamp: ${DateTime.now()}');

    if (_currentSong == null) {
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
      debugPrint('❌ Current path: ${_currentSong?.filePath}');
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
    debugPrint('⏸️ Current path: ${_currentSong?.filePath}');
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
        
        // Save to song if rememberPosition is enabled
        if (_currentSong != null && _currentSong!.rememberPosition) {
          _currentSong!.savedPosition = currentPosition;
          onPositionChangedCallback?.call(currentPosition);
        }
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
      debugPrint('❌ Current path: ${_currentSong?.filePath}');
      
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
      // Reset song's saved position in storage when manually stopped
      if (_currentSong != null) {
        _currentSong!.savedPosition = Duration.zero;
        onPositionChangedCallback?.call(Duration.zero);
      }
      
      await _audioPlayer.stop();
      _currentState = PlayerState.stopped;
      _currentSong = null;
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
    debugPrint('🔄 Current path: ${_currentSong?.filePath}');
    debugPrint('🔄 Saved position: $_savedPosition');
    debugPrint('🔄 Timestamp: ${DateTime.now()}');

    try {
      if (_currentState == PlayerState.playing) {
        debugPrint('🔄 Action: PAUSE (currently playing)');
        await pauseMusic();
      } else if (_currentState == PlayerState.paused) {
        debugPrint('🔄 Action: RESUME (currently paused)');
        await resumeMusic();
      } else if (_currentState == PlayerState.stopped && _currentSong != null) {
        debugPrint('🔄 Action: RESTART (currently stopped, have song)');
        await playMusic(_currentSong!);
      } else if (_currentState == PlayerState.idle && _currentSong != null) {
        debugPrint('🔄 Action: PLAY (currently idle, have song)');
        await playMusic(_currentSong!);
      } else {
        debugPrint('❌ No current music to play/resume');
        debugPrint('❌ State: $_currentState, Song: ${_currentSong?.title}');
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
      'currentMusicFilePath': _currentSong?.filePath,
      'currentSongTitle': _currentSong?.title,
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
    if (_currentSong != null) {
      debugPrint('🧪 - Is current song playing: ${isSongPlaying(_currentSong!.filePath)}');
      debugPrint('🧪 - Is current song paused: ${isSongPaused(_currentSong!.filePath)}');
      debugPrint('🧪 - Is current song stopped: ${isSongStopped(_currentSong!.filePath)}');
    }
    debugPrint('🧪 ===== END STATE TEST =====');
  }

  bool isSongPlaying(String songFilePath) {
    return _currentState == PlayerState.playing && _currentSong?.filePath == songFilePath;
  }

  bool isSongPaused(String songFilePath) {
    return _currentState == PlayerState.paused && _currentSong?.filePath == songFilePath;
  }

  bool isSongStopped(String songFilePath) {
    return (_currentState == PlayerState.stopped || _currentState == PlayerState.idle) &&
           _currentSong?.filePath == songFilePath;
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

  // Save current position to the song object and storage
  Future<void> saveCurrentPosition() async {
    if (_currentSong != null && _currentState == PlayerState.playing && _currentSong!.rememberPosition) {
      try {
        final pos = await _audioPlayer.getCurrentPosition();
        if (pos != null) {
          _savedPosition = pos;
          _currentSong!.savedPosition = pos;
          onPositionChangedCallback?.call(pos);
          debugPrint('💾 Manually saved current position: $pos');
        }
      } catch (e) {
        debugPrint('⚠️ Failed to manually save current position: $e');
      }
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  // Seek to specific position
  Future<void> seekTo(Duration position, {bool persist = false}) async {
    try {
      await _audioPlayer.seek(position);
      _savedPosition = position;
      
      if (persist && _currentSong != null && _currentSong!.rememberPosition) {
        _currentSong!.savedPosition = position;
        onPositionChangedCallback?.call(position);
      }
      
      debugPrint('MusicPlayer: Seeked to position $position (persist: $persist)');
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