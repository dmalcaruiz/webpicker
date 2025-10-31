🏗️ Palletator V2 - Complete Architecture Document
Ultra-Detailed State Management & Widget Architecture Focus: Minimal rebuilds, clean separation of concerns, scalable for 15+ filters
📋 Table of Contents
Architecture Philosophy
State Domain Breakdown
Data Models
Coordinator System
Widget Hierarchy
State Flow Diagrams
Color Pipeline
Grid Layout Engine
Undo/Redo System
Auto-Save Strategy
Development Phases
Complexity Estimates
🎯 Architecture Philosophy
Core Principles
Single Source of Truth: Each piece of data lives in exactly ONE domain state
Minimal Rebuilds: Only affected widgets rebuild when state changes
Clear Boundaries: Each domain has clear responsibilities, no overlap
Scalability: Architecture supports 15+ filters, 100+ boxes, complex interactions
Testability: Business logic separated from UI, fully testable
State Management Strategy
Using: Provider + ChangeNotifier + Coordinator Pattern
Provider: Dependency injection and widget rebuilding
ChangeNotifier: Observable state containers
Coordinators: Cross-domain orchestration logic
Why NOT Riverpod/BLoC?
Your app has moderate complexity, not enterprise-scale
Provider is simpler, faster to develop with
Can migrate to Riverpod later if needed
Less learning curve = faster shipping
🧩 State Domain Breakdown
Domain Map
┌─────────────────────────────────────────────────────────────────┐
│                      AppCoordinator                             │
│  (Orchestrates cross-domain logic, no state storage)           │
└─────────────────────────────────────────────────────────────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        │                     │                     │
        ↓                     ↓                     ↓
┌───────────────┐    ┌────────────────┐    ┌──────────────────┐
│   GridState   │    │ ColorEditor    │    │  FilterState     │
│               │    │     State      │    │                  │
│ • Boxes       │    │ • Current      │    │ • 15+ filters    │
│ • Layout      │    │   OKLCH        │    │ • Values         │
│ • Selection   │    │ • Edit mode    │    │ • Enabled        │
│ • Rows        │    │   (single/     │    │                  │
│ • Animation   │    │    multi)      │    │                  │
└───────────────┘    └────────────────┘    └──────────────────┘
        │                     │                     │
        ↓                     ↓                     ↓
┌───────────────┐    ┌────────────────┐    ┌──────────────────┐
│  MixerState   │    │  BgColorState  │    │ IccFilterService │
│               │    │                │    │                  │
│ • Left        │    │ • BgColor      │    │ • Profile        │
│ • Right       │    │ • Ambient      │    │ • Cache          │
│ • Mix mode    │    │   Color        │    │ • Toggle         │
└───────────────┘    └────────────────┘    └──────────────────┘
        │
        ↓
┌───────────────────────────────────────────────────────────────┐
│                    UndoRedoManager                             │
│  (Manages history across all domains)                         │
└───────────────────────────────────────────────────────────────┘
1️⃣ GridState (The Core Domain)
Responsibility: Manage boxes, layout, selection, rows, animations
class GridState extends ChangeNotifier {
  // ========== Box Data ==========
  List<ColorBox> _boxes = [];
  
  List<ColorBox> get boxes => List.unmodifiable(_boxes);
  int get totalBoxes => _boxes.where((b) => !b.isEmpty).length;
  int get totalEmptyBoxes => _boxes.where((b) => b.isEmpty).length;
  
  // ========== Layout Configuration ==========
  LayoutMode _layoutMode = LayoutMode.grid;
  AestheticMode _aestheticMode = AestheticMode.tile;
  int _rowCount = 4; // Number of horizontal rows (column items)
  
  LayoutMode get layoutMode => _layoutMode;
  AestheticMode get aestheticMode => _aestheticMode;
  int get rowCount => _rowCount;
  int get maxRowsAllowed => 10;
  int get minRowsAllowed => 1;
  
  // ========== Selection State ==========
  Set<String> _selectedBoxIds = {};
  
  Set<String> get selectedBoxIds => Set.unmodifiable(_selectedBoxIds);
  List<ColorBox> get selectedBoxes => 
      _boxes.where((b) => _selectedBoxIds.contains(b.id)).toList();
  bool get hasSelection => _selectedBoxIds.isNotEmpty;
  bool get isMultiSelect => _selectedBoxIds.length > 1;
  bool isBoxSelected(String id) => _selectedBoxIds.contains(id);
  
  // ========== Row Management ==========
  List<List<ColorBox>> get boxesByRow {
    // Returns boxes organized by row for rendering
    // Implementation depends on layout mode
  }
  
  int getMaxBoxesPerRow(double screenWidth) {
    // Calculate based on logical pixels
    // Standard phone: 4, tablet: 6-8, desktop: 10
  }
  
  // ========== Scroll/Animation State ==========
  bool _isRevealingRow = false;
  double _revealProgress = 0.0; // 0.0 to 1.0
  bool _isDeletingRow = false;
  double _deleteProgress = 0.0; // 0.0 to 1.0
  
  bool get isRevealingRow => _isRevealingRow;
  double get revealProgress => _revealProgress;
  bool get isDeletingRow => _isDeletingRow;
  double get deleteProgress => _deleteProgress;
  bool get canRevealRow => _rowCount < maxRowsAllowed;
  bool get canDeleteRow => _rowCount > minRowsAllowed;
  
  // ========== Operations ==========
  
  /// Add a new box
  void addBox({
    required OklchValues color,
    String? afterBoxId, // null = add at end
    bool select = true,
  }) {
    final box = ColorBox(
      id: _generateId(),
      localColor: color,
      isLocked: false,
      isEmpty: false,
    );
    
    if (afterBoxId != null) {
      final index = _boxes.indexWhere((b) => b.id == afterBoxId);
      _boxes.insert(index + 1, box);
    } else {
      _boxes.add(box);
    }
    
    if (select) {
      _selectedBoxIds = {box.id}; // Exclusive select
    }
    
    notifyListeners();
  }
  
  /// Remove box (convert to empty in Grid mode, delete in List/Custom)
  void removeBox(String boxId) {
    if (_layoutMode == LayoutMode.grid) {
      // Convert to empty
      final index = _boxes.indexWhere((b) => b.id == boxId);
      if (index != -1) {
        _boxes[index] = _boxes[index].copyWith(isEmpty: true);
      }
    } else {
      // Delete completely
      _boxes.removeWhere((b) => b.id == boxId);
    }
    
    _selectedBoxIds.remove(boxId);
    _cleanupEmptyRows();
    notifyListeners();
  }
  
  /// Update box color
  void updateBoxColor(String boxId, OklchValues newColor) {
    final index = _boxes.indexWhere((b) => b.id == boxId);
    if (index != -1) {
      _boxes[index] = _boxes[index].copyWith(localColor: newColor);
      notifyListeners();
    }
  }
  
  /// Toggle lock
  void toggleLock(String boxId) {
    final index = _boxes.indexWhere((b) => b.id == boxId);
    if (index != -1) {
      _boxes[index] = _boxes[index].copyWith(
        isLocked: !_boxes[index].isLocked,
      );
      notifyListeners();
    }
  }
  
