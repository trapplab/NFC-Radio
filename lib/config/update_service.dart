import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:version/version.dart';
import 'package:url_launcher/url_launcher.dart';
import 'config.dart';

Version _parseVersion(String tagName, {bool isLocal = false}) {
  // Remove 'v' prefix if present
  String cleaned = tagName.replaceFirst('v', '');
  
  // For local version, remove flavor suffix (e.g., "-github" from "0.7.6-github")
  if (isLocal) {
    cleaned = cleaned.split('-').first;
  }
  
  // Check if it's just a build number (single number)
  if (RegExp(r'^[0-9]+$').hasMatch(cleaned)) {
    // Convert build number to version format (e.g., 706 -> 0.0.706)
    cleaned = '0.0.$cleaned';
  }
  
  return Version.parse(cleaned);
}

class UpdateService {
  static Future<void> checkGithubUpdate(BuildContext context, String owner, String repo, {bool manual = false}) async {
    // Only check for updates if this is a GitHub release
    if (!AppConfig.isGitHubRelease) {
      debugPrint('Update check skipped: Not a GitHub release');
      return;
    }

    try {
      final response = await http.get(Uri.parse('https://api.github.com/repos/$owner/$repo/releases/latest'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final remoteVersion = _parseVersion(data['tag_name']);
        final localInfo = await PackageInfo.fromPlatform();
        final localVersion = _parseVersion(localInfo.version, isLocal: true);

        if (remoteVersion > localVersion) {
          final releaseUrl = data['html_url'];
          
          if (!context.mounted) return;

          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Update v$remoteVersion available'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('A new version is available on GitHub.'),
                    const SizedBox(height: 16),
                    const Text('Changelog:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(data['body'] ?? 'No changelog provided.'),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Later'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final url = Uri.parse(releaseUrl);
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url, mode: LaunchMode.externalApplication);
                    }
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text('Download'),
                ),
              ],
            ),
          );
        } else if (manual) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You are on the latest version.')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error checking for updates: $e');
      if (manual && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error checking for updates: $e')),
        );
      }
    }
  }
}
