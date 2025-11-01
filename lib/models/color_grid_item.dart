import 'package:flutter/material.dart';
import '../utils/color_operations.dart';

/// Represents a single color item in a grid
class ColorGridItem {
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

  /// OKLCH values for this color (source of truth)
  final OklchValues oklchValues;

  const ColorGridItem({
    required this.id,
    required this.color,
    this.name,
    required this.createdAt,
    required this.lastModified,
    this.isSelected = false,
    required this.oklchValues,
  });
  
  /// Create a copy of this item with updated values
  ColorGridItem copyWith({
    String? id,
    Color? color,
    String? name,
    DateTime? createdAt,
    DateTime? lastModified,
    bool? isSelected,
    OklchValues? oklchValues,
  }) {
    return ColorGridItem(
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
  factory ColorGridItem.fromColor(Color color, {String? name}) {
    final now = DateTime.now();
    // Convert color to OKLCH immediately - OKLCH is the source of truth
    final oklch = _colorToOklchValues(color);
    return ColorGridItem(
      id: _generateId(),
      color: color,
      name: name,
      createdAt: now,
      lastModified: now,
      oklchValues: oklch,
    );
  }

  /// Create a new color item from OKLCH values (preferred method)
  factory ColorGridItem.fromOklch({
    required double lightness,
    required double chroma,
    required double hue,
    double alpha = 1.0,
    String? name,
  }) {
    final now = DateTime.now();
    final oklch = OklchValues(
      lightness: lightness,
      chroma: chroma,
      hue: hue,
      alpha: alpha,
    );
    // Convert OKLCH to Color for display
    final color = _oklchValuesToColor(oklch);
    return ColorGridItem(
      id: _generateId(),
      color: color,
      name: name,
      createdAt: now,
      lastModified: now,
      oklchValues: oklch,
    );
  }

  /// Helper: Convert Color to OklchValues
  static OklchValues _colorToOklchValues(Color color) {
    final oklch = srgbToOklch(color);
    return OklchValues(
      lightness: oklch.l,
      chroma: oklch.c,
      hue: oklch.h,
      alpha: oklch.alpha,
    );
  }

  /// Helper: Convert OklchValues to Color
  static Color _oklchValuesToColor(OklchValues oklch) {
    return colorFromOklch(
      oklch.lightness,
      oklch.chroma,
      oklch.hue,
      oklch.alpha,
    );
  }
  
  /// Counter for generating unique IDs
  static int _idCounter = 0;
  
  /// Generate a unique ID for the color item
  static String _generateId() {
    _idCounter++;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    // Combine timestamp with counter for guaranteed uniqueness
    return 'color_${timestamp}_$_idCounter';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ColorGridItem && other.id == id;
  }
  
  @override
  int get hashCode => id.hashCode;
  
  @override
  String toString() {
    return 'ColorGridItem(id: $id, color: $color, name: $name)';
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