  /// Select box (tap = exclusive, swipe = additive)
  void selectBox(String boxId, {bool exclusive = true}) {
    if (exclusive) {
      _selectedBoxIds = {boxId};
    } else {
      if (_selectedBoxIds.contains(boxId)) {
        _selectedBoxIds.remove(boxId); // Deselect
      } else {
        _selectedBoxIds.add(boxId); // Add to selection
      }
    }
    notifyListeners();
  }
  
  /// Deselect all
  void deselectAll() {
    _selectedBoxIds.clear();
    notifyListeners();
  }
  
  /// Reorder boxes
  void reorderBox(String boxId, int newIndex) {
    final oldIndex = _boxes.indexWhere((b) => b.id == boxId);
    if (oldIndex == -1) return;
    
    final box = _boxes.removeAt(oldIndex);
    _boxes.insert(newIndex, box);
    notifyListeners();
  }
  
  /// Change layout mode
  void setLayoutMode(LayoutMode mode) {
    if (_layoutMode == mode) return;
    _layoutMode = mode;
    _reorganizeBoxesForLayout();
    notifyListeners();
  }
  
  /// Change aesthetic mode
  void setAestheticMode(AestheticMode mode) {
    if (_aestheticMode == mode) return;
    _aestheticMode = mode;
    notifyListeners(); // Only visual rebuild, no data change
  }
  
  /// Reveal row (scroll down UX)
  void updateRevealProgress(double progress) {
    _revealProgress = progress.clamp(0.0, 1.0);
    _isRevealingRow = progress > 0.0;
    notifyListeners();
  }
  
  void commitRevealRow() {
    if (_revealProgress >= 0.7 && canRevealRow) {
      _rowCount++;
      _addNewRow();
    }
    _revealProgress = 0.0;
    _isRevealingRow = false;
    notifyListeners();
  }
  
  /// Delete row (scroll up UX)
  void updateDeleteProgress(double progress) {
    _deleteProgress = progress.clamp(0.0, 1.0);
    _isDeletingRow = progress > 0.0;
    notifyListeners();
  }
  
  void commitDeleteRow() {
    if (_deleteProgress >= 0.7 && canDeleteRow) {
      _removeFirstRow();
      _rowCount--;
    }
    _deleteProgress = 0.0;
    _isDeletingRow = false;
    notifyListeners();
  }
  
  /// Randomize unlocked boxes
  void randomizeUnlocked() {
    for (int i = 0; i < _boxes.length; i++) {
      if (!_boxes[i].isLocked && !_boxes[i].isEmpty) {
        _boxes[i] = _boxes[i].copyWith(
          localColor: OklchValues.random(),
        );
      }
    }
    notifyListeners();
  }
  
  // ========== Private Helpers ==========
  
  void _cleanupEmptyRows() {
    // Remove rows that are entirely empty
    final rows = boxesByRow;
    for (var row in rows) {
      if (row.every((box) => box.isEmpty)) {
        _boxes.removeWhere((b) => row.contains(b));
      }
    }
  }
  
  void _addNewRow() {
    // Add boxes for new row with random colors
    final boxesPerRow = getMaxBoxesPerRow(/* screen width */);
    for (int i = 0; i < boxesPerRow; i++) {
      _boxes.add(ColorBox(
        id: _generateId(),
        localColor: OklchValues.random(),
        isLocked: false,
        isEmpty: false,
      ));
    }
  }
  
  void _removeFirstRow() {
    final rows = boxesByRow;
    if (rows.isNotEmpty) {
      final firstRow = rows.first;
      _boxes.removeWhere((b) => firstRow.contains(b));
    }
  }
  
  void _reorganizeBoxesForLayout() {
    // Handle layout mode transitions
    // Grid → List: Keep only non-empty, max 10
    // List → Grid: Distribute across rows
    // etc.
  }
  
  String _generateId() => 'box_${DateTime.now().millisecondsSinceEpoch}_${_boxes.length}';
}
What triggers rebuilds:
Adding/removing boxes → Only grid rebuilds
Updating box colors → Only affected box rebuilds (via selector)
Selection changes → Only selection stroke rebuilds
Layout/aesthetic mode → Only grid rebuilds
Animation progress → Only animating widgets rebuild
2️⃣ ColorEditorState
Responsibility: Manage current OKLCH values being edited
class ColorEditorState extends ChangeNotifier {
  // ========== Current Editing Values ==========
  OklchValues? _currentOklch;
  EditMode _editMode = EditMode.single;
  
  OklchValues? get currentOklch => _currentOklch;
  Color? get currentColor => _currentOklch?.toColor();
  EditMode get editMode => _editMode;
  bool get isSingleEdit => _editMode == EditMode.single;
  bool get isMultiEdit => _editMode == EditMode.multi;
  
  // ========== Operations ==========
  
  /// Set OKLCH values (from box selection or external)
  void setOklch(OklchValues? values) {
    _currentOklch = values;
    notifyListeners();
  }
  
  /// Update specific component
  void updateLightness(double l) {
    if (_currentOklch == null) return;
    _currentOklch = _currentOklch!.copyWith(lightness: l);
    notifyListeners();
  }
  
  void updateChroma(double c) {
    if (_currentOklch == null) return;
    _currentOklch = _currentOklch!.copyWith(chroma: c);
    notifyListeners();
  }
  
  void updateHue(double h) {
    if (_currentOklch == null) return;
    _currentOklch = _currentOklch!.copyWith(hue: h);
    notifyListeners();
  }
  
  void updateAlpha(double a) {
    if (_currentOklch == null) return;
    _currentOklch = _currentOklch!.copyWith(alpha: a);
    notifyListeners();
  }
  
  /// Set edit mode
  void setEditMode(EditMode mode) {
    if (_editMode == mode) return;
    _editMode = mode;
    
    // When switching to multi-edit, reset to neutral position
    if (mode == EditMode.multi) {
      _currentOklch = OklchValues.neutral(); // L=0.5, C=0, H=0
    }
    
    notifyListeners();
  }
  
  /// Apply relative adjustment (for multi-edit)
  OklchValues applyRelativeAdjustment(OklchValues base, OklchValues delta) {
    return OklchValues(
      lightness: (base.lightness + delta.lightness).clamp(0.0, 1.0),
      chroma: (base.chroma + delta.chroma).clamp(0.0, 0.4),
      hue: (base.hue + delta.hue) % 360,
      alpha: (base.alpha + delta.alpha).clamp(0.0, 1.0),
    );
  }
}

enum EditMode { single, multi }
What triggers rebuilds:
OKLCH updates → Only sliders rebuild
Edit mode changes → Only sliders rebuild
Does NOT trigger grid rebuilds (coordinator handles that)
3️⃣ FilterState
Responsibility: Manage global filters applied to all boxes
class FilterState extends ChangeNotifier {
  // ========== Filter Values ==========
  Map<FilterType, double> _filterValues = {};
  Map<FilterType, bool> _filterEnabled = {};
  
  double getFilterValue(FilterType type) => _filterValues[type] ?? 0.0;
  bool isFilterEnabled(FilterType type) => _filterEnabled[type] ?? false;
  
  // ========== Operations ==========
  
