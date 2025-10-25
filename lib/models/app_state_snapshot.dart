import 'package:flutter/material.dart';
import 'color_palette_item.dart';
import 'extreme_color_item.dart';

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

  /// ID of the selected extreme ('left', 'right', or null)
  final String? selectedExtremeId;

  /// Left extreme color state
  final ExtremeColorItem? leftExtreme;

  /// Right extreme color state
  final ExtremeColorItem? rightExtreme;

  /// Whether to constrain colors to real pigment gamut (ICC profile)
  /// This is a DISPLAY FILTER - doesn't modify stored OKLCH values
  final bool useRealPigmentsOnly;

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
    this.selectedExtremeId,
    this.leftExtreme,
    this.rightExtreme,
    bool? useRealPigmentsOnly,
    required this.timestamp,
    required this.actionDescription,
  }) : useRealPigmentsOnly = useRealPigmentsOnly ?? false;
  
  /// Create a deep copy of this snapshot
  AppStateSnapshot copyWith({
    List<ColorPaletteItem>? paletteItems,
    Color? currentColor,
    Color? bgColor,
    bool? isBgEditMode,
    String? selectedPaletteItemId,
    String? selectedExtremeId,
    ExtremeColorItem? leftExtreme,
    ExtremeColorItem? rightExtreme,
    bool? useRealPigmentsOnly,
    DateTime? timestamp,
    String? actionDescription,
  }) {
    return AppStateSnapshot(
      paletteItems: paletteItems ?? this.paletteItems.map((item) => item).toList(),
      currentColor: currentColor ?? this.currentColor,
      bgColor: bgColor ?? this.bgColor,
      isBgEditMode: isBgEditMode ?? this.isBgEditMode,
      selectedPaletteItemId: selectedPaletteItemId ?? this.selectedPaletteItemId,
      selectedExtremeId: selectedExtremeId ?? this.selectedExtremeId,
      leftExtreme: leftExtreme ?? this.leftExtreme,
      rightExtreme: rightExtreme ?? this.rightExtreme,
      useRealPigmentsOnly: useRealPigmentsOnly ?? this.useRealPigmentsOnly,
      timestamp: timestamp ?? this.timestamp,
      actionDescription: actionDescription ?? this.actionDescription,
    );
  }
  
  @override
  String toString() {
    return 'AppStateSnapshot($actionDescription, ${paletteItems.length} items, ${timestamp.toIso8601String()})';
  }
}
