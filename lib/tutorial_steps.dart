import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

/// Create tutorial targets for the coach marks tutorial
///
/// [addFolderButtonKey] - Key for the "Add New Folder" button
/// [addSongButtonKey] - Key for the "Add Song" button
/// [attachFileButtonKey] - Key for the "Attach File" button in song dialog
/// [nfcAreaKey] - Key for the NFC configuration area in song dialog
List<TargetFocus> createTutorialTargets({
  GlobalKey? addFolderButtonKey,
  GlobalKey? addSongButtonKey,
  GlobalKey? attachFileButtonKey,
  GlobalKey? nfcAreaKey,
}) {
  List<TargetFocus> targets = [];

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
                    'Create Music Collections',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap "Add New Folder" to create folders and organize your music collection.',
                    style: TextStyle(
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
                    'Add Your Songs',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Once a folder is created, tap "Add Song" to select audio files from your device.',
                    style: TextStyle(
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
                    'Select Audio File',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the paperclip icon to select an audio file from your device.',
                    style: TextStyle(
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
                    'Connect NFC Tag',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Near any NFC tag to the back of your phone until it vibrates to connect the tag to the audio file for playback.',
                    style: TextStyle(
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
