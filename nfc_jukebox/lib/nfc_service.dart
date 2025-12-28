import 'package:nfc_manager/nfc_manager.dart';
import 'package:flutter/material.dart';

class NFCService with ChangeNotifier {
  bool _isNfcAvailable = false;
  String? _currentNfcUuid;

  bool get isNfcAvailable => _isNfcAvailable;
  String? get currentNfcUuid => _currentNfcUuid;

  NFCService() {
    _checkNfcAvailability();
  }

  Future<void> _checkNfcAvailability() async {
    _isNfcAvailable = await NfcManager.instance.isAvailable();
    notifyListeners();
  }

  Future<void> startNfcSession() async {
    if (!_isNfcAvailable) {
      debugPrint('NFC is not available on this device.');
      return;
    }

    try {
      await NfcManager.instance.startSession(
        pollingOptions: {NfcPollingOption.iso14443, NfcPollingOption.iso15693},
        onDiscovered: (NfcTag tag) async {
          // Access tag data using dynamic to bypass protected member restriction
          try {
            dynamic tagData = tag.data;
            if (tagData is Map && tagData.containsKey('nfcid')) {
              _currentNfcUuid = tagData['nfcid'].toString();
            } else {
              _currentNfcUuid = null;
            }
          } catch (e) {
            _currentNfcUuid = null;
            debugPrint('Error accessing NFC tag data: $e');
          }
          debugPrint('NFC UUID: $_currentNfcUuid');
          notifyListeners();
          await NfcManager.instance.stopSession();
        },
      );
    } catch (e) {
      debugPrint('Error starting NFC session: $e');
    }
  }

  Future<void> stopNfcSession() async {
    await NfcManager.instance.stopSession();
  }
}