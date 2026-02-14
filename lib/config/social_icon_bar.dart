import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'social_links.dart';

class SocialIconBar extends StatelessWidget {
  const SocialIconBar({super.key});

  Future<void> _launchUrl(String link) async {
    final Uri url = Uri.parse(link);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.coffee),
          tooltip: 'Buy Me a Coffee',
          onPressed: () => _launchUrl(SocialLinks.buyMeACoffee),
        ),
        IconButton(
          icon: const FaIcon(FontAwesomeIcons.github),
          tooltip: 'GitHub',
          onPressed: () => _launchUrl(SocialLinks.github),
        ),
      ],
    );
  }
}