  void setFilterValue(FilterType type, double value) {
    _filterValues[type] = value;
    notifyListeners(); // Rebuilds all boxes (expensive!)
  }
  
  void toggleFilter(FilterType type) {
    _filterEnabled[type] = !(_filterEnabled[type] ?? false);
    notifyListeners();
  }
  
  void resetAllFilters() {
    _filterValues.clear();
    _filterEnabled.clear();
    notifyListeners();
  }
  
  // ========== Filter Application ==========
  
  /// Apply all enabled filters to a color
  OklchValues applyFilters(OklchValues input) {
    var result = input;
    
    for (var entry in _filterValues.entries) {
      if (_filterEnabled[entry.key] ?? false) {
        result = _applyFilter(result, entry.key, entry.value);
      }
    }
    
    return result;
  }
  
  OklchValues _applyFilter(OklchValues input, FilterType type, double value) {
    switch (type) {
      case FilterType.warmth:
        return _applyWarmth(input, value);
      case FilterType.saturation:
        return input.copyWith(chroma: input.chroma * (1 + value));
      case FilterType.brightness:
        return input.copyWith(lightness: input.lightness * (1 + value));
      // ... 15+ more filters
      default:
        return input;
    }
  }
  
  OklchValues _applyWarmth(OklchValues input, double warmth) {
    // Shift hue toward warm (orange/yellow) or cool (blue)
    final hueShift = warmth * 30; // ±30° shift
    return input.copyWith(hue: (input.hue + hueShift) % 360);
  }
}

enum FilterType {
  warmth,
  saturation,
  brightness,
  contrast,
  vibrance,
  hueShift,
  // ... 15+ total
}
Optimization: Filter application is expensive! We'll add caching later.
4️⃣ MixerState
Responsibility: Manage mixer extremes and interpolation mode
class MixerState extends ChangeNotifier {
  // ========== Extremes ==========
  ExtremeColor _left = ExtremeColor.defaultLeft();
  ExtremeColor _right = ExtremeColor.defaultRight();
  MixingMode _mixingMode = MixingMode.oklch;
  
  ExtremeColor get left => _left;
  ExtremeColor get right => _right;
  MixingMode get mixingMode => _mixingMode;
  
  // ========== Operations ==========
  
  void setLeftColor(OklchValues color) {
    _left = _left.copyWith(color: color);
    notifyListeners();
  }
  
  void setRightColor(OklchValues color) {
    _right = _right.copyWith(color: color);
    notifyListeners();
  }
  
  void setMixingMode(MixingMode mode) {
    _mixingMode = mode;
    notifyListeners(); // Rebuilds mixer gradient
  }
  
  /// Interpolate between extremes
  OklchValues interpolate(double t) {
    if (_mixingMode == MixingMode.oklch) {
      return OklchValues.lerp(_left.color, _right.color, t);
    } else {
      // Mixbox pigment mixing
      return _mixboxInterpolate(_left.color, _right.color, t);
    }
  }
  
  OklchValues _mixboxInterpolate(OklchValues a, OklchValues b, double t) {
    // Use Kubelka-Munk via Mixbox LUT
    // (Keep reference implementation from v1)
  }
}

class ExtremeColor {
  final OklchValues color;
  
  ExtremeColor({required this.color});
  
  ExtremeColor copyWith({OklchValues? color}) {
    return ExtremeColor(color: color ?? this.color);
  }
  
  static ExtremeColor defaultLeft() => ExtremeColor(
    color: OklchValues(lightness: 0.5, chroma: 0.0, hue: 0.0),
  );
  
  static ExtremeColor defaultRight() => ExtremeColor(
    color: OklchValues(lightness: 1.0, chroma: 0.0, hue: 0.0),
  );
}

enum MixingMode { oklch, pigment }
5️⃣ BgColorState
Responsibility: Manage background and ambient colors
class BgColorState extends ChangeNotifier {
  // ========== Colors ==========
  OklchValues _bgColor = OklchValues(lightness: 0.15, chroma: 0.0, hue: 0.0);
  OklchValues _ambientColor = OklchValues(lightness: 0.5, chroma: 0.0, hue: 0.0);
  
  OklchValues get bgColor => _bgColor;
  Color get bgColorRgb => _bgColor.toColor();
  OklchValues get ambientColor => _ambientColor;
  
  // ========== Operations ==========
  
  void setBgColor(OklchValues color) {
    _bgColor = color;
    notifyListeners(); // Rebuilds entire app bg + all boxes (expensive!)
  }
  
  void setAmbientColor(OklchValues color) {
    _ambientColor = color;
    notifyListeners(); // Rebuilds all boxes for shadow recalc
  }
}
Performance Note: These rebuilds are expensive! Consider debouncing.
6️⃣ IccFilterService (Singleton)
Responsibility: ICC profile filtering with caching
class IccFilterService extends ChangeNotifier {
  static final IccFilterService instance = IccFilterService._();
  IccFilterService._();
  
  // ========== State ==========
  bool _isEnabled = false;
  bool _isReady = false;
  
  // Cache: "L_C_H_A" → filtered OklchValues
  final Map<String, OklchValues> _cache = {};
  
  bool get isEnabled => _isEnabled;
  bool get isReady => _isReady;
  
  // ========== Operations ==========
  
  Future<void> initialize(Uint8List iccProfileBytes) async {
    // Same as v1 - load and parse ICC profile
    _isReady = true;
    notifyListeners();
  }
  
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
    if (!enabled) _cache.clear(); // Clear cache when disabled
    notifyListeners(); // Rebuilds all boxes
  }
  
  /// Apply ICC filter with caching
  OklchValues applyFilter(OklchValues input) {
    if (!_isEnabled || !_isReady) return input;
    
    final key = _cacheKey(input);
    if (_cache.containsKey(key)) {
      return _cache[key]!;
    }
    
    // Expensive ICC transform
    final filtered = _transform(input);
    _cache[key] = filtered;
    
    return filtered;
  }
  
  OklchValues _transform(OklchValues input) {
    // OKLCH → CIE Lab → ICC Transform → CIE Lab → OKLCH
    // (Keep reference implementation from v1)
  }
  
  String _cacheKey(OklchValues v) {
    return '${v.lightness.toStringAsFixed(4)}_'
           '${v.chroma.toStringAsFixed(4)}_'
           '${v.hue.toStringAsFixed(4)}_'
           '${v.alpha.toStringAsFixed(4)}';
  }
  
  void clearCache() {
    _cache.clear();
  }
}
Cache Performance: Transforms 10 ICC operations → 1-2 operations during animations.
7️⃣ UndoRedoManager
Responsibility: Manage history across all domains
class UndoRedoManager extends ChangeNotifier {
  // ========== Stacks ==========
  final List<AppSnapshot> _undoStack = [];
  final List<AppSnapshot> _redoStack = [];
  AppSnapshot? _currentSnapshot;
  
  final int maxHistorySize;
  
  UndoRedoManager({this.maxHistorySize = 50});
  
  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;
  
  // ========== Operations ==========
  
