
<!--
# Types of changes
[Source](https://keepachangelog.com/en/1.1.0/)

* __Added__ for new features.
* __Changed__ for changes in existing functionality.
* __Deprecated__ for soon-to-be removed features.
* __Removed__ for now removed features.
* __Fixed__ for any bug fixes.
* __Security__ in case of vulnerabilities.
-->

# Changelog

## [0.11.3]
### Fixed
- fix settings tutorial showing when already opened by user
- translate missing hardcoded ui strings

## [0.11.2]
### Fixed
- translate missing ui strings
- show info button in playstore version
- load older version from hivedb with default values

## [0.11.1]
### Fixed
- fixed github check for updates
- register android app as multilingual
- translated slider

## [0.11.0]
### Added
- Added internationalization on ui for German, English, Spanish, French, and Italian.

## [0.10.0]
### Added
- Added a color changer in the settings.
- Make Folders sortable
- Open org.fossify.voicerecorder to record audio files.
- added loop and save position to "add song" menu.

## [0.9.0]
### Changed
- Updated screen lock functionality to be easier visible and have a option to run in kiosk mode for better blocking of unwanted inputs.
- Added slide-to-lock to keep settings easily from children curios hands.

## [0.8.2]
### Added
- Introduced audio starter packs to include simply basic sounds for children.
- Added tutorial for first time users to help them get started.

## [0.8.1]
### Changed
- Some UI and usability improvements, from testers feedback
- Remove the INTERNET permission from the fdroid version. All flavours work fully offline, but github checks for updates and play for in app purchases.
- Opened file explorer filter so that not only audio files can be seen, but only audio files can be selected.

## [0.8.0]
### Changed
- Use file select to copy over files into apps local storage to make use of androids sandboxed design.
- Show given song name in the player when playing a song.

## [0.7.12]
### Changed
- Use fixed timestamps and javaversion in build.gradle to make build reproducible.

## [0.7.11]
### Changed
- Changed github toolchain to be similar to gitlabs configs for flutter build.

## [0.7.10]
### Fixed
- Make sure both builds (github and fdroid) are in the release.

## [0.7.9]
### Changed
- Release also a fdroid version in github to have a comparable version to the fdroid build.

## [0.7.8]
### Fixed
- Use flutter as a submodule in the github build to have reproducible build.

## [0.7.7]
### Fixed
- Fixed updated compare for latest github version

### Changed
- Updated app descriptions

## [0.7.6]
### Fixed
- Fixed script to prepare pubspec for fdroid version

## [0.7.5]
### Added
- Added a Playstore Version with In-App-Purchase, which is excluded in F-Droid an Github builds.

## [0.7.4]
### Changed
- included flutter as a submodule in the project.

## [0.7.3]
### Changed
- re add the google repsoitory as a dependency to the build.gradle file, to fix the github build. But make sure exluded google dependencies are not included in the build.

## [0.7.2]
### Changed
- Shrink apk file in the build settings to remove unused google libraries we don't want in the build.


## [0.7.1]
### Changed
- Make sure to exclude propietary google play core libraries in apk build for F-Droid compliance.

## [0.7.0]
### Changed
- Introduced reproducible builds

### Added
- Added versioning to work in fdroid toolchain

## [0.6.0]
### Changed
- Prepare Version to publish in F-Droid Store

### Added
- Added some documentation

## [0.5.0]
### Changed
- Sign deployed apks with secret key.
- Build apks only for arm64 architecture to have smaller apks.

## [0.4.0]
### Fixed
- Show add button always, even if not folders are visible
- build Github apk with Github Flavor to activate update mechanism.
- Don't play any file if no folder is opened

## [0.3.0]
### Added
- Introduced flavors to build for different plattforms
- Added update checker for github released version.

## [0.2.0]
### Added
- Added this changelog
- Added support to organize audio files in folders