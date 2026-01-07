#!/bin/bash
FLAVOR=$1

if [ -z "$FLAVOR" ]; then
    echo "Usage: ./scripts/prepare_flavor.sh <flavor>"
    echo "Flavors: fdroid, play, github"
    exit 1
fi

echo "Preparing flavor: $FLAVOR"

# Generate flavor config
echo "// Generated file. Do not edit.
class FlavorConfig {
  static const String flavor = '$FLAVOR';
  static bool get isFdroid => flavor == 'fdroid';
  static bool get isGithub => flavor == 'github';
  static bool get isPlay => flavor == 'play';
}" > lib/flavor_config.dart

if [ "$FLAVOR" == "fdroid" ] || [ "$FLAVOR" == "github" ]; then
    echo "Using F-Droid/GitHub configuration (no IAP)"
    cp pubspec.fdroid.yaml pubspec.yaml
    if grep -q "^  in_app_purchase:" pubspec.yaml; then
        echo "ERROR: in_app_purchase still present in pubspec.yaml!"
        exit 1
    fi
    cp lib/iap/iap_service_stub.dart lib/iap_service.dart
else
    echo "Using Play Store configuration (with IAP)"
    cp pubspec.play.yaml pubspec.yaml
    cp lib/iap/iap_service_play.dart lib/iap_service.dart
fi

echo "Running flutter clean..."
flutter clean
rm -rf build
rm -rf android/.gradle

echo "Running flutter pub get..."
flutter pub get

echo "Flavor $FLAVOR prepared successfully."
