import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class ThemeProvider with ChangeNotifier {
  Color _currentColor = Colors.white; // Default color
  static const String _boxName = 'settings';
  static const String _colorKey = 'theme_color';

  Color get currentColor => _currentColor;

  Color get bannerColor {
    final colorARGB = _currentColor.toARGB32();
    switch (colorARGB) {
      case 0xFFFFFFFF: // White
        return Colors.blue;
      case 0xFFC8B6A8: // Cappuccino
        return Colors.brown;
      case 0xFF000000: // Black
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  Color get footerColor {
    final colorARGB = _currentColor.toARGB32();
    switch (colorARGB) {
      case 0xFFFFFFFF: // White
        return Colors.blue[100]!;
      case 0xFFC8B6A8: // Cappuccino
        return Colors.brown[100]!;
      case 0xFF000000: // Black
        return Colors.grey[800]!;
      default:
        return Colors.blue[100]!;
    }
  }

  ThemeProvider() {
    _loadColor();
  }

  Future<void> _loadColor() async {
    final box = await Hive.openBox(_boxName);
    final colorValue = box.get(_colorKey);
    if (colorValue != null) {
      _currentColor = Color(colorValue);
      notifyListeners();
    }
  }

  Future<void> setColor(Color color) async {
    _currentColor = color;
    final box = await Hive.openBox(_boxName);
    await box.put(_colorKey, color.toARGB32());
    notifyListeners();
  }
}