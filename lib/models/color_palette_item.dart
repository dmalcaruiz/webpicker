import 'package:flutter/material.dart';

/// Represents a single color item in a palette
class ColorPaletteItem {
  /// Unique identifier for this color item
  final String id;
  
  /// The actual color value
  final Color color;
  
  /// Optional name/label for the color
  final String? name;
  
  /// When this color was created
  final DateTime createdAt;
  
  /// When this color was last modified
  final DateTime lastModified;
  
  /// Whether this color is currently selected
  final bool isSelected;
  
  /// Optional OKLCH values for this color
  final OklchValues? oklchValues;
  
  const ColorPaletteItem({
    required this.id,
    required this.color,
    this.name,
    required this.createdAt,
    required this.lastModified,
    this.isSelected = false,
    this.oklchValues,
  });
  
  /// Create a copy of this item with updated values
  ColorPaletteItem copyWith({
    String? id,
    Color? color,
    String? name,
    DateTime? createdAt,
    DateTime? lastModified,
    bool? isSelected,
    OklchValues? oklchValues,
  }) {
    return ColorPaletteItem(
      id: id ?? this.id,
      color: color ?? this.color,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      lastModified: lastModified ?? this.lastModified,
      isSelected: isSelected ?? this.isSelected,
      oklchValues: oklchValues ?? this.oklchValues,
    );
  }
  
  /// Create a new color item from a Color
  factory ColorPaletteItem.fromColor(Color color, {String? name}) {
    final now = DateTime.now();
    return ColorPaletteItem(
      id: _generateId(),
      color: color,
      name: name,
      createdAt: now,
      lastModified: now,
    );
  }
  
  /// Generate a unique ID for the color item
  static String _generateId() {
    return 'color_${DateTime.now().millisecondsSinceEpoch}_${(DateTime.now().microsecond % 1000).toString().padLeft(3, '0')}';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ColorPaletteItem && other.id == id;
  }
  
  @override
  int get hashCode => id.hashCode;
  
  @override
  String toString() {
    return 'ColorPaletteItem(id: $id, color: $color, name: $name)';
  }
}

/// OKLCH values for a color
class OklchValues {
  final double lightness;
  final double chroma;
  final double hue;
  final double alpha;
  
  const OklchValues({
    required this.lightness,
    required this.chroma,
    required this.hue,
    this.alpha = 1.0,
  });
  
  @override
  String toString() => 'OklchValues(l: $lightness, c: $chroma, h: $hue, a: $alpha)';
}
