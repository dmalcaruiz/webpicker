import 'package:flutter/material.dart';
import '../widgets/color_picker/color_preview_box.dart';
import '../widgets/color_picker/color_picker_controls.dart';

// Color Picker Home Screen
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Background color editing mode
  bool isBgEditMode = false;
  Color? bgColor;
  
  // Current color for display
  Color? currentColor;
  

  @override
  void initState() {
    super.initState();
    bgColor = const Color(0xFF252525); // Default dark background
  }
  

  void _onColorChanged(Color? color) {
    setState(() {
      currentColor = color;
    });
  }

  void _onBgEditModeChanged(bool isBgEditMode) {
    setState(() {
      this.isBgEditMode = isBgEditMode;
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
              ColorPreviewBox(
                color: currentColor,
              ),
              
              const SizedBox(height: 30),
              
              // Color picker controls
              ColorPickerControls(
                isBgEditMode: isBgEditMode,
                bgColor: bgColor,
                onBgEditModeChanged: _onBgEditModeChanged,
                onColorChanged: _onColorChanged,
              ),
                  ],
              ),
            ),
          ),
          // Bottom button for Edit Background/Edit Colors
          SizedBox(
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
                backgroundColor: Colors.black.withValues(alpha: 0.3),
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
