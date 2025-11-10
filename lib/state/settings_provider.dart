import 'package:flutter/material.dart';

// Grid layout modes
enum GridLayoutMode {
  responsive,  // Fixed 4 columns, boxes resize to fill width
  fixedSize,   // Dynamic columns based on 80px target size
  horizontal,  // 1 column, boxes fill full width
}

// Box height modes
enum BoxHeightMode {
  proportional,  // Height matches width (1:1 aspect ratio - square boxes)
  fillContainer, // Height fills available container space based on number of rows
  fixed,         // Fixed height, doesn't change with width
}

// Provider for application settings
//
// Manages application-wide settings such as ICC profile filtering
// and other preferences that should be part of the undo/redo history.
class SettingsProvider extends ChangeNotifier {
  bool _useRealPigmentsOnly = false;
  bool _autoCopyEnabled = true;
  bool _usePigmentMixing = false;
  GridLayoutMode _gridLayoutMode = GridLayoutMode.fixedSize;
  BoxHeightMode _boxHeightMode = BoxHeightMode.fillContainer;

  // Getters
  bool get useRealPigmentsOnly => _useRealPigmentsOnly;
  bool get autoCopyEnabled => _autoCopyEnabled;
  bool get usePigmentMixing => _usePigmentMixing;
  GridLayoutMode get gridLayoutMode => _gridLayoutMode;
  BoxHeightMode get boxHeightMode => _boxHeightMode;

  // Backward compatibility getter
  bool get useFixedBoxSizes => _gridLayoutMode == GridLayoutMode.fixedSize;

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

  // Set grid layout mode
  void setGridLayoutMode(GridLayoutMode mode) {
    if (_gridLayoutMode != mode) {
      _gridLayoutMode = mode;
      notifyListeners();
    }
  }

  // Backward compatibility - convert bool to enum
  void setUseFixedBoxSizes(bool value) {
    setGridLayoutMode(value ? GridLayoutMode.fixedSize : GridLayoutMode.responsive);
  }

  // Cycle through grid layout modes
  void cycleGridLayoutMode() {
    switch (_gridLayoutMode) {
      case GridLayoutMode.responsive:
        _gridLayoutMode = GridLayoutMode.fixedSize;
        break;
      case GridLayoutMode.fixedSize:
        _gridLayoutMode = GridLayoutMode.horizontal;
        break;
      case GridLayoutMode.horizontal:
        _gridLayoutMode = GridLayoutMode.responsive;
        break;
    }
    notifyListeners();
  }

  // Set box height mode
  void setBoxHeightMode(BoxHeightMode mode) {
    if (_boxHeightMode != mode) {
      _boxHeightMode = mode;
      notifyListeners();
    }
  }
}
