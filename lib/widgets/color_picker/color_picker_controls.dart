import 'package:flutter/material.dart';
import '../../utils/color_operations.dart';
import 'oklch_gradient_slider.dart';
import '../sliders/mixer_slider.dart' show MixedChannelSlider;

/// A widget containing all the color picker slider controls
class ColorPickerControls extends StatefulWidget {
  final bool isBgEditMode;
  final Color? bgColor;
  final Function(bool) onBgEditModeChanged;
  final Function(Color?) onColorChanged;
  final Function(bool)? onSliderInteractionChanged;
  
  /// External color to set the sliders to (e.g., from palette selection)
  final Color? externalColor;

  const ColorPickerControls({
    super.key,
    required this.isBgEditMode,
    required this.bgColor,
    required this.onBgEditModeChanged,
    required this.onColorChanged,
    this.onSliderInteractionChanged,
    this.externalColor,
  });

  @override
  State<ColorPickerControls> createState() => _ColorPickerControlsState();
}

class _ColorPickerControlsState extends State<ColorPickerControls> {
  // OKLCH values
  double lightness = 0.7;  // 0.0 to 1.0
  double chroma = 0.15;    // 0.0 to 0.4 (0.37 is max for sRGB)
  double hue = 240.0;      // 0 to 360 degrees
  double mixValue = 0.0;   // 0.0 to 1.0 for mixed channel slider
  
  // Extreme colors (independent of global OKLCH)
  Color leftExtremeColor = const Color(0xFF808080); // Gray initial
  Color rightExtremeColor = const Color(0xFFFFFFFF); // White initial
  
  // Tracking states
  bool isLeftExtremeTracking = false;
  bool isRightExtremeTracking = false;
  
  // Slider interaction state
  bool sliderIsActive = false;
  
  // Background color editing mode
  double bgLightness = 0.15;  // Dark gray for bg (252525)
  double bgChroma = 0.0;
  double bgHue = 0.0;
  
  // Converted color
  Color? currentColor;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    
    // Initialize from external color if provided
    if (widget.externalColor != null) {
      _setFromExternalColor(widget.externalColor!);
    }
    
