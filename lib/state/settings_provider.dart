import 'package:flutter/material.dart';

// Provider for application settings
//
// Manages application-wide settings such as ICC profile filtering
// and other preferences that should be part of the undo/redo history.
class SettingsProvider extends ChangeNotifier {
  bool _useRealPigmentsOnly = false;
  bool _autoCopyEnabled = true;
  bool _usePigmentMixing = false;

  // Getters
  bool get useRealPigmentsOnly => _useRealPigmentsOnly;
  bool get autoCopyEnabled => _autoCopyEnabled;
  bool get usePigmentMixing => _usePigmentMixing;

  // Enable or disable real pigments only filter (ICC profile filtering)
  void setRealPigmentsOnly(bool value) {
    if (_useRealPigmentsOnly != value) {
      _useRealPigmentsOnly = value;
      notifyListeners();
    }
  }

  // Toggle the real pigments filter on/off
  void toggleRealPigmentsOnly() {
    _useRealPigmentsOnly = !_useRealPigmentsOnly;
    notifyListeners();
  }

  // Enable or disable auto-copy to clipboard
  void setAutoCopyEnabled(bool value) {
    if (_autoCopyEnabled != value) {
      _autoCopyEnabled = value;
      debugPrint('SettingsProvider: autoCopyEnabled changed to $value');
      notifyListeners();
    }
  }

  // Toggle auto-copy to clipboard on/off
  void toggleAutoCopy() {
    _autoCopyEnabled = !_autoCopyEnabled;
    debugPrint('SettingsProvider: autoCopyEnabled toggled to $_autoCopyEnabled');
    notifyListeners();
  }

  // Enable or disable pigment mixing (Mixbox)
  void setUsePigmentMixing(bool value) {
    if (_usePigmentMixing != value) {
      _usePigmentMixing = value;
      notifyListeners();
    }
  }

  // Toggle pigment mixing on/off
  void toggleUsePigmentMixing() {
    _usePigmentMixing = !_usePigmentMixing;
    notifyListeners();
  }
}
