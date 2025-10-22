import 'package:flutter/material.dart';

/// Global gesture manager for tracking active sliders across the entire app
class GlobalGestureManager {
  static final GlobalGestureManager _instance = GlobalGestureManager._internal();
  factory GlobalGestureManager() => _instance;
  GlobalGestureManager._internal();

  // Track active slider information
  ActiveSliderInfo? _activeSlider;
  
  /// Register an active slider for global tracking
  void registerActiveSlider({
    required String sliderId,
    required double currentValue,
    required double min,
    required double max,
    required Rect sliderBounds,
    required Function(double) onChanged,
    required VoidCallback onEnd,
  }) {
    _activeSlider = ActiveSliderInfo(
      sliderId: sliderId,
      currentValue: currentValue,
      min: min,
      max: max,
      sliderBounds: sliderBounds,
      onChanged: onChanged,
      onEnd: onEnd,
    );
  }
  
  /// Unregister the active slider
  void unregisterActiveSlider() {
    _activeSlider = null;
  }
  
  /// Check if there's an active slider
  bool get hasActiveSlider => _activeSlider != null;
  
  /// Get the active slider info
  ActiveSliderInfo? get activeSlider => _activeSlider;
  
  /// Convert global position to slider value
  double convertGlobalPositionToSliderValue(Offset globalPosition) {
    if (_activeSlider == null) return 0.0;
    
    final bounds = _activeSlider!.sliderBounds;
    final sliderWidth = bounds.width;
    final relativeX = globalPosition.dx - bounds.left;
    
    // Clamp to slider bounds
    final clampedX = relativeX.clamp(0.0, sliderWidth);
    final percentage = clampedX / sliderWidth;
    
    // Convert percentage to slider value
    final range = _activeSlider!.max - _activeSlider!.min;
    return _activeSlider!.min + (percentage * range);
  }
  
  /// Handle global pan update
  void handleGlobalPanUpdate(Offset globalPosition) {
    if (_activeSlider == null) return;
    
    final newValue = convertGlobalPositionToSliderValue(globalPosition);
    _activeSlider!.onChanged(newValue);
  }
  
  /// Handle global pan end
  void handleGlobalPanEnd() {
    if (_activeSlider == null) return;
    
    _activeSlider!.onEnd();
    unregisterActiveSlider();
  }
}

/// Information about an active slider
class ActiveSliderInfo {
  final String sliderId;
  final double currentValue;
  final double min;
  final double max;
  final Rect sliderBounds;
  final Function(double) onChanged;
  final VoidCallback onEnd;
  
  ActiveSliderInfo({
    required this.sliderId,
    required this.currentValue,
    required this.min,
    required this.max,
    required this.sliderBounds,
    required this.onChanged,
    required this.onEnd,
  });
}
