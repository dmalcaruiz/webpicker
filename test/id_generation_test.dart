import 'package:flutter_test/flutter_test.dart';

/// Test to verify ID generation doesn't produce duplicates
void main() {
  group('ID Generation Tests', () {
    test('Should generate unique IDs', () {
      final ids = <String>{};
      
      // Generate 1000 IDs rapidly
      for (int i = 0; i < 1000; i++) {
        final id = _generateId();
        expect(ids.contains(id), false, 
          reason: 'Duplicate ID generated: $id');
        ids.add(id);
      }
      
      expect(ids.length, 1000);
    });
    
    test('Should not generate null or empty IDs', () {
      for (int i = 0; i < 100; i++) {
        final id = _generateId();
        expect(id, isNotNull);
        expect(id, isNotEmpty);
        expect(id.startsWith('color_'), true);
      }
    });
    
    test('IDs should have sufficient uniqueness', () {
      final id1 = _generateId();
      // Wait a tiny bit
      final id2 = _generateId();
      
      expect(id1, isNot(equals(id2)));
    });
  });
}

/// Simulate the ID generation from ColorPaletteItem (with counter)
int _counter = 0;

String _generateId() {
  _counter++;
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  return 'color_${timestamp}_$_counter';
}

