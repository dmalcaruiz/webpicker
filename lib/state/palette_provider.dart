import 'package:flutter/material.dart';
import '../models/color_palette_item.dart';
import '../services/palette_manager.dart';

/// Provider for the color palette
///
/// Manages the list of color items in the palette along with selection state.
/// All palette operations (add, delete, reorder, select) go through this provider.
class PaletteProvider extends ChangeNotifier {
  List<ColorPaletteItem> _items = [];

  // Getters
  List<ColorPaletteItem> get items => _items;
  int get itemCount => _items.length;
  bool get isEmpty => _items.isEmpty;
  bool get isNotEmpty => _items.isNotEmpty;

  /// Get the currently selected item (if any)
  ColorPaletteItem? get selectedItem => PaletteManager.getSelectedItem(_items);

  /// Get the ID of the selected item (if any)
  String? get selectedItemId => selectedItem?.id;

  /// Check if there's a selected item
  bool get hasSelection => PaletteManager.hasSelection(_items);

  /// Add a new color to the palette
  void addColor(Color color, {String? name, bool selectNew = true}) {
    _items = PaletteManager.addColor(
      currentPalette: _items,
      color: color,
      name: name,
      selectNew: selectNew,
    );
    notifyListeners();
  }

  /// Remove a color from the palette by ID
  void removeColor(String itemId) {
    _items = PaletteManager.removeColor(
      currentPalette: _items,
      itemId: itemId,
    );
    notifyListeners();
  }

  /// Reorder items in the palette
  void reorderItems(int oldIndex, int newIndex) {
    _items = PaletteManager.reorderItems(
      currentPalette: _items,
      oldIndex: oldIndex,
      newIndex: newIndex,
    );
    notifyListeners();
  }

  /// Select a specific item (deselects all others)
  void selectItem(String itemId) {
    _items = PaletteManager.selectItem(
      currentPalette: _items,
      itemId: itemId,
    );
    notifyListeners();
  }

  /// Deselect all items
  void deselectAll() {
    _items = PaletteManager.deselectAll(
      currentPalette: _items,
    );
    notifyListeners();
  }

  /// Update the OKLCH values of a specific item
  void updateItemOklch({
    required String itemId,
    required double lightness,
    required double chroma,
    required double hue,
    double? alpha,
  }) {
    _items = PaletteManager.updateItemOklch(
      currentPalette: _items,
      itemId: itemId,
      lightness: lightness,
      chroma: chroma,
      hue: hue,
      alpha: alpha ?? 1.0,
    );
    notifyListeners();
  }

  /// Update the color of a specific item (from Color)
  void updateItemColor({
    required String itemId,
    required Color color,
  }) {
    _items = PaletteManager.updateItemColor(
      currentPalette: _items,
      itemId: itemId,
      color: color,
    );
    notifyListeners();
  }

  /// Get item by ID
  ColorPaletteItem? getItemById(String itemId) {
    return PaletteManager.getItemById(
      palette: _items,
      itemId: itemId,
    );
  }

  /// Sync from snapshot (for undo/redo) - replaces entire palette
  void syncFromSnapshot(List<ColorPaletteItem> snapshot) {
    // Only notify if the palette actually changed
    if (_items != snapshot) {
      _items = List<ColorPaletteItem>.from(snapshot);
      notifyListeners();
    }
  }

  /// Replace entire palette (used during restore/load operations)
  void setPalette(List<ColorPaletteItem> newPalette) {
    _items = List<ColorPaletteItem>.from(newPalette);
    notifyListeners();
  }

  /// Clear the entire palette
  void clear() {
    if (_items.isNotEmpty) {
      _items = [];
      notifyListeners();
    }
  }
}
