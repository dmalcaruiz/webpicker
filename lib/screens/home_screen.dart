import 'package:flutter/material.dart';
import 'package:snapping_sheet_2/snapping_sheet.dart';
import '../widgets/color_picker/color_preview_box.dart';
import '../widgets/color_picker/color_picker_controls.dart';
import '../widgets/color_picker/reorderable_color_grid_view.dart';
import '../widgets/common/global_action_buttons.dart';
import '../widgets/common/undo_redo_buttons.dart';
import '../models/color_palette_item.dart';
import '../models/app_state_snapshot.dart';
import '../services/undo_redo_manager.dart';

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
  
  // Track when user is interacting with sliders to block sheet dragging
  bool _isInteractingWithSlider = false;
  
  // Track if sheet is pinned (locked in place)
  bool _isSheetPinned = false;
  
  // Track selected chips
  List<bool> _selectedChips = [false, false, false, false];
  
  // Color palette management
  List<ColorPaletteItem> _colorPalette = [];
  ColorPaletteItem? _selectedPaletteItem;
  
  // Undo/Redo management
  final UndoRedoManager _undoRedoManager = UndoRedoManager(maxHistorySize: 50);
  bool _isRestoringState = false;

  @override
  void initState() {
    super.initState();
    bgColor = const Color(0xFF252525); // Default dark background
    
    // Initialize with some sample colors
    _initializeSamplePalette();
    
    // Save initial state
    _saveStateToHistory('Initial state');
  }
  
  @override
  void dispose() {
    _undoRedoManager.dispose();
    super.dispose();
  }
  
  /// Initialize the palette with some sample colors
  void _initializeSamplePalette() {
    _colorPalette = [
      ColorPaletteItem.fromColor(const Color(0xFFE74C3C), name: 'Red'),
      ColorPaletteItem.fromColor(const Color(0xFF3498DB), name: 'Blue'),
      ColorPaletteItem.fromColor(const Color(0xFF2ECC71), name: 'Green'),
      ColorPaletteItem.fromColor(const Color(0xFFF39C12), name: 'Orange'),
    ];
  }

  void _onColorChanged(Color? color) {
    if (_isRestoringState) return;
    
    setState(() {
      currentColor = color;
      
      // If a palette item is selected, update it with the new color
      if (_selectedPaletteItem != null && color != null) {
        final selectedIndex = _colorPalette.indexWhere((p) => p.id == _selectedPaletteItem!.id);
        if (selectedIndex != -1) {
          _colorPalette[selectedIndex] = _colorPalette[selectedIndex].copyWith(
            color: color,
            lastModified: DateTime.now(),
          );
          _saveStateToHistory('Modified ${_selectedPaletteItem!.name ?? "color"}');
        }
      }
    });
  }

  void _onBgEditModeChanged(bool isBgEditMode) {
    setState(() {
      this.isBgEditMode = isBgEditMode;
    });
  }
  
  void _onSliderInteractionChanged(bool isInteracting) {
    setState(() {
      _isInteractingWithSlider = isInteracting;
    });
  }
  
  void _toggleSheetPin() {
    setState(() {
      _isSheetPinned = !_isSheetPinned;
    });
  }
  
  void _toggleChip(int index) {
    setState(() {
      _selectedChips[index] = !_selectedChips[index];
    });
  }
  
  /// Handle palette item reordering
  void _onPaletteReorder(int oldIndex, int newIndex) {
    if (_isRestoringState) return;
    
    setState(() {
      // Note: ReorderableGridView package provides the exact target index
      // Unlike ReorderableListView, we do NOT need to adjust newIndex
      // Simply remove from oldIndex and insert at newIndex
      final item = _colorPalette.removeAt(oldIndex);
      _colorPalette.insert(newIndex, item);
      _saveStateToHistory('Reordered palette items');
    });
  }
  
  /// Handle palette item tap
  void _onPaletteItemTap(ColorPaletteItem item) {
    setState(() {
      // Clear previous selection
      _colorPalette = _colorPalette.map((paletteItem) => 
        paletteItem.copyWith(isSelected: false)
      ).toList();
      
      // Select the tapped item
      final selectedIndex = _colorPalette.indexWhere((p) => p.id == item.id);
      if (selectedIndex != -1) {
        _colorPalette[selectedIndex] = _colorPalette[selectedIndex].copyWith(isSelected: true);
        _selectedPaletteItem = _colorPalette[selectedIndex];
        
        // Update the current color to match the selected palette item
        currentColor = item.color;
      }
    });
  }
  
  /// Handle palette item long press
  void _onPaletteItemLongPress(ColorPaletteItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: item.color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              title: Text(item.name ?? 'Unnamed Color'),
              subtitle: Text('#${item.color.toARGB32().toRadixString(16).substring(2).toUpperCase()}'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Delete'),
              onTap: () {
                Navigator.pop(context);
                _onPaletteItemDelete(item);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
  
  /// Handle palette item deletion
  void _onPaletteItemDelete(ColorPaletteItem item) {
    if (_isRestoringState) return;
    
    setState(() {
      _colorPalette.removeWhere((paletteItem) => paletteItem.id == item.id);
      if (_selectedPaletteItem?.id == item.id) {
        _selectedPaletteItem = null;
      }
      _saveStateToHistory('Deleted ${item.name ?? "color"} from palette');
    });
  }
  
  /// Save current state to undo/redo history
  void _saveStateToHistory(String actionDescription) {
    final snapshot = AppStateSnapshot(
      paletteItems: _colorPalette.map((item) => item).toList(),
      currentColor: currentColor,
      bgColor: bgColor,
      isBgEditMode: isBgEditMode,
      selectedPaletteItemId: _selectedPaletteItem?.id,
      timestamp: DateTime.now(),
      actionDescription: actionDescription,
    );
    _undoRedoManager.pushState(snapshot);
  }
  
  /// Restore state from snapshot
  void _restoreState(AppStateSnapshot snapshot) {
    _isRestoringState = true;
    
    setState(() {
      _colorPalette = snapshot.paletteItems.map((item) => item).toList();
      currentColor = snapshot.currentColor;
      bgColor = snapshot.bgColor;
      isBgEditMode = snapshot.isBgEditMode;
      
      // Restore selection
      if (snapshot.selectedPaletteItemId != null) {
        _selectedPaletteItem = _colorPalette.firstWhere(
          (item) => item.id == snapshot.selectedPaletteItemId,
          orElse: () => _colorPalette.first,
        );
      } else {
        _selectedPaletteItem = null;
      }
    });
    
    _isRestoringState = false;
  }
  
  /// Handle undo action
  void _handleUndo() {
    if (_undoRedoManager.canUndo) {
      final snapshot = _undoRedoManager.undo();
      if (snapshot != null) {
        _restoreState(snapshot);
      }
    }
  }
  
  /// Handle redo action
  void _handleRedo() {
    if (_undoRedoManager.canRedo) {
      final snapshot = _undoRedoManager.redo();
      if (snapshot != null) {
        _restoreState(snapshot);
      }
    }
  }
  
  /// Handle color selection from eyedropper or paste
  void _handleColorSelection(Color color) {
    if (_isRestoringState) return;
    
    setState(() {
      currentColor = color;
      
      // If a palette item is selected, update it
      if (_selectedPaletteItem != null) {
        final selectedIndex = _colorPalette.indexWhere((p) => p.id == _selectedPaletteItem!.id);
        if (selectedIndex != -1) {
          _colorPalette[selectedIndex] = _colorPalette[selectedIndex].copyWith(
            color: color,
            lastModified: DateTime.now(),
          );
        }
      }
      
      _saveStateToHistory('Color selected from eyedropper/paste');
    });
  }
  
  /// Handle adding a new color to the palette
  void _onAddColor() {
    if (_isRestoringState) return;
    
    if (currentColor != null) {
      setState(() {
        // Deselect all current items
        _colorPalette = _colorPalette.map((item) => 
          item.copyWith(isSelected: false)
        ).toList();
        
        // Add the new item as selected
        final newItem = ColorPaletteItem.fromColor(currentColor!, name: null).copyWith(isSelected: true);
        _colorPalette.add(newItem);
        _selectedPaletteItem = newItem;
        _saveStateToHistory('Added new color to palette');
      });
      
      // Show a snackbar to confirm
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Color added to palette'),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.black87,
        ),
      );
    } else {
      // Show a message if no color is available
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please create a color first'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return UndoRedoShortcuts(
      onUndo: _handleUndo,
      onRedo: _handleRedo,
      child: Scaffold(
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
        grabbingHeight: 95,
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
              const SizedBox(height: 8),
              
              // Toggleable chips
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: GestureDetector(
                      onTap: () => _toggleChip(index),
                      child: Container(
                        width: 32,
                        height: 24,
                        decoration: BoxDecoration(
                          color: _selectedChips[index] ? Colors.black : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _selectedChips[index] ? Colors.black : Colors.grey.shade400,
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: _selectedChips[index] ? Colors.white : Colors.grey.shade600,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
        
        // Sheet content below the grabbing widget
        sheetBelow: SnappingSheetContent(
          draggable: (details) => !_isInteractingWithSlider && !_isSheetPinned,
          child: Column(
            children: [
              // Fixed sliders area (no scrolling)
              Container(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: ColorPickerControls(
                  isBgEditMode: isBgEditMode,
                  bgColor: bgColor,
                  onBgEditModeChanged: _onBgEditModeChanged,
                  onColorChanged: _onColorChanged,
                  onSliderInteractionChanged: _onSliderInteractionChanged,
                ),
              ),
              
              // Scrollable content area
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  reverse: false,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                    child: Column(
                      children: [
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
            ],
          ),
        ),
        // Main content area (behind the sheet)
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 20),
              
              // Global action buttons row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Copy/Paste/Eyedropper buttons
                  Expanded(
                    child: GlobalActionButtons(
                      currentColor: currentColor,
                      onColorSelected: _handleColorSelection,
                    ),
                  ),
                  
                  // Undo/Redo buttons
                  UndoRedoButtons(
                    undoRedoManager: _undoRedoManager,
                    onUndo: _handleUndo,
                    onRedo: _handleRedo,
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Single color display box
              ColorPreviewBox(
                color: currentColor,
              ),
              
              const SizedBox(height: 30),
              
              // ReorderableColorGridView
              Expanded(
                child: ReorderableColorGridView(
                  items: _colorPalette,
                  onReorder: _onPaletteReorder,
                  onItemTap: _onPaletteItemTap,
                  onItemLongPress: _onPaletteItemLongPress,
                  onItemDelete: _onPaletteItemDelete,
                  onAddColor: _onAddColor,
                  crossAxisCount: 4,
                  spacing: 12.0,
                  itemSize: 80.0,
                  showAddButton: true,
                  emptyStateMessage: 'No colors in palette\nCreate a color above and tap + to add it',
                ),
              ),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      ),
    );
  }
}