  void pushSnapshot(AppSnapshot snapshot) {
    if (_currentSnapshot != null) {
      _undoStack.add(_currentSnapshot!);
      if (_undoStack.length > maxHistorySize) {
        _undoStack.removeAt(0);
      }
    }
    
    _currentSnapshot = snapshot;
    _redoStack.clear(); // Clear redo on new action
    notifyListeners();
  }
  
  AppSnapshot? undo() {
    if (!canUndo) return null;
    
    final previous = _undoStack.removeLast();
    _redoStack.add(_currentSnapshot!);
    _currentSnapshot = previous;
    
    notifyListeners();
    return previous;
  }
  
  AppSnapshot? redo() {
    if (!canRedo) return null;
    
    final next = _redoStack.removeLast();
    _undoStack.add(_currentSnapshot!);
    _currentSnapshot = next;
    
    notifyListeners();
    return next;
  }
  
  void clear() {
    _undoStack.clear();
    _redoStack.clear();
    _currentSnapshot = null;
    notifyListeners();
  }
}
🎭 AppCoordinator (The Orchestra Conductor)
Responsibility: Cross-domain orchestration, NO state storage
class AppCoordinator {
  // ========== Domain References ==========
  final GridState gridState;
  final ColorEditorState editorState;
  final FilterState filterState;
  final MixerState mixerState;
  final BgColorState bgColorState;
  final IccFilterService iccService;
  final UndoRedoManager undoRedo;
  
  AppCoordinator({
    required this.gridState,
    required this.editorState,
    required this.filterState,
    required this.mixerState,
    required this.bgColorState,
    required this.iccService,
    required this.undoRedo,
  }) {
    _setupListeners();
  }
  
  // ========== Cross-Domain Operations ==========
  
  /// User taps a box (exclusive select)
  void onBoxTapped(String boxId) {
    // 1. Select box in grid
    gridState.selectBox(boxId, exclusive: true);
    
    // 2. Load box color into editor
    final box = gridState.boxes.firstWhere((b) => b.id == boxId);
    editorState.setOklch(box.localColor);
    editorState.setEditMode(EditMode.single);
    
    // No snapshot - selections aren't tracked in undo
  }
  
  /// User swipes a box (multi-select)
  void onBoxSwiped(String boxId) {
    // 1. Toggle selection (additive)
    gridState.selectBox(boxId, exclusive: false);
    
    // 2. Set multi-edit mode
    if (gridState.isMultiSelect) {
      editorState.setEditMode(EditMode.multi);
      editorState.setOklch(OklchValues.neutral());
    } else if (gridState.hasSelection) {
      // Back to single selection
      final box = gridState.selectedBoxes.first;
      editorState.setEditMode(EditMode.single);
      editorState.setOklch(box.localColor);
    }
  }
  
  /// User adjusts slider
  void onSliderChanged(OklchValues newValues) {
    if (editorState.isSingleEdit && gridState.hasSelection) {
      // Single edit: Set absolute value
      final boxId = gridState.selectedBoxIds.first;
      gridState.updateBoxColor(boxId, newValues);
      _saveSnapshot('Modified color');
      
    } else if (editorState.isMultiEdit) {
      // Multi edit: Apply relative adjustment
      final delta = newValues; // Editor shows neutral, this is the delta
      
      for (var boxId in gridState.selectedBoxIds) {
        final box = gridState.boxes.firstWhere((b) => b.id == boxId);
        final adjusted = editorState.applyRelativeAdjustment(
          box.localColor,
          delta,
        );
        gridState.updateBoxColor(boxId, adjusted);
      }
      _saveSnapshot('Modified ${gridState.selectedBoxIds.length} colors');
    }
  }
  
  /// User presses plus button on a box
  void onPlusPressed(String boxId) {
    final layoutMode = gridState.layoutMode;
    
    if (layoutMode == LayoutMode.list) {
      // Add below current box
      gridState.addBox(
        color: OklchValues.random(),
        afterBoxId: boxId,
      );
    } else {
      // Add to right (or new row if full)
      gridState.addBox(
        color: OklchValues.random(),
        afterBoxId: boxId,
      );
    }
    
    _saveSnapshot('Added box');
  }
  
  /// User presses minus button on a box
  void onMinusPressed(String boxId) {
    gridState.removeBox(boxId);
    _saveSnapshot('Removed box');
  }
  
  /// User drags box to delete zone
  void onBoxDraggedToDeleteZone(String boxId) {
    gridState.removeBox(boxId);
    _saveSnapshot('Deleted box via drag');
  }
  
  /// User reorders boxes
  void onBoxReordered(String boxId, int newIndex) {
    gridState.reorderBox(boxId, newIndex);
    _saveSnapshot('Reordered boxes');
  }
  
  /// User toggles lock
  void onLockToggled(String boxId) {
    gridState.toggleLock(boxId);
    _saveSnapshot('Toggled lock');
  }
  
  /// User presses generate button
  void onGeneratePressed() {
    gridState.randomizeUnlocked();
    _saveSnapshot('Generated random colors');
  }
  
  /// User adjusts filter
  void onFilterChanged(FilterType type, double value) {
    filterState.setFilterValue(type, value);
    _saveSnapshot('Adjusted ${type.name} filter');
  }
  
  /// User changes layout mode (NOT undoable)
  void onLayoutModeChanged(LayoutMode mode) {
    gridState.setLayoutMode(mode);
    // No snapshot
  }
  
  /// User changes aesthetic mode (NOT undoable)
  void onAestheticModeChanged(AestheticMode mode) {
    gridState.setAestheticMode(mode);
    // No snapshot
  }
  
  /// User reveals new row (scroll down)
  void onRevealRowCommitted() {
    gridState.commitRevealRow();
    _saveSnapshot('Added row');
  }
  
  /// User deletes row (scroll up)
  void onDeleteRowCommitted() {
    gridState.commitDeleteRow();
    _saveSnapshot('Deleted row');
  }
  
  /// User uses eyedropper
  void onEyedropperColor(Color pickedColor) {
    final oklch = OklchValues.fromColor(pickedColor);
    
    if (gridState.hasSelection) {
      // Apply to selected box(es)
      for (var boxId in gridState.selectedBoxIds) {
        gridState.updateBoxColor(boxId, oklch);
      }
      editorState.setOklch(oklch);
      _saveSnapshot('Eyedropper picked color');
    }
  }
  
  /// User picks color for mixer extreme
  void onMixerExtremeColorChanged(bool isLeft, OklchValues color) {
    if (isLeft) {
      mixerState.setLeftColor(color);
    } else {
      mixerState.setRightColor(color);
    }
    _saveSnapshot('Modified ${isLeft ? 'left' : 'right'} extreme');
  }
  
  /// User changes background color
  void onBgColorChanged(OklchValues color) {
    bgColorState.setBgColor(color);
    _saveSnapshot('Changed background color');
  }
  
  /// User changes ambient color
  void onAmbientColorChanged(OklchValues color) {
    bgColorState.setAmbientColor(color);
    _saveSnapshot('Changed ambient color');
  }
  
  /// User triggers undo
  void onUndo() {
    final snapshot = undoRedo.undo();
    if (snapshot != null) {
      _restoreSnapshot(snapshot);
    }
  }
  
  /// User triggers redo
  void onRedo() {
    final snapshot = undoRedo.redo();
    if (snapshot != null) {
      _restoreSnapshot(snapshot);
    }
  }
  
