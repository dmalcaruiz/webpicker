import 'color_palette_item.dart';

/// Encapsulates the complete color palette state
/// 
/// Immutable state object that can be easily snapshotted for undo/redo
class ColorPaletteState {
  /// List of all palette items
  final List<ColorPaletteItem> items;
  
  /// ID of the currently selected item (if any)
  final String? selectedItemId;
  
  const ColorPaletteState({
    required this.items,
    this.selectedItemId,
  });
  
  /// Create an empty palette state
  factory ColorPaletteState.empty() {
    return const ColorPaletteState(items: []);
  }
  
  /// Create from a list of items
  factory ColorPaletteState.fromItems(List<ColorPaletteItem> items) {
    final selectedItem = items.where((item) => item.isSelected).firstOrNull;
    return ColorPaletteState(
      items: items,
      selectedItemId: selectedItem?.id,
    );
  }
  
  /// Get the selected item
  ColorPaletteItem? get selectedItem {
    if (selectedItemId == null) return null;
    try {
      return items.firstWhere((item) => item.id == selectedItemId);
    } catch (e) {
      return null;
    }
  }
  
  /// Check if there's a selection
  bool get hasSelection => selectedItemId != null;
  
  /// Get the number of items
  int get itemCount => items.length;
  
  /// Check if palette is empty
  bool get isEmpty => items.isEmpty;
  
  /// Check if palette is not empty
  bool get isNotEmpty => items.isNotEmpty;
  
  /// Create a copy with updated values
  ColorPaletteState copyWith({
    List<ColorPaletteItem>? items,
    String? selectedItemId,
    bool clearSelection = false,
  }) {
    return ColorPaletteState(
      items: items ?? this.items,
      selectedItemId: clearSelection ? null : (selectedItemId ?? this.selectedItemId),
    );
  }
  
  /// Create a copy with a new list of items
  ColorPaletteState withItems(List<ColorPaletteItem> items) {
    // Automatically update selectedItemId based on items
    final selectedItem = items.where((item) => item.isSelected).firstOrNull;
    return ColorPaletteState(
      items: items,
      selectedItemId: selectedItem?.id,
    );
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ColorPaletteState) return false;
    
    return other.selectedItemId == selectedItemId &&
           other.items.length == items.length &&
           _listsEqual(other.items, items);
  }
  
  bool _listsEqual(List<ColorPaletteItem> a, List<ColorPaletteItem> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id) return false;
    }
    return true;
  }
  
  @override
  int get hashCode => Object.hash(
    selectedItemId,
    items.length,
    items.isEmpty ? 0 : items.first.id,
  );
  
  @override
  String toString() {
    return 'ColorPaletteState(items: ${items.length}, selectedId: $selectedItemId)';
  }
}

// Extension for null safety
extension FirstWhereOrNullExtension<E> on Iterable<E> {
  E? get firstOrNull {
    final iterator = this.iterator;
    if (iterator.moveNext()) {
      return iterator.current;
    }
    return null;
  }
}

