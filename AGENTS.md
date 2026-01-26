# Architecture

## Requirements
* audio files are organized in folders
* only one folder can be opened at a time, but all can be closed
* NFC UIDs are used to be mapped to a audio file
* within one folder, only one NFC UID can be mapped to one audio file
* NFC UIDs can be mapped to multiple audio files across different folders

## Flavours
The app can be built with three flavors:

* **Github**:
  * Contains all features, checks for updates on the Github release page.
  * Access: INTERNET, NFC
* **F-Droid**:
  * Contains all features, gets updates from the F-Droid store.
  * Access: NFC
* **Google Play**:
  * Limited features, extended features can be unlocked with a purchase. Gets updates from the Google Play Store.
  * Access: INTERNET, NFC

## bump version
To bump the version, do the following:
1. Bump version `version: ` with version string and version code (MAJOR * 10000 + MINOR * 100 + PATCH) e.g. `version: 0.8.0+800` in:
   1. `pubspec.yaml`
   2. `pubspec.fdroid.yaml`
   3. `pubspec.play.yaml`
2. Bump the same version in Changelog.md e.g. `## [0.8.0]` and use the following format to describe the changes:
   * __Added__ for new features.
   * __Changed__ for changes in existing functionality.
   * __Deprecated__ for soon-to-be removed features.
   * __Removed__ for now removed features.
   * __Fixed__ for any bug fixes.
   * __Security__ in case of vulnerabilities.
3. The changelog and translations shall have a maximum of 500 characters in total.

# Security
* Never commit API keys or secrets
* Do not read .env files


# Translations
The app is translated into multiple languages. To add a new language, do the following:
1. add the app_[lang].arb file to the lib/l10n folder
2. run `flutter gen-l10n` to generate the translations
3. add the new language to `android/app/src/main/res/xml/locales_config.xml`