import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pie_menu/pie_menu.dart';
import 'color_operations.dart';
import 'widgets/oklch_gradient_slider.dart';
import 'widgets/alpha_slider.dart' show MixedChannelSlider;

/// Represents a color box with its own OKLCH values, lock state, and focus state
class ColorBox {
  final String id;
  double lightness;
  double chroma;
  double hue;
  bool isLocked;
  bool isFocused;  // Step 1: Add focus state to ColorBox class
  
  ColorBox({
    required this.id,
    required this.lightness,
    required this.chroma,
    required this.hue,
    this.isLocked = false,
    this.isFocused = false,  // Step 2: Initialize focus state as false
  });
  
  Color get color => colorFromOklch(lightness, chroma, hue);
  
  /// Step 3: Update method to respect both lock and focus states
  void updateFromGlobal(double l, double c, double h) {
    // Only update if not locked AND either focused or no box is focused
    if (!isLocked) {
      lightness = l;
      chroma = c;
      hue = h;
    }
  }
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: PieCanvas(
        child: const OklchPickerScreen(),
      ),
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
  
  // Color boxes management
  List<ColorBox> colorBoxes = [];
  int maxBoxes = 15;
  
  // Step 4: Add focus state management
  String? focusedBoxId;  // Track which box is currently focused

