import 'package:flutter_test/flutter_test.dart';

/// Test to verify reordering logic
void main() {
  group('ReorderableGridView Index Tests', () {
    test('Forward drag - item should move to correct position', () {
      // Initial list: [A, B, C, D, E]
      List<String> items = ['A', 'B', 'C', 'D', 'E'];
      
      // Drag item at index 1 (B) to index 3
      // Expected result: [A, C, D, B, E]
      int oldIndex = 1;
      int newIndex = 3;
      
      // Standard Flutter reordering logic
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      
      final item = items.removeAt(oldIndex);
      items.insert(newIndex, item);
      
      expect(items, ['A', 'C', 'D', 'B', 'E']);
    });
    
    test('Backward drag - item should move to correct position', () {
      // Initial list: [A, B, C, D, E]
      List<String> items = ['A', 'B', 'C', 'D', 'E'];
      
      // Drag item at index 3 (D) to index 1
      // Expected result: [A, D, B, C, E]
      int oldIndex = 3;
      int newIndex = 1;
      
      // Standard Flutter reordering logic
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      
      final item = items.removeAt(oldIndex);
      items.insert(newIndex, item);
      
      expect(items, ['A', 'D', 'B', 'C', 'E']);
    });
    
    test('ReorderableGridView behavior - no adjustment needed', () {
      // ReorderableGridView may provide already-adjusted indices
      // Initial list: [A, B, C, D, E]
      List<String> items = ['A', 'B', 'C', 'D', 'E'];
      
      // Drag item at index 1 (B) to index 3
      // If the library already adjusted, newIndex is where we want it
      int oldIndex = 1;
      int newIndex = 3;
      
      // Direct insertion without adjustment
      final item = items.removeAt(oldIndex);
      items.insert(newIndex, item);
      
      expect(items, ['A', 'C', 'D', 'E', 'B']);
    });
    
    test('Test sequence: multiple reorders', () {
      // Test moving items in sequence to verify consistency
      List<String> items = ['A', 'B', 'C', 'D', 'E'];
      
      // Move B (index 1) to position after D (index 3)
      // With adjustment: newIndex = 3 - 1 = 2
      // Result should be: [A, C, B, D, E]
      int oldIndex = 1;
      int newIndex = 3;
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      var item = items.removeAt(oldIndex);
      items.insert(newIndex, item);
      
      expect(items, ['A', 'C', 'B', 'D', 'E']);
      
      // Move D (now at index 3) to position before C (index 1)
      // No adjustment needed: newIndex stays 1
      // Result should be: [A, D, C, B, E]
      oldIndex = 3;
      newIndex = 1;
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      item = items.removeAt(oldIndex);
      items.insert(newIndex, item);
      
      expect(items, ['A', 'D', 'C', 'B', 'E']);
    });
  });
  
  group('ReorderableGridView Package Behavior', () {
    test('Verify if package returns raw or adjusted indices', () {
      // This test documents the expected behavior
      // Based on reorderable_grid_view package documentation,
      // the onReorder callback receives indices that need adjustment
      
      List<String> items = ['Red', 'Blue', 'Green', 'Orange'];
      
      // Scenario: Drag "Blue" (index 1) to after "Orange" (index 3)
      // Visual expectation: [Red, Green, Orange, Blue]
      
      // Test with adjustment (standard Flutter behavior)
      var testItems1 = List<String>.from(items);
      int oldIndex = 1;
      int newIndex = 3;
      
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      var item = testItems1.removeAt(oldIndex);
      testItems1.insert(newIndex, item);
      
      // This should give us [Red, Green, Blue, Orange]
      // Which means the item ends up ONE POSITION BEFORE where we wanted!
      expect(testItems1, ['Red', 'Green', 'Blue', 'Orange']);
      
      // Test without adjustment
      var testItems2 = List<String>.from(items);
      oldIndex = 1;
      newIndex = 3;
      
      item = testItems2.removeAt(oldIndex);
      testItems2.insert(newIndex, item);
      
      // This should give us [Red, Green, Orange, Blue]
      // This is the CORRECT visual result!
      expect(testItems2, ['Red', 'Green', 'Orange', 'Blue']);
    });
  });
}
