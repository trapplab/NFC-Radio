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
        onDiscovered: (NfcTag tag) async {
          _currentNfcUuid = tag.data['nfcid']?.toString();
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