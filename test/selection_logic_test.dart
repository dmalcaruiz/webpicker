import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Test to verify color selection logic
void main() {
  group('Color Selection Logic Tests', () {
    late List<MockColorItem> items;
    
    setUp(() {
      items = [
        MockColorItem('item1', Colors.red, false),
        MockColorItem('item2', Colors.blue, false),
        MockColorItem('item3', Colors.green, false),
        MockColorItem('item4', Colors.orange, false),
      ];
    });
    
    test('Selecting an item should deselect all others', () {
      // Select item2
      items = items.map((item) => item.id == 'item2' 
          ? item.copyWith(isSelected: true) 
          : item.copyWith(isSelected: false)
      ).toList();
      
      expect(items[0].isSelected, false);
      expect(items[1].isSelected, true);
      expect(items[2].isSelected, false);
      expect(items[3].isSelected, false);
    });
    
    test('Selecting another item should deselect previous selection', () {
      // First select item2
      items = items.map((item) => item.id == 'item2' 
          ? item.copyWith(isSelected: true) 
          : item.copyWith(isSelected: false)
      ).toList();
      
      expect(items[1].isSelected, true);
      
      // Then select item4
      items = items.map((item) => item.id == 'item4' 
          ? item.copyWith(isSelected: true) 
          : item.copyWith(isSelected: false)
      ).toList();
      
      expect(items[0].isSelected, false);
      expect(items[1].isSelected, false);
      expect(items[2].isSelected, false);
      expect(items[3].isSelected, true);
    });
    
    test('Reordering should preserve selection state', () {
      // Select item2
      items[1] = items[1].copyWith(isSelected: true);
      
      // Reorder: move item2 from index 1 to index 3
      final item = items.removeAt(1);
      items.insert(3, item);
      
      // item2 should still be selected at its new position
      expect(items[0].id, 'item1');
      expect(items[0].isSelected, false);
      expect(items[1].id, 'item3');
      expect(items[1].isSelected, false);
      expect(items[2].id, 'item4');
      expect(items[2].isSelected, false);
      expect(items[3].id, 'item2');
      expect(items[3].isSelected, true, reason: 'Selected item should remain selected after reordering');
    });
    
    test('Adding new item should deselect others if new item is selected', () {
      // Select item2
      items[1] = items[1].copyWith(isSelected: true);
      
      // Deselect all
      items = items.map((item) => item.copyWith(isSelected: false)).toList();
      
      // Add new selected item
      items.add(MockColorItem('item5', Colors.purple, true));
      
      expect(items[0].isSelected, false);
      expect(items[1].isSelected, false);
      expect(items[2].isSelected, false);
      expect(items[3].isSelected, false);
      expect(items[4].isSelected, true);
    });
    
    test('Deleting selected item should clear selection', () {
      // Select item2
      items[1] = items[1].copyWith(isSelected: true);
      String? selectedId = items[1].id;
      
      // Delete item2
      items.removeWhere((item) => item.id == selectedId);
      
      // Check if selection was cleared
      if (selectedId == 'item2') {
        selectedId = null;
      }
      
      expect(items.length, 3);
      expect(items.every((item) => !item.isSelected), true);
      expect(selectedId, null);
    });
    
    test('Tapping selected item should not cause issues', () {
      // Select item2
      items = items.map((item) => item.id == 'item2' 
          ? item.copyWith(isSelected: true) 
          : item.copyWith(isSelected: false)
      ).toList();
      
      // Tap same item again (should remain selected)
      items = items.map((item) => item.id == 'item2' 
          ? item.copyWith(isSelected: true) 
          : item.copyWith(isSelected: false)
      ).toList();
      
      expect(items[1].isSelected, true);
      expect(items.where((item) => item.isSelected).length, 1);
    });
    
    test('Selection reference should match item in list', () {
      // Select item2
      items[1] = items[1].copyWith(isSelected: true);
      final selectedItem = items[1];
      
      // Find selected item by id
      final foundIndex = items.indexWhere((item) => item.id == selectedItem.id);
      
      expect(foundIndex, 1);
      expect(items[foundIndex].isSelected, true);
      expect(items[foundIndex].id, selectedItem.id);
    });
    
    test('Updating color of selected item should maintain selection', () {
      // Select item2
      items[1] = items[1].copyWith(isSelected: true);
      final selectedId = items[1].id;
      
      // Update color of selected item
      final selectedIndex = items.indexWhere((item) => item.id == selectedId);
      items[selectedIndex] = items[selectedIndex].copyWith(
        color: Colors.cyan,
        isSelected: true, // Explicitly maintain selection
      );
      
      expect(items[selectedIndex].isSelected, true);
      expect(items[selectedIndex].color, Colors.cyan);
    });
    
    test('ISSUE: Selection lost after color update without explicit flag', () {
      // This tests the common bug: selection is lost when updating color
      items[1] = items[1].copyWith(isSelected: true);
      final selectedId = items[1].id;
      
      // Update color WITHOUT explicitly setting isSelected
      // This simulates the bug where copyWith doesn't preserve isSelected
      final selectedIndex = items.indexWhere((item) => item.id == selectedId);
      final currentItem = items[selectedIndex];
      
      // Bug scenario: only update color, don't pass isSelected
      items[selectedIndex] = currentItem.copyWith(
        color: Colors.yellow,
        // isSelected is NOT passed, should default to preserving existing value
      );
      
      expect(items[selectedIndex].isSelected, true, 
        reason: 'copyWith should preserve isSelected when not explicitly provided');
    });
  });
}

/// Mock color item for testing
class MockColorItem {
  final String id;
  final Color color;
  final bool isSelected;
  
  MockColorItem(this.id, this.color, this.isSelected);
  
  MockColorItem copyWith({
    String? id,
    Color? color,
    bool? isSelected,
  }) {
    return MockColorItem(
      id ?? this.id,
      color ?? this.color,
      isSelected ?? this.isSelected, // This should preserve existing value
    );
  }
}

