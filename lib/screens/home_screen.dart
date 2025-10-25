import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:snapping_sheet_2/snapping_sheet.dart';
import '../widgets/color_picker/color_preview_box.dart';
import '../widgets/color_picker/color_picker_controls.dart';
import '../widgets/color_picker/reorderable_color_grid_view.dart';
import '../widgets/home/sheet_grabbing_handle.dart';
import '../widgets/home/sheet_controls.dart';
import '../widgets/home/action_buttons_row.dart';
import '../widgets/common/undo_redo_buttons.dart';
import '../models/color_palette_item.dart';
import '../models/extreme_color_item.dart';
import '../models/app_state_snapshot.dart';
import '../services/undo_redo_manager.dart';
import '../services/palette_manager.dart';
import '../utils/color_operations.dart';
import '../utils/icc_color_manager.dart';

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

  /// Current OKLCH values being edited (source of truth)
  double? currentLightness;
  double? currentChroma;
  double? currentHue;
  double? currentAlpha;

  /// Current color (derived from OKLCH for display)
  Color? currentColor;

  /// Background color
  Color? bgColor;

  /// Background color OKLCH values (for proper tracking like palette boxes)
  double? _bgLightness;
  double? _bgChroma;
  double? _bgHue;
  double? _bgAlpha;

  /// Whether background color "box" is selected
  bool _isBgColorSelected = false;

  /// Color palette items
  List<ColorPaletteItem> _colorPalette = [];

  /// Mixer extreme colors
  late ExtremeColorItem _leftExtreme;
  late ExtremeColorItem _rightExtreme;

  /// Selected extreme ID ('left', 'right', or null)
  String? _selectedExtremeId;

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
  
  /// Track selected chips (placeholder feature)
  final List<bool> _selectedChips = [false, false, false, false];

  /// Whether to constrain colors to real pigment gamut (ICC profile)
  /// This is a DISPLAY FILTER - doesn't modify stored OKLCH values
  bool _useRealPigmentsOnly = false;

  // ========== Undo/Redo Management ==========
  
  /// Undo/redo manager
  final UndoRedoManager _undoRedoManager = UndoRedoManager(maxHistorySize: 50);
  
  /// Flag to prevent loops during state restoration
  bool _isRestoringState = false;

  // ========== Lifecycle ==========
  
  @override
  void initState() {
    super.initState();
    // Initialize background color with OKLCH values
    bgColor = const Color(0xFF252525);
    final bgOklch = srgbToOklch(bgColor!);
    _bgLightness = bgOklch.l;
    _bgChroma = bgOklch.c;
    _bgHue = bgOklch.h;
    _bgAlpha = bgOklch.alpha;

    _initializeSamplePalette();
    _initializeExtremes();
    _initializeIccProfile();
    _saveStateToHistory('Initial state');
  }
  
  @override
  void dispose() {
    IccColorManager.instance.dispose();
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

  /// Initialize mixer extremes with default colors
  void _initializeExtremes() {
    _leftExtreme = ExtremeColorItem.fromOklch(
      id: 'left',
      lightness: 0.5,
      chroma: 0.0,
      hue: 0.0,
    );
    _rightExtreme = ExtremeColorItem.fromOklch(
      id: 'right',
      lightness: 1.0,
      chroma: 0.0,
      hue: 0.0,
    );
  }

  /// Initialize ICC color management
  ///
  /// Loads Canon PRO-1000 profile from assets for real-time filtering.
  /// App continues normally if this fails (graceful degradation).
  Future<void> _initializeIccProfile() async {
    try {
      const profilePath = 'reference-icc/Canon ImagePROGRAPH PRO-1000.icc';

      // Load profile from assets
      final profileData = await rootBundle.load(profilePath);
      final bytes = profileData.buffer.asUint8List();

      // Initialize ICC manager
      final success = await IccColorManager.instance.initialize(bytes);

      if (success) {
        debugPrint('✓ ICC Profile loaded successfully');
        debugPrint('  Profile: Canon ImagePROGRAPH PRO-1000');
        debugPrint('  Size: ${bytes.length} bytes');
        debugPrint('  Mode: Real-time display filter');
      } else {
        debugPrint('⚠ ICC Profile initialization failed');
        debugPrint('  "Only Real Pigments" toggle will have no effect');
      }

    } catch (e) {
      debugPrint('⚠ ICC Profile loading error: $e');
      debugPrint('  App will continue with sRGB-only mode');
    }
  }

  // ========== Color Change Handlers ==========

  /// Handle OKLCH value changes from sliders (source of truth)
  void _onOklchChanged({
    required double lightness,
    required double chroma,
    required double hue,
    double alpha = 1.0,
  }) {
    if (_isRestoringState) return;

    setState(() {
      // Update OKLCH state
      currentLightness = lightness;
      currentChroma = chroma;
      currentHue = hue;
      currentAlpha = alpha;

      // Derive Color for display
      currentColor = colorFromOklch(lightness, chroma, hue, alpha);

      // Update selected palette item if exists
      final selectedItem = PaletteManager.getSelectedItem(_colorPalette);
      if (selectedItem != null) {
        _colorPalette = PaletteManager.updateItemOklch(
          currentPalette: _colorPalette,
          itemId: selectedItem.id,
          lightness: lightness,
          chroma: chroma,
          hue: hue,
          alpha: alpha,
        );
        _saveStateToHistory('Modified ${selectedItem.name ?? "color"}');
      } else if (_selectedExtremeId != null) {
        // Update selected extreme (behaves exactly like a box)
        final newColor = colorFromOklch(lightness, chroma, hue, alpha);
        final newOklch = OklchValues(
          lightness: lightness,
          chroma: chroma,
          hue: hue,
          alpha: alpha,
        );

        if (_selectedExtremeId == 'left') {
          _leftExtreme = _leftExtreme.copyWith(
            color: newColor,
            oklchValues: newOklch,
          );
          _saveStateToHistory('Modified left extreme');
        } else if (_selectedExtremeId == 'right') {
          _rightExtreme = _rightExtreme.copyWith(
            color: newColor,
            oklchValues: newOklch,
          );
          _saveStateToHistory('Modified right extreme');
        }
      } else if (_isBgColorSelected) {
        // Update background color (behaves exactly like a box)
        _bgLightness = lightness;
        _bgChroma = chroma;
        _bgHue = hue;
        _bgAlpha = alpha;
        bgColor = colorFromOklch(lightness, chroma, hue, alpha);
        _saveStateToHistory('Modified background color');
      }
    });
  }

  /// Legacy handler for Color-based changes (eyedropper, paste)
  void _onColorChanged(Color? color) {
    if (_isRestoringState || color == null) return;

    // Convert to OKLCH and use that as source of truth
    final oklch = srgbToOklch(color);
    _onOklchChanged(
      lightness: oklch.l,
      chroma: oklch.c,
      hue: oklch.h,
      alpha: oklch.alpha,
    );
  }
  
  void _handleColorSelection(Color color) {
    if (_isRestoringState) return;
    _onColorChanged(color);
    _saveStateToHistory('Color selected from eyedropper/paste');
  }

  /// Handle "Only Real Pigments" toggle
  ///
  /// This is a DISPLAY FILTER - doesn't modify stored OKLCH values.
  /// When toggled ON, colors are filtered through ICC profile for display only.
  void _onRealPigmentsOnlyChanged(bool value) {
    if (_isRestoringState) return;

    setState(() {
      _useRealPigmentsOnly = value;
      // Display will update automatically via filter
      _saveStateToHistory(
        value ? 'Enabled real pigments filter' : 'Disabled real pigments filter'
      );
    });
  }

  // ========== ICC Display Filter ==========

  /// Apply ICC display filter to color
  ///
  /// This is where the REAL-TIME FILTERING happens!
  ///
  /// Returns:
  /// - Original color if toggle OFF or ICC not ready
  /// - Gamut-mapped color if toggle ON and ICC ready
  ///
  /// Important: This doesn't modify state, only display!
  Color applyIccFilter(Color idealColor, {
    double? lightness,
    double? chroma,
    double? hue,
    double? alpha,
  }) {
    // No filter if toggle OFF or ICC not initialized
    if (!_useRealPigmentsOnly || !IccColorManager.instance.isReady) {
      return idealColor;
    }

    // Use provided OKLCH or extract from state
    final l = lightness ?? currentLightness ?? 0.5;
    final c = chroma ?? currentChroma ?? 0.0;
    final h = hue ?? currentHue ?? 0.0;
    final a = alpha ?? currentAlpha ?? 1.0;

    try {
      // Convert OKLCH → CIE Lab
      final cieLab = oklchToCieLab(l, c, h);

      // Apply ICC transform (the actual filter!)
      final mappedLab = IccColorManager.instance.transformLab(
        cieLab.l,
        cieLab.a,
        cieLab.b,
      );

      // Convert back: CIE Lab → OKLCH → sRGB
      final mappedOklch = cieLabToOklch(mappedLab[0], mappedLab[1], mappedLab[2]);

      return colorFromOklch(mappedOklch.l, mappedOklch.c, mappedOklch.h, a);
    } catch (e) {
      debugPrint('⚠ ICC filter error: $e');
      return idealColor; // Fallback on error
    }
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
      // If tapping an already-selected item, deselect it
      if (item.isSelected) {
        _colorPalette = PaletteManager.deselectAll(currentPalette: _colorPalette);
        return;
      }

      // Otherwise, select the item
      _colorPalette = PaletteManager.selectItem(
        currentPalette: _colorPalette,
        itemId: item.id,
      );

      // Deselect extremes when a box is selected
      _selectedExtremeId = null;
      _leftExtreme = _leftExtreme.copyWith(isSelected: false);
      _rightExtreme = _rightExtreme.copyWith(isSelected: false);

      // Deselect bg color box
      _isBgColorSelected = false;

      // Update current OKLCH values directly from the item (no conversion!)
      final selectedItem = PaletteManager.getSelectedItem(_colorPalette);
      if (selectedItem != null) {
        currentLightness = selectedItem.oklchValues.lightness;
        currentChroma = selectedItem.oklchValues.chroma;
        currentHue = selectedItem.oklchValues.hue;
        currentAlpha = selectedItem.oklchValues.alpha;
        currentColor = selectedItem.color; // Already computed, just use it
      }
    });
  }

  void _onBgColorBoxTap() {
    if (_isRestoringState) return;

    setState(() {
      // If tapping an already-selected bg color box, deselect it
      if (_isBgColorSelected) {
        _isBgColorSelected = false;
        return;
      }

      // Otherwise, select the bg color box
      // Deselect all palette boxes
      _colorPalette = PaletteManager.deselectAll(currentPalette: _colorPalette);

      // Deselect extremes
      _selectedExtremeId = null;
      _leftExtreme = _leftExtreme.copyWith(isSelected: false);
      _rightExtreme = _rightExtreme.copyWith(isSelected: false);

      // Select bg color box
      _isBgColorSelected = true;

      // Update sliders with bg color's OKLCH values
      currentLightness = _bgLightness;
      currentChroma = _bgChroma;
      currentHue = _bgHue;
      currentAlpha = _bgAlpha;
      currentColor = bgColor;
    });
  }

  void _onExtremeTap(String extremeId) {
    if (_isRestoringState) return;

    setState(() {
      // If tapping an already-selected extreme, deselect it
      if (_selectedExtremeId == extremeId) {
        _selectedExtremeId = null;
        _leftExtreme = _leftExtreme.copyWith(isSelected: false);
        _rightExtreme = _rightExtreme.copyWith(isSelected: false);
        return;
      }

      // Otherwise, select the tapped extreme
      // Deselect all palette boxes
      _colorPalette = PaletteManager.deselectAll(currentPalette: _colorPalette);

      // Deselect bg color box
      _isBgColorSelected = false;

      // Select tapped extreme, deselect the other
      if (extremeId == 'left') {
        _selectedExtremeId = 'left';
        _leftExtreme = _leftExtreme.copyWith(isSelected: true);
        _rightExtreme = _rightExtreme.copyWith(isSelected: false);

        // Update sliders with left extreme's OKLCH values
        currentLightness = _leftExtreme.oklchValues.lightness;
        currentChroma = _leftExtreme.oklchValues.chroma;
        currentHue = _leftExtreme.oklchValues.hue;
        currentAlpha = _leftExtreme.oklchValues.alpha;
        currentColor = _leftExtreme.color;

        _saveStateToHistory('Selected left extreme');
      } else if (extremeId == 'right') {
        _selectedExtremeId = 'right';
        _leftExtreme = _leftExtreme.copyWith(isSelected: false);
        _rightExtreme = _rightExtreme.copyWith(isSelected: true);

        // Update sliders with right extreme's OKLCH values
        currentLightness = _rightExtreme.oklchValues.lightness;
        currentChroma = _rightExtreme.oklchValues.chroma;
        currentHue = _rightExtreme.oklchValues.hue;
        currentAlpha = _rightExtreme.oklchValues.alpha;
        currentColor = _rightExtreme.color;

        _saveStateToHistory('Selected right extreme');
      }
    });
  }

  void _onMixerSliderTouched() {
    if (_isRestoringState) return;

    // Deselect extremes and bg color box when mixer slider is dragged
    if (_selectedExtremeId != null || _isBgColorSelected) {
      setState(() {
        _selectedExtremeId = null;
        _leftExtreme = _leftExtreme.copyWith(isSelected: false);
        _rightExtreme = _rightExtreme.copyWith(isSelected: false);
        _isBgColorSelected = false;
      });
    }
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
      bgLightness: _bgLightness,
      bgChroma: _bgChroma,
      bgHue: _bgHue,
      bgAlpha: _bgAlpha,
      isBgColorSelected: _isBgColorSelected,
      selectedPaletteItemId: PaletteManager.getSelectedItem(_colorPalette)?.id,
      selectedExtremeId: _selectedExtremeId,
      leftExtreme: _leftExtreme,
      rightExtreme: _rightExtreme,
      useRealPigmentsOnly: _useRealPigmentsOnly,
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
      _bgLightness = snapshot.bgLightness;
      _bgChroma = snapshot.bgChroma;
      _bgHue = snapshot.bgHue;
      _bgAlpha = snapshot.bgAlpha;
      _isBgColorSelected = snapshot.isBgColorSelected;
      _selectedExtremeId = snapshot.selectedExtremeId;
      _useRealPigmentsOnly = snapshot.useRealPigmentsOnly;
      if (snapshot.leftExtreme != null) {
        _leftExtreme = snapshot.leftExtreme!;
      }
      if (snapshot.rightExtreme != null) {
        _rightExtreme = snapshot.rightExtreme!;
      }
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
        body: Stack(
          children: [
            //---------------------------------------------------------------------------------------------------------------------
            // Snapping Sheet Stack (includes grabbing handle, sheet content, and content below the sheet)
            //---------------------------------------------------------------------------------------------------------------------
            SnappingSheet(
              // Snapping Sheet Properties
              controller: snappingSheetController,
              lockOverflowDrag: true,
              snappingPositions: const [
                SnappingPosition.pixels(
                  positionPixels: 0,
                  snappingCurve: Curves.easeOutExpo,
                  snappingDuration: Duration(milliseconds: 900),
                  grabbingContentOffset: GrabbingContentOffset.top,
                ),
                SnappingPosition.pixels(
                  positionPixels: 200,
                  snappingCurve: Curves.easeOutExpo,
                  snappingDuration: Duration(milliseconds: 900),
                ),
                  SnappingPosition.pixels(
                  positionPixels: 400,
                  snappingCurve: Curves.easeOutExpo,
                  snappingDuration: Duration(milliseconds: 900),
                  grabbingContentOffset: GrabbingContentOffset.bottom,
                ),
              ],

              //---------------------------------------------------------------------------------------------------------------------
              // Grabbing handle Content
              //---------------------------------------------------------------------------------------------------------------------
              grabbingHeight: 100,
              grabbing: SheetGrabbingHandle(
                chipStates: _selectedChips,
                onChipToggle: (index) => setState(() => _selectedChips[index] = !_selectedChips[index]),
              ),
            
              //---------------------------------------------------------------------------------------------------------------------
              // Sheet Content
              //---------------------------------------------------------------------------------------------------------------------
              sheetBelow: SnappingSheetContent(
                draggable: (details) => !_isInteractingWithSlider,
                child: Column(
                  children: [
                    // Color picker controls
                    Expanded(
                      child: Container(
                      color: Colors.white,
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: ColorPickerControls(
                        // Pass OKLCH values directly (no conversion!)
                        externalLightness: currentLightness,
                        externalChroma: currentChroma,
                        externalHue: currentHue,
                        externalAlpha: currentAlpha,
                        // Pass extreme data without modification
                        leftExtreme: _leftExtreme,
                        rightExtreme: _rightExtreme,
                        // Pass ICC filter for extreme colors
                        extremeColorFilter: (extreme) => applyIccFilter(
                          extreme.color,
                          lightness: extreme.oklchValues.lightness,
                          chroma: extreme.oklchValues.chroma,
                          hue: extreme.oklchValues.hue,
                          alpha: extreme.oklchValues.alpha,
                        ),
                        // Pass ICC filter for gradient colors
                        gradientColorFilter: (color, l, c, h, a) => applyIccFilter(
                          color,
                          lightness: l,
                          chroma: c,
                          hue: h,
                          alpha: a,
                        ),
                        onExtremeTap: _onExtremeTap,
                        onMixerSliderTouched: _onMixerSliderTouched,
                        onOklchChanged: _onOklchChanged,
                        onSliderInteractionChanged: (interacting) =>
                            setState(() => _isInteractingWithSlider = interacting),
                        useRealPigmentsOnly: _useRealPigmentsOnly,
                        onRealPigmentsOnlyChanged: _onRealPigmentsOnlyChanged,
                      ),
                      ),
                    ),
                  ],
                ),
              ),

              //---------------------------------------------------------------------------------------------------------------------
              // Main content area (behind the grabbing sheet)
              //---------------------------------------------------------------------------------------------------------------------
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
                              // Background color button (acts like a palette box)
                              GestureDetector(
                                onTap: _onBgColorBoxTap,
                                child: Container(
                                  width: 48,
                                  height: 48,
                                  margin: const EdgeInsets.only(right: 12),
                                  decoration: BoxDecoration(
                                    color: applyIccFilter(
                                      bgColor ?? const Color(0xFF252525),
                                      lightness: _bgLightness,
                                      chroma: _bgChroma,
                                      hue: _bgHue,
                                      alpha: _bgAlpha,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _isBgColorSelected
                                          ? Colors.white.withOpacity(0.9)
                                          : Colors.white.withOpacity(0.3),
                                      width: _isBgColorSelected ? 3 : 2,
                                    ),
                                    boxShadow: _isBgColorSelected
                                        ? [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.3),
                                              blurRadius: 8,
                                              offset: const Offset(0, 4),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Icon(
                                    Icons.format_paint,
                                    color: Colors.white.withOpacity(_isBgColorSelected ? 0.9 : 0.7),
                                    size: 24,
                                  ),
                                ),
                              ),
                              
                              // Other action buttons
                              Expanded(
                                child: ActionButtonsRow(
                                  currentColor: currentColor,
                                  selectedExtremeId: _selectedExtremeId,
                                  leftExtreme: _leftExtreme,
                                  rightExtreme: _rightExtreme,
                                  onColorSelected: _handleColorSelection,
                                  undoRedoManager: _undoRedoManager,
                                  onUndo: _handleUndo,
                                  onRedo: _handleRedo,
                                  colorFilter: (color) => applyIccFilter(color),
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 20),

                          // Color preview (with ICC filter if enabled)
                          ColorPreviewBox(
                            color: applyIccFilter(
                              currentColor ?? Colors.grey,
                              lightness: currentLightness,
                              chroma: currentChroma,
                              hue: currentHue,
                              alpha: currentAlpha,
                            ),
                          ),

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
                              colorFilter: (item) => applyIccFilter(
                                item.color,
                                lightness: item.oklchValues.lightness,
                                chroma: item.oklchValues.chroma,
                                hue: item.oklchValues.hue,
                                alpha: item.oklchValues.alpha,
                              ),
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
                                  '',
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
            
            //---------------------------------------------------------------------------------------------------------------------
            // Floating Action Button Stack)
            //---------------------------------------------------------------------------------------------------------------------
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                    color: Colors.red,
                  child: Text('Hello'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
