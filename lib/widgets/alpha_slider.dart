import 'package:flutter/material.dart';
import 'package:pie_menu/pie_menu.dart';
import 'diamond_slider_thumb.dart';

/// Mixed channel slider widget with dot-based extreme control
/// 
/// Features three independent controllers:
/// 1. LCH sliders (always control global)
/// 2. Mixed channel slider (controls global only while touched)
/// 3. Extreme buttons (can track global via pie menu)
class MixedChannelSlider extends StatefulWidget {
  /// Current slider value (0.0 to 1.0)
  final double value;
  
  /// Current global OKLCH color (for display reference)
  final Color currentColor;
  
  /// Left extreme color
  final Color leftExtremeColor;
  
  /// Right extreme color
  final Color rightExtremeColor;
  
  /// Is left extreme tracking global OKLCH
  final bool isLeftTracking;
  
  /// Is right extreme tracking global OKLCH
  final bool isRightTracking;
  
  /// Is slider currently active (being touched)
  final bool sliderIsActive;
  
  /// Callback when slider value changes
  final Function(double) onChanged;
  
  /// Callback for left extreme actions
  final Function(String action) onLeftExtremeAction;
  
  /// Callback for right extreme actions
  final Function(String action) onRightExtremeAction;
  
  /// Callback when slider is touched
  final VoidCallback onSliderTouchStart;
  
  /// Callback when slider is released
  final VoidCallback onSliderTouchEnd;
  
  /// Number of color samples for smooth gradient (default 300)
  final int samples;
  
  const MixedChannelSlider({
    super.key,
    required this.value,
    required this.currentColor,
    required this.leftExtremeColor,
    required this.rightExtremeColor,
    required this.isLeftTracking,
    required this.isRightTracking,
    required this.sliderIsActive,
    required this.onChanged,
    required this.onLeftExtremeAction,
    required this.onRightExtremeAction,
    required this.onSliderTouchStart,
    required this.onSliderTouchEnd,
    this.samples = 300,
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
          
          // Slider with gradient and extended hit area
          SizedBox(
              height: 40,
              child: Stack(
                children: [
                  // Gradient background
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CustomPaint(
                        painter: MixedChannelGradientPainter(
                          gradientColors: _generateMixGradient(),
                          borderRadius: 8.0,
                        ),
                      ),
                    ),
                  ),
                  // Slider with extended hit area (beyond gradient edges)
                  Positioned(
                    left: -13.5,
                    right: -13.5,
                    top: 0,
                    bottom: 0,
                    child: SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: Colors.transparent,
                        inactiveTrackColor: Colors.transparent,
                        trackHeight: 40,
                        
                        // Use track shape with no padding so thumb reaches edges
                        trackShape: const RectangularSliderTrackShape(),
                        
                        thumbShape: DiamondSliderThumb(
                          thumbSize: 27.0,
                          color: _getCurrentThumbColor(),
                          showCheckerboard: true,
                        ),
                        overlayColor: Colors.white.withOpacity(0.2),
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 20.0,
                        ),
                      ),
                      child: Slider(
                        value: widget.value.clamp(0.0, 1.0),
                        min: 0.0,
                        max: 1.0,
                        onChanged: (value) {
                          // Step 1: Clamp value to prevent floating-point precision errors
                          widget.onChanged(value.clamp(0.0, 1.0));
                        },
                        onChangeStart: (_) => widget.onSliderTouchStart(),
                        onChangeEnd: (_) => widget.onSliderTouchEnd(),
                      ),
                    ),
                  ),
                ],
              ),
          ),
          
          // Dot buttons below slider
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Left dot button
                _buildDotButton(
                  isTracking: widget.isLeftTracking,
                  isLeft: true,
                  extremeColor: widget.leftExtremeColor,
                ),
                
                // Right dot button
                _buildDotButton(
                  isTracking: widget.isRightTracking,
                  isLeft: false,
                  extremeColor: widget.rightExtremeColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // Helper function to determine if text should be dark or light based on background
  Color _getContrastColor(Color background) {
    // Calculate relative luminance
    final double luminance = (0.299 * background.red + 
                             0.587 * background.green + 
                             0.114 * background.blue) / 255;
    // Return black for light backgrounds, white for dark backgrounds
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
  
  Widget _buildDotButton({
    required bool isTracking,
    required bool isLeft,
    required Color extremeColor,
  }) {
    // If tracking, simple tap to disconnect (no pie menu)
    if (isTracking) {
      return InkWell(
        onTap: () => isLeft
            ? widget.onLeftExtremeAction('disconnect')
            : widget.onRightExtremeAction('disconnect'),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: Colors.orange,
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.orange,
              width: 2,
            ),
          ),
        ),
      );
    }
    
    // If disconnected, show pie menu with take in/give to options
    return PieMenu(
      onPressed: () {},
      theme: PieTheme(
        brightness: Brightness.dark,
        overlayColor: Colors.black45,
        pointerSize: 15,
        buttonSize: 40,
        buttonTheme: const PieButtonTheme(
          backgroundColor: Color(0xFF2A2A2A),
          iconColor: Colors.white,
        ),
        leftClickShowsMenu: true,
        rightClickShowsMenu: false,
        delayDuration: const Duration(milliseconds: 50),
        radius: 60,
        customAngle: 180, // Half circle for vertical
        customAngleAnchor: PieAnchor.center,
        angleOffset: 90, // Vertical arrangement
        menuAlignment: Alignment.center,
        menuDisplacement: const Offset(0, -30),
      ),
      actions: [
        // Take in global value (show global color)
        PieAction(
          tooltip: const Text('Take in global value'),
          onSelect: () => isLeft 
              ? widget.onLeftExtremeAction('takeIn')
              : widget.onRightExtremeAction('takeIn'),
          child: Container(
            width: 35,
            height: 35,
            decoration: BoxDecoration(
              color: widget.currentColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white30, width: 2),
            ),
            child: Icon(
              Icons.arrow_downward,
              size: 20,
              color: _getContrastColor(widget.currentColor),
            ),
          ),
        ),
        
        // Give to global value (show extreme color)
        PieAction(
          tooltip: const Text('Give to global value'),
          onSelect: () => isLeft
              ? widget.onLeftExtremeAction('giveTo')
              : widget.onRightExtremeAction('giveTo'),
          child: Container(
            width: 35,
            height: 35,
            decoration: BoxDecoration(
              color: extremeColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white30, width: 2),
            ),
            child: Icon(
              Icons.arrow_upward,
              size: 20,
              color: _getContrastColor(extremeColor),
            ),
          ),
        ),
      ],
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white54,
            width: 2,
          ),
        ),
      ),
    );
  }
  
  /// Step 1: Get current color for the thumb based on slider value
  /// 
  /// Interpolates between left and right extreme colors
  Color _getCurrentThumbColor() {
    // Step 2: Interpolate between left and right extreme colors
    return Color.lerp(
      widget.leftExtremeColor,
      widget.rightExtremeColor,
      widget.value,
    )!;
  }
  
  List<Color> _generateMixGradient() {
    final List<Color> colors = [];
    
    for (int i = 0; i < widget.samples; i++) {
      final double t = i / (widget.samples - 1);
      colors.add(Color.lerp(widget.leftExtremeColor, widget.rightExtremeColor, t)!);
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
      ..color = Colors.white.withOpacity(0.2)
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
