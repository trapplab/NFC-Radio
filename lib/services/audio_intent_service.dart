import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/external_audio_file.dart';

class AudioIntentService {
  static const String _channelName = 'com.trapplab.nfc_radio/audio_picker';
  static const String _methodPickAudio = 'pickAudio';
  static const String _methodOnAudioPicked = 'onAudioPicked';

  static final AudioIntentService _instance = AudioIntentService._internal();
  factory AudioIntentService() => _instance;
  AudioIntentService._internal();

  final _audioPickedController = StreamController<ExternalAudioFile>.broadcast();
  Stream<ExternalAudioFile> get onAudioPicked => _audioPickedController.stream;

  MethodChannel? _channel;
  bool _isInitialized = false;

  void initialize() {
    if (_isInitialized) return;
    
    _channel = const MethodChannel(_channelName);
    _channel?.setMethodCallHandler(_handleMethodCall);
    _isInitialized = true;
    debugPrint('AudioIntentService initialized');
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    if (call.method == _methodOnAudioPicked) {
      final Map<dynamic, dynamic> args = call.arguments as Map<dynamic, dynamic>;
      final String filePath = args['filePath'] as String;
      final String? displayName = args['displayName'] as String?;
      
      final audioFile = ExternalAudioFile(
        sourceUri: Uri.file(filePath),
        displayName: displayName ?? filePath.split('/').last,
      );
      debugPrint('AudioIntentService: Picked audio - $audioFile');
      _audioPickedController.add(audioFile);
    }
    return null;
  }

  Future<bool> pickAudioFromApp() async {
    if (!_isInitialized) {
      initialize();
    }
    
    try {
      await _channel?.invokeMethod(_methodPickAudio);
      return true;
    } catch (e) {
      debugPrint('AudioIntentService: Error launching picker: $e');
      return false;
    }
  }

  void dispose() {
    _audioPickedController.close();
    _channel?.setMethodCallHandler(null);
    _isInitialized = false;
  }
}
