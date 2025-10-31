import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:snapping_sheet_2/snapping_sheet.dart';
import '../widgets/color_picker/color_picker_controls.dart';
import '../widgets/color_picker/reorderable_color_grid_view.dart';
import '../widgets/home/sheet_grabbing_handle.dart';
import '../widgets/home/action_buttons_row.dart';
import '../widgets/common/undo_redo_buttons.dart';
import '../models/color_palette_item.dart';
import '../services/undo_redo_manager.dart';
import '../services/app_state_coordinator.dart';
import '../state/color_editor_provider.dart';
import '../state/palette_provider.dart';
import '../state/extreme_colors_provider.dart';
import '../state/bg_color_provider.dart';
import '../state/settings_provider.dart';
import '../utils/color_operations.dart';
import '../utils/icc_color_manager.dart';
import '../utils/color_utils.dart';
import 'menu_screen.dart';
import '../cyclop_eyedropper/eye_dropper_layer.dart';
import '../services/clipboard_service.dart';

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
  // NOTE: All undoable state is now in Providers:
  // - ColorEditorProvider: current OKLCH editing values
  // - PaletteProvider: color palette items
  // - ExtremeColorsProvider: left/right extreme colors
  // - BgColorProvider: background color and OKLCH values
  // - SettingsProvider: ICC filter toggle and other settings

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
  final List<bool> _selectedChips = [false, true, false, false];

  /// Current height of the snapping sheet
  double _currentSheetHeight = 0.0;

  // ========== Undo/Redo Management ==========

  /// Undo/redo manager
  final UndoRedoManager _undoRedoManager = UndoRedoManager(maxHistorySize: 50);

  /// State coordinator for undo/redo across all providers
  late AppStateCoordinator _coordinator;

  // ========== Lifecycle ==========

  @override
  void initState() {
    super.initState();

    // Defer Provider updates and initialization to after build phase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Initialize coordinator
      _coordinator = AppStateCoordinator(
        colorEditor: context.read<ColorEditorProvider>(),
        palette: context.read<PaletteProvider>(),
        extremes: context.read<ExtremeColorsProvider>(),
        bgColor: context.read<BgColorProvider>(),
        settings: context.read<SettingsProvider>(),
        undoRedo: _undoRedoManager,
      );

      _initializeSamplePalette();
      _coordinator.saveState('Initial state');
    });

    _initializeIccProfile();
  }
  
  @override
  void dispose() {
    IccColorManager.instance.dispose();
    _undoRedoManager.dispose();
    super.dispose();
  }
  
  /// Initialize with sample colors
  void _initializeSamplePalette() {
    final sampleColors = [
      ColorPaletteItem.fromColor(const Color(0xFFE74C3C), name: 'Red'),
      ColorPaletteItem.fromColor(const Color(0xFF3498DB), name: 'Blue'),
      ColorPaletteItem.fromColor(const Color(0xFF2ECC71), name: 'Green'),
      ColorPaletteItem.fromColor(const Color(0xFFF39C12), name: 'Orange'),
    ];
    context.read<PaletteProvider>().syncFromSnapshot(sampleColors);
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
    // Update ColorEditorProvider (source of truth)
    context.read<ColorEditorProvider>().updateOklch(
      lightness: lightness,
      chroma: chroma,
      hue: hue,
      alpha: alpha,
    );

    // Coordinate with selected item
    final paletteProvider = context.read<PaletteProvider>();
    final selectedItem = paletteProvider.selectedItem;
    final extremesProvider = context.read<ExtremeColorsProvider>();
    final bgColorProvider = context.read<BgColorProvider>();

    if (selectedItem != null) {
      // Update selected palette item
      paletteProvider.updateItemOklch(
        itemId: selectedItem.id,
        lightness: lightness,
        chroma: chroma,
        hue: hue,
        alpha: alpha,
      );
      _coordinator.saveState('Modified ${selectedItem.name ?? "color"}');
    } else if (extremesProvider.selectedExtremeId != null) {
      // Update selected extreme (behaves exactly like a box)
      extremesProvider.updateExtremeOklch(
        extremeId: extremesProvider.selectedExtremeId!,
        lightness: lightness,
        chroma: chroma,
        hue: hue,
        alpha: alpha,
      );
      final extremeName = extremesProvider.selectedExtremeId == 'left' ? 'left' : 'right';
      _coordinator.saveState('Modified $extremeName extreme');
    } else if (bgColorProvider.isSelected) {
      // Update background color (behaves exactly like a box)
      bgColorProvider.updateOklch(
        lightness: lightness,
        chroma: chroma,
        hue: hue,
        alpha: alpha,
      );
      _coordinator.saveState('Modified background color');
    }
  }

  /// Legacy handler for Color-based changes (eyedropper, paste)
  void _onColorChanged(Color? color) {
    if (color == null) return;

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
    _onColorChanged(color);
    _coordinator.saveState('Color selected from eyedropper/paste');
  }

  /// Handle "Only Real Pigments" toggle
  ///
  /// This is a DISPLAY FILTER - doesn't modify stored OKLCH values.
  /// When toggled ON, colors are filtered through ICC profile for display only.
  void _onRealPigmentsOnlyChanged(bool value) {
    final settingsProvider = context.read<SettingsProvider>();
    settingsProvider.setRealPigmentsOnly(value);
    _coordinator.saveState(
      value ? 'Enabled real pigments filter' : 'Disabled real pigments filter'
    );
  }

  /// ========== ICC Display Filter Operations ==========

  /// Apply ICC display filter to color
  ///
  /// This is where the REAL-TIME ICC FILTERING happens!
  ///
  /// Returns:
  /// - Original color if toggle OFF or ICC not ready
  /// - Gamut-mapped (filtered) color if toggle ON and ICC ready
  ///
  /// NOTE: This doesn't modify state, only display!
  Color applyIccFilter(Color idealColor, {
    double? lightness,
    double? chroma,
    double? hue,
    double? alpha,
  }) {
    // No filter if toggle OFF or ICC not initialized
    final settingsProvider = context.read<SettingsProvider>();
    if (!settingsProvider.useRealPigmentsOnly || !IccColorManager.instance.isReady) {
      return idealColor;
    }

    // Use provided OKLCH or extract from ColorEditorProvider
    final colorEditor = context.read<ColorEditorProvider>();
    final l = lightness ?? colorEditor.lightness ?? 0.5;
    final c = chroma ?? colorEditor.chroma ?? 0.0;
    final h = hue ?? colorEditor.hue ?? 0.0;
    final a = alpha ?? 1.0;

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

  // ========== Palette Item Operations ==========
  
  void _onPaletteReorder(int oldIndex, int newIndex) {
    context.read<PaletteProvider>().reorderItems(oldIndex, newIndex);
    _coordinator.saveState('Reordered palette items');
  }
  
  void _onPaletteItemTap(ColorPaletteItem item) {
    // If tapping an already-selected item, deselect it
    if (item.isSelected) {
      context.read<PaletteProvider>().deselectAll();
      return;
    }

    // Otherwise, select the item
    context.read<PaletteProvider>().selectItem(item.id);

    // Deselect extremes when a box is selected
    final extremesProvider = context.read<ExtremeColorsProvider>();
    extremesProvider.deselectAll();

    // Deselect bg color box
    context.read<BgColorProvider>().setSelected(false);

    // Update ColorEditorProvider with the selected item's OKLCH values
    context.read<ColorEditorProvider>().setFromOklchValues(item.oklchValues);
  }

  void _onBgColorBoxTap() {
    final bgColorProvider = context.read<BgColorProvider>();

    // If tapping an already-selected bg color box, deselect it
    if (bgColorProvider.isSelected) {
      bgColorProvider.setSelected(false);
      return;
    }

    // Otherwise, select the bg color box
    // Deselect all palette boxes
    context.read<PaletteProvider>().deselectAll();

    // Deselect extremes
    context.read<ExtremeColorsProvider>().deselectAll();

    // Select bg color box
    bgColorProvider.setSelected(true);

    // Update ColorEditorProvider with bg color's OKLCH values
    context.read<ColorEditorProvider>().updateOklch(
      lightness: bgColorProvider.lightness,
      chroma: bgColorProvider.chroma,
      hue: bgColorProvider.hue,
      alpha: bgColorProvider.alpha,
    );
  }

  void _onExtremeTap(String extremeId) {
    final extremesProvider = context.read<ExtremeColorsProvider>();

    // If tapping an already-selected extreme, deselect it
    if (extremesProvider.selectedExtremeId == extremeId) {
      extremesProvider.deselectAll();
      return;
    }

    // Otherwise, select the tapped extreme
    // Deselect all palette boxes
    context.read<PaletteProvider>().deselectAll();

    // Deselect bg color box
    context.read<BgColorProvider>().setSelected(false);

    // Select tapped extreme
    extremesProvider.selectExtreme(extremeId);

    // Update ColorEditorProvider with the selected extreme's OKLCH values
    final selectedExtreme = extremeId == 'left' ? extremesProvider.leftExtreme : extremesProvider.rightExtreme;
    context.read<ColorEditorProvider>().setFromOklchValues(selectedExtreme.oklchValues);
  }

  void _onMixerSliderTouched() {
    final extremesProvider = context.read<ExtremeColorsProvider>();
    final bgColorProvider = context.read<BgColorProvider>();

    // Deselect extremes and bg color box when mixer slider is dragged
    if (extremesProvider.selectedExtremeId != null || bgColorProvider.isSelected) {
      extremesProvider.deselectAll();
      bgColorProvider.setSelected(false);
    }
  }

  void _onPaletteItemLongPress(ColorPaletteItem item) {
    _showColorItemMenu(item);
  }
  
  void _onPaletteItemDelete(ColorPaletteItem item) {
    context.read<PaletteProvider>().removeColor(item.id);
    _coordinator.saveState('Deleted ${item.name ?? "color"} from palette');
  }
  
  void _onAddColor() {
    // Determine color to add:
    // 1. If a box is selected, use its current color (which may have been edited via sliders)
    // 2. Otherwise, use current color from ColorEditorProvider
    final paletteProvider = context.read<PaletteProvider>();
    final selectedItem = paletteProvider.selectedItem;
    final colorEditor = context.read<ColorEditorProvider>();
    final colorToAdd = selectedItem?.color ?? colorEditor.currentColor;

    if (colorToAdd != null) {
      paletteProvider.addColor(colorToAdd, selectNew: true);
      _coordinator.saveState('Added new color to palette');
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
    final paletteSizeBefore = context.read<PaletteProvider>().items.length;

    debugPrint('Drag ended - Last Y: $_lastDragPointerY, Current Y: $_dragPointerY, InZone: $_isInDeleteZone, Should delete: $shouldDelete, Palette size before: $paletteSizeBefore');

    if (shouldDelete) {
      _onDropToDelete();
      final paletteSizeAfter = context.read<PaletteProvider>().items.length;
      debugPrint('Palette size after delete: $paletteSizeAfter');
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
    if (_draggingItem != null) {
      final itemToDelete = _draggingItem!;
      debugPrint('Deleting item: ${itemToDelete.id}');

      // Remove item from palette
      context.read<PaletteProvider>().removeColor(itemToDelete.id);
      _coordinator.saveState('Deleted ${itemToDelete.name ?? "color"} via drag');
    }
  }
  
  bool get _isInDeleteZone => _dragPointerY < _deleteZoneThreshold;

  // ========== Eyedropper Logic ==========
  
  // New method for eyedropper logic for background color
  void _startEyedropperForBgColor(DragStartDetails details) {
    try {
      Future.delayed(
        const Duration(milliseconds: 50),
        () => EyeDrop.of(context).capture(context, (color) {
          final oklchColor = srgbToOklch(color);

          // Update via provider
          final bgColorProvider = context.read<BgColorProvider>();
          bgColorProvider.updateOklch(
            lightness: oklchColor.l,
            chroma: oklchColor.c,
            hue: oklchColor.h,
            alpha: oklchColor.alpha,
          );
          bgColorProvider.setSelected(true); // Select bg color when picked

          // Update color editor
          context.read<ColorEditorProvider>().updateOklch(
            lightness: oklchColor.l,
            chroma: oklchColor.c,
            hue: oklchColor.h,
            alpha: oklchColor.alpha,
          );

          _coordinator.saveState('Eyedropper picked color for background');

          // Show feedback
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Picked ${ClipboardService.colorToHex(color)} for background'),
                duration: const Duration(milliseconds: 100),
                behavior: SnackBarBehavior.floating,
                backgroundColor: Colors.black87,
              ),
            );
          }
        }, null),
      );
    } catch (err) {
      debugPrint('EyeDrop capture error for background: $err');
    }
  }

  // New method for eyedropper logic for extremes
  void _startEyedropperForExtreme(String extremeId, DragStartDetails details) {
    try {
      Future.delayed(
        const Duration(milliseconds: 50),
        () => EyeDrop.of(context).capture(context, (color) {
          final oklchColor = srgbToOklch(color);
          final extremesProvider = context.read<ExtremeColorsProvider>();

          if (extremeId == 'left') {
            // Update via provider
            extremesProvider.updateExtremeOklch(
              extremeId: 'left',
              lightness: oklchColor.l,
              chroma: oklchColor.c,
              hue: oklchColor.h,
              alpha: oklchColor.alpha,
            );

            // Update color editor
            context.read<ColorEditorProvider>().updateOklch(
              lightness: oklchColor.l,
              chroma: oklchColor.c,
              hue: oklchColor.h,
              alpha: oklchColor.alpha,
            );

            _coordinator.saveState('Eyedropper picked color for left extreme');
          } else if (extremeId == 'right') {
            // Update via provider
            extremesProvider.updateExtremeOklch(
              extremeId: 'right',
              lightness: oklchColor.l,
              chroma: oklchColor.c,
              hue: oklchColor.h,
              alpha: oklchColor.alpha,
            );

            // Update color editor
            context.read<ColorEditorProvider>().updateOklch(
              lightness: oklchColor.l,
              chroma: oklchColor.c,
              hue: oklchColor.h,
              alpha: oklchColor.alpha,
            );

            _coordinator.saveState('Eyedropper picked color for right extreme');
          }

          // Show feedback
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Picked ${ClipboardService.colorToHex(color)} for extreme'),
                duration: const Duration(milliseconds: 100),
                behavior: SnackBarBehavior.floating,
                backgroundColor: Colors.black87,
              ),
            );
          }
        }, null),
      );
    } catch (err) {
      debugPrint('EyeDrop capture error for extreme: $err');
    }
  }

  // ========== Undo/Redo Actions==========
  
  void _handleUndo() {
    _coordinator.undo();
  }

  void _handleRedo() {
    _coordinator.redo();
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
  
  // ========== Build ==========
  
  @override
  Widget build(BuildContext context) {
    // Read provider values once for the entire build method
    final bgColorProvider = context.watch<BgColorProvider>();
    final extremesProvider = context.watch<ExtremeColorsProvider>();
    final settingsProvider = context.watch<SettingsProvider>();

    final bgColor = bgColorProvider.color;
    final bgLightness = bgColorProvider.lightness;
    final bgChroma = bgColorProvider.chroma;
    final bgHue = bgColorProvider.hue;
    final bgAlpha = bgColorProvider.alpha;
    final isBgColorSelected = bgColorProvider.isSelected;

    final leftExtreme = extremesProvider.leftExtreme;
    final rightExtreme = extremesProvider.rightExtreme;
    final selectedExtremeId = extremesProvider.selectedExtremeId;

    final useRealPigmentsOnly = settingsProvider.useRealPigmentsOnly;

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
              // Snapping Sheet Positions
              snappingPositions: const [
                SnappingPosition.pixels(
                  positionPixels: 60,
                  snappingCurve: Curves.easeOutExpo,
                  snappingDuration: Duration(milliseconds: 900),
                  grabbingContentOffset: GrabbingContentOffset.top,
                ),
                SnappingPosition.pixels(
                  positionPixels: 220,
                  snappingCurve: Curves.easeOutExpo,
                  snappingDuration: Duration(milliseconds: 900),
                ),
                SnappingPosition.pixels(
                  positionPixels: 370,
                  snappingCurve: Curves.easeOutExpo,
                  snappingDuration: Duration(milliseconds: 900),
                  grabbingContentOffset: GrabbingContentOffset.bottom,
                ),
                SnappingPosition.pixels(
                  positionPixels: 440,
                  snappingCurve: Curves.easeOutExpo,
                  snappingDuration: Duration(milliseconds: 900),
                ),
                SnappingPosition.pixels(
                  positionPixels: 700,
                  snappingCurve: Curves.easeOutExpo,
                  snappingDuration: Duration(milliseconds: 900),
                ),
              ],

              onSheetMoved: (positionData) {
                setState(() {
                  _currentSheetHeight = positionData.pixels;
                });
              },

              //---------------------------------------------------------------------------------------------------------------------
              // Grabbing handle Content
              //---------------------------------------------------------------------------------------------------------------------
              grabbingHeight: 80,
              grabbing: SheetGrabbingHandle(
                chipStates: _selectedChips,
                onChipToggle: (index) => setState(() => _selectedChips[index] = !_selectedChips[index]),
                bgColor: bgColor, // Pass bgColor
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
                      color: bgColor ?? Colors.white, // Use bgColor for the sheet content
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                      child: ColorPickerControls(
                        onOklchChanged: _onOklchChanged,
                        // Pass extreme data without modification
                        leftExtreme: leftExtreme,
                        rightExtreme: rightExtreme,
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
                        onSliderInteractionChanged: (interacting) =>
                            setState(() => _isInteractingWithSlider = interacting),
                        useRealPigmentsOnly: useRealPigmentsOnly,
                        bgColor: bgColor, // Pass bgColor
                        onPanStartExtreme: _startEyedropperForExtreme, // Pass eyedropper function
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
                    Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              children: [
                                const SizedBox(height: 0),
                                // Only Real Pigments toggle (ICC profile filter)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 0.0),
                                  child: GestureDetector(
                                    onTap: () {
                                      _onRealPigmentsOnlyChanged(!useRealPigmentsOnly);
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: useRealPigmentsOnly
                                            ? Colors.blue.shade700.withOpacity(0.9) // Selected color
                                            : Colors.grey.shade200, // Unselected color
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            useRealPigmentsOnly ? Icons.check_circle : Icons.circle_outlined,
                                            size: 20,
                                            color: useRealPigmentsOnly ? Colors.white : Colors.grey.shade700,
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            'Only Real Pigments',
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color: useRealPigmentsOnly ? Colors.white : Colors.grey.shade800,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 70),
                                // Color palette grid
                                ReorderableColorGridView(
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
                                SizedBox(height: _currentSheetHeight),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 80),
                      ],
                    ),

                    //---------------------------------------------------------------------------------------------------------------------
                    // App Bar (overlays on top)
                    //---------------------------------------------------------------------------------------------------------------------
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        color: bgColor, // Use current background color
                        padding: const EdgeInsets.fromLTRB(40, 20, 40, 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.star_border,
                                color: getTextColor(bgColor ?? const Color(0xFF252525)),
                              ),
                              onPressed: () {
                                // TODO: Implement star functionality
                              },
                            ),
                            Text('Palletator',
                              style: TextStyle(
                                color: getTextColor(bgColor ?? const Color(0xFF252525)),
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Hero(
                              tag: 'menuButton',
                              child: IconButton(
                                icon: Icon(
                                  Icons.menu,
                                  color: getTextColor(bgColor ?? const Color(0xFF252525)), // Apply color logic
                                ),
                                onPressed: () {
                                  Navigator.push(context, PageRouteBuilder(
                                    pageBuilder: (context, animation, secondaryAnimation) => const MenuScreen(),
                                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                      const begin = Offset(1.0, 0.0); // Start from right
                                      const end = Offset.zero;
                                      const curve = Curves.ease;

                                      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

                                      return SlideTransition(
                                        position: animation.drive(tween),
                                        child: child,
                                      );
                                    },
                                  ));
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    //---------------------------------------------------------------------------------------------------------------------
                    // Drag-to-delete zone (overlays on top)
                    //---------------------------------------------------------------------------------------------------------------------
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
              bottom: 0,
              left: 20,
              right: 20,
              child: 
                          Container(
                            color: bgColor ?? Colors.white, // Use bgColor for the action bar
                            padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                            child: Row(
                              children: [
                                // Background color button (acts like a palette box)
                                GestureDetector(
                                  onTap: _onBgColorBoxTap,
                                  onPanStart: _startEyedropperForBgColor, // Add this line
                                  child: Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: applyIccFilter(
                                        bgColor ?? const Color(0xFF252525),
                                        lightness: bgLightness,
                                        chroma: bgChroma,
                                        hue: bgHue,
                                        alpha: bgAlpha,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isBgColorSelected
                                            ? getTextColor(bgColor ?? Colors.white).withOpacity(0.9)
                                            : getTextColor(bgColor ?? Colors.white).withOpacity(0.3),
                                        width: isBgColorSelected ? 3 : 2,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.format_paint,
                                      color: getTextColor(bgColor ?? Colors.white).withOpacity(isBgColorSelected ? 0.9 : 0.7),
                                      size: 24,
                                    ),
                                  ),
                                ),
                                
                                // Other action buttons
                                Expanded(
                                  child: ActionButtonsRow(
                                    currentColor: context.watch<ColorEditorProvider>().currentColor,
                                    selectedExtremeId: selectedExtremeId,
                                    leftExtreme: leftExtreme,
                                    rightExtreme: rightExtreme,
                                    onColorSelected: _handleColorSelection,
                                    undoRedoManager: _undoRedoManager,
                                    onUndo: _handleUndo,
                                    onRedo: _handleRedo,
                                    colorFilter: (color) => applyIccFilter(color),
                                    bgColor: bgColor, // Pass bgColor to ActionButtonsRow
                                  ),
                                ),
                              ],
                            ),
                          ),
            ),
          ],
        ),
      ),
    );
  }
}
