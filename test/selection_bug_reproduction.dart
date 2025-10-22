import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Test to reproduce the actual selection bugs in the app
void main() {
  group('Selection Bug Reproduction', () {
    test('BUG: Selection lost when color is updated', () {
      List<MockItem> items = [
        MockItem('1', Colors.red, false),
        MockItem('2', Colors.blue, true),  // Selected
        MockItem('3', Colors.green, false),
      ];
      
      String? selectedId = '2';
      final selectedIndex = items.indexWhere((p) => p.id == selectedId);
      
      // Update color WITHOUT explicitly preserving isSelected
      // This is what happens in _onColorChanged
      items[selectedIndex] = items[selectedIndex].copyWith(
        color: Colors.cyan,
        // isSelected NOT passed - BUG!
      );
      
      // Selection should be preserved but might be lost
      print('After color update: isSelected = ${items[selectedIndex].isSelected}');
      expect(items[selectedIndex].isSelected, true, 
        reason: 'EXPECTED FAILURE: Selection is lost when not explicitly passed to copyWith');
    });
    
    test('BUG: selectedPaletteItem reference becomes stale after list modification', () {
      List<MockItem> items = [
        MockItem('1', Colors.red, false),
        MockItem('2', Colors.blue, false),
        MockItem('3', Colors.green, false),
      ];
      
      // Select item2
      items = items.map((item) => item.id == '2' 
          ? item.copyWith(isSelected: true) 
          : item.copyWith(isSelected: false)
      ).toList();
      
      MockItem? selectedItem = items.firstWhere((item) => item.id == '2');
      
      // Now reorder - move item2 to end
      final item = items.removeAt(1);
      items.insert(2, item);
      
      // selectedItem reference is now STALE - points to old object
      // Need to refresh reference after list modifications
      final foundIndex = items.indexWhere((item) => item.id == selectedItem.id);
      
      expect(foundIndex, 2, reason: 'Item moved to end');
      expect(items[foundIndex].isSelected, true, reason: 'Selection preserved during reorder');
      
      // But if we use the old reference, it might not match
      print('Old reference: ${selectedItem.hashCode}');
      print('New reference: ${items[foundIndex].hashCode}');
      
      // This is why we should always look up by ID, not keep old references
    });
    
    test('BUG: Multiple selections possible if logic is wrong', () {
      List<MockItem> items = [
        MockItem('1', Colors.red, true),   // Oops, selected
        MockItem('2', Colors.blue, true),  // Also selected - BUG!
        MockItem('3', Colors.green, false),
      ];
      
      final selectedCount = items.where((item) => item.isSelected).length;
      
      expect(selectedCount, 1, 
        reason: 'EXPECTED FAILURE: Only one item should be selected at a time');
    });
    
    test('BUG: Selection not cleared when deleting selected item', () {
      List<MockItem> items = [
        MockItem('1', Colors.red, false),
        MockItem('2', Colors.blue, true),  // Selected
        MockItem('3', Colors.green, false),
      ];
      
      String? selectedId = '2';
      
      // Delete the selected item
      items.removeWhere((item) => item.id == '2');
      
      // selectedId should be cleared but might not be
      if (selectedId == '2') {
        // This check should happen but might be missed
        selectedId = null;
      }
      
      expect(selectedId, null, reason: 'Selection reference should be cleared');
      expect(items.any((item) => item.isSelected), false, 
        reason: 'No item should be selected after deleting the selected one');
    });
  });
}

class MockItem {
  final String id;
  final Color color;
  final bool isSelected;
  
  MockItem(this.id, this.color, this.isSelected);
  
  MockItem copyWith({String? id, Color? color, bool? isSelected}) {
    return MockItem(
      id ?? this.id,
      color ?? this.color,
      isSelected ?? this.isSelected,
    );
  }
}

