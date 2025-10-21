import 'package:flutter/material.dart';
import 'package:snapping_sheet_2/snapping_sheet.dart';
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
  
  // Sheet controller for programmatic control
  final SnappingSheetController snappingSheetController = SnappingSheetController();
  
  // Scroll controller for the sheet content
  final ScrollController scrollController = ScrollController();
  
  // Track chip selection states
  List<bool> _chipSelections = [false, false, false, false];
  
  // Track if sheet is pinned (locked in place)
  bool _isSheetPinned = false;

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
  
  void _toggleChip(int index) {
    setState(() {
      _chipSelections[index] = !_chipSelections[index];
    });
  }
  
  void _toggleSheetPin() {
    setState(() {
      _isSheetPinned = !_isSheetPinned;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor ?? const Color(0xFF252525),
      body: SnappingSheet(
        controller: snappingSheetController,
        lockOverflowDrag: true,
        snappingPositions: const [
          SnappingPosition.factor(
            positionFactor: 0.3,
            snappingCurve: Curves.easeOutExpo,
            snappingDuration: Duration(milliseconds: 900),
            grabbingContentOffset: GrabbingContentOffset.top,
          ),
          SnappingPosition.factor(
            positionFactor: 0.7,
            snappingCurve: Curves.easeOutExpo,
            snappingDuration: Duration(milliseconds: 900),
          ),
          SnappingPosition.factor(
            positionFactor: 1.0,
            snappingCurve: Curves.easeOutExpo,
            snappingDuration: Duration(milliseconds: 900),
            grabbingContentOffset: GrabbingContentOffset.bottom,
          ),
        ],
        
        // Grabbing widget (the handle)
        grabbingHeight: 120, // Increased height to accommodate chips
        grabbing: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 12,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Color Picker',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: _toggleSheetPin,
                    icon: Icon(
                      _isSheetPinned ? Icons.push_pin : Icons.push_pin_outlined,
                      color: _isSheetPinned ? Colors.blue : Colors.grey,
                      size: 20,
                    ),
                    tooltip: _isSheetPinned ? 'Unpin sheet' : 'Pin sheet',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Chips section in draggable area
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: List.generate(4, (index) {
                    return FilterChip(
                      label: Text('Chip ${index + 1}'),
                      selected: _chipSelections[index],
                      onSelected: (_) => _toggleChip(index),
                      selectedColor: Colors.black,
                      checkmarkColor: Colors.white,
                      labelStyle: TextStyle(
                        color: _chipSelections[index] ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  }),
                ),
              ),
              
              const SizedBox(height: 12),
            ],
          ),
        ),
        
        // Sheet content below the grabbing widget
        sheetBelow: SnappingSheetContent(
          draggable: (details) => !_isSheetPinned, // Allow dragging unless pinned
          childScrollController: scrollController,
          child: SingleChildScrollView(
            controller: scrollController,
            reverse: false,
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Color picker controls
                  ColorPickerControls(
                    isBgEditMode: isBgEditMode,
                    bgColor: bgColor,
                    onBgEditModeChanged: _onBgEditModeChanged,
                    onColorChanged: _onColorChanged,
                  ),
                  
                  const SizedBox(height: 20),
                  
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
                  
                  const SizedBox(height: 10),
                  
                  // Sheet control buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => snappingSheetController.snapToPosition(
                            const SnappingPosition.factor(positionFactor: 0.3),
                          ),
                          icon: const Icon(Icons.keyboard_arrow_down),
                          label: const Text('Collapse'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.shade200,
                            foregroundColor: Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => snappingSheetController.snapToPosition(
                            const SnappingPosition.factor(positionFactor: 1.0),
                          ),
                          icon: const Icon(Icons.keyboard_arrow_up),
                          label: const Text('Expand'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.shade200,
                            foregroundColor: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
        // Main content area (behind the sheet)
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 20),
              
              // Single color display box
              ColorPreviewBox(
                color: currentColor,
              ),
              
              const SizedBox(height: 30),
              
              // Placeholder for ReorderableGridView
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      'ReorderableGridView\n(To be implemented)',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
