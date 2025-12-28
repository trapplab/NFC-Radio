import 'package:flutter/material.dart';

class NFCMusicMapping {
  final String nfcUuid;
  final String musicFilePath;

  NFCMusicMapping({
    required this.nfcUuid,
    required this.musicFilePath,
  });

  // Convert the mapping to a JSON map
  Map<String, dynamic> toJson() => {
    'nfcUuid': nfcUuid,
    'musicFilePath': musicFilePath,
  };

  // Create a mapping from a JSON map
  factory NFCMusicMapping.fromJson(Map<String, dynamic> json) => NFCMusicMapping(
    nfcUuid: json['nfcUuid'],
    musicFilePath: json['musicFilePath'],
  );
}

class NFCMusicMappingProvider with ChangeNotifier {
  final List<NFCMusicMapping> _mappings = [];

  List<NFCMusicMapping> get mappings => _mappings;

  void addMapping(NFCMusicMapping mapping) {
    _mappings.add(mapping);
    notifyListeners();
  }

  void removeMapping(String nfcUuid) {
    _mappings.removeWhere((mapping) => mapping.nfcUuid == nfcUuid);
    notifyListeners();
  }

  String? getMusicFilePath(String nfcUuid) {
    final mapping = _mappings.firstWhere(
      (mapping) => mapping.nfcUuid == nfcUuid,
      orElse: () => NFCMusicMapping(nfcUuid: '', musicFilePath: ''),
    );
    return mapping.musicFilePath.isNotEmpty ? mapping.musicFilePath : null;
  }
}