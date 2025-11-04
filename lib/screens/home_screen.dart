import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:snapping_sheet_2/snapping_sheet.dart';
import '../widgets/color_picker/color_picker_controls.dart';
import '../widgets/color_picker/reorderable_color_grid_view.dart';
import '../widgets/home/sheet_grabbing_handle.dart';
import '../widgets/home/home_app_bar.dart';
import '../widgets/home/delete_zone_overlay.dart';
import '../widgets/home/real_pigments_toggle.dart';
import '../widgets/home/bottom_action_bar.dart';
import '../widgets/common/undo_redo_buttons.dart';
import '../models/color_grid_item.dart';
import '../services/undo_redo_service.dart';
import '../services/clipboard_service.dart';
import '../coordinator/state_history_coordinator.dart';
import '../controllers/drag_drop_controller.dart';
import '../state/color_editor_provider.dart';
import '../state/color_grid_provider.dart';
import '../state/extreme_colors_provider.dart';
import '../state/bg_color_provider.dart';
import '../state/settings_provider.dart';
import '../services/icc_color_service.dart';
import '../utils/color_operations.dart';
import '../cyclop_eyedropper/eye_dropper_layer.dart';

// Color Picker Home Screen
//
// Orchestrates the main color picker UI using Providers for state management.
// Coordination logic lives here where we have easy access to all providers.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  // ================================================
  // ========== Widget-Scoped Objects ===============
  // ================================================
  //
  // These live in the widget's state and are disposed with the widget.
  //
  // DragDropController:
  //   - Manages UI state for drag-drop behavior (drag position, delete zone)
  //   - Extends ChangeNotifier for reactive UI updates
  //   - Lives here because it's widget-scoped, not app-wide
  //
  // StateHistoryCoordinator:
  //   - Orchestrates undo/redo across ALL providers
  //   - Captures and restores state snapshots
  //   - Lives here because it needs references to all providers
  //
  // UndoRedoService:
  //   - Manages the undo/redo history stack
  //   - Maintains state (undo stack, redo stack, current state)
  //   - Extends ChangeNotifier to notify on history changes

  late DragDropController _dragDropController;
  late StateHistoryCoordinator _coordinator;
  final UndoRedoService _undoRedoService = UndoRedoService(maxHistorySize: 100);

  // ================================================
  // ========== Widget UI State =====================
  // ================================================
  //
  // Local UI state that doesn't need to be shared across the app.
  // This is ephemeral state tied to this widget's lifecycle.
  //
  // - SnappingSheetController: Controls the bottom sheet position/animations
  // - _currentSheetHeight: Tracks sheet height for layout adjustments
  // - ScrollController: Controls scrolling behavior
  // - _isInteractingWithSlider: Prevents sheet dragging during slider interaction
  // - _selectedChips: Toggle states for chip filters (currently unused?)

  final SnappingSheetController snappingSheetController = SnappingSheetController();
  double _currentSheetHeight = 0.0;
  final ScrollController scrollController = ScrollController();
  bool _isInteractingWithSlider = false;
  final List<bool> _selectedChips = [false, true, false, false];

  // ================================================
  // ========== Lifecycle & Initialization ==========
  // ================================================
  // Widget lifecycle methods that set up and tear down resources.

  // initState():
  //   1. Creates widget-scoped objects (Coordinator, Controller, Service)
  //   2. Loads sample grid data (deferred to postFrameCallback)
  //   3. Initializes ICC color profile asynchronously
  @override
  void initState() {
    super.initState();

    // Create state history coordinator (needs references to all providers)
    _coordinator = StateHistoryCoordinator(
      colorEditor: context.read<ColorEditorProvider>(),
      grid: context.read<ColorGridProvider>(),
      extremes: context.read<ExtremeColorsProvider>(),
      bgColor: context.read<BgColorProvider>(),
      settings: context.read<SettingsProvider>(),
      undoRedo: _undoRedoService,
    );

    // Create drag & drop controller (manages drag UI state)
    _dragDropController = DragDropController(
      gridProvider: context.read<ColorGridProvider>(),
      coordinator: _coordinator,
    );

    // Defer state-modifying operations until after first build
    // (Can't modify provider state during initState)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeSampleGrid();
      _coordinator.saveState('Initial state');
    });

    // Load ICC profile asynchronously (doesn't block UI)
    _initializeIccProfile();
  }

  // Loads sample colors into the grid on first launch
  void _initializeSampleGrid() {
    final sampleColors = [
      ColorGridItem.fromColor(const Color.fromARGB(255, 240, 98, 82), name: 'Red'),
      ColorGridItem.fromColor(const Color.fromARGB(255, 87, 165, 218), name: 'Blue'),
      ColorGridItem.fromColor(const Color.fromARGB(255, 85, 219, 141), name: 'Green'),
      ColorGridItem.fromColor(const Color.fromARGB(255, 255, 190, 86), name: 'Orange'),
    ];
    context.read<ColorGridProvider>().syncFromSnapshot(sampleColors);
  }

  // Loads ICC color profile for "Real Pigments Only" feature
  //
  // Runs asynchronously - app works fine if this fails
  Future<void> _initializeIccProfile() async {
    try {
      const profilePath = 'reference-icc/Canon ImagePROGRAPH PRO-1000.icc';
      final profileData = await rootBundle.load(profilePath);
      final bytes = profileData.buffer.asUint8List();
      final success = await IccColorManager.instance.initialize(bytes);

      if (success) {
        debugPrint('✓ ICC Profile loaded successfully');
      } else {
        debugPrint('⚠ ICC Profile initialization failed');
      }
    } catch (e) {
      debugPrint('⚠ ICC Profile loading error: $e');
    }
  }

  // dispose():
  //   Cleans up all resources to prevent memory leaks
  @override
  void dispose() {
    // Clean up singleton service
    IccColorManager.instance.dispose();

    // Clean up widget-scoped objects
    _undoRedoService.dispose();
    _dragDropController.dispose();

    // Call the parent class's dispose method to complete widget lifecycle, after this,
    //the widget is dead and doesnt access any resources.
    super.dispose();
  }

  // ================================================
  // ========== Cross-Provider Coordination =========
  // ================================================
  //
  // These methods coordinate operations across multiple providers.
  // They live here because they need access to all providers via context.read<>()
  //
  // This is the "glue code" that makes providers work together.

  // ========== Color Update Coordination ===========

  // Handles OKLCH color changes from sliders
  void _handleOklchChanged({
    required double lightness,
    required double chroma,
    required double hue,
    double alpha = 1.0,
  }) {
    final colorEditor = context.read<ColorEditorProvider>();
    final grid = context.read<ColorGridProvider>();
    final extremes = context.read<ExtremeColorsProvider>();
    final bgColor = context.read<BgColorProvider>();

    // Update ColorEditorProvider (source of truth)
    colorEditor.updateOklch(
      lightness: lightness,
      chroma: chroma,
      hue: hue,
      alpha: alpha,
    );

    // Coordinate with selected item
    final selectedItem = grid.selectedItem;

    if (selectedItem != null) {
      grid.updateItemOklch(
        itemId: selectedItem.id,
        lightness: lightness,
        chroma: chroma,
        hue: hue,
        alpha: alpha,
      );
      _coordinator.saveState('Modified ${selectedItem.name ?? "color"}');
    } else if (extremes.selectedExtremeId != null) {
      extremes.updateExtremeOklch(
        extremeId: extremes.selectedExtremeId!,
        lightness: lightness,
        chroma: chroma,
        hue: hue,
        alpha: alpha,
      );
      final extremeName = extremes.selectedExtremeId == 'left' ? 'left' : 'right';
      _coordinator.saveState('Modified $extremeName extreme');
    } else if (bgColor.isSelected) {
      bgColor.updateOklch(
        lightness: lightness,
        chroma: chroma,
        hue: hue,
        alpha: alpha,
      );
      _coordinator.saveState('Modified background color');
    }
  }

  // Converts sRGB Color to OKLCH and delegates to _handleOklchChanged
  void _handleColorChanged(Color? color) {
    if (color == null) return;
    final oklch = srgbToOklch(color);
    _handleOklchChanged(
      lightness: oklch.l,
      chroma: oklch.c,
      hue: oklch.h,
      alpha: oklch.alpha,
    );
  }

  // Handles color selection from eyedropper or paste
  void _handleColorSelection(Color color) {
    _handleColorChanged(color);
    _coordinator.saveState('Color selected from eyedropper/paste');
  }

  // Applies ICC color profile filter if "Real Pigments Only" is enabled
  //
  // Transforms colors through printer gamut (sRGB → Lab → CMYK → Lab → sRGB)
  // Returns original color if filter is disabled or ICC profile not loaded
  Color _applyIccFilter(Color idealColor, {
    double? lightness,
    double? chroma,
    double? hue,
    double? alpha,
  }) {
    final settings = context.read<SettingsProvider>();
    if (!settings.useRealPigmentsOnly || !IccColorManager.instance.isReady) {
      return idealColor;
    }

    final colorEditor = context.read<ColorEditorProvider>();
    final l = lightness ?? colorEditor.lightness ?? 0.5;
    final c = chroma ?? colorEditor.chroma ?? 0.0;
    final h = hue ?? colorEditor.hue ?? 0.0;
    final a = alpha ?? 1.0;

    try {
      final cieLab = oklchToCieLab(l, c, h);
      final mappedLab = IccColorManager.instance.transformLab(cieLab.l, cieLab.a, cieLab.b);
      final mappedOklch = cieLabToOklch(mappedLab[0], mappedLab[1], mappedLab[2]);
      return colorFromOklch(mappedOklch.l, mappedOklch.c, mappedOklch.h, a);
    } catch (e) {
      debugPrint('⚠ ICC filter error: $e');
      return idealColor;
    }
  }

  // ========== Selection Coordination ============

  // When user selects something (grid item, extreme, background),
  // we need to:
  // 1. Deselect everything else across all providers
  // 2. Select the new item
  // 3. Update ColorEditorProvider with the selected color
  // 4. Optionally auto-copy to clipboard

  // Handles reordering grid items via drag-and-drop
  void _handleGridReorder(int oldIndex, int newIndex) {
    context.read<ColorGridProvider>().reorderItems(oldIndex, newIndex);
    _coordinator.saveState('Reordered grid items');
  }

  // Handles tapping a grid item
  //
  // Coordinates selection across:
  // - ColorGridProvider (select this item)
  // - ExtremeColorsProvider (deselect extremes)
  // - BgColorProvider (deselect background)
  // - ColorEditorProvider (load item's color)
  // - ClipboardService (auto-copy if enabled)
  void _handleGridItemTap(ColorGridItem item) {
    final grid = context.read<ColorGridProvider>();
    final extremes = context.read<ExtremeColorsProvider>();
    final bgColor = context.read<BgColorProvider>();
    final colorEditor = context.read<ColorEditorProvider>();
    final settings = context.read<SettingsProvider>();

    if (item.isSelected) {
      grid.deselectAll();
      return;
    }

    grid.selectItem(item.id);
    extremes.deselectAll();
    bgColor.setSelected(false);
    colorEditor.setFromOklchValues(item.oklchValues);

    if (settings.autoCopyEnabled) {
      ClipboardService.copyColorToClipboard(item.color);
    }
  }

  // Handles tapping the background color box
  //
  // Coordinates selection across all providers (deselects grid items and extremes)
  void _handleBgColorBoxTap() {
    final bgColor = context.read<BgColorProvider>();
    final grid = context.read<ColorGridProvider>();
    final extremes = context.read<ExtremeColorsProvider>();
    final colorEditor = context.read<ColorEditorProvider>();

    if (bgColor.isSelected) {
      bgColor.setSelected(false);
      return;
    }

    grid.deselectAll();
    extremes.deselectAll();
    bgColor.setSelected(true);

    colorEditor.updateOklch(
      lightness: bgColor.lightness,
      chroma: bgColor.chroma,
      hue: bgColor.hue,
      alpha: bgColor.alpha,
    );
  }

  // Handles tapping a mixer extreme (left or right)
  //
  // Coordinates selection across all providers
  void _handleExtremeTap(String extremeId) {
    final extremes = context.read<ExtremeColorsProvider>();
    final grid = context.read<ColorGridProvider>();
    final bgColor = context.read<BgColorProvider>();
    final colorEditor = context.read<ColorEditorProvider>();
    final settings = context.read<SettingsProvider>();

    if (extremes.selectedExtremeId == extremeId) {
      extremes.deselectAll();
      return;
    }

    grid.deselectAll();
    bgColor.setSelected(false);
    extremes.selectExtreme(extremeId);

    final selectedExtreme = extremeId == 'left' ? extremes.leftExtreme : extremes.rightExtreme;
    colorEditor.setFromOklchValues(selectedExtreme.oklchValues);

    if (settings.autoCopyEnabled) {
      ClipboardService.copyColorToClipboard(selectedExtreme.color);
    }
  }

  // Handles when user touches the mixer slider
  //
  // Deselects extremes and background color since the mixer slider
  // operates independently and should clear any extreme/background selection
  void _handleMixerSliderTouched() {
    final extremes = context.read<ExtremeColorsProvider>();
    final bgColor = context.read<BgColorProvider>();

    if (extremes.selectedExtremeId != null || bgColor.isSelected) {
      extremes.deselectAll();
      bgColor.setSelected(false);
    }
  }

  // Handles long press on a grid item
  //
  // Shows a bottom sheet menu with options (delete, etc.)
  void _handleGridItemLongPress(ColorGridItem item) {
    _showColorItemMenu(item);
  }

  // Handles deletion of a grid item
  //
  // Removes the item from the grid and saves undo state
  void _handleGridItemDelete(ColorGridItem item) {
    context.read<ColorGridProvider>().removeColor(item.id);
    _coordinator.saveState('Deleted ${item.name ?? "color"} from grid');
  }

  // Handles adding a new color to the grid
  //
  // Adds the currently selected color (or current editor color if nothing selected)
  // to the grid and selects it automatically
  void _handleAddColor() {
    final grid = context.read<ColorGridProvider>();
    final colorEditor = context.read<ColorEditorProvider>();
    final selectedItem = grid.selectedItem;
    final colorToAdd = selectedItem?.color ?? colorEditor.currentColor;

    if (colorToAdd != null) {
      grid.addColor(colorToAdd, selectNew: true);
      _coordinator.saveState('Added new color to grid');
    }
  }

  // ========== Other Actions & Handlers ============

  // Starts eyedropper tool for background color selection
  //
  // Launches the eyedropper overlay to pick a color from screen,
  // then updates background color and ColorEditor with the picked color
  void _startEyedropperForBgColor(DragStartDetails details) {
    try {
      Future.delayed(
        const Duration(milliseconds: 50),
        () => EyeDrop.of(context).capture(context, (color) {
          final oklchColor = srgbToOklch(color);
          final bgColor = context.read<BgColorProvider>();
          final colorEditor = context.read<ColorEditorProvider>();

          bgColor.updateOklch(
            lightness: oklchColor.l,
            chroma: oklchColor.c,
            hue: oklchColor.h,
            alpha: oklchColor.alpha,
          );
          bgColor.setSelected(true);

          colorEditor.updateOklch(
            lightness: oklchColor.l,
            chroma: oklchColor.c,
            hue: oklchColor.h,
            alpha: oklchColor.alpha,
          );

          _coordinator.saveState('Eyedropper picked color for background');

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Picked ${ClipboardService.colorToHex(color)} for background'),
              duration: const Duration(milliseconds: 100),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.black87,
            ),
          );
        }, null),
      );
    } catch (err) {
      debugPrint('EyeDrop capture error for background: $err');
    }
  }

  // Starts eyedropper tool for mixer extreme color selection
  //
  // Launches the eyedropper overlay to pick a color from screen,
  // then updates the specified extreme (left or right) and ColorEditor
  void _startEyedropperForExtreme(String extremeId, DragStartDetails details) {
    try {
      Future.delayed(
        const Duration(milliseconds: 50),
        () => EyeDrop.of(context).capture(context, (color) {
          final oklchColor = srgbToOklch(color);
          final extremes = context.read<ExtremeColorsProvider>();
          final colorEditor = context.read<ColorEditorProvider>();

          extremes.updateExtremeOklch(
            extremeId: extremeId,
            lightness: oklchColor.l,
            chroma: oklchColor.c,
            hue: oklchColor.h,
            alpha: oklchColor.alpha,
          );

          colorEditor.updateOklch(
            lightness: oklchColor.l,
            chroma: oklchColor.c,
            hue: oklchColor.h,
            alpha: oklchColor.alpha,
          );

          _coordinator.saveState('Eyedropper picked color for $extremeId extreme');

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Picked ${ClipboardService.colorToHex(color)} for extreme'),
              duration: const Duration(milliseconds: 100),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.black87,
            ),
          );
        }, null),
      );
    } catch (err) {
      debugPrint('EyeDrop capture error for extreme: $err');
    }
  }

  // Triggers undo operation via coordinator
  void _handleUndo() => _coordinator.undo();

  // Triggers redo operation via coordinator
  void _handleRedo() => _coordinator.redo();

  // Randomizes all colors in the grid
  //
  // Generates random OKLCH values for all existing grid items
  // while preserving names and selection state
  void _handleGenerateColors() {
    _coordinator.saveState('Randomize colors');
    context.read<ColorGridProvider>().randomizeAllColors();
  }

  // Handles toggle of "Real Pigments Only" setting
  //
  // When enabled, colors are filtered through ICC profile to simulate
  // printer gamut limitations (only colors achievable with real pigments)
  void _handleRealPigmentsOnlyChanged(bool value) {
    context.read<SettingsProvider>().setRealPigmentsOnly(value);
  }

  // ========== UI Helpers ==========

  // Shows a bottom sheet menu for a color item
  //
  // Displays item details (color swatch, name, hex code) and actions (delete)
  void _showColorItemMenu(ColorGridItem item) {
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
                _handleGridItemDelete(item);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ================================================
  // ========== Build & UI Rendering ================
  // ================================================
  //
  // Renders the complete home screen with a snapping bottom sheet UI.
  //
  // UI Hierarchy (bottom to top):
  // 1. Background (bgColor fills entire screen)
  // 2. SnappingSheet with grabbable handle containing:
  //    - Color grid (reorderable, drag-to-delete)
  //    - Real Pigments toggle
  //    - Home app bar
  //    - Delete zone overlay (appears during drag)
  // 3. Bottom sheet content (color picker controls/sliders)
  // 4. Bottom action bar (background color box, undo/redo, randomize, eyedropper)
  //
  // State Management:
  // - Watches all providers for reactive updates
  // - Uses ListenableBuilder for drag-drop controller updates
  // - UndoRedoShortcuts wrapper handles keyboard shortcuts

  @override
  Widget build(BuildContext context) {
    final bgColorProvider = context.watch<BgColorProvider>();
    final extremesProvider = context.watch<ExtremeColorsProvider>();
    final settingsProvider = context.watch<SettingsProvider>();
    final colorEditor = context.watch<ColorEditorProvider>();

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

    return ListenableBuilder(
      listenable: _dragDropController,
      builder: (context, _) => UndoRedoShortcuts(
        onUndo: _handleUndo,
        onRedo: _handleRedo,
        child: Scaffold(
          backgroundColor: bgColor,
        body: Stack(
          children: [
            SnappingSheet(
              controller: snappingSheetController,
              lockOverflowDrag: true,
              // Bottom sheet snap positions (height in pixels from bottom)
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

              grabbingHeight: 80,
              grabbing: SheetGrabbingHandle(
                chipStates: _selectedChips,
                onChipToggle: (index) => setState(() => _selectedChips[index] = !_selectedChips[index]),
                bgColor: bgColor,
              ),

              sheetBelow: SnappingSheetContent(
                draggable: (details) => !_isInteractingWithSlider,
                child: Column(
                  children: [
                    Expanded(
                      child: Container(
                        color: bgColor,
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                        child: ColorPickerControls(
                          onOklchChanged: _handleOklchChanged,
                          leftExtreme: leftExtreme,
                          rightExtreme: rightExtreme,
                          extremeColorFilter: (extreme) => _applyIccFilter(
                            extreme.color,
                            lightness: extreme.oklchValues.lightness,
                            chroma: extreme.oklchValues.chroma,
                            hue: extreme.oklchValues.hue,
                            alpha: extreme.oklchValues.alpha,
                          ),
                          gradientColorFilter: (color, l, c, h, a) => _applyIccFilter(
                            color,
                            lightness: l,
                            chroma: c,
                            hue: h,
                            alpha: a,
                          ),
                          onExtremeTap: _handleExtremeTap,
                          onMixerSliderTouched: _handleMixerSliderTouched,
                          onSliderInteractionChanged: (interacting) =>
                              setState(() => _isInteractingWithSlider = interacting),
                          useRealPigmentsOnly: useRealPigmentsOnly,
                          bgColor: bgColor,
                          onPanStartExtreme: _startEyedropperForExtreme,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              child: Listener(
                onPointerMove: (event) {
                  if (_dragDropController.isDragging) {
                    _dragDropController.onDragUpdate(event.position);
                  }
                },
                child: Stack(
                  children: [
                    Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              children: [
                                const SizedBox(height: 0),
                                RealPigmentsToggle(
                                  isEnabled: useRealPigmentsOnly,
                                  onChanged: _handleRealPigmentsOnlyChanged,
                                ),
                                const SizedBox(height: 70),
                                ReorderableColorGridView(
                                  onReorder: _handleGridReorder,
                                  onItemTap: _handleGridItemTap,
                                  onItemLongPress: _handleGridItemLongPress,
                                  onItemDelete: _handleGridItemDelete,
                                  onAddColor: _handleAddColor,
                                  onDragStarted: _dragDropController.onDragStarted,
                                  onDragEnded: _dragDropController.onDragEnded,
                                  crossAxisCount: 4,
                                  spacing: 12.0,
                                  itemSize: 80.0,
                                  showAddButton: true,
                                  emptyStateMessage: 'No colors in grid\nCreate a color above and tap + to add it',
                                  colorFilter: (item) => _applyIccFilter(
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

                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: HomeAppBar(bgColor: bgColor),
                    ),

                    Positioned(
                      top: 20,
                      left: 0,
                      right: 0,
                      child: DeleteZoneOverlay(
                        isDragging: _dragDropController.isDragging,
                        isInDeleteZone: _dragDropController.isInDeleteZone,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Positioned(
              bottom: 0,
              left: 20,
              right: 20,
              child: BottomActionBar(
                bgColor: bgColor,
                isBgColorSelected: isBgColorSelected,
                currentColor: colorEditor.currentColor,
                selectedExtremeId: selectedExtremeId,
                leftExtreme: leftExtreme,
                rightExtreme: rightExtreme,
                onBgColorBoxTap: _handleBgColorBoxTap,
                onBgColorPanStart: _startEyedropperForBgColor,
                onColorSelected: _handleColorSelection,
                undoRedoManager: _undoRedoService,
                onUndo: _handleUndo,
                onRedo: _handleRedo,
                onGenerateColors: _handleGenerateColors,
                colorFilter: _applyIccFilter,
                bgLightness: bgLightness,
                bgChroma: bgChroma,
                bgHue: bgHue,
                bgAlpha: bgAlpha,
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }
}
