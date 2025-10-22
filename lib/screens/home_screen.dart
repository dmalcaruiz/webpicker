import 'package:flutter/material.dart';
import 'package:snapping_sheet_2/snapping_sheet.dart';
import '../widgets/color_picker/color_preview_box.dart';
import '../widgets/color_picker/color_picker_controls.dart';
import '../widgets/color_picker/reorderable_color_grid_view.dart';
import '../widgets/home/sheet_grabbing_handle.dart';
import '../widgets/home/sheet_controls.dart';
import '../widgets/home/action_buttons_row.dart';
import '../widgets/home/background_edit_button.dart';
import '../widgets/common/undo_redo_buttons.dart';
import '../models/color_palette_item.dart';
import '../models/app_state_snapshot.dart';
import '../services/undo_redo_manager.dart';
import '../services/palette_manager.dart';

/// Color Picker Home Screen
/// 
/// Orchestrates the main color picker UI and manages:
/// - Color palette state
/// - Undo/redo history
/// - Sheet interactions
/// - Background vs. color edit modes
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ========== Core State ==========
  
  /// Current color being edited
  Color? currentColor;
  
  /// Background color
  Color? bgColor;
  
  /// Whether in background edit mode
  bool isBgEditMode = false;
  
  /// Color palette items
  List<ColorPaletteItem> _colorPalette = [];
  
  /// Currently dragging item (for delete zone)
  ColorPaletteItem? _draggingItem;
  
  /// Current pointer Y position during drag
  double _dragPointerY = double.infinity;
  
  /// Last known pointer Y before drag ended
  double _lastDragPointerY = double.infinity;
  
  /// Threshold for delete zone (pixels from top)
  static const double _deleteZoneThreshold = 120.0;
  
  // ========== UI State ==========
  
  /// Sheet controller for programmatic control
  final SnappingSheetController snappingSheetController = SnappingSheetController();
  
  /// Scroll controller for the sheet content
  final ScrollController scrollController = ScrollController();
  
  /// Track when user is interacting with sliders
  bool _isInteractingWithSlider = false;
  
  /// Track if sheet is pinned
  bool _isSheetPinned = false;
  
  /// Track selected chips (placeholder feature)
  final List<bool> _selectedChips = [false, false, false, false];
  
  // ========== Undo/Redo Management ==========
  
  /// Undo/redo manager
  final UndoRedoManager _undoRedoManager = UndoRedoManager(maxHistorySize: 50);
  
  /// Flag to prevent loops during state restoration
  bool _isRestoringState = false;

  // ========== Lifecycle ==========
  
  @override
  void initState() {
    super.initState();
    bgColor = const Color(0xFF252525);
    _initializeSamplePalette();
    _saveStateToHistory('Initial state');
  }
  
  @override
  void dispose() {
    _undoRedoManager.dispose();
    super.dispose();
  }
  
  /// Initialize with sample colors
  void _initializeSamplePalette() {
    _colorPalette = [
      ColorPaletteItem.fromColor(const Color(0xFFE74C3C), name: 'Red'),
      ColorPaletteItem.fromColor(const Color(0xFF3498DB), name: 'Blue'),
      ColorPaletteItem.fromColor(const Color(0xFF2ECC71), name: 'Green'),
      ColorPaletteItem.fromColor(const Color(0xFFF39C12), name: 'Orange'),
    ];
  }

  // ========== Color Change Handlers ==========
  
  void _onColorChanged(Color? color) {
    if (_isRestoringState || color == null) return;
    
    setState(() {
      currentColor = color;
      
      // Update selected palette item if exists
      final selectedItem = PaletteManager.getSelectedItem(_colorPalette);
      if (selectedItem != null) {
        _colorPalette = PaletteManager.updateItemColor(
          currentPalette: _colorPalette,
          itemId: selectedItem.id,
          color: color,
        );
        _saveStateToHistory('Modified ${selectedItem.name ?? "color"}');
      }
    });
  }
  
  void _handleColorSelection(Color color) {
    if (_isRestoringState) return;
    _onColorChanged(color);
    _saveStateToHistory('Color selected from eyedropper/paste');
  }

  // ========== Palette Operations ==========
  
  void _onPaletteReorder(int oldIndex, int newIndex) {
    if (_isRestoringState) return;
    
    setState(() {
      _colorPalette = PaletteManager.reorderItems(
        currentPalette: _colorPalette,
        oldIndex: oldIndex,
        newIndex: newIndex,
      );
      _saveStateToHistory('Reordered palette items');
    });
  }
  
  void _onPaletteItemTap(ColorPaletteItem item) {
    if (_isRestoringState) return;
    
    setState(() {
      _colorPalette = PaletteManager.selectItem(
        currentPalette: _colorPalette,
        itemId: item.id,
      );
      
      // Update current color to match selection
      final selectedItem = PaletteManager.getSelectedItem(_colorPalette);
      if (selectedItem != null) {
        currentColor = selectedItem.color;
      }
    });
  }
  
  void _onPaletteItemLongPress(ColorPaletteItem item) {
    _showColorItemMenu(item);
  }
  
  void _onPaletteItemDelete(ColorPaletteItem item) {
    if (_isRestoringState) return;
    
    setState(() {
      _colorPalette = PaletteManager.removeColor(
        currentPalette: _colorPalette,
        itemId: item.id,
      );
      _saveStateToHistory('Deleted ${item.name ?? "color"} from palette');
    });
  }
  
  void _onAddColor() {
    if (_isRestoringState) return;
    
    // Determine color to add:
    // 1. If a box is selected, use its current color (which may have been edited via sliders)
    // 2. Otherwise, use currentColor
    final selectedItem = PaletteManager.getSelectedItem(_colorPalette);
    final colorToAdd = selectedItem?.color ?? currentColor;
    
    if (colorToAdd != null) {
      setState(() {
        _colorPalette = PaletteManager.addColor(
          currentPalette: _colorPalette,
          color: colorToAdd,
          selectNew: true,
        );
        _saveStateToHistory('Added new color to palette');
      });
      
      _showSnackBar('Color added to palette');
    } else {
      _showSnackBar('Please create a color first', isError: true);
    }
  }
  
  // ========== Drag & Drop Handlers ==========
  
  void _onDragStarted(ColorPaletteItem item) {
    // Only reset if this is a NEW drag (not already dragging)
    if (_draggingItem == null) {
      setState(() {
        _draggingItem = item;
        _dragPointerY = double.infinity; // Start with a safe value
        _lastDragPointerY = double.infinity;
      });
      debugPrint('Drag started for item: ${item.id}');
    }
  }
  
  bool _onDragEnded() {
    // Use the LAST known position since current might have been reset
    final shouldDelete = _draggingItem != null && _lastDragPointerY < _deleteZoneThreshold;
    
    debugPrint('Drag ended - Last Y: $_lastDragPointerY, Current Y: $_dragPointerY, InZone: $_isInDeleteZone, Should delete: $shouldDelete, Palette size before: ${_colorPalette.length}');
    
    if (shouldDelete) {
      _onDropToDelete();
      debugPrint('Palette size after delete: ${_colorPalette.length}');
    }
    
    setState(() {
      _draggingItem = null;
      _dragPointerY = double.infinity;
      _lastDragPointerY = double.infinity;
    });
    
    debugPrint('Returning shouldDelete=$shouldDelete to skip reorder');
    // Return whether we deleted to signal reorder should be skipped
    return shouldDelete;
  }
  
  void _onDragUpdate(Offset globalPosition) {
    if (_draggingItem != null) {
      setState(() {
        _dragPointerY = globalPosition.dy;
        _lastDragPointerY = _dragPointerY; // Save it
        // Debug: print position
        debugPrint('Drag Y: $_dragPointerY, Threshold: $_deleteZoneThreshold, InZone: $_isInDeleteZone');
      });
    }
  }
  
  void _onDropToDelete() {
    if (_draggingItem != null && !_isRestoringState) {
      final itemToDelete = _draggingItem!;
      debugPrint('Deleting item: ${itemToDelete.id}');
      
      // Remove item from palette
      _colorPalette = PaletteManager.removeColor(
        currentPalette: _colorPalette,
        itemId: itemToDelete.id,
      );
      _saveStateToHistory('Deleted ${itemToDelete.name ?? "color"} via drag');
      _showSnackBar('Color deleted');
    }
  }
  
  bool get _isInDeleteZone => _dragPointerY < _deleteZoneThreshold;

  // ========== Undo/Redo ==========
  
  void _saveStateToHistory(String actionDescription) {
    final snapshot = AppStateSnapshot(
      paletteItems: List.from(_colorPalette),
      currentColor: currentColor,
      bgColor: bgColor,
      isBgEditMode: isBgEditMode,
      selectedPaletteItemId: PaletteManager.getSelectedItem(_colorPalette)?.id,
      timestamp: DateTime.now(),
      actionDescription: actionDescription,
    );
    _undoRedoManager.pushState(snapshot);
  }
  
  void _restoreState(AppStateSnapshot snapshot) {
    _isRestoringState = true;
    
    setState(() {
      _colorPalette = List.from(snapshot.paletteItems);
      currentColor = snapshot.currentColor;
      bgColor = snapshot.bgColor;
      isBgEditMode = snapshot.isBgEditMode;
    });
    
    _isRestoringState = false;
  }
  
  void _handleUndo() {
    if (_undoRedoManager.canUndo) {
      final snapshot = _undoRedoManager.undo();
      if (snapshot != null) _restoreState(snapshot);
    }
  }
  
  void _handleRedo() {
    if (_undoRedoManager.canRedo) {
      final snapshot = _undoRedoManager.redo();
      if (snapshot != null) _restoreState(snapshot);
    }
  }

  // ========== UI Helpers ==========
  
  void _showColorItemMenu(ColorPaletteItem item) {
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
            // Handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Color info
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
            // Delete action
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
  
  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: isError ? 2 : 1),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? Colors.red.shade700 : Colors.black87,
      ),
    );
  }

  // ========== Build ==========
  
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
          
          // Grabbing handle
          grabbingHeight: 95,
          grabbing: SheetGrabbingHandle(
            isPinned: _isSheetPinned,
            onPinToggle: () => setState(() => _isSheetPinned = !_isSheetPinned),
            chipStates: _selectedChips,
            onChipToggle: (index) => setState(() => _selectedChips[index] = !_selectedChips[index]),
          ),
          
          // Sheet content
          sheetBelow: SnappingSheetContent(
            draggable: (details) => !_isInteractingWithSlider && !_isSheetPinned,
            child: Column(
              children: [
                // Color picker controls
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: ColorPickerControls(
                    isBgEditMode: isBgEditMode,
                    bgColor: bgColor,
                    externalColor: currentColor,
                    onBgEditModeChanged: (mode) => setState(() => isBgEditMode = mode),
                    onColorChanged: _onColorChanged,
                    onSliderInteractionChanged: (interacting) => 
                        setState(() => _isInteractingWithSlider = interacting),
                  ),
                ),
                
                // Scrollable controls area
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                      child: Column(
                        children: [
                          BackgroundEditButton(
                            isBgEditMode: isBgEditMode,
                            onPressed: () => setState(() => isBgEditMode = !isBgEditMode),
                          ),
                          const SizedBox(height: 10),
                          SheetControls(controller: snappingSheetController),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Main content area
          child: Listener(
            onPointerMove: (event) {
              if (_draggingItem != null) {
                _onDragUpdate(event.position);
              }
            },
            child: Stack(
              children: [
                // Main content (behind the delete zone)
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      
              // Action buttons with BG color button
              Row(
                children: [
                  // Background color button
                  GestureDetector(
                    onTap: () {
                      if (currentColor != null) {
                        setState(() {
                          bgColor = currentColor;
                        });
                        _showSnackBar('Background color updated');
                      }
                    },
                    child: Container(
                      width: 48,
                      height: 48,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: bgColor ?? const Color(0xFF252525),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.format_paint,
                        color: Colors.white70,
                        size: 24,
                      ),
                    ),
                  ),
                  
                  // Other action buttons
                  Expanded(
                    child: ActionButtonsRow(
                      currentColor: currentColor,
                      onColorSelected: _handleColorSelection,
                      undoRedoManager: _undoRedoManager,
                      onUndo: _handleUndo,
                      onRedo: _handleRedo,
                    ),
                  ),
                ],
              ),
                      
                      const SizedBox(height: 20),
                      
                      // Color preview
                      ColorPreviewBox(color: currentColor),
                      
                      const SizedBox(height: 30),
                      
                      // Color palette grid
                      Expanded(
                        child: ReorderableColorGridView(
                          items: _colorPalette,
                          onReorder: _onPaletteReorder,
                          onItemTap: _onPaletteItemTap,
                          onItemLongPress: _onPaletteItemLongPress,
                          onItemDelete: _onPaletteItemDelete,
                          onAddColor: _onAddColor,
                          onDragStarted: _onDragStarted,
                          onDragEnded: _onDragEnded,
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
                
                // Drag-to-delete zone (overlays on top)
                Positioned(
                  top: 20,
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: _draggingItem != null ? 1.0 : 0.0,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                        decoration: BoxDecoration(
                          color: _isInDeleteZone
                              ? Colors.red.shade700.withOpacity(0.95)
                              : Colors.red.shade600.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.4),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.delete,
                              color: Colors.white,
                              size: 32,
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Drag to Delete',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
