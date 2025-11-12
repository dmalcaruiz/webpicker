import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learning/models/color_grid_item.dart';
import 'package:learning/utils/color_grid_operations.dart';

void main() {
  group('Empty Slots - Last Row Cleanup', () {
    test('Single empty slot alone on last row should be removed (2 columns)', () {
      final grid = [
        ColorGridItem.fromColor(Colors.red, name: 'Red'),
        ColorGridItem.fromColor(Colors.blue, name: 'Blue'),
        ColorGridItem.empty(), // Alone on row 1
      ];

      final result = ColorGridManager.cleanupTrailingEmptyRows(
        currentGrid: grid,
        columns: 2,
      );

      expect(result.length, 2);
      expect(result[0].name, 'Red');
      expect(result[1].name, 'Blue');
    });

    test('Multiple empty slots on last row should be removed (2 columns)', () {
      final grid = [
        ColorGridItem.fromColor(Colors.red, name: 'Red'),
        ColorGridItem.fromColor(Colors.blue, name: 'Blue'),
        ColorGridItem.empty(),
        ColorGridItem.empty(), // Complete row 1 of empties
      ];

      final result = ColorGridManager.cleanupTrailingEmptyRows(
        currentGrid: grid,
        columns: 2,
      );

      expect(result.length, 2);
      expect(result[0].name, 'Red');
      expect(result[1].name, 'Blue');
    });

    test('Empty slot on same row as color SHOULD be removed', () {
      final grid = [
        ColorGridItem.fromColor(Colors.red, name: 'Red'),
        ColorGridItem.empty(), // Same row as Red, but trailing
      ];

      final result = ColorGridManager.cleanupTrailingEmptyRows(
        currentGrid: grid,
        columns: 2,
      );

      expect(result.length, 1); // Should remove trailing empty
      expect(result[0].name, 'Red');
    });

    test('Multiple trailing empty rows should all be removed (3 columns)', () {
      final grid = [
        ColorGridItem.fromColor(Colors.red, name: 'Red'),
        ColorGridItem.fromColor(Colors.blue, name: 'Blue'),
        ColorGridItem.fromColor(Colors.green, name: 'Green'),
        // Row 1: all empty
        ColorGridItem.empty(),
        ColorGridItem.empty(),
        ColorGridItem.empty(),
        // Row 2: all empty
        ColorGridItem.empty(),
        ColorGridItem.empty(),
        ColorGridItem.empty(),
      ];

      final result = ColorGridManager.cleanupTrailingEmptyRows(
        currentGrid: grid,
        columns: 3,
      );

      expect(result.length, 3);
      expect(result.every((item) => !item.isEmpty), true);
    });

    test('Partial trailing row with color should keep all items', () {
      final grid = [
        ColorGridItem.fromColor(Colors.red, name: 'Red'),
        ColorGridItem.fromColor(Colors.blue, name: 'Blue'),
        ColorGridItem.fromColor(Colors.green, name: 'Green'),
        ColorGridItem.empty(),
        ColorGridItem.fromColor(Colors.yellow, name: 'Yellow'), // Color on row 1
      ];

      final result = ColorGridManager.cleanupTrailingEmptyRows(
        currentGrid: grid,
        columns: 3,
      );

      expect(result.length, 5);
    });

    test('Grid with only empty slots should be cleared', () {
      final grid = [
        ColorGridItem.empty(),
        ColorGridItem.empty(),
        ColorGridItem.empty(),
      ];

      final result = ColorGridManager.cleanupTrailingEmptyRows(
        currentGrid: grid,
        columns: 2,
      );

      expect(result.length, 0); // Remove all empties if no colors
    });

    test('Empty grid should return empty', () {
      final grid = <ColorGridItem>[];

      final result = ColorGridManager.cleanupTrailingEmptyRows(
        currentGrid: grid,
        columns: 2,
      );

      expect(result.length, 0);
    });
  });

  group('Empty Slots - Reordering', () {
    test('Reorder color before empty slot', () {
      final grid = [
        ColorGridItem.fromColor(Colors.red, name: 'Red'),
        ColorGridItem.empty(),
        ColorGridItem.fromColor(Colors.blue, name: 'Blue'),
      ];

      final result = ColorGridManager.reorderItems(
        currentGrid: grid,
        oldIndex: 0, // Red
        newIndex: 2, // After empty
      );

      // After removing Red from 0 and inserting at 2: [Empty, Blue, Red]
      expect(result[0].isEmpty, true);
      expect(result[1].name, 'Blue');
      expect(result[2].name, 'Red');
    });

    test('Reorder empty slot between colors', () {
      final grid = [
        ColorGridItem.fromColor(Colors.red, name: 'Red'),
        ColorGridItem.fromColor(Colors.blue, name: 'Blue'),
        ColorGridItem.empty(),
      ];

      final result = ColorGridManager.reorderItems(
        currentGrid: grid,
        oldIndex: 2, // Empty
        newIndex: 1, // Between Red and Blue
      );

      expect(result[0].name, 'Red');
      expect(result[1].isEmpty, true);
      expect(result[2].name, 'Blue');
    });

    test('Reorder color to end leaves empty at start', () {
      final grid = [
        ColorGridItem.fromColor(Colors.red, name: 'Red'),
        ColorGridItem.fromColor(Colors.blue, name: 'Blue'),
      ];

      // Simulate dragging to add button (handled by addEmptySlot)
      final withEmpty = ColorGridManager.addEmptySlot(
        currentGrid: grid,
        index: 0,
      );

      expect(withEmpty[0].isEmpty, true);
      expect(withEmpty[1].name, 'Red');
      expect(withEmpty[2].name, 'Blue');
    });
  });

  group('Empty Slots - Replace Operations', () {
    test('Replace empty slot with color', () {
      final grid = [
        ColorGridItem.fromColor(Colors.red, name: 'Red'),
        ColorGridItem.empty(),
      ];

      final emptyId = grid[1].id;
      final result = ColorGridManager.replaceEmptySlot(
        currentGrid: grid,
        slotId: emptyId,
        color: Colors.blue,
        name: 'Blue',
      );

      expect(result.length, 2);
      expect(result[1].isEmpty, false);
      expect(result[1].name, 'Blue');
      expect(result[1].color, Colors.blue);
    });

    test('Replace non-existent empty slot should return original grid', () {
      final grid = [
        ColorGridItem.fromColor(Colors.red, name: 'Red'),
      ];

      final result = ColorGridManager.replaceEmptySlot(
        currentGrid: grid,
        slotId: 'non_existent_id',
        color: Colors.blue,
      );

      expect(result, grid);
    });

    test('Replace color item should return original grid (not an empty)', () {
      final grid = [
        ColorGridItem.fromColor(Colors.red, name: 'Red'),
      ];

      final result = ColorGridManager.replaceEmptySlot(
        currentGrid: grid,
        slotId: grid[0].id,
        color: Colors.blue,
      );

      expect(result, grid);
      expect(result[0].color, Colors.red); // Unchanged
    });
  });

  group('Empty Slots - Complex Scenarios', () {
    test('Scenario: Drag color to add button, then reorder, then cleanup', () {
      // Start: [Red][Blue] (2 columns)
      var grid = [
        ColorGridItem.fromColor(Colors.red, name: 'Red'),
        ColorGridItem.fromColor(Colors.blue, name: 'Blue'),
      ];

      // Drag Blue to add button position -> creates empty at index 1
      grid = ColorGridManager.addEmptySlot(currentGrid: grid, index: 1);
      // Result: [Red][Empty][Blue]
      expect(grid.length, 3);
      expect(grid[1].isEmpty, true);

      // Cleanup - Blue is on row 1 with empty, so no cleanup should happen
      var result = ColorGridManager.cleanupTrailingEmptyRows(
        currentGrid: grid,
        columns: 2,
      );
      expect(result.length, 3); // No cleanup

      // Now remove Blue to create trailing empties
      grid = grid.sublist(0, 2); // [Red][Empty]

      // Cleanup should remove all trailing empties
      grid = ColorGridManager.cleanupTrailingEmptyRows(
        currentGrid: grid,
        columns: 2,
      );
      expect(grid.length, 1); // Should keep only Red

      // Add a new color
      grid = ColorGridManager.addColor(
        currentGrid: grid,
        color: Colors.green,
        name: 'Green',
      );
      // Result: [Red][Green]
      expect(grid.length, 2);
      expect(grid[0].name, 'Red');
      expect(grid[1].name, 'Green');
    });

    test('Scenario: Create gap, reorder around it, cleanup', () {
      // Start: [Red][Blue][Green][Yellow] (2 columns)
      var grid = [
        ColorGridItem.fromColor(Colors.red, name: 'Red'),
        ColorGridItem.fromColor(Colors.blue, name: 'Blue'),
        ColorGridItem.fromColor(Colors.green, name: 'Green'),
        ColorGridItem.fromColor(Colors.yellow, name: 'Yellow'),
      ];

      // Delete Green -> replace with empty
      grid[2] = ColorGridItem.empty();
      // Result: [Red][Blue][Empty][Yellow]

      expect(grid.length, 4);
      expect(grid[2].isEmpty, true);

      // Reorder Yellow before Empty
      grid = ColorGridManager.reorderItems(
        currentGrid: grid,
        oldIndex: 3,
        newIndex: 2,
      );
      // Result: [Red][Blue][Yellow][Empty]
      expect(grid[2].name, 'Yellow');
      expect(grid[3].isEmpty, true);

      // Cleanup removes trailing empty
      var result = ColorGridManager.cleanupTrailingEmptyRows(
        currentGrid: grid,
        columns: 2,
      );
      expect(result.length, 3); // Trailing empty removed

      // Use the cleaned grid
      grid = result; // [Red][Blue][Yellow]

      // Verify final state
      expect(grid.length, 3);
      expect(grid[0].name, 'Red');
      expect(grid[1].name, 'Blue');
      expect(grid[2].name, 'Yellow');
    });

    test('Scenario: Multiple empties, partial cleanup', () {
      // Start: [Red][Empty][Empty][Blue] (2 columns)
      var grid = [
        ColorGridItem.fromColor(Colors.red, name: 'Red'),
        ColorGridItem.empty(),
        ColorGridItem.empty(),
        ColorGridItem.fromColor(Colors.blue, name: 'Blue'),
      ];

      // No cleanup - last row has Blue
      var result = ColorGridManager.cleanupTrailingEmptyRows(
        currentGrid: grid,
        columns: 2,
      );
      expect(result.length, 4);

      // Remove Blue
      grid = grid.sublist(0, 3); // [Red][Empty][Empty]

      // Cleanup: removes all trailing empties
      result = ColorGridManager.cleanupTrailingEmptyRows(
        currentGrid: grid,
        columns: 2,
      );
      // Result: [Red]
      expect(result.length, 1);
      expect(result[0].name, 'Red');
    });

    test('Scenario: 3-column grid with scattered empties', () {
      // [Red][Blue][Empty]
      // [Empty][Green][Yellow]
      var grid = [
        ColorGridItem.fromColor(Colors.red, name: 'Red'),
        ColorGridItem.fromColor(Colors.blue, name: 'Blue'),
        ColorGridItem.empty(),
        ColorGridItem.empty(),
        ColorGridItem.fromColor(Colors.green, name: 'Green'),
        ColorGridItem.fromColor(Colors.yellow, name: 'Yellow'),
      ];

      // No cleanup - last row has colors
      var result = ColorGridManager.cleanupTrailingEmptyRows(
        currentGrid: grid,
        columns: 3,
      );
      expect(result.length, 6);

      // Add trailing empty row
      grid.addAll([
        ColorGridItem.empty(),
        ColorGridItem.empty(),
        ColorGridItem.empty(),
      ]);
      // [Red][Blue][Empty]
      // [Empty][Green][Yellow]
      // [Empty][Empty][Empty]

      // Cleanup should remove row 2
      result = ColorGridManager.cleanupTrailingEmptyRows(
        currentGrid: grid,
        columns: 3,
      );
      expect(result.length, 6);
    });
  });

  group('Empty Slots - Middle Row Cleanup', () {
    test('Complete empty row in the middle should be removed (2 columns)', () {
      // [Red][Blue]
      // [Empty][Empty]  <- Should be removed
      // [Green][Yellow]
      final grid = [
        ColorGridItem.fromColor(Colors.red, name: 'Red'),
        ColorGridItem.fromColor(Colors.blue, name: 'Blue'),
        ColorGridItem.empty(),
        ColorGridItem.empty(),
        ColorGridItem.fromColor(Colors.green, name: 'Green'),
        ColorGridItem.fromColor(Colors.yellow, name: 'Yellow'),
      ];

      final result = ColorGridManager.cleanupTrailingEmptyRows(
        currentGrid: grid,
        columns: 2,
      );

      // Should remove the empty row, leaving 4 items
      expect(result.length, 4);
      expect(result[0].name, 'Red');
      expect(result[1].name, 'Blue');
      expect(result[2].name, 'Green');
      expect(result[3].name, 'Yellow');
    });

    test('Multiple complete empty rows in the middle should be removed (3 columns)', () {
      // [Red][Blue][Green]
      // [Empty][Empty][Empty]  <- Should be removed
      // [Empty][Empty][Empty]  <- Should be removed
      // [Yellow][Purple][Orange]
      final grid = [
        ColorGridItem.fromColor(Colors.red, name: 'Red'),
        ColorGridItem.fromColor(Colors.blue, name: 'Blue'),
        ColorGridItem.fromColor(Colors.green, name: 'Green'),
        ColorGridItem.empty(),
        ColorGridItem.empty(),
        ColorGridItem.empty(),
        ColorGridItem.empty(),
        ColorGridItem.empty(),
        ColorGridItem.empty(),
        ColorGridItem.fromColor(Colors.yellow, name: 'Yellow'),
        ColorGridItem.fromColor(Colors.purple, name: 'Purple'),
        ColorGridItem.fromColor(Colors.orange, name: 'Orange'),
      ];

      final result = ColorGridManager.cleanupTrailingEmptyRows(
        currentGrid: grid,
        columns: 3,
      );

      // Should remove both empty rows, leaving 6 items
      expect(result.length, 6);
      expect(result[0].name, 'Red');
      expect(result[1].name, 'Blue');
      expect(result[2].name, 'Green');
      expect(result[3].name, 'Yellow');
      expect(result[4].name, 'Purple');
      expect(result[5].name, 'Orange');
    });

    test('Incomplete empty row in the middle should NOT be removed', () {
      // [Red][Blue]
      // [Empty][Green]  <- Not all empty, keep it
      // [Yellow][Purple]
      final grid = [
        ColorGridItem.fromColor(Colors.red, name: 'Red'),
        ColorGridItem.fromColor(Colors.blue, name: 'Blue'),
        ColorGridItem.empty(),
        ColorGridItem.fromColor(Colors.green, name: 'Green'),
        ColorGridItem.fromColor(Colors.yellow, name: 'Yellow'),
        ColorGridItem.fromColor(Colors.purple, name: 'Purple'),
      ];

      final result = ColorGridManager.cleanupTrailingEmptyRows(
        currentGrid: grid,
        columns: 2,
      );

      // Should keep all items
      expect(result.length, 6);
      expect(result[2].isEmpty, true); // Empty still there
      expect(result[3].name, 'Green');
    });

    test('Partial last row with empties should NOT be removed', () {
      // [Red][Blue]
      // [Green][Empty]  <- Last row is incomplete (only 2 items with 3 columns)
      final grid = [
        ColorGridItem.fromColor(Colors.red, name: 'Red'),
        ColorGridItem.fromColor(Colors.blue, name: 'Blue'),
        ColorGridItem.fromColor(Colors.green, name: 'Green'),
        ColorGridItem.empty(),
      ];

      final result = ColorGridManager.cleanupTrailingEmptyRows(
        currentGrid: grid,
        columns: 3,
      );

      // Trailing empty gets removed (step 1), but row isn't removed as complete row
      expect(result.length, 3);
      expect(result[0].name, 'Red');
      expect(result[1].name, 'Blue');
      expect(result[2].name, 'Green');
    });

    test('Combined: Empty row in middle + trailing empties', () {
      // [Red][Blue]
      // [Empty][Empty]  <- Should be removed (middle)
      // [Green][Yellow]
      // [Empty][Empty]  <- Should be removed (trailing)
      final grid = [
        ColorGridItem.fromColor(Colors.red, name: 'Red'),
        ColorGridItem.fromColor(Colors.blue, name: 'Blue'),
        ColorGridItem.empty(),
        ColorGridItem.empty(),
        ColorGridItem.fromColor(Colors.green, name: 'Green'),
        ColorGridItem.fromColor(Colors.yellow, name: 'Yellow'),
        ColorGridItem.empty(),
        ColorGridItem.empty(),
      ];

      final result = ColorGridManager.cleanupTrailingEmptyRows(
        currentGrid: grid,
        columns: 2,
      );

      // Should remove both the middle empty row and trailing empties
      expect(result.length, 4);
      expect(result[0].name, 'Red');
      expect(result[1].name, 'Blue');
      expect(result[2].name, 'Green');
      expect(result[3].name, 'Yellow');
    });

    test('First row all empty, second row has colors', () {
      // This shouldn't happen in normal usage, but test for completeness
      // [Empty][Empty]  <- Should be removed
      // [Red][Blue]
      final grid = [
        ColorGridItem.empty(),
        ColorGridItem.empty(),
        ColorGridItem.fromColor(Colors.red, name: 'Red'),
        ColorGridItem.fromColor(Colors.blue, name: 'Blue'),
      ];

      final result = ColorGridManager.cleanupTrailingEmptyRows(
        currentGrid: grid,
        columns: 2,
      );

      // Should remove the first empty row
      expect(result.length, 2);
      expect(result[0].name, 'Red');
      expect(result[1].name, 'Blue');
    });
  });

  group('Empty Slots - Edge Cases', () {
    test('Add empty slot at specific index', () {
      final grid = [
        ColorGridItem.fromColor(Colors.red, name: 'Red'),
        ColorGridItem.fromColor(Colors.blue, name: 'Blue'),
      ];

      final result = ColorGridManager.addEmptySlot(
        currentGrid: grid,
        index: 1,
      );

      expect(result.length, 3);
      expect(result[0].name, 'Red');
      expect(result[1].isEmpty, true);
      expect(result[2].name, 'Blue');
    });

    test('Add empty slot at end (no index)', () {
      final grid = [
        ColorGridItem.fromColor(Colors.red, name: 'Red'),
      ];

      final result = ColorGridManager.addEmptySlot(
        currentGrid: grid,
      );

      expect(result.length, 2);
      expect(result[1].isEmpty, true);
    });

    test('getTrailingEmptyCount returns correct count', () {
      final grid = [
        ColorGridItem.fromColor(Colors.red, name: 'Red'),
        ColorGridItem.empty(),
        ColorGridItem.empty(),
        ColorGridItem.empty(),
      ];

      final count = ColorGridManager.getTrailingEmptyCount(grid);
      expect(count, 3);
    });

    test('getTrailingEmptyCount with no trailing empties', () {
      final grid = [
        ColorGridItem.fromColor(Colors.red, name: 'Red'),
        ColorGridItem.empty(),
        ColorGridItem.fromColor(Colors.blue, name: 'Blue'),
      ];

      final count = ColorGridManager.getTrailingEmptyCount(grid);
      expect(count, 0);
    });

    test('Cleanup with invalid columns (zero)', () {
      final grid = [
        ColorGridItem.fromColor(Colors.red, name: 'Red'),
        ColorGridItem.empty(),
      ];

      final result = ColorGridManager.cleanupTrailingEmptyRows(
        currentGrid: grid,
        columns: 0,
      );

      expect(result, grid); // No cleanup with invalid columns
    });
  });
}
