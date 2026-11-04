// Smoke test: the app starts and shows its main screen.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nfc_radio/main.dart';
import 'package:nfc_radio/storage/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('nfc_radio_test_');
    // Point path_provider to a temp dir so Hive stores its boxes there.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => tempDir.path,
        );
    // Same as main(): storage must be ready before the app is built.
    await StorageService.instance.initialize();
  });

  tearDownAll(() async {
    await tempDir.delete(recursive: true);
  });

  testWidgets('NFC Jukebox app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const NFCJukeboxApp());
    await tester.pump();

    expect(find.byType(Scaffold), findsWidgets);
    expect(find.byType(AppBar), findsOneWidget);
    expect(find.text('NFC Radio'), findsWidgets);
  });
}
