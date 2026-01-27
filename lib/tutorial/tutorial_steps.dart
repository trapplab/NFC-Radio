import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import '../l10n/app_localizations.dart';

/// Create tutorial targets for the coach marks tutorial
///
/// [addFolderButtonKey] - Key for the "Add New Folder" button
/// [addSongButtonKey] - Key for the "Add Audio File" button
/// [attachFileButtonKey] - Key for the "Attach File" button in song dialog
/// [nfcAreaKey] - Key for the NFC configuration area in song dialog
/// [settingsMenuKey] - Key for the settings menu button
List<TargetFocus> createTutorialTargets({
  required BuildContext context,
  GlobalKey? addFolderButtonKey,
  GlobalKey? addSongButtonKey,
  GlobalKey? attachFileButtonKey,
  GlobalKey? nfcAreaKey,
  GlobalKey? settingsMenuKey,
}) {
  List<TargetFocus> targets = [];
  final l10n = AppLocalizations.of(context)!;

  if (addFolderButtonKey != null) {
    targets.add(
      TargetFocus(
        identify: 'add_folder',
        keyTarget: addFolderButtonKey,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.tutorialAddFolderTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.tutorialAddFolderDesc,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        shape: ShapeLightFocus.RRect,
        radius: 8,
      ),
    );
  }

  if (addSongButtonKey != null) {
    targets.add(
      TargetFocus(
        identify: 'add_song',
        keyTarget: addSongButtonKey,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.tutorialAddSongTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.tutorialAddSongDesc,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        shape: ShapeLightFocus.RRect,
        radius: 8,
      ),
    );
  }

  if (attachFileButtonKey != null) {
    targets.add(
      TargetFocus(
        identify: 'attach_file',
        keyTarget: attachFileButtonKey,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.tutorialAttachFileTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.tutorialAttachFileDesc,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        shape: ShapeLightFocus.Circle,
      ),
    );
  }

  if (nfcAreaKey != null) {
    targets.add(
      TargetFocus(
        identify: 'nfc_connection',
        keyTarget: nfcAreaKey,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.tutorialConnectNfcTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.tutorialConnectNfcDesc,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        shape: ShapeLightFocus.RRect,
        radius: 8,
      ),
    );
  }

  if (settingsMenuKey != null) {
    targets.add(
      TargetFocus(
        identify: 'settings_menu',
        keyTarget: settingsMenuKey,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.tutorialSettingsTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.tutorialSettingsDesc,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        shape: ShapeLightFocus.Circle,
      ),
    );
  }

  return targets;
}

/// Show the tutorial
///
/// [context] - The build context
/// [targets] - The tutorial targets to highlight
/// [onFinish] - Callback when tutorial completes
void showTutorial({
  required BuildContext context,
  required List<TargetFocus> targets,
  VoidCallback? onFinish,
  VoidCallback? onSkip,
}) {
  TutorialCoachMark(
    targets: targets,
    colorShadow: Colors.black87,
    onFinish: onFinish,
    onSkip: () {
      if (onSkip != null) onSkip();
      return true;
    },
    textStyleSkip: const TextStyle(
      color: Colors.white,
      fontSize: 16,
      fontWeight: FontWeight.bold,
    ),
  ).show(context: context);
}
