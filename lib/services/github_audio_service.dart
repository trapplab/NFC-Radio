import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../models/github_audio_folder.dart';

class GitHubAudioService {
  static const String _baseUrl = 'https://api.github.com/repos/trapplab/NFC-Radio-audiofiles/contents/audio';
  static const String _rawBaseUrl = 'https://raw.githubusercontent.com/trapplab/NFC-Radio-audiofiles/main/audio';

  /// Fetch all folders from the GitHub repository
  static Future<List<GitHubAudioFolder>> fetchFolders() async {
    try {
      final response = await http.get(Uri.parse(_baseUrl));
      if (response.statusCode == 200) {
        final List<dynamic> contents = json.decode(response.body);
        final List<GitHubAudioFolder> folders = [];

        for (final item in contents) {
          if (item['type'] == 'dir') {
            final folderName = item['name'];
            final folderInfo = await _fetchFolderInfo(folderName);
            if (folderInfo != null) {
              folders.add(folderInfo);
            }
          }
        }
        return folders;
      } else {
        throw Exception('Failed to load folders: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching GitHub folders: $e');
      rethrow;
    }
  }

  /// Fetch info.json for a specific folder
  static Future<GitHubAudioFolder?> _fetchFolderInfo(String folderName) async {
    try {
      final response = await http.get(Uri.parse('$_rawBaseUrl/$folderName/info.json'));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return GitHubAudioFolder.fromJson(folderName, data);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching info.json for $folderName: $e');
      return null;
    }
  }

  /// Download an audio file and return the local path and file size
  static Future<DownloadResult> downloadAudioFile(String folderName, String fileName) async {
    try {
      final url = '$_rawBaseUrl/$folderName/$fileName';
      debugPrint('📥 Downloading: $url');
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final directory = await getApplicationDocumentsDirectory();
        final audioDir = Directory(p.join(directory.path, 'audio_templates', folderName));
        if (!await audioDir.exists()) {
          await audioDir.create(recursive: true);
        }

        final filePath = p.join(audioDir.path, fileName);
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);
        final fileSize = response.bodyBytes.length;
        return DownloadResult(path: filePath, sizeBytes: fileSize);
      } else {
        throw Exception('Failed to download audio file (HTTP ${response.statusCode}): $fileName');
      }
    } catch (e) {
      debugPrint('Error downloading audio file $fileName: $e');
      rethrow;
    }
  }
}

/// Result of a file download operation
class DownloadResult {
  final String path;
  final int sizeBytes;

  DownloadResult({required this.path, required this.sizeBytes});
}
