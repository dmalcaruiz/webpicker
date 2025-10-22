import 'package:flutter/material.dart';
import 'color_palette_item.dart';

/// Represents a complete snapshot of the app state for undo/redo
class AppStateSnapshot {
  /// List of color palette items
  final List<ColorPaletteItem> paletteItems;
  
  /// Current color being edited
  final Color? currentColor;
  
  /// Background color
  final Color? bgColor;
  
  /// Whether in background edit mode
  final bool isBgEditMode;
  
  /// ID of the selected palette item
  final String? selectedPaletteItemId;
  
  /// Timestamp when this snapshot was created
  final DateTime timestamp;
  
  /// Description of the action that created this snapshot
  final String actionDescription;
  
  const AppStateSnapshot({
    required this.paletteItems,
    required this.currentColor,
    required this.bgColor,
    required this.isBgEditMode,
    this.selectedPaletteItemId,
    required this.timestamp,
    required this.actionDescription,
  });
  
  /// Create a deep copy of this snapshot
  AppStateSnapshot copyWith({
    List<ColorPaletteItem>? paletteItems,
    Color? currentColor,
    Color? bgColor,
    bool? isBgEditMode,
    String? selectedPaletteItemId,
    DateTime? timestamp,
    String? actionDescription,
  }) {
    return AppStateSnapshot(
      paletteItems: paletteItems ?? this.paletteItems.map((item) => item).toList(),
      currentColor: currentColor ?? this.currentColor,
      bgColor: bgColor ?? this.bgColor,
      isBgEditMode: isBgEditMode ?? this.isBgEditMode,
      selectedPaletteItemId: selectedPaletteItemId ?? this.selectedPaletteItemId,
      timestamp: timestamp ?? this.timestamp,
      actionDescription: actionDescription ?? this.actionDescription,
    );
  }
  
  @override
  String toString() {
    return 'AppStateSnapshot($actionDescription, ${paletteItems.length} items, ${timestamp.toIso8601String()})';
  }
}
