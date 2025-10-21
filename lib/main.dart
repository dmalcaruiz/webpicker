import 'package:flutter/material.dart';
import 'color_operations.dart';
import 'widgets/oklch_gradient_slider.dart';
import 'widgets/mixer_slider.dart' show MixedChannelSlider;



void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const OklchPickerScreen(),
    );
  }
}

// OKLCH Color Picker Screen
class OklchPickerScreen extends StatefulWidget {
  const OklchPickerScreen({super.key});

  @override
  State<OklchPickerScreen> createState() => _OklchPickerScreenState();
}

class _OklchPickerScreenState extends State<OklchPickerScreen> {
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
  bool isBgEditMode = false;
  double bgLightness = 0.15;  // Dark gray for bg (252525)
  double bgChroma = 0.0;
  double bgHue = 0.0;
  Color? bgColor;
  
  // Converted color
  Color? currentColor;
  String errorMessage = '';
  

  @override
  void initState() {
    super.initState();
    _updateColor();
    bgColor = colorFromOklch(bgLightness, bgChroma, bgHue);
  }
  
  

  void _updateColor() {
    try {
      setState(() {
        // Update background color if in bg edit mode
        if (isBgEditMode) {
          bgColor = colorFromOklch(bgLightness, bgChroma, bgHue);
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
    return Scaffold(
      backgroundColor: bgColor ?? const Color(0xFF252525),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
              
              const SizedBox(height: 20),
              
              // Single color display box
              Container(
                height: 120,
                margin: const EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                  color: currentColor ?? const Color(0xFF808080),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '#${(currentColor?.value.toRadixString(16).substring(2).toUpperCase() ?? '808080')}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: (currentColor?.computeLuminance() ?? 0.5) > 0.5 ? Colors.black : Colors.white,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 30),
              
              // Lightness slider with gradient
              OklchGradientSlider(
                value: isBgEditMode ? bgLightness : lightness,
                min: 0.0,
                max: 1.0,
                label: 'Lightness (L)',
                description: '',
                step: 0.01,
                decimalPlaces: 2,
                onChanged: (value) {
                  setState(() {
                    if (isBgEditMode) {
                      bgLightness = value;
                    } else {
                      lightness = value;
                      sliderIsActive = false; // Disconnect slider
                    }
                    _updateColor();
                  });
                },
                generateGradient: () => isBgEditMode 
                    ? generateLightnessGradient(bgChroma, bgHue, 300)
                    : generateLightnessGradient(chroma, hue, 300),
                showSplitView: true,
              ),
              
              // Chroma slider with gradient
              OklchGradientSlider(
                value: isBgEditMode ? bgChroma : chroma,
                min: 0.0,
                max: 0.4,
                label: 'Chroma (C)',
                description: '',
                step: 0.01,
                decimalPlaces: 2,
                onChanged: (value) {
                  setState(() {
                    if (isBgEditMode) {
                      bgChroma = value;
                    } else {
                      chroma = value;
                      sliderIsActive = false; // Disconnect slider
                    }
                    _updateColor();
                  });
                },
                generateGradient: () => isBgEditMode
                    ? generateChromaGradient(bgLightness, bgHue, 300)
                    : generateChromaGradient(lightness, hue, 300),
                showSplitView: true,
              ),
              
              // Hue slider with gradient
              OklchGradientSlider(
                value: isBgEditMode ? bgHue : hue,
                min: 0.0,
                max: 360.0,
                label: 'Hue (H)',
                description: '',
                step: 1.0,
                decimalPlaces: 0,
                onChanged: (value) {
                  setState(() {
                    if (isBgEditMode) {
                      bgHue = value;
                    } else {
                      hue = value;
                      sliderIsActive = false; // Disconnect slider
                    }
                    _updateColor();
                  });
                },
                generateGradient: () => isBgEditMode
                    ? generateHueGradient(bgLightness, bgChroma, 300)
                    : generateHueGradient(lightness, chroma, 300),
                showSplitView: true,
              ),
              
              // Mixed channel slider with dot system (hidden in bg edit mode)
              if (!isBgEditMode)
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
              ),
            ),
          ),
          // Bottom button for Edit Background/Edit Colors
          Container(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  isBgEditMode = !isBgEditMode;
                });
              },
              icon: Icon(isBgEditMode ? Icons.palette : Icons.format_paint),
              label: Text(isBgEditMode ? 'Edit Colors' : 'Edit Background'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black.withOpacity(0.3),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}