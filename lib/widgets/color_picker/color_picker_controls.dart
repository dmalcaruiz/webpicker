import 'package:flutter/material.dart';
import '../../utils/color_operations.dart';
import '../../models/extreme_color_item.dart';
import 'oklch_gradient_slider.dart';
import '../sliders/mixer_slider.dart' show MixedChannelSlider;

/// A widget containing all the color picker slider controls
class ColorPickerControls extends StatefulWidget {
  final bool isBgEditMode;
  final Color? bgColor;
  final Function(bool) onBgEditModeChanged;

  /// OKLCH change callback (source of truth)
  final Function({
    required double lightness,
    required double chroma,
    required double hue,
    double alpha,
  }) onOklchChanged;

  final Function(bool)? onSliderInteractionChanged;

  /// External OKLCH values to set the sliders to (e.g., from palette selection)
  final double? externalLightness;
  final double? externalChroma;
  final double? externalHue;
  final double? externalAlpha;

  /// Mixer extreme colors (managed by parent)
  final ExtremeColorItem leftExtreme;
  final ExtremeColorItem rightExtreme;

  /// Callback when an extreme is tapped
  final Function(String extremeId) onExtremeTap;

  /// Callback when mixer slider is touched (to deselect extremes)
  final VoidCallback? onMixerSliderTouched;

  /// Whether to use ICC profile filtering for display
  final bool useRealPigmentsOnly;

  /// Callback when real pigments toggle changes
  final Function(bool)? onRealPigmentsOnlyChanged;

