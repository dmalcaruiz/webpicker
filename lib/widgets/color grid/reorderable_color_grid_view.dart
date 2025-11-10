import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../custom_reorderable_grid/reorderable_grid_view.dart';
import '../../models/color_grid_item.dart';
import '../../state/color_grid_provider.dart';
import '../../state/settings_provider.dart';
import 'color_item_widget.dart';

// A reorderable grid view for displaying and managing color grids
//
// Features:
// - Drag and drop reordering
// - Add/remove colors
// - Selection management
// - Responsive grid layout
// - Empty state handling
//
// Uses GridProvider for accessing the color grid items.
class ReorderableColorGridView extends StatefulWidget {
  
  // Callback when items are reordered
  final Function(int oldIndex, int newIndex) onReorder;
  
  // Callback when an item is tapped
  final Function(ColorGridItem) onItemTap;
  
  // Callback when an item is long pressed
  final Function(ColorGridItem) onItemLongPress;
  
  // Callback when an item should be deleted
  final Function(ColorGridItem) onItemDelete;
  
  // Callback when add button is pressed
  final VoidCallback onAddColor;
  
  // Callback when drag starts (for showing delete zone)
  final Function(ColorGridItem)? onDragStarted;
  
  // Callback when drag ends (for hiding delete zone)
  // Returns true if item was deleted, false otherwise
  final bool Function()? onDragEnded;
  
  // Number of columns in the grid
  final int crossAxisCount;
  
  // Spacing between grid items
  final double spacing;
  
  // Size of each color item
  final double itemSize;
  
  // Whether to show the add button
  final bool showAddButton;
  
  // Empty state message
  final String emptyStateMessage;

  // Optional color filter for display (e.g., ICC profile filtering)
  // Takes the grid item and returns the display color
  final Color Function(ColorGridItem)? colorFilter;

  // Grid layout mode
  final GridLayoutMode layoutMode;

  // Box height mode
  final BoxHeightMode heightMode;

  // Available height for fillContainer mode (optional, calculated from screen - header - sheet)
  final double? availableHeight;

  const ReorderableColorGridView({
    super.key,
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
    this.emptyStateMessage = 'No colors in grid\nTap + to add your first color',
    this.colorFilter,
    this.layoutMode = GridLayoutMode.responsive,
    this.heightMode = BoxHeightMode.proportional,
    this.availableHeight,
  });
  
  @override
  State<ReorderableColorGridView> createState() => _ReorderableColorGridViewState();
}

class _ReorderableColorGridViewState extends State<ReorderableColorGridView> {
  @override
  Widget build(BuildContext context) {
    // Get items from GridProvider
    final items = context.watch<ColorGridProvider>().items;

    if (items.isEmpty) {
      return _buildEmptyState();
    }

    return _buildGridView(items);
  }
  
