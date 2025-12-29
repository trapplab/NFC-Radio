import 'dart:typed_data';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class NFCService with ChangeNotifier {
  bool _isNfcAvailable = false;
  String? _currentNfcUuid;
  bool _isScanning = false;

  bool get isNfcAvailable => _isNfcAvailable;
  String? get currentNfcUuid => _currentNfcUuid;
  bool get isScanning => _isScanning;

  NFCService() {
    _checkNfcAvailability();
  }

  Future<void> _checkNfcAvailability() async {
    _isNfcAvailable = await NfcManager.instance.isAvailable();
    
    // Request permission on Android 13+ (API 33+)
    if (_isNfcAvailable) {
      await _requestNfcPermission();
    }
    
    notifyListeners();
  }

  Future<bool> _requestNfcPermission() async {
    try {
      // For Android 13+ (API 33+), we need to request NEARBY_WIFI_DEVICES permission
      final status = await Permission.nearbyWifiDevices.status;
      if (!status.isGranted) {
        final result = await Permission.nearbyWifiDevices.request();
        return result.isGranted;
      }
      return true;
    } catch (e) {
      debugPrint('Error requesting NFC permission: $e');
      return false;
    }
  }

  String? _extractNfcIdentifier(NfcTag tag) {
    try {
      final tagData = tag.data as dynamic;
      debugPrint('Tag type: ${tagData.runtimeType}');
      
      // Method 1: Try direct tag ID (most common)
      try {
        final id = tagData.id;
        if (id is Uint8List) {
          final uid = id.map((b) => b.toRadixString(16).padLeft(2, '0')).join(':');
          debugPrint('ID found: $uid');
          return uid;
        }
      } catch (e) {}
      
      // Method 2: Try tag.identifier
      try {
        final id = tagData.identifier;
        if (id is Uint8List) {
          final uid = id.map((b) => b.toRadixString(16).padLeft(2, '0')).join(':');
          debugPrint('Identifier found: $uid');
          return uid;
        }
      } catch (e) {}
      
      // Method 3: Try accessing via Map.from
      try {
        final map = Map<String, dynamic>.from(tagData as Map);
        debugPrint('Map keys: ${map.keys}');
        if (map['nfca'] != null) {
          final nfca = map['nfca'] as Map<String, dynamic>;
          final uidBytes = nfca['identifier'] as Uint8List;
          final uid = uidBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(':');
          return uid;
        }
      } catch (e) {
        debugPrint('Map conversion failed: $e');
      }
      
    } catch (e, s) {
      debugPrint('Error: $e');
    }
    return null;
  }




  Future<void> startNfcSession() async {
    if (!_isNfcAvailable) {
      debugPrint('NFC is not available on this device.');
      return;
    }

    // Request permission before starting session
    await _requestNfcPermission();

    _isScanning = true;
    notifyListeners();

    try {
      await NfcManager.instance.startSession(
        pollingOptions: {NfcPollingOption.iso14443, NfcPollingOption.iso15693},
        onDiscovered: (NfcTag tag) async {
          try {
            _currentNfcUuid = _extractNfcIdentifier(tag);
            debugPrint('NFC UUID: $_currentNfcUuid');
          } catch (e, s) {
            _currentNfcUuid = null;
            debugPrint('Error accessing NFC tag data: $e');
            debugPrint('Stack trace: $s');
          } finally {
            _isScanning = false;
            notifyListeners();
            await NfcManager.instance.stopSession();
          }
        },
      );
    } catch (e) {
      debugPrint('Error starting NFC session: $e');
      _isScanning = false;
      notifyListeners();
    }
  }

  Future<void> stopNfcSession() async {
    _isScanning = false;
    notifyListeners();
    await NfcManager.instance.stopSession();
  }
}
