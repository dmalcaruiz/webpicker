import 'package:flutter/material.dart';
import '../models/color_grid_item.dart';
import 'color_operations.dart';

// Manages color grid operations
// 
// Handles:
// - Adding/removing colors
// - Reordering items
// - Selection management
// - Validation
class ColorGridManager {
  // Add a new color to the grid
  static List<ColorGridItem> addColor({
    required List<ColorGridItem> currentGrid,
    required Color color,
    String? name,
    bool selectNew = true,
  }) {
    // Deselect all if we're selecting the new one
    final updatedGrid = selectNew
        ? currentGrid.map((item) => item.copyWith(isSelected: false)).toList()
        : List<ColorGridItem>.from(currentGrid);
    
    // Create and add new item
    final newItem = ColorGridItem.fromColor(color, name: name)
        .copyWith(isSelected: selectNew);
    
    updatedGrid.add(newItem);
    
    return updatedGrid;
  }
  
  // Remove a color from the grid
  static List<ColorGridItem> removeColor({
    required List<ColorGridItem> currentGrid,
    required String itemId,
  }) {
    return currentGrid.where((item) => item.id != itemId).toList();
  }
  
  // Reorder items in the grid
  static List<ColorGridItem> reorderItems({
    required List<ColorGridItem> currentGrid,
    required int oldIndex,
    required int newIndex,
  }) {
    debugPrint('REORDER: ColorGridManager.reorderItems - oldIndex=$oldIndex, newIndex=$newIndex, gridLength=${currentGrid.length}');

    final grid = List<ColorGridItem>.from(currentGrid);
    debugPrint('REORDER: Order before: ${grid.map((e) => e.name).join(", ")}');

    final item = grid.removeAt(oldIndex);
    debugPrint('REORDER: Removed item "${item.name}" (id: ${item.id}) from index $oldIndex');

    grid.insert(newIndex, item);
    debugPrint('REORDER: Inserted item "${item.name}" at index $newIndex');
    debugPrint('REORDER: Order after: ${grid.map((e) => e.name).join(", ")}');

    return grid;
  }
  
  // Select a specific item (deselects all others)
  static List<ColorGridItem> selectItem({
    required List<ColorGridItem> currentGrid,
    required String itemId,
  }) {
    return currentGrid.map((item) => 
      item.copyWith(isSelected: item.id == itemId)
    ).toList();
  }
  
  // Deselect all items
  static List<ColorGridItem> deselectAll({
    required List<ColorGridItem> currentGrid,
  }) {
    return currentGrid.map((item) => 
      item.copyWith(isSelected: false)
    ).toList();
  }
  
  // Update color of a specific item (from sRGB Color)
  static List<ColorGridItem> updateItemColor({
    required List<ColorGridItem> currentGrid,
    required String itemId,
    required Color color,
  }) {
    // Convert to OKLCH - this is the source of truth
    final oklch = srgbToOklch(color);
    final oklchValues = OklchValues(
      lightness: oklch.l,
      chroma: oklch.c,
      hue: oklch.h,
      alpha: oklch.alpha,
    );

    return currentGrid.map((item) {
      if (item.id == itemId) {
        return item.copyWith(
          color: color,
          oklchValues: oklchValues,
          lastModified: DateTime.now(),
          isSelected: item.isSelected, // Preserve selection
        );
      }
      return item;
    }).toList();
  }

  // Update color of a specific item (from OKLCH values - preferred)
  static List<ColorGridItem> updateItemOklch({
    required List<ColorGridItem> currentGrid,
    required String itemId,
    required double lightness,
    required double chroma,
    required double hue,
    double alpha = 1.0,
  }) {
    final oklchValues = OklchValues(
      lightness: lightness,
      chroma: chroma,
      hue: hue,
      alpha: alpha,
    );

    // Convert to Color for display
    final color = colorFromOklch(lightness, chroma, hue, alpha);

    return currentGrid.map((item) {
      if (item.id == itemId) {
        return item.copyWith(
          color: color,
          oklchValues: oklchValues,
          lastModified: DateTime.now(),
          isSelected: item.isSelected, // Preserve selection
        );
      }
      return item;
    }).toList();
  }
  
  // Get the currently selected item
  static ColorGridItem? getSelectedItem(List<ColorGridItem> grid) {
    try {
      return grid.firstWhere((item) => item.isSelected);
    } catch (e) {
      return null;
    }
  }
  
  // Get item by ID
  static ColorGridItem? getItemById({
    required List<ColorGridItem> grid,
    required String itemId,
  }) {
    try {
      return grid.firstWhere((item) => item.id == itemId);
    } catch (e) {
      return null;
    }
  }
  
  // Check if an item is selected
  static bool hasSelection(List<ColorGridItem> grid) {
    return grid.any((item) => item.isSelected);
  }
  
  // Get index of item by ID
  static int getIndexById({
    required List<ColorGridItem> grid,
    required String itemId,
  }) {
    return grid.indexWhere((item) => item.id == itemId);
  }
  
  // Validate grid doesn't have duplicate IDs
  static bool validateNoDuplicateIds(List<ColorGridItem> grid) {
    final ids = grid.map((item) => item.id).toSet();
    return ids.length == grid.length;
  }
  
  // Ensure only one item is selected (fix inconsistent state)
  static List<ColorGridItem> ensureSingleSelection({
    required List<ColorGridItem> currentGrid,
  }) {
    final selectedItems = currentGrid.where((item) => item.isSelected).toList();
    
    if (selectedItems.length <= 1) {
      return currentGrid; // Already consistent
    }
    
    // Keep only the first selected item
    final firstSelectedId = selectedItems.first.id;
    return currentGrid.map((item) => 
      item.copyWith(isSelected: item.id == firstSelectedId)
    ).toList();
  }
}

