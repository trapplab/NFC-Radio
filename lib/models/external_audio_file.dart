class ExternalAudioFile {
  final Uri sourceUri;
  final String? mimeType;
  final String? displayName;

  ExternalAudioFile({
    required this.sourceUri,
    this.mimeType,
    this.displayName,
  });

  @override
  String toString() {
    return 'ExternalAudioFile(sourceUri: $sourceUri, mimeType: $mimeType, displayName: $displayName)';
  }
}