  // ========== Snapshot Management ==========
  
  void _saveSnapshot(String description) {
    final snapshot = AppSnapshot(
      boxes: gridState.boxes,
      rowCount: gridState.rowCount,
      layoutMode: gridState.layoutMode,
      filters: filterState._filterValues,
      mixerLeft: mixerState.left.color,
      mixerRight: mixerState.right.color,
      bgColor: bgColorState.bgColor,
      ambientColor: bgColorState.ambientColor,
      iccEnabled: iccService.isEnabled,
      timestamp: DateTime.now(),
      description: description,
    );
    
    undoRedo.pushSnapshot(snapshot);
    _triggerAutoSave();
  }
  
  void _restoreSnapshot(AppSnapshot snapshot) {
    // Restore all domain states
    gridState._boxes = List.from(snapshot.boxes);
    gridState._rowCount = snapshot.rowCount;
    // ... restore all other values
    
    // Notify all domains
    gridState.notifyListeners();
    filterState.notifyListeners();
    mixerState.notifyListeners();
    bgColorState.notifyListeners();
  }
  
  void _setupListeners() {
    // Listen for domain changes that affect other domains
    // (Advanced: auto-coordinate without explicit methods)
  }
  
  void _triggerAutoSave() {
    // Debounced auto-save to local storage
  }
}
📦 Data Models
ColorBox
class ColorBox {
  final String id;
  final OklchValues localColor;
  final bool isLocked;
  final bool isEmpty;
  
  ColorBox({
    required this.id,
    required this.localColor,
    required this.isLocked,
    required this.isEmpty,
  });
  
  ColorBox copyWith({
    String? id,
    OklchValues? localColor,
    bool? isLocked,
    bool? isEmpty,
  }) {
    return ColorBox(
      id: id ?? this.id,
      localColor: localColor ?? this.localColor,
      isLocked: isLocked ?? this.isLocked,
      isEmpty: isEmpty ?? this.isEmpty,
    );
  }
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'localColor': localColor.toJson(),
    'isLocked': isLocked,
    'isEmpty': isEmpty,
  };
  
  factory ColorBox.fromJson(Map<String, dynamic> json) => ColorBox(
    id: json['id'],
    localColor: OklchValues.fromJson(json['localColor']),
    isLocked: json['isLocked'],
    isEmpty: json['isEmpty'],
  );
}
OklchValues
class OklchValues {
  final double lightness; // 0.0 to 1.0
  final double chroma;    // 0.0 to ~0.4
  final double hue;       // 0.0 to 360.0
  final double alpha;     // 0.0 to 1.0
  
  OklchValues({
    required this.lightness,
    required this.chroma,
    required this.hue,
    this.alpha = 1.0,
  });
  
  OklchValues copyWith({
    double? lightness,
    double? chroma,
    double? hue,
    double? alpha,
  }) {
    return OklchValues(
      lightness: lightness ?? this.lightness,
      chroma: chroma ?? this.chroma,
      hue: hue ?? this.hue,
      alpha: alpha ?? this.alpha,
    );
  }
  
  Color toColor() {
    // Use v1's colorFromOklch implementation
  }
  
  factory OklchValues.fromColor(Color color) {
    // Use v1's srgbToOklch implementation
  }
  
  static OklchValues neutral() => OklchValues(
    lightness: 0.5,
    chroma: 0.0,
    hue: 0.0,
  );
  
  static OklchValues random() => OklchValues(
    lightness: Random().nextDouble(),
    chroma: Random().nextDouble() * 0.3,
    hue: Random().nextDouble() * 360,
  );
  
  static OklchValues lerp(OklchValues a, OklchValues b, double t) {
    // Perceptually uniform interpolation
    // (Use v1's lerpOklch implementation)
  }
  
  Map<String, dynamic> toJson() => {
    'l': lightness,
    'c': chroma,
    'h': hue,
    'a': alpha,
  };
  
  factory OklchValues.fromJson(Map<String, dynamic> json) => OklchValues(
    lightness: json['l'],
    chroma: json['c'],
    hue: json['h'],
    alpha: json['a'] ?? 1.0,
  );
}
AppSnapshot (for undo/redo)
class AppSnapshot {
  final List<ColorBox> boxes;
  final int rowCount;
  final LayoutMode layoutMode;
  final Map<FilterType, double> filters;
  final OklchValues mixerLeft;
  final OklchValues mixerRight;
  final OklchValues bgColor;
  final OklchValues ambientColor;
  final bool iccEnabled;
  final DateTime timestamp;
  final String description;
  
  AppSnapshot({
    required this.boxes,
    required this.rowCount,
    required this.layoutMode,
    required this.filters,
    required this.mixerLeft,
    required this.mixerRight,
    required this.bgColor,
    required this.ambientColor,
    required this.iccEnabled,
    required this.timestamp,
    required this.description,
  });
  
  Map<String, dynamic> toJson() => {
    'boxes': boxes.map((b) => b.toJson()).toList(),
    'rowCount': rowCount,
    'layoutMode': layoutMode.name,
    'filters': filters.map((k, v) => MapEntry(k.name, v)),
    'mixerLeft': mixerLeft.toJson(),
    'mixerRight': mixerRight.toJson(),
    'bgColor': bgColor.toJson(),
    'ambientColor': ambientColor.toJson(),
    'iccEnabled': iccEnabled,
    'timestamp': timestamp.toIso8601String(),
    'description': description,
  };
  
  factory AppSnapshot.fromJson(Map<String, dynamic> json) {
    // Parse JSON back to AppSnapshot
  }
}
Enums
enum LayoutMode { list, grid, custom }
enum AestheticMode { tile, flat }
🎨 Color Pipeline
The complete color processing pipeline:
User's Local Color (OklchValues)
         ↓
[STEP 1: ICC Profile Filter]
   if (iccEnabled && iccReady)
     → Transform via ICC → OklchValues
         ↓
[STEP 2: Global Filters]
   for each enabled filter:
     → Apply filter transform → OklchValues
         ↓
[STEP 3: Visual Calculations]
   • Top squircle color (darker lightness)
   • Stroke color (mix local + bg + ambient)
   • Shadow color (same calculation)
         ↓
[STEP 4: Convert to Display Color]
   → OklchValues.toColor() → Color (sRGB)
         ↓
   Paint on screen
Implemented as:
class ColorPipeline {
  final IccFilterService iccService;
  final FilterState filterState;
  final BgColorState bgColorState;
  
  ColorPipeline({
    required this.iccService,
    required this.filterState,
    required this.bgColorState,
  });
  
  /// Full pipeline for a box
  ProcessedBoxColors processBox(ColorBox box) {
    // Step 1: ICC
    var color = iccService.applyFilter(box.localColor);
    
    // Step 2: Global filters
    color = filterState.applyFilters(color);
    
    // Step 3: Visual calculations
    final topColor = _calculateTopColor(color);
    final strokeColor = _calculateStroke(color);
    final shadowColor = _calculateShadow(color);
    
    return ProcessedBoxColors(
      mainColor: color.toColor(),
      topColor: topColor.toColor(),
      strokeColor: strokeColor.toColor(),
      shadowColor: shadowColor.toColor(),
    );
  }
  
