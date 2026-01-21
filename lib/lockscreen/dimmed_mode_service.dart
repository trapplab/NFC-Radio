import 'package:flutter/material.dart';

class DimmedModeService with ChangeNotifier {
  bool _isDimmed = false;
  
  bool get isDimmed => _isDimmed;
  
  void toggleDimmedMode() {
    _isDimmed = !_isDimmed;
    notifyListeners();
  }
  
  void enableDimmedMode() {
    _isDimmed = true;
    notifyListeners();
  }
  
  void disableDimmedMode() {
    _isDimmed = false;
    notifyListeners();
  }
}