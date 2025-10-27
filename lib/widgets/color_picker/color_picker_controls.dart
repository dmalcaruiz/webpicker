import 'package:flutter/material.dart';
import '../../utils/color_operations.dart';
import '../../utils/mixbox.dart';
import '../../models/extreme_color_item.dart';
import 'oklch_gradient_slider.dart';
import '../sliders/mixer_slider.dart' show MixedChannelSlider;


/// A widget containing all the color picker slider controls
class ColorPickerControls extends StatefulWidget {
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

  /// Whether to constrain colors to real pigment gamut (ICC profile)
  final bool useRealPigmentsOnly;

  /// Optional color filter for extreme colors (ICC profile display)
  final Color Function(ExtremeColorItem)? extremeColorFilter;

  /// Optional color filter for gradient colors (ICC profile display)
  final Color Function(Color color, double l, double c, double h, double a)? gradientColorFilter;

  final Color? bgColor;

  final Function(String extremeId, DragStartDetails details)? onPanStartExtreme; // Add this line

  const ColorPickerControls({
    super.key,
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
    this.extremeColorFilter,
    this.gradientColorFilter,
    this.bgColor,
    this.onPanStartExtreme, // Add this line
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

  // Slider order (for reorderable list)
  List<String> _sliderOrder = ['lightness', 'chroma', 'hue', 'mixer'];

  // Converted color
  Color? currentColor;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    debugPrint('ColorPickerControls initState - usePigmentMixing: $usePigmentMixing');
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
    debugPrint('ColorPickerControls didUpdateWidget - usePigmentMixing: $usePigmentMixing');
    // If external OKLCH values changed, update sliders
    // BUT skip if we're the source of the change (prevent feedback loop)
    if (widget.externalLightness != null &&
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

        // Get current global OKLCH color
        final globalColor = colorFromOklch(lightness, chroma, hue);

        // Calculate final values
        if (sliderIsActive) {
          // Slider is controlling: interpolate between extremes

          if (usePigmentMixing) {
            // Use Kubelka-Munk (Mixbox) for realistic pigment mixing
            final mixedColor = lerpMixbox(
              widget.leftExtreme.color,
              widget.rightExtreme.color,
              mixValue,
            );

            // Extract OKLCH values from the mixed color
            final mixedOklch = srgbToOklch(mixedColor);
            lightness = mixedOklch.l;
            chroma = mixedOklch.c;
            hue = mixedOklch.h;
            currentColor = mixedColor;
          } else {
            // Use OKLCH interpolation (perceptually uniform)

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
          }
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

  Widget _buildLightnessSlider() {
    return OklchGradientSlider(
      value: lightness,
      min: 0.0,
      max: 1.0,
      label: 'Lightness (L)',
      description: '',
      step: 0.01,
      decimalPlaces: 2,
      onChanged: (value) {
        setState(() {
          lightness = value;
          sliderIsActive = false;
          _updateColor();
        });
      },
      generateGradient: () => generateLightnessGradient(
        chroma,
        hue,
        300,
        useRealPigmentsOnly: widget.useRealPigmentsOnly,
      ),
      showSplitView: true,
      onInteractionChanged: widget.onSliderInteractionChanged,
      bgColor: widget.bgColor, // Pass bgColor
    );
  }

  Widget _buildChromaSlider() {
    return OklchGradientSlider(
      value: chroma,
      min: 0.0,
      max: 0.4,
      label: 'Chroma (C)',
      description: '',
      step: 0.01,
      decimalPlaces: 2,
      onChanged: (value) {
        setState(() {
          chroma = value;
          sliderIsActive = false;
          _updateColor();
        });
      },
      generateGradient: () => generateChromaGradient(
        lightness,
        hue,
        300,
        useRealPigmentsOnly: widget.useRealPigmentsOnly,
      ),
      showSplitView: true,
      onInteractionChanged: widget.onSliderInteractionChanged,
      bgColor: widget.bgColor, // Pass bgColor
    );
  }

  Widget _buildHueSlider() {
    return OklchGradientSlider(
      value: hue,
      min: 0.0,
      max: 360.0,
      label: 'Hue (H)',
      description: '',
      step: 1.0,
      decimalPlaces: 0,
      onChanged: (value) {
        setState(() {
          hue = value;
          sliderIsActive = false;
          _updateColor();
        });
      },
      generateGradient: () => generateHueGradient(
        lightness,
        chroma,
        300,
        useRealPigmentsOnly: widget.useRealPigmentsOnly,
      ),
      showSplitView: true,
      onInteractionChanged: widget.onSliderInteractionChanged,
      bgColor: widget.bgColor, // Pass bgColor
    );
  }

  Widget _buildMixerSlider() {
    return MixedChannelSlider(
      value: mixValue,
      currentColor: colorFromOklch(lightness, chroma, hue),
      leftExtreme: widget.leftExtreme,
      rightExtreme: widget.rightExtreme,
      sliderIsActive: sliderIsActive,
      usePigmentMixing: usePigmentMixing,
      useRealPigmentsOnly: widget.useRealPigmentsOnly,
      extremeColorFilter: widget.extremeColorFilter,
      gradientColorFilter: widget.gradientColorFilter,
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
          debugPrint('ColorPickerControls onPigmentMixingChanged - usePigmentMixing: $usePigmentMixing');
        });
      },
      onExtremeTap: widget.onExtremeTap,
      onSliderTouchStart: _handleSliderTouchStart,
      onSliderTouchEnd: _handleSliderTouchEnd,
      onInteractionChanged: widget.onSliderInteractionChanged,
      bgColor: widget.bgColor, // Pass bgColor
      onPanStartExtreme: widget.onPanStartExtreme, // Pass to MixedChannelSlider
    );
  }

  Widget _buildSliderByType(String type) {
    switch (type) {
      case 'lightness':
        return _buildLightnessSlider();
      case 'chroma':
        return _buildChromaSlider();
      case 'hue':
        return _buildHueSlider();
      case 'mixer':
        return _buildMixerSlider();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _wrapWithDragHandle(Widget slider, int index) {
    return Stack(
      children: [
        slider,
        // Long-press drag handle positioned ONLY over the title text (left side)
        Positioned(
          top: 12,
          left: 13.5,
          width: 90, // Only covers the title text area, not the buttons
          height: 35,
          child: ReorderableDragStartListener(
            index: index,
            child: Container(
              color: Colors.transparent,
              // This transparent container only covers the title text
              // Long-pressing on "Lightness (L)" etc will trigger reordering
              // Plus/minus buttons remain clickable
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ReorderableListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      onReorder: (oldIndex, newIndex) {
        setState(() {
          if (newIndex > oldIndex) {
            newIndex -= 1;
          }
          final item = _sliderOrder.removeAt(oldIndex);
          _sliderOrder.insert(newIndex, item);
        });
      },
      proxyDecorator: (Widget child, int index, Animation<double> animation) {
        return Material(
          color: widget.bgColor ?? Colors.transparent, // Use the provided background color
          borderRadius: BorderRadius.circular(10),
          child: child,
        );
      },
      children: [
        for (int index = 0; index < _sliderOrder.length; index++)
          Container(
            key: ValueKey(_sliderOrder[index]),
            child: _wrapWithDragHandle(
              _buildSliderByType(_sliderOrder[index]),
              index,
            ),
          ),
      ],
    );
  }
}
