class GitHubAudioFile {
  final String name;
  final String title;
  final String licence;
  final String source;

  GitHubAudioFile({
    required this.name,
    required this.title,
    required this.licence,
    required this.source,
  });

  factory GitHubAudioFile.fromJson(Map<String, dynamic> json) {
    return GitHubAudioFile(
      name: json['name'],
      title: json['title'],
      licence: json['licence'],
      source: json['source'],
    );
  }
}

class GitHubAudioFolder {
  final String folderName; // The directory name on GitHub
  final Map<String, GitHubAudioFolderLocalization> localizations;
  final String version;

  GitHubAudioFolder({
    required this.folderName,
    required this.localizations,
    required this.version,
  });

  factory GitHubAudioFolder.fromJson(String folderName, Map<String, dynamic> json) {
    final localizations = <String, GitHubAudioFolderLocalization>{};
    json.forEach((key, value) {
      if (key != 'version') {
        localizations[key] = GitHubAudioFolderLocalization.fromJson(value);
      }
    });

    return GitHubAudioFolder(
      folderName: folderName,
      localizations: localizations,
      version: json['version'] ?? '1.0.0',
    );
  }

  GitHubAudioFolderLocalization? getLocalization(String locale) {
    final normalizedLocale = locale.replaceAll('_', '-');
    // Try exact match (e.g., de-DE)
    if (localizations.containsKey(normalizedLocale)) {
      return localizations[normalizedLocale];
    }
    // Try language match (e.g., de)
    final lang = normalizedLocale.split('-').first;
    for (final key in localizations.keys) {
      if (key.startsWith(lang)) {
        return localizations[key];
      }
    }
    // Fallback to en-US or first available
    return localizations['en-US'] ?? (localizations.isNotEmpty ? localizations.values.first : null);
  }
}

class GitHubAudioFolderLocalization {
  final String title;
  final String description;
  final List<GitHubAudioFile> files;

  GitHubAudioFolderLocalization({
    required this.title,
    required this.description,
    required this.files,
  });

  factory GitHubAudioFolderLocalization.fromJson(Map<String, dynamic> json) {
    return GitHubAudioFolderLocalization(
      title: json['title'],
      description: json['description'],
      files: (json['files'] as List).map((f) => GitHubAudioFile.fromJson(f)).toList(),
    );
  }
}
