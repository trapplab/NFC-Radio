# Increase version
- [ ] update pubspec.yaml
- [ ] update Changelog.md
- [ ] add Tag in git

# call fastlane
- [ ] update screenshots
- [ ] update fastlane changelogs from Changelog.md (shoudl be challed automatically by a post commit hook)

# in fdroid data
- [ ] run: fdroid lint com.trapplab.nfc_radio
- [ ] run: fdroid rewritemeta com.trapplab.nfc_radio

# Apendix
## Check licenses
* nfc_manager: ^4.1.1: MIT
* audioplayers: ^6.5.1: MIT
* provider: ^6.0.5: MIT
* wakelock_plus: ^1.1.2: BSD-3-Clause
* uuid: ^4.5.2: MIT
* file_picker: ^10.3.8: MIT
* path: ^1.9.0: BSD-3-Clause
* permission_handler: ^12.0.1: MIT
* hive: ^2.2.3: Apache License, Version 2.0  
* hive_flutter: ^1.1.0: Apache License, Version 2.0
* version: ^3.0.0: BSD-3-Clause
* url_launcher: ^6.3.1: BSD-3-Clause
* flutter_native_splash: ^2.4.7: MIT
* package_info_plus: ^9.0.0: BSD-3-Clause
* http: ^1.6.0: BSD-3-Clause

## useful commands
```bash
# check if google libraries are contained
dexdump build/app/outputs/flutter-apk/app-release.apk | grep OnFailureListener
# checksum
sha256sum build/app/outputs/flutter-apk/app-release.apk
```