  @override
  void initState() {
    super.initState();
    _updateColor();
    bgColor = colorFromOklch(bgLightness, bgChroma, bgHue);
    
    // Initialize with one unlocked color box
    colorBoxes.add(ColorBox(
      id: 'box_0',
      lightness: lightness,
      chroma: chroma,
      hue: hue,
      isLocked: false,
    ));
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

        // Step 5: Update color boxes based on focus state
        for (final box in colorBoxes) {
          // Only update if no box is focused, OR this box is focused
          if (focusedBoxId == null || box.id == focusedBoxId) {
            box.updateFromGlobal(lightness, chroma, hue);
          }
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

  /// Apply hex color from clipboard
  /// 
  /// Step 1: Read clipboard, parse hex (with or without #), convert to OKLCH
  void _applyHexFromClipboard() async {
    try {
      final data = await Clipboard.getData('text/plain');
      if (data?.text != null) {
        String hex = data!.text!.trim();
        
        // Step 2: Remove # if present
        if (hex.startsWith('#')) {
          hex = hex.substring(1);
        }
        
        // Step 3: Parse hex and convert to color
        if (hex.length == 6) {
          final color = Color(int.parse('FF$hex', radix: 16));
          final oklch = srgbToOklch(color);
          
          // Step 4: Apply to global OKLCH state
          setState(() {
            lightness = oklch.l;
            chroma = oklch.c;
            hue = oklch.h;
            _updateColor();
          });
        }
      }
    } catch (e) {
      // Ignore parsing errors
    }
  }

  /// Apply preset color from pie menu
  /// 
  /// Step 1: Convert color to OKLCH and apply to global state
  void _applyPresetColor(Color color) {
    final oklch = srgbToOklch(color);
    setState(() {
      lightness = oklch.l;
      chroma = oklch.c;
      hue = oklch.h;
      _updateColor();
    });
  }

  /// Add a new color box
  void _addColorBox() {
    if (colorBoxes.length < maxBoxes) {
      setState(() {
        colorBoxes.add(ColorBox(
          id: 'box_${colorBoxes.length}',
          lightness: lightness,
          chroma: chroma,
          hue: hue,
          isLocked: false,
        ));
      });
    }
  }

  /// Remove a color box (but keep at least one unlocked)
  void _removeColorBox() {
    if (colorBoxes.length > 1) {
      setState(() {
        // Find first unlocked box to keep
        final unlockedBox = colorBoxes.firstWhere(
          (box) => !box.isLocked,
          orElse: () => colorBoxes.first,
        );
        
        // Remove the last box if it's not the only unlocked one
        if (colorBoxes.last.id != unlockedBox.id) {
          colorBoxes.removeLast();
        } else {
          // If removing the only unlocked box, unlock another one
          final otherBox = colorBoxes.firstWhere(
            (box) => box.id != unlockedBox.id,
            orElse: () => colorBoxes.first,
          );
          otherBox.isLocked = false;
          colorBoxes.removeLast();
        }
      });
    }
  }

  /// Toggle lock state of a color box
  void _toggleBoxLock(ColorBox box) {
    setState(() {
      // Ensure at least one box remains unlocked
      final unlockedCount = colorBoxes.where((b) => !b.isLocked).length;
      if (box.isLocked || unlockedCount > 1) {
        box.isLocked = !box.isLocked;
      }
    });
  }
  
  /// Step 6: Toggle focus state of a color box
  void _toggleBoxFocus(ColorBox box) {
    setState(() {
      if (focusedBoxId == box.id) {
        // If this box is focused, unfocus it
        focusedBoxId = null;
        box.isFocused = false;
      } else {
        // Focus this box and unfocus all others
        focusedBoxId = box.id;
        for (final otherBox in colorBoxes) {
          otherBox.isFocused = (otherBox.id == box.id);
        }
      }
    });
  }

  /// Apply hex color to specific box or all unlocked boxes
  void _applyHexToBox(ColorBox? targetBox) async {
    try {
      final data = await Clipboard.getData('text/plain');
      if (data?.text != null) {
        String hex = data!.text!.trim();
        
        // Remove # if present
        if (hex.startsWith('#')) {
          hex = hex.substring(1);
        }
        
        // Parse hex and convert to color
        if (hex.length == 6) {
          final color = Color(int.parse('FF$hex', radix: 16));
          final oklch = srgbToOklch(color);
          
          setState(() {
            if (targetBox != null && targetBox.isLocked) {
              // Apply only to locked box
              targetBox.lightness = oklch.l;
              targetBox.chroma = oklch.c;
              targetBox.hue = oklch.h;
            } else {
              // Apply to global and all unlocked boxes
              lightness = oklch.l;
              chroma = oklch.c;
              hue = oklch.h;
              _updateColor();
            }
          });
        }
      }
    } catch (e) {
      // Ignore parsing errors
    }
  }

  /// Calculate dynamic font size based on container dimensions
  double _calculateFontSize(double containerWidth, double containerHeight) {
    // Use the smaller dimension to ensure text fits well
    double minDimension = containerWidth < containerHeight ? containerWidth : containerHeight;
    // Reasonable scaling - 15% of container size
    double baseSize = (minDimension * 0.15).clamp(12.0, 48.0);
    return baseSize;
  }

  /// Build split color box rows (flexbox system)
  /// 
  /// Creates up to 3 rows with 5 boxes each, splitting the main global color
  List<Widget> _buildSplitColorBoxRows() {
    const int maxPerRow = 5;
    const int maxRows = 3;
    const int maxTotalBoxes = maxPerRow * maxRows; // 15
    
    List<Widget> rows = [];
    
    // Calculate how many boxes to show (based on current global color)
    int boxesToShow = (colorBoxes.length).clamp(1, maxTotalBoxes);
    
    for (int row = 0; row < maxRows; row++) {
      int startIndex = row * maxPerRow;
      int endIndex = (startIndex + maxPerRow).clamp(0, boxesToShow);
      
      if (startIndex >= boxesToShow) break;
      
      // Create boxes for this row
      List<Widget> rowBoxes = [];
      for (int i = startIndex; i < endIndex; i++) {
        // Use existing colorBox if available, otherwise use global color
        ColorBox box;
        if (i < colorBoxes.length) {
          box = colorBoxes[i];
        } else {
          // Create new box with current global color
          box = ColorBox(
            id: 'split_box_$i',
            lightness: lightness,
            chroma: chroma,
            hue: hue,
            isLocked: false,
          );
        }
        rowBoxes.add(_buildSplitColorBox(box, i));
      }
      
      rows.add(
        Row(
          children: rowBoxes,
        ),
      );
      
      if (row < maxRows - 1 && endIndex < boxesToShow) {
        rows.add(const SizedBox(height: 8));
      }
    }
    
    return rows;
  }

  /// Build individual split color box (flexbox version)
  Widget _buildSplitColorBox(ColorBox box, int index) {
    return Expanded(
      child: Container(
        height: 120,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: box.color,
          borderRadius: BorderRadius.circular(8),
          // Step 1: Remove stroke creation when box is locked
        ),
        child: Stack(
          children: [
            // Main color box content
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                // Copy hex to clipboard
                final hex = box.color.value.toRadixString(16).substring(2).toUpperCase();
                Clipboard.setData(ClipboardData(text: '#$hex'));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Copied #$hex to clipboard'),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
              onLongPress: () => _applyHexToBox(box),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Container(
        width: double.infinity,
        height: double.infinity,
                    child: Center(
                      child: Text(
                        '#${box.color.value.toRadixString(16).substring(2).toUpperCase()}',
              style: TextStyle(
                          fontSize: _calculateFontSize(constraints.maxWidth, constraints.maxHeight),
                          fontWeight: FontWeight.bold,
                          color: box.lightness > 0.6 ? Colors.black : Colors.white,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            
            // Lock/unlock button (only show if more than one box)
            if (colorBoxes.length > 1)
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: () => _toggleBoxLock(box),
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      // Step 2: White background for locked, semi-transparent for unlocked
                      color: box.isLocked ? Colors.white : Colors.white24,
                      shape: BoxShape.circle,
                      // Step 3: Remove all borders completely
                    ),
                    child: Icon(
                      box.isLocked ? Icons.lock : Icons.lock_open,
                      size: 12,
                      // Step 2: Black icon for locked, white for unlocked
                      color: box.isLocked ? Colors.black : Colors.white,
                    ),
                  ),
                ),
              ),
            
            // Step 7: Focus button (bottom right) - only show if more than one box
            if (colorBoxes.length > 1)
              Positioned(
                bottom: 4,
                right: 4,
                child: GestureDetector(
                  onTap: () => _toggleBoxFocus(box),
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: box.isFocused ? const Color(0xFFFF9800) : Colors.white24,
                      shape: BoxShape.circle,
                      // Remove border from focus icon too
                    ),
                    child: Icon(
                      Icons.center_focus_strong,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor ?? const Color(0xFF252525),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
              // Preset color picker with pie menu and color box controls
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Remove color box button (left side)
                  IconButton(
                    onPressed: colorBoxes.length > 1 ? _removeColorBox : null,
                    icon: const Icon(Icons.remove),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white30, width: 1),
                    ),
                    tooltip: 'Remove Color Box',
                  ),
                  
                  const SizedBox(width: 20),
                  
                  // Pie menu
                  PieMenu(
                    onPressed: () {},
                    theme: PieTheme(
                      brightness: Brightness.dark,
                      overlayColor: Colors.black45,
                      pointerSize: 15,
                      buttonSize: 45,
                      buttonTheme: const PieButtonTheme(
                        backgroundColor: Color(0xFF2A2A2A),
                        iconColor: Colors.white,
                      ),
                      leftClickShowsMenu: true,
                      rightClickShowsMenu: false,
                      delayDuration: const Duration(milliseconds: 50),
                      radius: 80,
                      customAngle: 180,
                      customAngleAnchor: PieAnchor.center,
                      angleOffset: 270, // Downward vertical
                      menuAlignment: Alignment.center,
                      menuDisplacement: const Offset(0, 40),
                    ),
                    actions: [
                      // Red
                      PieAction(
                        tooltip: const Text('Red'),
                        onSelect: () => _applyPresetColor(const Color(0xFFFF0000)),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFF0000),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      // Green
                      PieAction(
                        tooltip: const Text('Green'),
                        onSelect: () => _applyPresetColor(const Color(0xFF00FF00)),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: Color(0xFF00FF00),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      // Blue
                      PieAction(
                        tooltip: const Text('Blue'),
                        onSelect: () => _applyPresetColor(const Color(0xFF0000FF)),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: Color(0xFF0000FF),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      // Cyan
                      PieAction(
                        tooltip: const Text('Cyan'),
                        onSelect: () => _applyPresetColor(const Color(0xFF00FFFF)),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: Color(0xFF00FFFF),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      // Magenta
                      PieAction(
                        tooltip: const Text('Magenta'),
                        onSelect: () => _applyPresetColor(const Color(0xFFFF00FF)),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFF00FF),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      // Yellow
                      PieAction(
                        tooltip: const Text('Yellow'),
                        onSelect: () => _applyPresetColor(const Color(0xFFFFFF00)),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFFF00),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      // White
                      PieAction(
                        tooltip: const Text('White'),
                        onSelect: () => _applyPresetColor(const Color(0xFFFFFFFF)),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFFFF),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white30, width: 2),
                          ),
                        ),
                      ),
                      // Black
                      PieAction(
                        tooltip: const Text('Black'),
                        onSelect: () => _applyPresetColor(const Color(0xFF000000)),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFF000000),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white30, width: 2),
                          ),
                        ),
                      ),
                    ],
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white54, width: 2),
                      ),
                      child: const Icon(
                        Icons.palette,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 20),
                  
