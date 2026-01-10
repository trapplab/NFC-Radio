import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

/// Create tutorial targets for the coach marks tutorial
///
/// [addFolderButtonKey] - Key for the "Add New Folder" button
/// [foldersAreaKey] - Key for the folders list area
List<TargetFocus> createTutorialTargets({
  required GlobalKey addFolderButtonKey,
  required GlobalKey foldersAreaKey,
}) {
  return [
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
    TargetFocus(
      identify: 'folders_area',
      keyTarget: foldersAreaKey,
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
  ];
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
}) {
  TutorialCoachMark(
    targets: targets,
    colorShadow: Colors.black87,
    onFinish: onFinish,
    textStyleSkip: const TextStyle(
      color: Colors.white,
      fontSize: 16,
      fontWeight: FontWeight.bold,
    ),
  ).show(context: context);
}