  OklchValues _calculateTopColor(OklchValues base) {
    // Darker version for 3D effect
    return base.copyWith(
      lightness: (base.lightness * 0.7).clamp(0.0, 1.0),
    );
  }
  
  OklchValues _calculateStroke(OklchValues localColor) {
    // Mix: 50% local + 30% bg + 20% ambient
    final bg = bgColorState.bgColor;
    final ambient = bgColorState.ambientColor;
    
    return OklchValues(
      lightness: localColor.lightness * 0.5 + bg.lightness * 0.3 + ambient.lightness * 0.2,
      chroma: localColor.chroma * 0.5 + bg.chroma * 0.3 + ambient.chroma * 0.2,
      hue: localColor.hue, // Keep local hue dominant
    );
  }
  
  OklchValues _calculateShadow(OklchValues localColor) {
    // Similar to stroke but darker
    return _calculateStroke(localColor).copyWith(
      lightness: _calculateStroke(localColor).lightness * 0.5,
    );
  }
}

class ProcessedBoxColors {
  final Color mainColor;
  final Color topColor;
  final Color strokeColor;
  final Color shadowColor;
  
  ProcessedBoxColors({
    required this.mainColor,
    required this.topColor,
    required this.strokeColor,
    required this.shadowColor,
  });
}
🏗️ Widget Hierarchy
MaterialApp
└─ MultiProvider (provides all domain states)
   └─ HomeScreen (thin coordinator UI, ~300 lines)
      └─ Scaffold
         ├─ backgroundColor: bgColorState.bgColorRgb
         │
         └─ Stack
            ├─ [1] AppBar (top overlay)
            │
            ├─ [2] ColorGridView (main content)
            │   └─ Consumer<GridState> (only rebuilds when grid changes)
            │      └─ LayoutBuilder
            │         └─ switch (gridState.layoutMode)
            │            ├─ ListLayoutGrid
            │            ├─ GridLayoutGrid
            │            └─ CustomLayoutGrid
            │               └─ Column (rows)
            │                  └─ Row (boxes per row)
            │                     └─ ColorBoxWidget
            │                        ├─ Consumer2<GridState, BgColorState>
            │                        │  (only this box rebuilds when selected)
            │                        │
            │                        └─ Slideable (flutter_slideable)
            │                           └─ GestureDetector
            │                              ├─ onTap: coordinator.onBoxTapped
            │                              ├─ onLongPress: eyedropper
            │                              └─ LongPressDraggable
            │                                 ├─ feedback: scaled box
            │                                 └─ onDragEnd: check delete zone
            │                                    │
            │                                    └─ Stack (visual layers)
            │                                       ├─ Base squircle (main color)
            │                                       ├─ Top squircle (darker)
            │                                       ├─ Highlight SVG
            │                                       ├─ Lock icon
            │                                       ├─ Selection stroke
            │                                       └─ Plus/minus buttons
            │
            ├─ [3] DragDeleteZone (top overlay, fades in when dragging)
            │   └─ Consumer<GridState>
            │      (only rebuilds when _draggingItem changes)
            │
            ├─ [4] SnappingSheet (bottom sheet)
            │   ├─ controller: SnappingSheetController
            │   ├─ onSheetMoved: (height) → updates grid available space
            │   │
            │   ├─ grabbingHeight: 80
            │   ├─ grabbing: SheetHandle
            │   │   └─ SheetModeChips (Color / Filters / Settings)
            │   │
            │   └─ sheetBelow: switch (currentSheetMode)
            │      ├─ ColorSheet (OKLCH sliders + mixer)
            │      │  └─ Consumer2<ColorEditorState, MixerState>
            │      │     └─ Column
            │      │        ├─ MixerSlider
            │      │        ├─ LightnessSlider
            │      │        ├─ ChromaSlider
            │      │        ├─ HueSlider
            │      │        └─ AlphaSlider
            │      │
            │      ├─ FilterSheet (15+ filter sliders)
            │      │  └─ Consumer<FilterState>
            │      │     └─ ListView (filter sliders)
            │      │
            │      └─ SettingsSheet
            │         └─ Column
            │            ├─ Layout mode picker
            │            ├─ Aesthetic mode picker
            │            ├─ ICC toggle
            │            └─ Generate button
            │
            └─ [5] ActionBar (bottom overlay)
               └─ Row
                  ├─ BgColorButton
                  │  └─ Consumer<BgColorState>
                  ├─ EyedropperButton
                  ├─ UndoButton
                  │  └─ Consumer<UndoRedoManager>
                  ├─ RedoButton
                  │  └─ Consumer<UndoRedoManager>
                  └─ CopyButton
🔄 State Flow Diagrams
1. Single Box Selection Flow
User taps Box #3
      ↓
GestureDetector.onTap
      ↓
