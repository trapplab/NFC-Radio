
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