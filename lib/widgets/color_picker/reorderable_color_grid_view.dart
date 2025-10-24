import 'package:flutter/material.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';
import '../../models/color_palette_item.dart';
import 'color_item_widget.dart';

/// A reorderable grid view for displaying and managing color palettes
/// 
/// Features:
/// - Drag and drop reordering
/// - Add/remove colors
/// - Selection management
/// - Responsive grid layout
/// - Empty state handling
class ReorderableColorGridView extends StatefulWidget {
  /// List of color palette items to display
  final List<ColorPaletteItem> items;
  
  /// Callback when items are reordered
  final Function(int oldIndex, int newIndex) onReorder;
  
  /// Callback when an item is tapped
  final Function(ColorPaletteItem) onItemTap;
  
  /// Callback when an item is long pressed
  final Function(ColorPaletteItem) onItemLongPress;
  
  /// Callback when an item should be deleted
  final Function(ColorPaletteItem) onItemDelete;
  
  /// Callback when add button is pressed
  final VoidCallback onAddColor;
  
  /// Callback when drag starts (for showing delete zone)
  final Function(ColorPaletteItem)? onDragStarted;
  
  /// Callback when drag ends (for hiding delete zone)
  /// Returns true if item was deleted, false otherwise
  final bool Function()? onDragEnded;
  
  /// Number of columns in the grid
  final int crossAxisCount;
  
  /// Spacing between grid items
  final double spacing;
  
  /// Size of each color item
  final double itemSize;
  
  /// Whether to show the add button
  final bool showAddButton;
  
  /// Empty state message
  final String emptyStateMessage;
  
  const ReorderableColorGridView({
    super.key,
    required this.items,
    required this.onReorder,
    required this.onItemTap,
    required this.onItemLongPress,
    required this.onItemDelete,
    required this.onAddColor,
    this.onDragStarted,
    this.onDragEnded,
    this.crossAxisCount = 4,
    this.spacing = 12.0,
    this.itemSize = 80.0,
    this.showAddButton = true,
    this.emptyStateMessage = 'No colors in palette\nTap + to add your first color',
  });
  
  @override
  State<ReorderableColorGridView> createState() => _ReorderableColorGridViewState();
}

class _ReorderableColorGridViewState extends State<ReorderableColorGridView> {
  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return _buildEmptyState();
    }
    
    return _buildGridView();
  }
  
  /// Build the main grid view with drag-and-drop support
  Widget _buildGridView() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: ReorderableGridView.count(
        crossAxisCount: widget.crossAxisCount,
        crossAxisSpacing: widget.spacing,
        mainAxisSpacing: widget.spacing,
        childAspectRatio: 1.0,
        dragStartDelay: const Duration(milliseconds: 200),
        restrictDragScope: false,
        onReorder: (oldIndex, newIndex) {
          // Call the drag ended callback before reordering
          final wasDeleted = widget.onDragEnded?.call() ?? false;
          
          // Only perform reorder if item wasn't deleted
          if (!wasDeleted) {
            widget.onReorder(oldIndex, newIndex);
          }
        },
        footer: widget.showAddButton ? [_buildAddButton()] : null,
        dragWidgetBuilderV2: DragWidgetBuilderV2(
          builder: (index, child, screenshot) {
            // Notify that drag has started
            if (widget.onDragStarted != null && index < widget.items.length) {
              // Use post-frame callback to avoid calling setState during build
              WidgetsBinding.instance.addPostFrameCallback((_) {
                widget.onDragStarted!(widget.items[index]);
              });
            }
            
            // Use the child directly for smooth dragging experience
            return Transform.scale(
              scale: 1.1,
              child: Opacity(
                opacity: 0.9,
                child: child,
              ),
            );
          },
        ),
        placeholderBuilder: (dropIndex, dropIndexInReordering, dragIndex) {
          // Show a placeholder where the item will be dropped
          return Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.5),
                width: 2,
                style: BorderStyle.solid,
              ),
            ),
          );
        },
        children: widget.items.map((item) => _buildColorItem(item)).toList(),
      ),
    );
  }
  
  /// Build a single color item
  Widget _buildColorItem(ColorPaletteItem item) {
    return ColorItemWidget(
      key: ValueKey(item.id),
      item: item,
      size: widget.itemSize,
      onTap: () => widget.onItemTap(item),
      onLongPress: () => widget.onItemLongPress(item),
      onDelete: () => widget.onItemDelete(item),
      onDragToDeleteStart: widget.onDragStarted != null 
          ? () => widget.onDragStarted!(item)
          : null,
      onDragToDeleteEnd: widget.onDragEnded,
    );
  }
  
  /// Build the add button
  Widget _buildAddButton() {
    return GestureDetector(
      key: const ValueKey('add_button'),
      onTap: widget.onAddColor,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: const Icon(
          Icons.add,
          color: Colors.white70,
          size: 32,
        ),
      ),
    );
  }
  
  /// Build empty state when no colors are present
  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.palette_outlined,
            size: 64,
            color: Colors.white.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            widget.emptyStateMessage,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: widget.onAddColor,
            icon: const Icon(Icons.add),
            label: const Text('Add Color'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}