import 'package:flutter/material.dart';

/// Show the initial tutorial/welcome dialog with NFC usage instructions
///
/// [context] - The build context
/// [onFinish] - Callback when the user closes the dialog
void showTutorial({
  required BuildContext context,
  VoidCallback? onFinish,
}) {
  showDialog(
    context: context,
    barrierDismissible: false, // User must tap a button to dismiss
    builder: (context) => AlertDialog(
      title: const Text('Welcome to NFC Radio! 🎵'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'How to use NFC Tags:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Text(
              '• NFC scanning is always active',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              '• Use NFC cards, dongles, stickers, or any NFC-enabled device. Just try out what works, sometimes you find a NFC tag where you wouldn\'t expect it',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              '• Hold the NFC tag at the back of your phone - it will vibrate when recognized. In the "Add New Audio" menu you will see the found ID of the NFC tag.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              '• The Screen must be turned on for NFC scanning to work',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              '• Use 3-finger swipe to lock the app while playing',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Text(
              'Tip: Create folders and add songs, then connect NFC tags to play them!',
              style: TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onFinish?.call();
          },
          child: const Text('Got it!'),
        ),
      ],
    ),
  );
}
