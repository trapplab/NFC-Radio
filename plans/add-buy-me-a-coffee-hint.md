# Plan: Add Buy Me a Coffee Hint in Settings Menu

## Overview
Add a hint section in the settings menu that links to a Buy Me a Coffee shop for users who need NFC tags. The hint will use Buy Me a Coffee branding colors and be fully internationalized. The link is configurable and the hint only shows when a link is set.

## Google Play Store Policy Compliance
✅ **Allowed** - Based on Google Play Store policies:
- The donation is optional and not required to use the app's core features
- The link is clearly labeled as a donation/support link
- The app does not mislead users about the purpose of the link
- The link does not bypass Google Play's billing system for premium features (the app already handles premium upgrades separately via IAP)

## Implementation Details

### 1. Add i10n Strings
Add the following strings to all language files (`lib/l10n/app_*.arb`):

```json
"needNfcTagsTitle": "Need NFC Tags? Checkout fan equipment here",
"buyMeACoffeeLink": "Buy Me a Coffee Link"
```

**Files to modify:**
- `lib/l10n/app_en.arb`
- `lib/l10n/app_de.arb`
- `lib/l10n/app_es.arb`
- `lib/l10n/app_fr.arb`
- `lib/l10n/app_it.arb`

### 2. Create Buy Me a Coffee Settings File
Create a new settings file `lib/config/buy_me_a_coffee_settings.dart` to store the Buy Me a Coffee link:

```dart
import 'package:flutter/material.dart';

class BuyMeACoffeeSettings {
  String link = '';

  BuyMeACoffeeSettings({this.link = ''});

  BuyMeACoffeeSettings copyWith({String? link}) {
    return BuyMeACoffeeSettings(
      link: link ?? this.link,
    );
  }
}
```

### 3. Create Buy Me a Coffee Widget
Create a new widget file `lib/config/buy_me_a_coffee_widget.dart` with:

```dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'l10n/app_localizations.dart';
import 'buy_me_a_coffee_settings.dart';

class BuyMeACoffeeWidget extends StatelessWidget {
  final BuyMeACoffeeSettings settings;

  const BuyMeACoffeeWidget({super.key, required this.settings});

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

    // Only show widget if link is configured
    if (settings.link.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bmcYellow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: bmcBlue, width: 2),
      ),
      child: InkWell(
        onTap: () => _launchUrl(settings.link),
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
```

### 4. Add Buy Me a Coffee Link Setting to Settings Drawer
Modify `lib/main.dart` to add a setting for configuring the Buy Me a Coffee link:

**Location:** In the `endDrawer` widget's ListView children, after the `ColorChooser` widget (around line 566)

**Note:** Both the ListTile (for setting the link) and the BuyMeACoffeeWidget (for showing the hint) are conditionally displayed - they only appear when the link is set.

```dart
// Add widget in ListView children (after ColorChooser, before Divider)
if (AppConfig.isGitHubRelease || AppConfig.isFdroidRelease)
  ListTile(
    title: Text(AppLocalizations.of(context)!.buyMeACoffeeLink),
    subtitle: Text(buyMeACoffeeSettings.link.isEmpty ? 'Not set' : buyMeACoffeeSettings.link),
    trailing: Icon(Icons.edit),
    onTap: () => _showBuyMeACoffeeLinkDialog(context),
  ),
const BuyMeACoffeeWidget(settings: buyMeACoffeeSettings),
```

### 5. Add Dialog for Setting Buy Me a Coffee Link
Add a new method in `lib/main.dart` to show a dialog for setting the Buy Me a Coffee link:

```dart
void _showBuyMeACoffeeLinkDialog(BuildContext context) {
  final TextEditingController linkController = TextEditingController(text: buyMeACoffeeSettings.link);

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(AppLocalizations.of(context)!.buyMeACoffeeLink),
      content: TextField(
        controller: linkController,
        decoration: InputDecoration(
          labelText: 'Link URL',
          hintText: buyMeACoffeeSettings.link,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context)!.cancel),
        ),
        TextButton(
          onPressed: () {
            if (linkController.text.isNotEmpty) {
              setState(() {
                buyMeACoffeeSettings = buyMeACoffeeSettings.copyWith(link: linkController.text);
              });
            }
            Navigator.pop(context);
          },
          child: Text(AppLocalizations.of(context)!.save),
        ),
      ],
    ),
  );
}
```

### 6. Generate Translation Files
Run the following command to generate translation files:

```bash
flutter gen-l10n
```

### 7. Update Changelog
Update `Changelog.md` with the new feature:

```markdown
## [0.13.0]

### Added
- Added Buy Me a Coffee hint in settings menu for users who need NFC tags
- Added configurable Buy Me a Coffee link setting (only shown when link is set)
```

## Testing Checklist
- [ ] Verify hint appears in settings menu when link is configured
- [ ] Verify hint does NOT appear when link is empty
- [ ] Verify link setting appears in settings (all flavors)
- [ ] Verify link can be set via dialog
- [ ] Verify link opens correctly in an external browser
- [ ] Verify colors match Buy Me a Coffee branding
- [ ] Test on all three flavors (GitHub, F-Droid, Google Play)
- [ ] Verify translations work for all supported languages (en, de, es, fr, it)
- [ ] Verify hint is clickable and responsive
- [ ] Verify hint does not interfere with other settings options

## Notes
- The Buy Me a Coffee link is stored in a settings file (`lib/config/buy_me_a_coffee_settings.dart`)
- The hint only displays when a link is set (empty link = no hint shown)
- The link setting is available on all flavors (GitHub, F-Droid, Google Play)
- The widget uses Buy Me a Coffee's brand colors (Yellow: `#FFDD00`, Blue: `#0D0C22`)
- The implementation is compliant with Google Play Store policies as it's an optional donation link that doesn't bypass the app's premium IAP system
- The settings file is a simple Dart class that can be easily modified or extended in the future
- The default URL hint in the dialog is loaded from the settings file (not hardcoded)