  const ColorPickerControls({
    super.key,
    required this.isBgEditMode,
    required this.bgColor,
    required this.onBgEditModeChanged,
    required this.onOklchChanged,
    this.onSliderInteractionChanged,
    this.externalLightness,
    this.externalChroma,
    this.externalHue,
    this.externalAlpha,
    required this.leftExtreme,
    required this.rightExtreme,
    required this.onExtremeTap,
    this.onMixerSliderTouched,
    this.useRealPigmentsOnly = false,
    this.onRealPigmentsOnlyChanged,
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

  // Slider interaction state
  bool sliderIsActive = false;

  // Pigment mixing toggle state
  bool usePigmentMixing = false;

  // Flag to prevent feedback loop when we update the color internally
  bool _isInternalUpdate = false;

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

    // Initialize from external OKLCH values if provided (no conversion!)
    if (widget.externalLightness != null &&
        widget.externalChroma != null &&
        widget.externalHue != null) {
      lightness = widget.externalLightness!;
      chroma = widget.externalChroma!;
      hue = widget.externalHue!;
    }

    // Defer the initial color update to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateColor();
    });
  }

  @override
  void didUpdateWidget(ColorPickerControls oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If external OKLCH values changed, update sliders (only in color edit mode)
    // BUT skip if we're the source of the change (prevent feedback loop)
    if (!widget.isBgEditMode &&
        widget.externalLightness != null &&
        widget.externalChroma != null &&
        widget.externalHue != null &&
        (widget.externalLightness != oldWidget.externalLightness ||
         widget.externalChroma != oldWidget.externalChroma ||
         widget.externalHue != oldWidget.externalHue) &&
        !_isInternalUpdate) {
      setState(() {
        // Direct OKLCH assignment - NO CONVERSION!
        lightness = widget.externalLightness!;
        chroma = widget.externalChroma!;
        hue = widget.externalHue!;

        // Reset slider state when external values are set
        sliderIsActive = false;

        // Update display color
        currentColor = colorFromOklch(lightness, chroma, hue);
      });
    }

    // Reset the flag after processing
    _isInternalUpdate = false;
  }

  /// Linear interpolation for double values
  double _lerpDouble(double a, double b, double t) {
    return a + (b - a) * t;
  }

  /// Hue interpolation with wraparound (shortest path around color wheel)
  double _lerpHue(double h1, double h2, double t) {
    // Normalize hues to [0, 360)
    h1 = h1 % 360;
    h2 = h2 % 360;
    if (h1 < 0) h1 += 360;
    if (h2 < 0) h2 += 360;

    // Calculate the shortest distance between hues
    double diff = h2 - h1;

    // If difference is more than 180°, go the other way around the wheel
    if (diff > 180) {
      diff -= 360;
    } else if (diff < -180) {
      diff += 360;
    }

    // Interpolate and normalize result
    double result = h1 + diff * t;
    if (result < 0) result += 360;
    if (result >= 360) result -= 360;

    return result;
  }

  void _updateColor() {
    try {
      setState(() {
        // Set flag to prevent feedback loop
        _isInternalUpdate = true;

        // Update background color if in bg edit mode
        if (widget.isBgEditMode) {
          // For bg mode, send OKLCH values too
          widget.onOklchChanged(
            lightness: bgLightness,
            chroma: bgChroma,
            hue: bgHue,
            alpha: 1.0,
          );
          errorMessage = '';
          return;
        }

        // Get current global OKLCH color
        final globalColor = colorFromOklch(lightness, chroma, hue);

        // Calculate final values
        if (sliderIsActive) {
          // Slider is controlling: interpolate IN OKLCH SPACE (perceptually uniform!)

          // Step 1: Convert extremes to OKLCH
          final leftOklch = srgbToOklch(widget.leftExtreme.color);
          final rightOklch = srgbToOklch(widget.rightExtreme.color);

          // Step 2: Interpolate each OKLCH component separately
          lightness = _lerpDouble(leftOklch.l, rightOklch.l, mixValue);
          chroma = _lerpDouble(leftOklch.c, rightOklch.c, mixValue);

          // Step 3: Interpolate hue with wraparound (shortest path around color wheel)
          hue = _lerpHue(leftOklch.h, rightOklch.h, mixValue);

          // Step 4: Convert back to sRGB for display
          currentColor = colorFromOklch(lightness, chroma, hue);
        } else {
          // Slider is not controlling: just display global color
          currentColor = globalColor;
        }

        // Call OKLCH callback (source of truth)
        widget.onOklchChanged(
          lightness: lightness,
          chroma: chroma,
          hue: hue,
          alpha: 1.0,
        );
        errorMessage = '';
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error: $e';
      });
    }
  }

  void _handleSliderTouchStart() {
    // Notify parent to deselect extremes when mixer slider is touched
    widget.onMixerSliderTouched?.call();

    setState(() {
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
              : generateLightnessGradient(
                  chroma,
                  hue,
                  300,
                  useRealPigmentsOnly: widget.useRealPigmentsOnly,
                ),
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
              : generateChromaGradient(
                  lightness,
                  hue,
                  300,
                  useRealPigmentsOnly: widget.useRealPigmentsOnly,
                ),
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
              : generateHueGradient(
                  lightness,
                  chroma,
                  300,
                  useRealPigmentsOnly: widget.useRealPigmentsOnly,
                ),
          showSplitView: true,
          onInteractionChanged: widget.onSliderInteractionChanged,
        ),
        
        // Mixed channel slider with extreme circles (hidden in bg edit mode)
        if (!widget.isBgEditMode)
          MixedChannelSlider(
            value: mixValue,
            currentColor: colorFromOklch(lightness, chroma, hue),
            leftExtreme: widget.leftExtreme,
            rightExtreme: widget.rightExtreme,
            sliderIsActive: sliderIsActive,
            usePigmentMixing: usePigmentMixing,
            useRealPigmentsOnly: widget.useRealPigmentsOnly,
            onChanged: (value) {
              setState(() {
                mixValue = value.clamp(0.0, 1.0);
                if (sliderIsActive) {
                  _updateColor();
                }
              });
            },
            onPigmentMixingChanged: (value) {
              setState(() {
                usePigmentMixing = value;
              });
            },
            onRealPigmentsOnlyChanged: widget.onRealPigmentsOnlyChanged,
            onExtremeTap: widget.onExtremeTap,
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
