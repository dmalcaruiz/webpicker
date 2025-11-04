import 'package:flutter/material.dart';
import '../../models/extreme_color_item.dart';

// A circular widget displaying a mixer extreme color
//
// Behaves like a grid box but circular:
// - Tap to select (shows in sliders)
// - Visual feedback for selection state
// - Integrates with global copy/paste
class ExtremeColorCircle extends StatelessWidget {
  // The extreme color item to display
  final ExtremeColorItem extreme;

  // Callback when this circle is tapped
  final VoidCallback? onTap;

  // Size of the circle
  final double size;

  // Optional color filter for ICC profile display
  final Color Function(ExtremeColorItem)? colorFilter;

  final Color? bgColor;

  final GestureDragStartCallback? onPanStart;

  const ExtremeColorCircle({
    super.key,
    required this.extreme,
    this.onTap,
    this.size = 44.0,
    this.colorFilter,
    this.bgColor,
    this.onPanStart,
  });

  @override
  Widget build(BuildContext context) {
    // Apply color filter if provided, otherwise use original color
    final displayColor = colorFilter != null ? colorFilter!(extreme) : extreme.color;

    return GestureDetector(
      onTap: onTap,
      onPanStart: onPanStart,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: displayColor,
          shape: BoxShape.circle,
          border: Border.all(
            color: extreme.isSelected
                ? (bgColor ?? Colors.white).computeLuminance() > 0.5 ? Colors.black.withOpacity(0.9) : Colors.white.withOpacity(0.9)
                : (bgColor ?? Colors.white).computeLuminance() > 0.5 ? Colors.black.withOpacity(0.3) : Colors.white.withOpacity(0.3),
            width: extreme.isSelected ? 3 : 2,
          ),
          boxShadow: extreme.isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
      ),
    );
  }
}
