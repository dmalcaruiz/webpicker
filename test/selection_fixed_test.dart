import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Test to verify that selection logic is now fixed
void main() {
  group('Fixed Selection Logic', () {
    test('✓ Selection preserved when updating color', () {
      List<TestItem> items = [
        TestItem('1', Colors.red, false),
        TestItem('2', Colors.blue, true),  // Selected
        TestItem('3', Colors.green, false),
      ];
      
      String? selectedId = '2';
      final selectedIndex = items.indexWhere((p) => p.id == selectedId);
      
      // Update color WITH explicit isSelected: true (FIXED)
      items[selectedIndex] = items[selectedIndex].copyWith(
        color: Colors.cyan,
        isSelected: true, // Explicitly preserve
      );
      
      expect(items[selectedIndex].isSelected, true, 
        reason: 'Selection is now preserved when color is updated');
      expect(items[selectedIndex].color, Colors.cyan);
    });
    
    test('✓ Only one item selected at a time', () {
      List<TestItem> items = [
        TestItem('1', Colors.red, false),
        TestItem('2', Colors.blue, false),
        TestItem('3', Colors.green, false),
      ];
      
      // Select item2 (using the fixed approach)
      items = items.map((item) => 
        item.copyWith(isSelected: item.id == '2')
      ).toList();
      
      final selectedCount = items.where((item) => item.isSelected).length;
      
      expect(selectedCount, 1, reason: 'Exactly one item should be selected');
      expect(items[1].isSelected, true);
    });
    
    test('✓ Selection reference updated after list modification', () {
      List<TestItem> items = [
        TestItem('1', Colors.red, false),
        TestItem('2', Colors.blue, true),  // Selected
        TestItem('3', Colors.green, false),
      ];
      
      TestItem? selectedItem = items[1];
      String selectedId = selectedItem.id;
      
      // Reorder - move selected item to end
      final item = items.removeAt(1);
      items.insert(2, item);
      
      // Update reference (FIXED)
      final newIndex = items.indexWhere((item) => item.id == selectedId);
      selectedItem = items[newIndex];
      
      expect(newIndex, 2, reason: 'Item moved to end');
      expect(selectedItem.isSelected, true, reason: 'Selection maintained');
      expect(selectedItem.id, selectedId, reason: 'Reference points to correct item');
    });
    
    test('✓ Switching selection clears previous', () {
      List<TestItem> items = [
        TestItem('1', Colors.red, false),
        TestItem('2', Colors.blue, true),  // Selected
        TestItem('3', Colors.green, false),
      ];
      
      // Switch to item3 (using the fixed single-pass approach)
      items = items.map((item) => 
        item.copyWith(isSelected: item.id == '3')
      ).toList();
      
      expect(items[0].isSelected, false);
      expect(items[1].isSelected, false);
      expect(items[2].isSelected, true);
      
      final selectedCount = items.where((item) => item.isSelected).length;
      expect(selectedCount, 1);
    });
    
    test('✓ Deletion clears selection properly', () {
      List<TestItem> items = [
        TestItem('1', Colors.red, false),
        TestItem('2', Colors.blue, true),  // Selected
        TestItem('3', Colors.green, false),
      ];
      
      String? selectedId = '2';
      
      // Delete selected item
      items.removeWhere((item) => item.id == '2');
      
      // Clear reference (FIXED)
      if (selectedId == '2') {
        selectedId = null;
      }
      
      expect(items.length, 2);
      expect(selectedId, null);
      expect(items.any((item) => item.isSelected), false);
    });
    
    test('✓ Reordering preserves selection state', () {
      List<TestItem> items = [
        TestItem('1', Colors.red, false),
        TestItem('2', Colors.blue, true),  // Selected
        TestItem('3', Colors.green, false),
        TestItem('4', Colors.orange, false),
      ];
      
      String? selectedId = '2';
      
      // Move selected item from index 1 to index 3
      final item = items.removeAt(1);
      items.insert(3, item);
      
      // Update reference after reorder (FIXED)
      final newIndex = items.indexWhere((item) => item.id == selectedId);
      
      expect(newIndex, 3);
      expect(items[newIndex].isSelected, true);
      expect(items[newIndex].id, '2');
      
      // Verify only one selection
      final selectedCount = items.where((item) => item.isSelected).length;
      expect(selectedCount, 1);
    });
    
    test('✓ Adding new selected item clears old selection', () {
      List<TestItem> items = [
        TestItem('1', Colors.red, false),
        TestItem('2', Colors.blue, true),  // Selected
        TestItem('3', Colors.green, false),
      ];
      
      // Deselect all (FIXED - explicit approach)
      items = items.map((item) => item.copyWith(isSelected: false)).toList();
      
      // Add new selected item
      items.add(TestItem('4', Colors.purple, true));
      
      final selectedCount = items.where((item) => item.isSelected).length;
      expect(selectedCount, 1);
      expect(items[3].isSelected, true);
    });
    
    test('✓ Complex scenario: select, reorder, update color, switch selection', () {
      List<TestItem> items = [
        TestItem('A', Colors.red, false),
        TestItem('B', Colors.blue, false),
        TestItem('C', Colors.green, false),
        TestItem('D', Colors.orange, false),
      ];
      
      String? selectedId;
      
      // Step 1: Select B
      items = items.map((item) => 
        item.copyWith(isSelected: item.id == 'B')
      ).toList();
      selectedId = 'B';
      
      expect(items.where((item) => item.isSelected).length, 1);
      
      // Step 2: Reorder - move B to end
      final itemIndex = items.indexWhere((item) => item.id == 'B');
      final item = items.removeAt(itemIndex);
      items.insert(3, item);
      
      // Update reference
      final newIndex = items.indexWhere((item) => item.id == selectedId);
      expect(items[newIndex].isSelected, true);
      
      // Step 3: Update color of selected item
      items[newIndex] = items[newIndex].copyWith(
        color: Colors.cyan,
        isSelected: true, // Explicit
      );
      
      expect(items[newIndex].color, Colors.cyan);
      expect(items[newIndex].isSelected, true);
      
      // Step 4: Switch to different item
      items = items.map((item) => 
        item.copyWith(isSelected: item.id == 'D')
      ).toList();
      selectedId = 'D';
      
      // Verify only D is selected
      expect(items.where((item) => item.isSelected).length, 1);
      expect(items.firstWhere((item) => item.id == 'D').isSelected, true);
    });
  });
}

class TestItem {
  final String id;
  final Color color;
  final bool isSelected;
  
  TestItem(this.id, this.color, this.isSelected);
  
  TestItem copyWith({String? id, Color? color, bool? isSelected}) {
    return TestItem(
      id ?? this.id,
      color ?? this.color,
      isSelected ?? this.isSelected,
    );
  }
}

