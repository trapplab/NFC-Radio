import 'package:flutter_test/flutter_test.dart';
import 'package:nfc_radio/dimmed_mode_service.dart';
import 'package:nfc_radio/dimmed_overlay.dart';
import 'package:flutter/material.dart';

void main() {
  group('DimmedModeService Tests', () {
    test('Initial state should be not dimmed', () {
      final service = DimmedModeService();
      expect(service.isDimmed, false);
    });

    test('Enable dimmed mode should set isDimmed to true', () {
      final service = DimmedModeService();
      service.enableDimmedMode();
      expect(service.isDimmed, true);
    });

    test('Disable dimmed mode should set isDimmed to false', () {
      final service = DimmedModeService();
      service.enableDimmedMode();
      service.disableDimmedMode();
      expect(service.isDimmed, false);
    });

    test('Toggle should switch between states', () {
      final service = DimmedModeService();
      expect(service.isDimmed, false);
      
      service.toggleDimmedMode();
      expect(service.isDimmed, true);
      
      service.toggleDimmedMode();
      expect(service.isDimmed, false);
    });
  });

  group('DimmedOverlay Widget Tests', () {
    testWidgets('DimmedOverlay should be invisible when not active', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DimmedOverlay(
              isActive: false,
              onLockScreen: () {},
            ),
          ),
        ),
      );

      // Should be an empty container when not active
      expect(find.byType(Container), findsOneWidget);
      expect(find.text('Screen Dimmed'), findsNothing);
    });

    testWidgets('DimmedOverlay should show content when active', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DimmedOverlay(
              isActive: true,
              onLockScreen: () {},
            ),
          ),
        ),
      );

      expect(find.text('Screen Dimmed'), findsOneWidget);
      expect(find.text('3-Finger Swipe Up to Unlock'), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    });
  });
}