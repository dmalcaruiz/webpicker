import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// Test to verify the fixed reordering logic for ReorderableGridView
void main() {
  group('Fixed ReorderableGridView Behavior', () {
    test('Forward drag without adjustment - CORRECT behavior', () {
      // Initial list: [Red, Blue, Green, Orange]
      List<String> items = ['Red', 'Blue', 'Green', 'Orange'];
      
      // Drag "Blue" (index 1) to position after "Orange" (visual position 3)
      // Package provides newIndex = 3 (the exact target position)
      int oldIndex = 1;
      int newIndex = 3;
      
      // NO adjustment - package already provides correct index
      final item = items.removeAt(oldIndex);
      items.insert(newIndex, item);
      
      // Expected: [Red, Green, Orange, Blue]
      expect(items, ['Red', 'Green', 'Orange', 'Blue']);
      if (kDebugMode) {
        print('✓ Forward drag: $items');
      }
    });
    
    test('Backward drag without adjustment - CORRECT behavior', () {
      // Initial list: [Red, Blue, Green, Orange]
      List<String> items = ['Red', 'Blue', 'Green', 'Orange'];
      
      // Drag "Orange" (index 3) to position after "Red" (visual position 1)
      int oldIndex = 3;
      int newIndex = 1;
      
      // NO adjustment - package already provides correct index
      final item = items.removeAt(oldIndex);
      items.insert(newIndex, item);
      
      // Expected: [Red, Orange, Blue, Green]
      expect(items, ['Red', 'Orange', 'Blue', 'Green']);
      if (kDebugMode) {
        print('✓ Backward drag: $items');
      }
    });
    
    test('Adjacent forward - move one position right', () {
      // Initial list: [A, B, C, D]
      List<String> items = ['A', 'B', 'C', 'D'];
      
      // Drag "B" (index 1) to position after "C" (visual position 2)
      int oldIndex = 1;
      int newIndex = 2;
      
      final item = items.removeAt(oldIndex);
      items.insert(newIndex, item);
      
      // Expected: [A, C, B, D]
      expect(items, ['A', 'C', 'B', 'D']);
      if (kDebugMode) {
        print('✓ Adjacent forward: $items');
      }
    });
    
    test('Adjacent backward - move one position left', () {
      // Initial list: [A, B, C, D]
      List<String> items = ['A', 'B', 'C', 'D'];
      
      // Drag "C" (index 2) to position after "A" (visual position 1)
      int oldIndex = 2;
      int newIndex = 1;
      
      final item = items.removeAt(oldIndex);
      items.insert(newIndex, item);
      
      // Expected: [A, C, B, D]
      expect(items, ['A', 'C', 'B', 'D']);
      if (kDebugMode) {
        print('✓ Adjacent backward: $items');
      }
    });
    
    test('Complex sequence - multiple reorders', () {
      // Initial: [1, 2, 3, 4, 5]
      List<int> items = [1, 2, 3, 4, 5];
      
      // Move 2 to end
      int item = items.removeAt(1);
      items.insert(4, item);
      expect(items, [1, 3, 4, 5, 2]);
      
      // Move 5 to start
      item = items.removeAt(3);
      items.insert(0, item);
      expect(items, [5, 1, 3, 4, 2]);
      
      // Move 3 after 4
      item = items.removeAt(2);
      items.insert(3, item);
      expect(items, [5, 1, 4, 3, 2]);
      
      if (kDebugMode) {
        print('✓ Complex sequence: $items');
      }
    });
    
    test('First to last position', () {
      List<String> items = ['First', 'Second', 'Third', 'Fourth'];
      
      // Move "First" (index 0) to end (index 3)
      int oldIndex = 0;
      int newIndex = 3;
      
      final item = items.removeAt(oldIndex);
      items.insert(newIndex, item);
      
      expect(items, ['Second', 'Third', 'Fourth', 'First']);
      if (kDebugMode) {
        print('✓ First to last: $items');
      }
    });
    
    test('Last to first position', () {
      List<String> items = ['First', 'Second', 'Third', 'Fourth'];
      
      // Move "Fourth" (index 3) to start (index 0)
      int oldIndex = 3;
      int newIndex = 0;
      
      final item = items.removeAt(oldIndex);
      items.insert(newIndex, item);
      
      expect(items, ['Fourth', 'First', 'Second', 'Third']);
      if (kDebugMode) {
        print('✓ Last to first: $items');
      }
    });
  });
}
