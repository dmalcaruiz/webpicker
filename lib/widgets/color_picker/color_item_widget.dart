import 'package:flutter/material.dart';
import '../../models/color_palette_item.dart';

/// Individual color item widget for the reorderable grid
/// 
/// Features:
/// - Color preview with hex code
/// - Drag handle for reordering
/// - Selection state indication
/// - Tap to select/edit
/// - Long press for context menu
class ColorItemWidget extends StatelessWidget {
  /// The color palette item to display
  final ColorPaletteItem item;
  
  /// Callback when this item is tapped
  final VoidCallback? onTap;
  
  /// Callback when this item is long pressed
  final VoidCallback? onLongPress;
  
  /// Callback when this item should be deleted
  final VoidCallback? onDelete;
  
  /// Whether this item is currently being dragged
  final bool isDragging;
  
  /// Size of the color item
  final double size;
  
  /// Whether to show the drag handle
  final bool showDragHandle;
  
  const ColorItemWidget({
    super.key,
    required this.item,
    this.onTap,
    this.onLongPress,
    this.onDelete,
    this.isDragging = false,
    this.size = 80.0,
    this.showDragHandle = true,
  });
  
  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      transform: Matrix4.identity()..scale(isDragging ? 1.05 : 1.0),
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: item.color,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: item.isSelected 
                  ? Colors.white 
                  : Colors.white.withValues(alpha: 0.3),
              width: item.isSelected ? 3 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: isDragging ? 8 : 4,
                offset: Offset(0, isDragging ? 4 : 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Main color content
              _buildColorContent(),
              
              // Drag handle
              if (showDragHandle) _buildDragHandle(),
              
              // Selection indicator
              if (item.isSelected) _buildSelectionIndicator(),
            ],
          ),
        ),
      ),
    );
  }
  
  /// Build the main color content area
  Widget _buildColorContent() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top area - could show name if available
          if (item.name != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                item.name!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          
          // Bottom area - hex code
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              _getHexCode(),
              style: TextStyle(
                color: _getTextColor(),
                fontSize: 10,
                fontWeight: FontWeight.w600,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Build the drag handle
  Widget _buildDragHandle() {
    return Positioned(
      top: 4,
      right: 4,
      child: Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.drag_indicator,
          size: 12,
          color: Colors.black54,
        ),
      ),
    );
  }
  
  /// Build the selection indicator
  Widget _buildSelectionIndicator() {
    return Positioned(
      top: 4,
      left: 4,
      child: Container(
        width: 16,
        height: 16,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.check,
          size: 12,
          color: Colors.black,
        ),
      ),
    );
  }
  
  /// Get the hex code for the color
  String _getHexCode() {
    final hex = item.color.toARGB32().toRadixString(16).substring(2).toUpperCase();
    return '#$hex';
  }
  
  /// Get appropriate text color based on background luminance
  Color _getTextColor() {
    return item.color.computeLuminance() > 0.5 ? Colors.black : Colors.white;
  }
}
