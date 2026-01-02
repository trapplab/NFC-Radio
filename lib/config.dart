// Configuration file to define the build source
class AppConfig {
  static const bool isGitHubRelease = bool.fromEnvironment('GITHUB_FLAVOR', defaultValue: false);
  static const bool isFdroidRelease = bool.fromEnvironment('FDROID_FLAVOR', defaultValue: false);
  static const bool isGooglePlayRelease = bool.fromEnvironment('GOOGLE_PLAY_FLAVOR', defaultValue: false);
}