coordinator.onBoxTapped('box_3')
      ↓
   ┌──────────────────────────────┐
   │ gridState.selectBox('box_3', │
   │   exclusive: true)            │
   │ ↓                             │
   │ _selectedBoxIds = {'box_3'}  │
   │ notifyListeners()            │
   └──────────────────────────────┘
      ↓
   Consumer<GridState> rebuilds
      ↓
   Only Box #3's selection stroke appears
   (Other boxes don't rebuild!)
      ↓
   ┌──────────────────────────────┐
   │ editorState.setOklch(        │
   │   box3.localColor)            │
   │ editorState.setEditMode(     │
   │   EditMode.single)            │
   │ ↓                             │
   │ notifyListeners()            │
   └──────────────────────────────┘
      ↓
   Consumer<ColorEditorState> rebuilds
      ↓
   Sliders update to show Box #3's OKLCH values
   (Grid doesn't rebuild!)
Key: GridState and EditorState are independent. Only affected widgets rebuild.
2. Multi-Select + Slider Adjustment Flow
User swipes Box #3
      ↓
Slideable gesture detected
      ↓
coordinator.onBoxSwiped('box_3')
      ↓
   ┌──────────────────────────────┐
   │ gridState.selectBox('box_3', │
   │   exclusive: false)           │
   │ ↓                             │
   │ _selectedBoxIds.add('box_3') │
   │ (Already has box_1, box_2)   │
   │ ↓                             │
   │ _selectedBoxIds = {          │
   │   'box_1', 'box_2', 'box_3'  │
   │ }                             │
   │ notifyListeners()            │
   └──────────────────────────────┘
      ↓
   Consumer<GridState> rebuilds
      ↓
   Selection strokes appear on 3 boxes
      ↓
   ┌──────────────────────────────┐
   │ editorState.setEditMode(     │
   │   EditMode.multi)             │
   │ editorState.setOklch(        │
   │   OklchValues.neutral())      │
   │ ↓                             │
   │ notifyListeners()            │
   └──────────────────────────────┘
      ↓
   Consumer<ColorEditorState> rebuilds
      ↓
   Sliders reset to neutral position (L=0.5, C=0, H=0)
      ↓
   ╔════════════════════════════╗
   ║ User drags Lightness to +0.2║
   ╚════════════════════════════╝
      ↓
coordinator.onSliderChanged(
  OklchValues(l: 0.7, c: 0, h: 0)
)
      ↓
   ┌──────────────────────────────┐
   │ for each selected box:        │
   │   current = box.localColor    │
   │   adjusted = current + delta  │
   │   ↓                           │
   │   Box 1: L=0.3 → L=0.5       │
   │   Box 2: L=0.6 → L=0.8       │
   │   Box 3: L=0.4 → L=0.6       │
   │   ↓                           │
   │   gridState.updateBoxColor()  │
   │ notifyListeners()            │
   └──────────────────────────────┘
      ↓
   Consumer<GridState> rebuilds
      ↓
   Only 3 selected boxes re-render with new colors
   (Unselected boxes don't rebuild!)
      ↓
   ┌──────────────────────────────┐
   │ undoRedo.pushSnapshot(       │
   │   'Modified 3 colors')        │
   └──────────────────────────────┘
Key: Multi-edit applies deltas, not absolute values. Each box gets individual adjustment.
3. Global Filter Adjustment Flow
User adjusts Warmth filter slider
      ↓
coordinator.onFilterChanged(
  FilterType.warmth, 0.5
)
      ↓
   ┌──────────────────────────────┐
   │ filterState.setFilterValue(  │
   │   warmth, 0.5)                │
   │ ↓                             │
   │ _filterValues[warmth] = 0.5  │
   │ notifyListeners()            │
   └──────────────────────────────┘
      ↓
   Consumer<FilterState> rebuilds
   (This is EVERY ColorBoxWidget!)
      ↓
   ╔════════════════════════════╗
   ║ Each box runs color pipeline:║
   ║                            ║
   ║ localColor                 ║
   ║   → iccFilter              ║
   ║   → globalFilters (NEW!)   ║
   ║   → display color          ║
   ╚════════════════════════════╝
      ↓
   ALL boxes re-render with warmer hues
      ↓
   ┌──────────────────────────────┐
   │ undoRedo.pushSnapshot(       │
   │   'Adjusted warmth filter')   │
   └──────────────────────────────┘
Performance Note: This rebuilds EVERY box! With 40 boxes on screen, this is 40 color pipeline runs. Needs optimization (debouncing, caching).
4. Row Reveal Scroll Flow
User scrolls down past bottom
      ↓
ScrollController detects overscroll
      ↓
gridState.updateRevealProgress(0.3)
      ↓
   ┌──────────────────────────────┐
   │ _revealProgress = 0.3        │
   │ _isRevealingRow = true       │
   │ notifyListeners()            │
   └──────────────────────────────┘
      ↓
   Consumer<GridState> rebuilds
      ↓
   ╔════════════════════════════╗
   ║ Animated changes:          ║
   ║                            ║
   ║ Current row height:        ║
   ║   100% / 4 rows            ║
   ║   → 100% / 4.3 rows        ║
   ║                            ║
   ║ New row opacity:           ║
   ║   0% → 30%                 ║
   ╚════════════════════════════╝
      ↓
   User continues scrolling...
      ↓
gridState.updateRevealProgress(0.8)
      ↓
   Row height: 100% / 4.8 rows
   New row opacity: 80%
      ↓
   ╔════════════════════════════╗
   ║ User releases finger!      ║
   ╚════════════════════════════╝
      ↓
coordinator.onRevealRowCommitted()
      ↓
   ┌──────────────────────────────┐
   │ if (progress >= 0.7):        │
   │   gridState.commitRevealRow()│
   │   ↓                           │
   │   _rowCount++                │
   │   _addNewRow()               │
   │   (Adds 4 new colored boxes) │
   │   ↓                           │
   │   _revealProgress = 0        │
   │   _isRevealingRow = false    │
   │   notifyListeners()          │
   └──────────────────────────────┘
      ↓
   Consumer<GridState> rebuilds
      ↓
   Grid animates to 5 rows (smooth!)
      ↓
   ┌──────────────────────────────┐
   │ undoRedo.pushSnapshot(       │
   │   'Added row')                │
   └──────────────────────────────┘
Cancel flow: If user scrolls back up before release (progress < 0.7), animation reverses and commit is cancelled.
🎨 Grid Layout Engine
Responsive Box Sizing
class GridLayoutCalculator {
  /// Calculate how many boxes fit per row based on screen width
  static int calculateMaxBoxesPerRow(double screenWidth) {
    const minBoxSize = 60.0;  // Minimum logical pixels
    const maxBoxSize = 120.0; // Maximum logical pixels
    const spacing = 12.0;
    
    if (screenWidth < 400) {
      return 4; // Phone portrait
    } else if (screenWidth < 600) {
      return 5; // Large phone / small tablet
    } else if (screenWidth < 900) {
      return 6; // Tablet portrait
    } else {
      return 10; // Tablet landscape / desktop
    }
  }
  
  /// Calculate box size given available space and number of boxes
  static double calculateBoxSize({
    required double availableWidth,
    required int boxesPerRow,
    required double spacing,
  }) {
    final totalSpacing = spacing * (boxesPerRow - 1);
    final availableForBoxes = availableWidth - totalSpacing - 40; // 40 = padding
    return (availableForBoxes / boxesPerRow).clamp(60.0, 120.0);
  }
  
  /// Calculate spacing based on available space
  static double calculateSpacing(double availableWidth) {
    if (availableWidth < 400) {
      return 8.0;  // Tight spacing on small screens
    } else if (availableWidth < 600) {
      return 12.0;
    } else {
      return 16.0; // Generous spacing on large screens
    }
  }
  
  /// Organize boxes into rows for Grid mode
  static List<List<ColorBox>> organizeGridLayout({
    required List<ColorBox> boxes,
    required int maxBoxesPerRow,
    required int totalRows,
  }) {
    final rows = <List<ColorBox>>[];
    
    for (int row = 0; row < totalRows; row++) {
      final startIndex = row * maxBoxesPerRow;
      final endIndex = (startIndex + maxBoxesPerRow).clamp(0, boxes.length);
      
      if (startIndex < boxes.length) {
        final rowBoxes = boxes.sublist(startIndex, endIndex);
        
        // Pad with empty boxes if needed
        while (rowBoxes.length < maxBoxesPerRow) {
          rowBoxes.add(ColorBox.empty());
        }
        
        rows.add(rowBoxes);
      }
    }
    
    return rows;
  }
  
  /// Organize boxes into rows for Custom mode
  static List<List<ColorBox>> organizeCustomLayout({
    required List<ColorBox> boxes,
    required Map<int, int> rowBoxCounts, // row index → box count
  }) {
    final rows = <List<ColorBox>>[];
    int boxIndex = 0;
    
    for (var entry in rowBoxCounts.entries) {
      final boxCount = entry.value;
      final rowBoxes = <ColorBox>[];
      
      for (int i = 0; i < boxCount && boxIndex < boxes.length; i++) {
        rowBoxes.add(boxes[boxIndex++]);
      }
      
      rows.add(rowBoxes);
    }
    
    return rows;
  }
}
💾 Auto-Save Strategy
Local Persistence
class AutoSaveService {
  static const _debounceDelay = Duration(seconds: 2);
  Timer? _debounceTimer;
  
  final SharedPreferences prefs;
  
  AutoSaveService(this.prefs);
  
  /// Debounced save - called after every state change
  void scheduleSave(AppSnapshot snapshot) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDelay, () {
      _saveSnapshot(snapshot);
    });
  }
  
  Future<void> _saveSnapshot(AppSnapshot snapshot) async {
    final json = snapshot.toJson();
    final jsonString = jsonEncode(json);
    
    await prefs.setString('app_state', jsonString);
    await prefs.setInt('last_save_time', DateTime.now().millisecondsSinceEpoch);
    
    debugPrint('✓ Auto-saved at ${DateTime.now()}');
  }
  
  Future<AppSnapshot?> loadSnapshot() async {
    final jsonString = prefs.getString('app_state');
    if (jsonString == null) return null;
    
    try {
      final json = jsonDecode(jsonString);
      return AppSnapshot.fromJson(json);
    } catch (e) {
      debugPrint('⚠ Failed to load snapshot: $e');
      return null;
    }
  }
  
  Future<void> clearSave() async {
    await prefs.remove('app_state');
    await prefs.remove('last_save_time');
  }
}
Integration with Coordinator
class AppCoordinator {
  final AutoSaveService autoSave;
  
  void _saveSnapshot(String description) {
    final snapshot = AppSnapshot(/* ... */);
    undoRedo.pushSnapshot(snapshot);
    
    // Trigger debounced auto-save
    autoSave.scheduleSave(snapshot);
  }
  
  Future<void> restoreFromAutoSave() async {
    final snapshot = await autoSave.loadSnapshot();
    if (snapshot != null) {
      _restoreSnapshot(snapshot);
    }
  }
}
📅 Development Phases
Phase 1: Foundation (Week 1)
Goal: Basic grid with colored boxes, single selection Tasks:
Create project structure
Implement data models (ColorBox, OklchValues)
Implement GridState (basic operations)
Implement ColorEditorState
Implement AppCoordinator (basic)
Create HomeScreen with MultiProvider setup
Create basic ColorBoxWidget (just colored squircle, no fancy layers)
Implement single selection (tap to select)
Connect sliders to selected box
Copy color operations from v1 (OKLCH system)
Deliverable: App with 4x4 grid, tap to select, sliders work Estimated: 20-30 hours
Phase 2: Selection & Layout Modes (Week 2)
Goal: Multi-select, layout modes, basic interactions Tasks:
Implement flutter_slideable for multi-select
Update coordinator for multi-edit mode
Implement relative adjustments for multi-edit
Create layout mode switcher
Implement List layout
Implement Grid layout (with empty boxes)
Implement Custom layout
Add drag-to-reorder
Add plus/minus buttons
Add lock toggle
Deliverable: All 3 layout modes work, multi-select works, plus/minus works Estimated: 25-35 hours
Phase 3: Aesthetic Modes & Visual Polish (Week 3)
Goal: Tile/Flat modes, complex box rendering Tasks:
Implement ColorPipeline for visual calculations
Create ProcessedBoxColors
Implement top squircle layer
Implement highlight SVG layer
Implement lock icon overlay
Implement selection stroke
Implement stroke/shadow calculations
Create Tile aesthetic mode
Create Flat aesthetic mode
Add spacing calculations
Deliverable: Boxes look amazing, Tile/Flat modes work Estimated: 20-30 hours
Phase 4: Filters & BgColor (Week 4)
Goal: Global filters, background/ambient color Tasks:
Implement FilterState
Create 3 basic RGB filters (warmth, saturation, brightness)
Integrate filters into ColorPipeline
Create FilterSheet UI
Implement BgColorState
Integrate bg/ambient into stroke calculations
Add filter undo/redo
Optimize filter rebuilds (debouncing)
Add filter presets (stretch goal)
Test filter performance with 40+ boxes
Deliverable: Filters work, bg/ambient color affects boxes Estimated: 20-25 hours
Phase 5: Advanced Interactions (Week 5)
Goal: Scroll reveal/hide, drag-to-delete Tasks:
Implement scroll reveal row UX
Implement scroll delete row UX
Add progress tracking (0.0 to 1.0)
Implement 70% commit threshold
Add elastic scroll behavior
Create DragDeleteZone widget
Integrate drag-to-delete with grid
Add row animations
Test scroll edge cases
Polish animations
Deliverable: Scroll gestures work smoothly, drag-to-delete works Estimated: 25-35 hours
Phase 6: Features from V1 (Week 6)
Goal: ICC, mixer, eyedropper, undo/redo Tasks:
Port IccFilterService from v1
Add ICC caching
Integrate ICC into ColorPipeline
Implement MixerState
Create mixer slider UI
Port Mixbox pigment mixing
Integrate eyedropper (cyclop)
Implement UndoRedoManager
Add undo/redo keyboard shortcuts
Implement generate/randomize
Deliverable: All v1 features working in new architecture Estimated: 25-30 hours
Phase 7: Auto-Save & Polish (Week 7)
Goal: Persistence, optimization, final polish Tasks:
Implement AutoSaveService
Add debounced save
Add load on startup
Optimize filter rebuilds (caching)
Optimize ColorPipeline (memoization)
Add loading states
Add error handling
Performance testing
Bug fixes
Final polish
Deliverable: Production-ready app Estimated: 20-25 hours
Total Development Time
Minimum: 155 hours (~ 4 weeks full-time) Maximum: 215 hours (~ 5.5 weeks full-time) Realistic with part-time: 8-12 weeks
📊 Complexity Estimates
Per Feature
Feature	Complexity	Time	Reason
GridState	High	15-20h	Complex row management, 3 layouts, empty box handling
ColorEditorState	Low	3-5h	Simple OKLCH tracking + edit modes
FilterState	Medium	8-12h	15+ filters, optimization needed
MixerState	Medium	6-8h	Port from v1, add Mixbox
BgColorState	Low	2-3h	Simple color tracking
IccFilterService	Medium	5-7h	Port from v1, add caching
UndoRedoManager	Low	3-5h	Keep v1 pattern
AppCoordinator	High	20-25h	Complex cross-domain logic
ColorBoxWidget	High	15-20h	Complex Stack, 6 layers, gestures
Layout Engine	High	12-15h	Responsive sizing, 3 modes, Custom layout logic
Color Pipeline	Medium	8-10h	ICC + Filters + Visual calcs
Scroll Reveal/Hide	High	15-20h	Custom scroll physics, animations
Drag-to-Delete	Medium	6-8h	DragTarget integration
Multi-Select (Slideable)	Medium	8-10h	Flutter Slideable integration
Auto-Save	Low	4-6h	SharedPreferences + debouncing
Filters UI	Medium	8-10h	15+ sliders, sheet layout
Biggest Risks
Custom Layout Mode - Most complex, lots of edge cases
Scroll Reveal/Hide UX - Custom scroll physics tricky
Filter Performance - 15 filters × 40 boxes = 600 operations/frame
ColorPipeline Optimization - Needs caching/memoization

Biggest Risks
Custom Layout Mode - Most complex, lots of edge cases
Scroll Reveal/Hide UX - Custom scroll physics tricky
Filter Performance - 15 filters × 40 boxes = 600 operations/frame
ColorPipeline Optimization - Needs caching/memoization