  // Build the main grid view with drag-and-drop support
  Widget _buildGridView(List<ColorGridItem> items) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: switch (widget.layoutMode) {
        GridLayoutMode.responsive => _buildResponsiveGrid(items),
        GridLayoutMode.fixedSize => _buildFixedSizeGrid(items),
        GridLayoutMode.horizontal => _buildHorizontalGrid(items),
      },
    );
  }

  // Calculate aspect ratio based on height mode
  double _calculateAspectRatio({
    required double boxWidth,
    required double availableHeight,
    required int totalItems,
    required int columns,
  }) {
    switch (widget.heightMode) {
      case BoxHeightMode.proportional:
        return 1.0; // Square boxes (width = height)

      case BoxHeightMode.fillContainer:
        // Calculate rows needed
        final rows = (totalItems / columns).ceil();
        if (rows <= 0) return 1.0;

        // Calculate height per row to fill container
        final totalSpacing = (rows - 1) * widget.spacing;
        final boxHeight = (availableHeight - totalSpacing) / rows;

        // Guard against invalid values - fallback to proportional if calculations fail
        if (boxHeight <= 0 || boxWidth <= 0 || !boxHeight.isFinite || !availableHeight.isFinite) {
          return 1.0;
        }

        return boxWidth / boxHeight;

      case BoxHeightMode.fixed:
        return boxWidth / widget.itemSize; // Fixed height = itemSize
    }
  }

  // Build grid with fixed box sizes
  // Uses LayoutBuilder to calculate how many columns fit at the specified itemSize
  Widget _buildFixedSizeGrid(List<ColorGridItem> items) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate how many columns can fit based on itemSize
        final availableWidth = constraints.maxWidth - 16;
        final columnWidth = widget.itemSize + widget.spacing;
        final calculatedColumns = (availableWidth / columnWidth).floor().clamp(1, 10);
        final boxWidth = (availableWidth - (calculatedColumns - 1) * widget.spacing) / calculatedColumns;

        // Use provided availableHeight if given, otherwise use constraints
        // Note: Subtract 16 (8px top + 8px bottom padding) from provided height
        final heightForCalculation = widget.availableHeight != null
            ? widget.availableHeight! - 16
            : constraints.maxHeight - 16;

        final aspectRatio = _calculateAspectRatio(
          boxWidth: boxWidth,
          availableHeight: heightForCalculation,
          totalItems: items.length + (widget.showAddButton ? 1 : 0),
          columns: calculatedColumns,
        );

        final gridView = ReorderableGridView.count(
          crossAxisCount: calculatedColumns,
          crossAxisSpacing: widget.spacing,
          mainAxisSpacing: widget.spacing,
          childAspectRatio: aspectRatio,
          shrinkWrap: widget.heightMode != BoxHeightMode.fillContainer,
          physics: const NeverScrollableScrollPhysics(),
          dragStartDelay: const Duration(milliseconds: 200),
          restrictDragScope: false,
          onReorder: _handleReorder,
          footer: widget.showAddButton ? [_buildAddButton()] : null,
          dragWidgetBuilderV2: _buildDragWidget(items),
          children: items.map((item) => _buildColorItem(item)).toList(),
        );

        // When filling container, wrap in SizedBox to enforce height
        if (widget.heightMode == BoxHeightMode.fillContainer && widget.availableHeight != null) {
          return SizedBox(
            height: widget.availableHeight,
            child: gridView,
          );
        }

        return gridView;
      },
    );
  }

  // Build grid with responsive sizing using count
  Widget _buildResponsiveGrid(List<ColorGridItem> items) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth - 16;
        final boxWidth = (availableWidth - (widget.crossAxisCount - 1) * widget.spacing) / widget.crossAxisCount;

        // Use provided availableHeight if given, otherwise use constraints
        final heightForCalculation = (widget.availableHeight ?? constraints.maxHeight) - 16;

        final aspectRatio = _calculateAspectRatio(
          boxWidth: boxWidth,
          availableHeight: heightForCalculation,
          totalItems: items.length + (widget.showAddButton ? 1 : 0),
          columns: widget.crossAxisCount,
        );

        final gridView = ReorderableGridView.count(
          crossAxisCount: widget.crossAxisCount,
          crossAxisSpacing: widget.spacing,
          mainAxisSpacing: widget.spacing,
          childAspectRatio: aspectRatio,
          shrinkWrap: widget.heightMode != BoxHeightMode.fillContainer,
          physics: const NeverScrollableScrollPhysics(),
          dragStartDelay: const Duration(milliseconds: 200),
          restrictDragScope: false,
          onReorder: _handleReorder,
          footer: widget.showAddButton ? [_buildAddButton()] : null,
          dragWidgetBuilderV2: _buildDragWidget(items),
          children: items.map((item) => _buildColorItem(item)).toList(),
        );

        // When filling container, wrap in SizedBox to enforce height
        if (widget.heightMode == BoxHeightMode.fillContainer && widget.availableHeight != null) {
          return SizedBox(
            height: widget.availableHeight,
            child: gridView,
          );
        }

        return gridView;
      },
    );
  }

  // Build grid with horizontal layout (1 column, full width boxes)
  Widget _buildHorizontalGrid(List<ColorGridItem> items) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.maxWidth - 16;

        // Use provided availableHeight if given, otherwise use constraints
        final heightForCalculation = widget.availableHeight ?? constraints.maxHeight - 16;

        final aspectRatio = _calculateAspectRatio(
          boxWidth: boxWidth,
          availableHeight: heightForCalculation,
          totalItems: items.length + (widget.showAddButton ? 1 : 0),
          columns: 1,
        );

        final gridView = ReorderableGridView.count(
          crossAxisCount: 1,
          crossAxisSpacing: widget.spacing,
          mainAxisSpacing: widget.spacing,
          childAspectRatio: aspectRatio,
          shrinkWrap: widget.heightMode != BoxHeightMode.fillContainer,
          physics: const NeverScrollableScrollPhysics(),
          dragStartDelay: const Duration(milliseconds: 200),
          restrictDragScope: false,
          onReorder: _handleReorder,
          footer: widget.showAddButton ? [_buildAddButton()] : null,
          dragWidgetBuilderV2: _buildDragWidget(items),
          children: items.map((item) => _buildColorItem(item)).toList(),
        );

        // When filling container, wrap in SizedBox to enforce height
        if (widget.heightMode == BoxHeightMode.fillContainer && widget.availableHeight != null) {
          return SizedBox(
            height: widget.availableHeight,
            child: gridView,
          );
        }

        return gridView;
      },
    );
  }

  // Handle reorder callback
  void _handleReorder(int oldIndex, int newIndex) {
    // Call the drag ended callback before reordering
    final wasDeleted = widget.onDragEnded?.call() ?? false;

    // Only perform reorder if item wasn't deleted
    if (!wasDeleted) {
      widget.onReorder(oldIndex, newIndex);
    }
  }

  // Build drag widget
  DragWidgetBuilderV2 _buildDragWidget(List<ColorGridItem> items) {
    return DragWidgetBuilderV2(
      builder: (index, child, screenshot) {
        // Notify that drag has started
        if (widget.onDragStarted != null && index < items.length) {
          // Use post-frame callback to avoid calling setState during build
          WidgetsBinding.instance.addPostFrameCallback((_) {
            widget.onDragStarted!(items[index]);
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
    );
  }

  // Build a single color item
  Widget _buildColorItem(ColorGridItem item) {
    return ColorItemWidget(
      key: ValueKey(item.id),
      item: item,
      displayColor: widget.colorFilter != null ? widget.colorFilter!(item) : null,
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
  
  // Build the add button
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
  
  // Build empty state when no colors are present
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