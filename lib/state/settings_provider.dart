import 'package:flutter/material.dart';

/// Provider for application settings
///
/// Manages application-wide settings such as ICC profile filtering
/// and other preferences that should be part of the undo/redo history.
class SettingsProvider extends ChangeNotifier {
  bool _useRealPigmentsOnly = false;

  // Getters
  bool get useRealPigmentsOnly => _useRealPigmentsOnly;

  /// Enable or disable real pigments only filter (ICC profile filtering)
  void setRealPigmentsOnly(bool value) {
    if (_useRealPigmentsOnly != value) {
      _useRealPigmentsOnly = value;
      notifyListeners();
    }
  }

  /// Toggle the real pigments filter on/off
  void toggleRealPigmentsOnly() {
    _useRealPigmentsOnly = !_useRealPigmentsOnly;
    notifyListeners();
  }

  /// Sync from snapshot (for undo/redo) - optimized to avoid unnecessary rebuilds
  void syncFromSnapshot({
    required bool useRealPigmentsOnly,
  }) {
    if (_useRealPigmentsOnly != useRealPigmentsOnly) {
      _useRealPigmentsOnly = useRealPigmentsOnly;
      notifyListeners();
    }
  }
}
