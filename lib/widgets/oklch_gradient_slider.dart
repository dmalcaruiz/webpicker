import 'package:flutter/material.dart';
import '../color_operations.dart';
import 'gradient_painter.dart';
import 'value_adjuster.dart';

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
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step 2: Display label and value adjuster
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
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
          ),
          
          // Step 3: Display description (if not empty)
          if (widget.description.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
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
          
          // Step 4: Slider with gradient background
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SizedBox(
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
                  
                  // Step 6: Slider overlay for interaction
                  SliderTheme(
                    data: SliderThemeData(
                      // Step 6a: Make track transparent (gradient shows through)
                      activeTrackColor: Colors.transparent,
                      inactiveTrackColor: Colors.transparent,
                      trackHeight: 40,
                      
                      // Step 6b: Custom thumb styling
                      thumbColor: Colors.white,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 12.0,
                        elevation: 4.0,
                      ),
                      overlayColor: Colors.white.withOpacity(0.2),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 20.0,
                      ),
                    ),
                    child: Slider(
                      value: widget.value,
                      min: widget.min,
                      max: widget.max,
                      onChanged: (newValue) {
                        // Step 7: Clear cache when value changes
                        setState(() {
                          _cachedGradient = null;
                        });
                        widget.onChanged(newValue);
                      },
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

