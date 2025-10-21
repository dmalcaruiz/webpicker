import 'package:flutter/material.dart';
import '../color_operations.dart';
import 'gradient_painter.dart';
import 'plus_minus_adjuster_buttons.dart';
import 'diamond_slider_thumb.dart';

/// OKLCH gradient slider widget with live color gradient background
/// 
/// This widget displays a slider with a gradient showing the range of colors
/// available for the current OKLCH parameters. When colors are out of sRGB
/// gamut, it shows a split-view with the requested color on top and the
/// gamut-mapped fallback on bottom.
class OklchGradientSlider extends StatefulWidget {
  /// Current slider value
  final double value;
  
  /// Minimum slider value
  final double min;
  
  /// Maximum slider value
  final double max;
  
  /// Slider label text
  final String label;
  
  /// Description text shown below the label
  final String description;
  
  /// Callback when value changes
  final Function(double) onChanged;
  
  /// Function to generate gradient stops for this slider
  final List<GradientStop> Function() generateGradient;
  
  /// Whether to show split-view for out-of-gamut colors
  final bool showSplitView;
  
  /// Number of color samples for smooth gradient (default 300)
  final int samples;
  
  /// Step size for +/- buttons
  final double step;
  
  /// Number of decimal places to display
  final int decimalPlaces;
  
  /// Constructor
  /// 
  /// Step 1: Initialize slider with all required parameters
  const OklchGradientSlider({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.label,
    required this.description,
    required this.onChanged,
    required this.generateGradient,
    required this.step,
    required this.decimalPlaces,
    this.showSplitView = true,
    this.samples = 300,
  });
  
  @override
  State<OklchGradientSlider> createState() => _OklchGradientSliderState();
}

class _OklchGradientSliderState extends State<OklchGradientSlider> {
  /// Cached gradient stops to avoid regenerating on every build
  List<GradientStop>? _cachedGradient;
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 13.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step 2: Display label and value adjuster
          Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                ValueAdjuster(
                  value: widget.value,
                  min: widget.min,
                  max: widget.max,
                  step: widget.step,
                  decimalPlaces: widget.decimalPlaces,
                  onChanged: widget.onChanged,
                ),
              ],
          ),
          
          // Step 3: Display description (if not empty)
          if (widget.description.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Text(
                widget.description,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white54,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          
          // Step 4: Slider with gradient background and extended hit area
          SizedBox(
              height: 40,
              child: Stack(
                children: [
                  // Step 5: Gradient background
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CustomPaint(
                        painter: GradientPainter(
                          stops: _getGradientStops(),
                          showSplitView: widget.showSplitView,
                          borderRadius: 8.0,
                        ),
                      ),
                    ),
                  ),
                  
                  // Step 6: Slider with extended hit area (beyond gradient edges)
                  Positioned(
                    left: -13.5,
                    right: -13.5,
                    top: 0,
                    bottom: 0,
                    child: SliderTheme(
                      data: SliderThemeData(
                        // Step 6a: Make track transparent (gradient shows through)
                        activeTrackColor: Colors.transparent,
                        inactiveTrackColor: Colors.transparent,
                        trackHeight: 40,
                        
                        // Step 6a-2: Use track shape with no padding so thumb reaches edges
                        trackShape: const RectangularSliderTrackShape(),
                        
                        // Step 6b: Diamond thumb with current color
                        thumbShape: DiamondSliderThumb(
                          thumbSize: 27.0,
                          color: _getCurrentThumbColor(),
                          showCheckerboard: false, // No checkerboard for OKLCH (no alpha)
                        ),
                        overlayColor: Colors.white.withOpacity(0.2),
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 20.0,
                        ),
                      ),
                      child: Slider(
                        value: widget.value.clamp(widget.min, widget.max),
                        min: widget.min,
                        max: widget.max,
                        onChanged: (newValue) {
                          // Step 7: Clear cache when value changes
                          setState(() {
                            _cachedGradient = null;
                          });
                          // Step 8: Clamp value to prevent floating-point precision errors
                          widget.onChanged(newValue.clamp(widget.min, widget.max));
                        },
                      ),
                    ),
                  ),
                ],
              ),
          ),
        ],
      ),
    );
  }
  
  /// Step 8: Get or generate gradient stops with caching
  List<GradientStop> _getGradientStops() {
    // Step 8a: Return cached gradient if available
    if (_cachedGradient != null) {
      return _cachedGradient!;
    }
    
    // Step 8b: Generate new gradient and cache it
    _cachedGradient = widget.generateGradient();
    return _cachedGradient!;
  }
  
  /// Step 9: Get current color for the thumb based on slider value
  /// 
  /// Interpolates between gradient stops to find the color at current position
  Color _getCurrentThumbColor() {
    final stops = _getGradientStops();
    if (stops.isEmpty) return Colors.white;
    
    // Step 9a: Normalize value to 0-1 range
    final normalizedValue = (widget.value - widget.min) / (widget.max - widget.min);
    
    // Step 9b: Find position in gradient stops array
    final stopIndex = (normalizedValue * (stops.length - 1)).clamp(0, stops.length - 1).toDouble();
    final lowerIndex = stopIndex.floor();
    final upperIndex = stopIndex.ceil();
    
    // Step 9c: Interpolate between two nearest stops
    if (lowerIndex == upperIndex) {
      return stops[lowerIndex].fallbackColor;
    }
    
    final t = stopIndex - lowerIndex;
    return Color.lerp(
      stops[lowerIndex].fallbackColor,
      stops[upperIndex].fallbackColor,
      t,
    )!;
  }
  
  @override
  void didUpdateWidget(OklchGradientSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Step 9: Clear cache if gradient generator changed
    // (This happens when other OKLCH parameters change)
    if (oldWidget.generateGradient != widget.generateGradient) {
      _cachedGradient = null;
    }
  }
}

