import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/app_localizations.dart';
import 'buy_me_a_coffee_settings.dart';

class BuyMeACoffeeWidget extends StatelessWidget {
  const BuyMeACoffeeWidget({super.key});

  // Buy Me a Coffee brand colors
  static const Color bmcYellow = Color(0xFFFFDD00);
  static const Color bmcBlue = Color(0xFF0D0C22);

  Future<void> _launchUrl(String link) async {
    final Uri url = Uri.parse(link);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bmcYellow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: bmcBlue, width: 2),
      ),
      child: InkWell(
        onTap: () => _launchUrl(BuyMeACoffeeSettings.link),
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            Icon(Icons.coffee, color: bmcBlue, size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.needNfcTagsTitle,
                style: TextStyle(
                  color: bmcBlue,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Icon(Icons.open_in_new, color: bmcBlue, size: 20),
          ],
        ),
      ),
    );
  }
}
