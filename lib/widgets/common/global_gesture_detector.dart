import 'package:flutter/material.dart';
import '../../utils/global_gesture_manager.dart';

/// Global gesture detector that wraps the entire app
/// Handles slider tracking when fingers move outside slider bounds
class GlobalGestureDetector extends StatelessWidget {
  final Widget child;
  
  const GlobalGestureDetector({
    super.key,
    required this.child,
  });
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        // Only handle if there's an active slider
        if (GlobalGestureManager().hasActiveSlider) {
          GlobalGestureManager().handleGlobalPanUpdate(details.globalPosition);
        }
      },
      onPanEnd: (details) {
        // Only handle if there's an active slider
        if (GlobalGestureManager().hasActiveSlider) {
          GlobalGestureManager().handleGlobalPanEnd();
        }
      },
      onPanCancel: () {
        // Only handle if there's an active slider
        if (GlobalGestureManager().hasActiveSlider) {
          GlobalGestureManager().handleGlobalPanEnd();
        }
      },
      child: child,
    );
  }
}