                  // Add color box button (right side)
                  IconButton(
                    onPressed: colorBoxes.length < maxBoxes ? _addColorBox : null,
                    icon: const Icon(Icons.add),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white30, width: 1),
                    ),
                    tooltip: 'Add Color Box',
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Split main color box into flexbox rows
              Column(
                children: _buildSplitColorBoxRows(),
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
          ),
          // Bottom button for Edit Background/Edit Colors
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20.0),
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
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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

// ============================================================================
// VISUAL COMPARISON TEST SCREEN
// ============================================================================

class VisualTestScreen extends StatelessWidget {
  const VisualTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Visual Comparison Tests'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            '👁️ Compare these colors with the reference app',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Open the reference picker on another device and enter the same L, C, H values. '
            'Colors should look identical or imperceptibly different.',
            style: TextStyle(fontSize: 14, color: Colors.black54),
          ),
          const SizedBox(height: 24),
          
          // Test 1: In-gamut blue
          _buildTestCase(
            title: 'Test 1: Mid-Blue (IN-GAMUT)',
            oklch: 'L=0.7, C=0.15, H=240',
            color: colorFromOklch(0.7, 0.15, 240),
            description: 'Should be a pleasant blue. No gamut mapping needed.',
          ),
          
          // Test 2: In-gamut green
          _buildTestCase(
            title: 'Test 2: Lime Green (IN-GAMUT)',
            oklch: 'L=0.8, C=0.2, H=130',
            color: colorFromOklch(0.8, 0.2, 130),
            description: 'Bright lime green. Should match exactly.',
          ),
          
          // Test 3: Out-of-gamut cyan (requires mapping)
          _buildTestCase(
            title: 'Test 3: Cyan (OUT-OF-GAMUT)',
            oklch: 'L=0.7, C=0.4, H=180',
            color: colorFromOklch(0.7, 0.4, 180),
            description: 'Vibrant cyan. Gamut mapping reduces chroma to ~0.28.',
          ),
          
          // Test 4: Out-of-gamut red
          _buildTestCase(
            title: 'Test 4: Red (OUT-OF-GAMUT)',
            oklch: 'L=0.6, C=0.35, H=25',
            color: colorFromOklch(0.6, 0.35, 25),
            description: 'Orange-red. Gamut mapping should preserve hue.',
          ),
          
          // Test 5: Pure gray (no chroma)
          _buildTestCase(
            title: 'Test 5: Gray (ACHROMATIC)',
            oklch: 'L=0.5, C=0, H=0',
            color: colorFromOklch(0.5, 0, 0),
            description: 'Pure gray. Hue should be irrelevant.',
          ),
          
          // Test 6: Near-white with slight tint
          _buildTestCase(
            title: 'Test 6: Warm White',
            oklch: 'L=0.95, C=0.05, H=60',
            color: colorFromOklch(0.95, 0.05, 60),
            description: 'Very light yellow-white. Subtle tint.',
          ),
          
          // Test 7: Deep purple (edge of gamut)
          _buildTestCase(
            title: 'Test 7: Purple (EDGE)',
            oklch: 'L=0.5, C=0.25, H=300',
            color: colorFromOklch(0.5, 0.25, 300),
            description: 'Magenta-purple. Testing purple gamut edge.',
          ),
          
          // Test 8: Saturated orange
          _buildTestCase(
            title: 'Test 8: Orange (HIGH CHROMA)',
            oklch: 'L=0.7, C=0.25, H=50',
            color: colorFromOklch(0.7, 0.25, 50),
            description: 'Bright orange. Should be vivid.',
          ),
          
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 8),
          const Text(
            '✅ PASS CRITERIA',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
          ),
          const SizedBox(height: 8),
          const Text(
            '• Colors should look identical side-by-side\n'
            '• Any difference should be imperceptible (< 2 RGB units)\n'
            '• Hue should NEVER shift (especially important for out-of-gamut)\n'
            '• Lightness should remain very similar',
            style: TextStyle(fontSize: 14, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _buildTestCase({
    required String title,
    required String oklch,
    required Color color,
    required String description,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            
            // Color swatch
            Container(
              height: 100,
        width: double.infinity,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300, width: 2),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // OKLCH values
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
          children: [
                  const Icon(Icons.colorize, size: 20, color: Colors.black54),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      oklch,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 8),
            
            // RGB values (for debugging)
            Text(
              'RGB: ${color.red}, ${color.green}, ${color.blue}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontFamily: 'monospace',
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Description
            Text(
              description,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black54,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

