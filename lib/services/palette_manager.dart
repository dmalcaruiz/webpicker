import 'package:flutter/material.dart';
import '../models/color_palette_item.dart';

/// Manages color palette operations
/// 
/// Handles:
/// - Adding/removing colors
/// - Reordering items
/// - Selection management
/// - Validation
class PaletteManager {
  /// Add a new color to the palette
  static List<ColorPaletteItem> addColor({
    required List<ColorPaletteItem> currentPalette,
    required Color color,
    String? name,
    bool selectNew = true,
  }) {
    // Deselect all if we're selecting the new one
    final updatedPalette = selectNew
        ? currentPalette.map((item) => item.copyWith(isSelected: false)).toList()
        : List<ColorPaletteItem>.from(currentPalette);
    
    // Create and add new item
    final newItem = ColorPaletteItem.fromColor(color, name: name)
        .copyWith(isSelected: selectNew);
    
    updatedPalette.add(newItem);
    
    return updatedPalette;
  }
  
  /// Remove a color from the palette
  static List<ColorPaletteItem> removeColor({
    required List<ColorPaletteItem> currentPalette,
    required String itemId,
  }) {
    return currentPalette.where((item) => item.id != itemId).toList();
  }
  
  /// Reorder items in the palette
  static List<ColorPaletteItem> reorderItems({
    required List<ColorPaletteItem> currentPalette,
    required int oldIndex,
    required int newIndex,
  }) {
    final palette = List<ColorPaletteItem>.from(currentPalette);
    final item = palette.removeAt(oldIndex);
    palette.insert(newIndex, item);
    return palette;
  }
  
  /// Select a specific item (deselects all others)
  static List<ColorPaletteItem> selectItem({
    required List<ColorPaletteItem> currentPalette,
    required String itemId,
  }) {
    return currentPalette.map((item) => 
      item.copyWith(isSelected: item.id == itemId)
    ).toList();
  }
  
  /// Deselect all items
  static List<ColorPaletteItem> deselectAll({
    required List<ColorPaletteItem> currentPalette,
  }) {
    return currentPalette.map((item) => 
      item.copyWith(isSelected: false)
    ).toList();
  }
  
  /// Update color of a specific item
  static List<ColorPaletteItem> updateItemColor({
    required List<ColorPaletteItem> currentPalette,
    required String itemId,
    required Color color,
  }) {
    return currentPalette.map((item) {
      if (item.id == itemId) {
        return item.copyWith(
          color: color,
          lastModified: DateTime.now(),
          isSelected: item.isSelected, // Preserve selection
        );
      }
      return item;
    }).toList();
  }
  
  /// Get the currently selected item
  static ColorPaletteItem? getSelectedItem(List<ColorPaletteItem> palette) {
    try {
      return palette.firstWhere((item) => item.isSelected);
    } catch (e) {
      return null;
    }
  }
  
  /// Get item by ID
  static ColorPaletteItem? getItemById({
    required List<ColorPaletteItem> palette,
    required String itemId,
  }) {
    try {
      return palette.firstWhere((item) => item.id == itemId);
    } catch (e) {
      return null;
    }
  }
  
  /// Check if an item is selected
  static bool hasSelection(List<ColorPaletteItem> palette) {
    return palette.any((item) => item.isSelected);
  }
  
  /// Get index of item by ID
  static int getIndexById({
    required List<ColorPaletteItem> palette,
    required String itemId,
  }) {
    return palette.indexWhere((item) => item.id == itemId);
  }
  
  /// Validate palette doesn't have duplicate IDs
  static bool validateNoDuplicateIds(List<ColorPaletteItem> palette) {
    final ids = palette.map((item) => item.id).toSet();
    return ids.length == palette.length;
  }
  
  /// Ensure only one item is selected (fix inconsistent state)
  static List<ColorPaletteItem> ensureSingleSelection({
    required List<ColorPaletteItem> currentPalette,
  }) {
    final selectedItems = currentPalette.where((item) => item.isSelected).toList();
    
    if (selectedItems.length <= 1) {
      return currentPalette; // Already consistent
    }
    
    // Keep only the first selected item
    final firstSelectedId = selectedItems.first.id;
    return currentPalette.map((item) => 
      item.copyWith(isSelected: item.id == firstSelectedId)
    ).toList();
  }
}

