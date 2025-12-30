// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nfc_radio/main.dart';

void main() {
  testWidgets('NFC Jukebox app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const NFCJukeboxApp());

    // Verify that our NFC jukebox app starts properly.
    expect(find.text('NFC Radio'), findsOneWidget);
    
    // Check if the main content appears (could be different in test environment)
    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.byType(AppBar), findsOneWidget);
    expect(find.text('NFC Radio'), findsOneWidget);
    
    // Additional checks for core app elements
    expect(find.byType(ListView), findsOneWidget);
    expect(find.text('Add Song'), findsOneWidget);
  });
}
