import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../models/color_grid_item.dart';
import '../../utils/ui_color_utils.dart';

// Individual color item widget for the reorderable grid
// 
// Features:
// - Color preview with hex code
// - Drag handle for reordering
// - Selection state indication
// - Tap to select/edit
// - Long press for context menu
class ColorItemWidget extends StatelessWidget {
  // The color grid item to display
  final ColorGridItem item;

  // Optional display color (e.g., ICC filtered)
  // If provided, this is used instead of item.color for display only
  final Color? displayColor;

  // Callback when this item is tapped
  final VoidCallback? onTap;

  // Callback when this item is long pressed
  final VoidCallback? onLongPress;

  // Callback when this item should be deleted
  final VoidCallback? onDelete;

  // Callback when lock icon is tapped
  final VoidCallback? onToggleLock;

  // Callback when drag to delete starts
  final VoidCallback? onDragToDeleteStart;

  // Callback when drag to delete ends
  // Returns true if deleted, false otherwise
  final bool Function()? onDragToDeleteEnd;

  // Whether this item is currently being dragged
  final bool isDragging;

  // Size of the color item
  final double size;

  // Whether to show the drag handle
  final bool showDragHandle;

  ColorItemWidget({
    super.key,
    required this.item,
    this.displayColor,
    this.onTap,
    this.onLongPress,
    this.onDelete,
    this.onToggleLock,
    this.onDragToDeleteStart,
    this.onDragToDeleteEnd,
    this.isDragging = false,
    this.size = 80.0,
    this.showDragHandle = true,
  });
  
  @override
  Widget build(BuildContext context) {
    final colorWidget = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      transform: isDragging 
          ? (Matrix4.identity()..scale(1.05))
          : Matrix4.identity(),
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: displayColor ?? item.color,
            borderRadius: BorderRadius.circular(12),
            border: item.isSelected
                ? Border.all(
                    color: Colors.white,
                    width: 2,
                  )
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: isDragging ? 8 : 0,
                offset: Offset(0, isDragging ? 4 : 0),
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

              // Lock icon (always visible)
              _buildLockIcon(),
            ],
          ),
        ),
      ),
    );
    
    // Wrap in LongPressDraggable for drag-to-delete functionality
    if (onDragToDeleteStart != null && onDragToDeleteEnd != null) {
      return LongPressDraggable<String>(
        data: item.id,
        delay: const Duration(milliseconds: 500), // Longer delay to avoid conflicting with reorder
        feedback: Transform.scale(
          scale: 1.1,
          child: Opacity(
            opacity: 0.8,
            child: Material(
              color: Colors.transparent,
              child: colorWidget,
            ),
          ),
        ),
        childWhenDragging: Opacity(
          opacity: 0.3,
          child: colorWidget,
        ),
        onDragStarted: onDragToDeleteStart,
        onDragEnd: (_) {
          onDragToDeleteEnd?.call();
        },
        onDraggableCanceled: (_, __) {
          onDragToDeleteEnd?.call();
        },
        child: colorWidget,
      );
    }
    
    return colorWidget;
  }
  
  // Build the main color content area
  Widget _buildColorContent() {
    // Just pure color - no text or labels
    return const SizedBox.expand();
  }
  
  // Build the drag handle
  Widget _buildDragHandle() {
    // No visible drag handle - drag anywhere on the box
    return const SizedBox.shrink();
  }
  
  // Build the selection indicator
  Widget _buildSelectionIndicator() {
    // No visible selection indicator - selection shown via border in main container
    return const SizedBox.shrink();
  }

  // Build the lock icon overlay
  Widget _buildLockIcon() {
    // Use the same color determination method as action buttons
    final bgColor = displayColor ?? item.color;
    final iconColor = getTextColor(bgColor);

    return Positioned(
      bottom: 18,
      left: 0,
      right: 0,
      child: Center(
        child: GestureDetector(
          onTap: onToggleLock,
          child: SvgPicture.asset(
            item.isLocked ? 'assets/icons/locked.svg' : 'assets/icons/unlocked.svg',
            width: 26,
            height: 18,
            colorFilter: ColorFilter.mode(
              iconColor.withValues(alpha: item.isLocked ? 0.5 : 0.2),
              BlendMode.srcIn,
            ),
          ),
        ),
      ),
    );
  }
}