    // Defer the initial color update to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateColor();
    });
  }
  
  @override
  void didUpdateWidget(ColorPickerControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // If external color changed, update sliders (only in color edit mode)
    if (!widget.isBgEditMode && 
        widget.externalColor != null && 
        widget.externalColor != oldWidget.externalColor) {
      setState(() {
        _setFromExternalColor(widget.externalColor!);
        // Don't call _updateColor() here - it would trigger onColorChanged callback
        // and create an infinite loop. Just update the internal state.
        currentColor = widget.externalColor;
      });
    }
  }
  
  /// Set slider values from an external color
  void _setFromExternalColor(Color color) {
    final oklch = srgbToOklch(color);
    lightness = oklch.l;
    chroma = oklch.c;
    hue = oklch.h;
    
    // Reset slider state when external color is set
    sliderIsActive = false;
    isLeftExtremeTracking = false;
    isRightExtremeTracking = false;
  }

  void _updateColor() {
    try {
      setState(() {
        // Update background color if in bg edit mode
        if (widget.isBgEditMode) {
          final bgColor = colorFromOklch(bgLightness, bgChroma, bgHue);
          widget.onColorChanged(bgColor);
          errorMessage = '';
          return;
        }

        // Get current global OKLCH color
        final globalColor = colorFromOklch(lightness, chroma, hue);

        // Update tracking extremes
        if (isLeftExtremeTracking) {
          leftExtremeColor = globalColor;
        }
        if (isRightExtremeTracking) {
          rightExtremeColor = globalColor;
        }

        // Calculate final display color
        if (sliderIsActive) {
          // Slider is controlling: interpolate and set as global
          final interpolated = Color.lerp(leftExtremeColor, rightExtremeColor, mixValue)!;
          final oklch = srgbToOklch(interpolated);
          lightness = oklch.l;
          chroma = oklch.c;
          hue = oklch.h;
          currentColor = interpolated;
        } else {
          // Slider is not controlling: just display global color
          currentColor = globalColor;
        }

        widget.onColorChanged(currentColor);
        errorMessage = '';
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error: $e';
      });
    }
  }

  void _handleLeftExtremeAction(String action) {
    setState(() {
      if (action == 'takeIn' || action == 'giveTo') {
        // Disconnect the other extreme (only one can track)
        isRightExtremeTracking = false;
        
        if (action == 'takeIn') {
          // Copy global to left extreme
          leftExtremeColor = colorFromOklch(lightness, chroma, hue);
        } else {
          // Copy left extreme to global
          final oklch = srgbToOklch(leftExtremeColor);
          lightness = oklch.l;
          chroma = oklch.c;
          hue = oklch.h;
        }
        
        // Start tracking
        isLeftExtremeTracking = true;
      } else if (action == 'disconnect') {
        isLeftExtremeTracking = false;
      }
      _updateColor();
    });
  }

  void _handleRightExtremeAction(String action) {
    setState(() {
      if (action == 'takeIn' || action == 'giveTo') {
        // Disconnect the other extreme (only one can track)
        isLeftExtremeTracking = false;
        
        if (action == 'takeIn') {
          // Copy global to right extreme
          rightExtremeColor = colorFromOklch(lightness, chroma, hue);
        } else {
          // Copy right extreme to global
          final oklch = srgbToOklch(rightExtremeColor);
          lightness = oklch.l;
          chroma = oklch.c;
          hue = oklch.h;
        }
        
        // Start tracking
        isRightExtremeTracking = true;
      } else if (action == 'disconnect') {
        isRightExtremeTracking = false;
      }
      _updateColor();
    });
  }

  void _handleSliderTouchStart() {
    setState(() {
      // Disconnect both extremes when slider is touched
      isLeftExtremeTracking = false;
      isRightExtremeTracking = false;
      sliderIsActive = true;
      _updateColor();
    });
  }

  void _handleSliderTouchEnd() {
    setState(() {
      sliderIsActive = false;
      // Slider position stays fixed, global disconnects
      _updateColor();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Lightness slider with gradient
        OklchGradientSlider(
          value: widget.isBgEditMode ? bgLightness : lightness,
          min: 0.0,
          max: 1.0,
          label: 'Lightness (L)',
          description: '',
          step: 0.01,
          decimalPlaces: 2,
          onChanged: (value) {
            setState(() {
              if (widget.isBgEditMode) {
                bgLightness = value;
              } else {
                lightness = value;
                sliderIsActive = false; // Disconnect slider
              }
              _updateColor();
            });
          },
          generateGradient: () => widget.isBgEditMode 
              ? generateLightnessGradient(bgChroma, bgHue, 300)
              : generateLightnessGradient(chroma, hue, 300),
          showSplitView: true,
          onInteractionChanged: widget.onSliderInteractionChanged,
        ),
        
        // Chroma slider with gradient
        OklchGradientSlider(
          value: widget.isBgEditMode ? bgChroma : chroma,
          min: 0.0,
          max: 0.4,
          label: 'Chroma (C)',
          description: '',
          step: 0.01,
          decimalPlaces: 2,
          onChanged: (value) {
            setState(() {
              if (widget.isBgEditMode) {
                bgChroma = value;
              } else {
                chroma = value;
                sliderIsActive = false; // Disconnect slider
              }
              _updateColor();
            });
          },
          generateGradient: () => widget.isBgEditMode
              ? generateChromaGradient(bgLightness, bgHue, 300)
              : generateChromaGradient(lightness, hue, 300),
          showSplitView: true,
          onInteractionChanged: widget.onSliderInteractionChanged,
        ),
        
        // Hue slider with gradient
        OklchGradientSlider(
          value: widget.isBgEditMode ? bgHue : hue,
          min: 0.0,
          max: 360.0,
          label: 'Hue (H)',
          description: '',
          step: 1.0,
          decimalPlaces: 0,
          onChanged: (value) {
            setState(() {
              if (widget.isBgEditMode) {
                bgHue = value;
              } else {
                hue = value;
                sliderIsActive = false; // Disconnect slider
              }
              _updateColor();
            });
          },
          generateGradient: () => widget.isBgEditMode
              ? generateHueGradient(bgLightness, bgChroma, 300)
              : generateHueGradient(lightness, chroma, 300),
          showSplitView: true,
          onInteractionChanged: widget.onSliderInteractionChanged,
        ),
        
        // Mixed channel slider with dot system (hidden in bg edit mode)
        if (!widget.isBgEditMode)
          MixedChannelSlider(
            value: mixValue,
            currentColor: colorFromOklch(lightness, chroma, hue),
            leftExtremeColor: leftExtremeColor,
            rightExtremeColor: rightExtremeColor,
            isLeftTracking: isLeftExtremeTracking,
            isRightTracking: isRightExtremeTracking,
            sliderIsActive: sliderIsActive,
            onChanged: (value) {
              setState(() {
                mixValue = value.clamp(0.0, 1.0);
                if (sliderIsActive) {
                  _updateColor();
                }
              });
            },
            onLeftExtremeAction: _handleLeftExtremeAction,
            onRightExtremeAction: _handleRightExtremeAction,
            onSliderTouchStart: _handleSliderTouchStart,
            onSliderTouchEnd: _handleSliderTouchEnd,
            onInteractionChanged: widget.onSliderInteractionChanged,
          ),
        
        if (errorMessage.isNotEmpty) ...[
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber),
            ),
            child: Text(
              errorMessage,
              style: const TextStyle(
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
        
        const SizedBox(height: 30),
      ],
    );
  }
}
