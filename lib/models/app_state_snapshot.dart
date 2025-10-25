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

  /// Background color OKLCH values
  final double? bgLightness;
  final double? bgChroma;
  final double? bgHue;
  final double? bgAlpha;

  /// Whether background color box is selected
  final bool isBgColorSelected;

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
    this.bgLightness,
    this.bgChroma,
    this.bgHue,
    this.bgAlpha,
    this.isBgColorSelected = false,
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
    double? bgLightness,
    double? bgChroma,
    double? bgHue,
    double? bgAlpha,
    bool? isBgColorSelected,
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
      bgLightness: bgLightness ?? this.bgLightness,
      bgChroma: bgChroma ?? this.bgChroma,
      bgHue: bgHue ?? this.bgHue,
      bgAlpha: bgAlpha ?? this.bgAlpha,
      isBgColorSelected: isBgColorSelected ?? this.isBgColorSelected,
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
