import 'package:flutter/material.dart';
import '../../models/extreme_color_item.dart';

/// A circular widget displaying a mixer extreme color
///
/// Behaves like a palette box but circular:
/// - Tap to select (shows in sliders)
/// - Visual feedback for selection state
/// - Integrates with global copy/paste
class ExtremeColorCircle extends StatelessWidget {
  /// The extreme color item to display
  final ExtremeColorItem extreme;

  /// Callback when this circle is tapped
  final VoidCallback? onTap;

  /// Size of the circle
  final double size;

  const ExtremeColorCircle({
    super.key,
    required this.extreme,
    this.onTap,
    this.size = 44.0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: extreme.color,
          shape: BoxShape.circle,
          border: Border.all(
            color: extreme.isSelected
                ? Colors.white.withValues(alpha: 0.9)
                : Colors.white.withValues(alpha: 0.3),
            width: extreme.isSelected ? 3 : 2,
          ),
          boxShadow: extreme.isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
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
