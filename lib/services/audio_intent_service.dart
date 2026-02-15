import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/external_audio_file.dart';

class AudioIntentService {
  static const String _channelName = 'com.trapplab.nfc_radio/audio_picker';
  static const String _methodPickAudio = 'pickAudio';

  static final AudioIntentService _instance = AudioIntentService._internal();
  factory AudioIntentService() => _instance;
  AudioIntentService._internal();

  MethodChannel? _channel;
  bool _isInitialized = false;

  void initialize() {
    if (_isInitialized) return;
    _channel = const MethodChannel(_channelName);
    _isInitialized = true;
    debugPrint('AudioIntentService initialized');
  }

  /// Opens the audio file picker and returns the list of files the user selected.
  /// Returns an empty list if cancelled or on error.
  Future<List<ExternalAudioFile>> pickAudioFromApp({bool filterAudioOnly = false}) async {
    if (!_isInitialized) {
      initialize();
    }
    try {
      final result = await _channel?.invokeMethod(_methodPickAudio, {
        'filterAudioOnly': filterAudioOnly,
      });
      if (result == null) return [];
      final List<dynamic> files = result as List<dynamic>;
      return files.map((item) {
        final Map<dynamic, dynamic> fileMap = item as Map<dynamic, dynamic>;
        final String filePath = fileMap['filePath'] as String;
        final String? displayName = fileMap['displayName'] as String?;
        debugPrint('AudioIntentService: Picked audio - $filePath');
        return ExternalAudioFile(
          sourceUri: Uri.file(filePath),
          displayName: displayName ?? filePath.split('/').last,
        );
      }).toList();
    } catch (e) {
      debugPrint('AudioIntentService: Error picking audio: $e');
      return [];
    }
  }

  Future<bool> openApp(String packageName) async {
    if (!_isInitialized) {
      initialize();
    }
    
    try {
      final bool? success = await _channel?.invokeMethod<bool>('openApp', {
        'packageName': packageName,
      });
      return success ?? false;
    } catch (e) {
      debugPrint('AudioIntentService: Error opening app $packageName: $e');
      return false;
    }
  }

  void dispose() {
    _isInitialized = false;
  }
}
