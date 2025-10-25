import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../models/extreme_color_item.dart';
import '../../utils/color_operations.dart';
import '../../utils/mixbox.dart';
import '../color_picker/mixer_extremes_row.dart';
import 'invisible_slider.dart';

/// Mixed channel slider widget with extreme circle controls
///
/// Features:
/// 1. LCH sliders (always control global or selected extreme/box)
/// 2. Mixed channel slider (controls global only while touched)
/// 3. Extreme circles (tap to select, behave like palette boxes)
class MixedChannelSlider extends StatefulWidget {
  /// Current slider value (0.0 to 1.0)
  final double value;

  /// Current global OKLCH color (for display reference)
  final Color currentColor;

  /// Left extreme
  final ExtremeColorItem leftExtreme;

  /// Right extreme
  final ExtremeColorItem rightExtreme;

  /// Is slider currently active (being touched)
  final bool sliderIsActive;

  /// Callback when slider value changes
  final Function(double) onChanged;

  /// Callback when an extreme is tapped
  final Function(String extremeId) onExtremeTap;

  /// Callback when slider is touched
  final VoidCallback onSliderTouchStart;

  /// Callback when slider is released
  final VoidCallback onSliderTouchEnd;

  /// Number of color samples for smooth gradient (default 300)
  final int samples;

  /// Callback when interaction with slider starts/ends
  final Function(bool)? onInteractionChanged;

  /// Whether to use pigment mixing (Mixbox) instead of OKLCH
  final bool usePigmentMixing;

  /// Callback when pigment mixing toggle changes
  final Function(bool)? onPigmentMixingChanged;

  /// Whether to use ICC profile filtering (real pigments only)
  final bool useRealPigmentsOnly;

  /// Callback when real pigments only toggle changes
  final Function(bool)? onRealPigmentsOnlyChanged;

  const MixedChannelSlider({
    super.key,
    required this.value,
    required this.currentColor,
    required this.leftExtreme,
    required this.rightExtreme,
    required this.sliderIsActive,
    required this.onChanged,
    required this.onExtremeTap,
    required this.onSliderTouchStart,
    required this.onSliderTouchEnd,
    this.samples = 300,
    this.onInteractionChanged,
    this.usePigmentMixing = false,
    this.onPigmentMixingChanged,
    this.useRealPigmentsOnly = false,
    this.onRealPigmentsOnlyChanged,
  });
  
  @override
  State<MixedChannelSlider> createState() => _MixedChannelSliderState();
}

class _MixedChannelSliderState extends State<MixedChannelSlider> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 13.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label and value
          Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Mixed Channel',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  widget.value.toStringAsFixed(2),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white70,
                  ),
                ),
              ],
          ),
          
          
          const SizedBox(height: 8),
          
          // Slider with gradient and external thumb
          GestureDetector(
            // Add mobile web gesture detection
            onPanStart: kIsWeb ? (_) => widget.onInteractionChanged?.call(true) : null,
            onPanEnd: kIsWeb ? (_) => widget.onInteractionChanged?.call(false) : null,
            onPanCancel: kIsWeb ? () => widget.onInteractionChanged?.call(false) : null,
            child: InvisibleSliderWithExternalThumb(
              value: widget.value,
              min: 0.0,
              max: 1.0,
              onChanged: (value) {
                widget.onChanged(value.clamp(0.0, 1.0));
              },
              onChangeStart: () {
                widget.onSliderTouchStart();
                widget.onInteractionChanged?.call(true);
              },
              onChangeEnd: () {
                widget.onSliderTouchEnd();
                widget.onInteractionChanged?.call(false);
              },
              background: CustomPaint(
                painter: MixedChannelGradientPainter(
                  gradientColors: _generateMixGradient(),
                  borderRadius: 8.0,
                ),
              ),
              thumbColor: _getCurrentThumbColor(),
              showCheckerboard: true,
              trackHeight: 50.0,
              hitAreaExtension: 13.5,
              thumbSize: 27.0,
              thumbOffset: 8.0,
            ),
          ),

          // Extreme circles below slider
          MixerExtremesRow(
            leftExtreme: widget.leftExtreme,
            rightExtreme: widget.rightExtreme,
            onExtremeTap: widget.onExtremeTap,
          ),

          // Pigment mixing toggle
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              widget.onPigmentMixingChanged?.call(!widget.usePigmentMixing);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: widget.usePigmentMixing
                    ? Colors.white.withValues(alpha: 0.15)
                    : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: widget.usePigmentMixing
                      ? Colors.white.withValues(alpha: 0.3)
                      : Colors.white.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    widget.usePigmentMixing ? Icons.check_box : Icons.check_box_outline_blank,
                    size: 16,
                    color: widget.usePigmentMixing
                        ? Colors.white.withValues(alpha: 0.9)
                        : Colors.white.withValues(alpha: 0.5),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Pigment Mixing',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: widget.usePigmentMixing
                          ? Colors.white.withValues(alpha: 0.9)
                          : Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Only Real Pigments toggle (ICC profile filter)
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              widget.onRealPigmentsOnlyChanged?.call(!widget.useRealPigmentsOnly);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: widget.useRealPigmentsOnly
                    ? Colors.white.withValues(alpha: 0.15)
                    : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: widget.useRealPigmentsOnly
                      ? Colors.white.withValues(alpha: 0.3)
                      : Colors.white.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    widget.useRealPigmentsOnly ? Icons.check_box : Icons.check_box_outline_blank,
                    size: 16,
                    color: widget.useRealPigmentsOnly
                        ? Colors.white.withValues(alpha: 0.9)
                        : Colors.white.withValues(alpha: 0.5),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Only Real Pigments',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: widget.useRealPigmentsOnly
                          ? Colors.white.withValues(alpha: 0.9)
                          : Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Interpolates between left and right extreme colors
  /// Uses either OKLCH or Mixbox pigment mixing based on toggle
  Color _getCurrentThumbColor() {
    if (widget.usePigmentMixing) {
      return lerpMixbox(
        widget.leftExtreme.color,
        widget.rightExtreme.color,
        widget.value,
      );
    } else {
      return lerpOklch(
        widget.leftExtreme.color,
        widget.rightExtreme.color,
        widget.value,
      );
    }
  }

  List<Color> _generateMixGradient() {
    final List<Color> colors = [];

    for (int i = 0; i < widget.samples; i++) {
      final double t = i / (widget.samples - 1);
      if (widget.usePigmentMixing) {
        colors.add(lerpMixbox(widget.leftExtreme.color, widget.rightExtreme.color, t));
      } else {
        colors.add(lerpOklch(widget.leftExtreme.color, widget.rightExtreme.color, t));
      }
    }

    return colors;
  }
}

/// Custom painter for mixed channel gradient
class MixedChannelGradientPainter extends CustomPainter {
  final List<Color> gradientColors;
  final double borderRadius;
  
  const MixedChannelGradientPainter({
    required this.gradientColors,
    this.borderRadius = 8.0,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    final rectWidth = width / gradientColors.length;
    
    for (int i = 0; i < gradientColors.length; i++) {
      final double x = i * rectWidth;
      final paint = Paint()..color = gradientColors[i];
      
      canvas.drawRect(
        Rect.fromLTWH(x, 0, rectWidth + 1, height),
        paint,
      );
    }
    
    // Border
    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, width, height),
        Radius.circular(borderRadius),
      ),
      borderPaint,
    );
  }
  
  @override
  bool shouldRepaint(MixedChannelGradientPainter oldDelegate) {
    return gradientColors != oldDelegate.gradientColors ||
           borderRadius != oldDelegate.borderRadius;
  }
}
