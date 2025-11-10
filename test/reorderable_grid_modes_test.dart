import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:learning/state/color_grid_provider.dart';
import 'package:learning/state/settings_provider.dart';
import 'package:learning/widgets/color%20grid/reorderable_color_grid_view.dart';

// Test reordering in different grid layout and box height modes
void main() {
  group('ReorderableColorGridView - Different Modes', () {
    late ColorGridProvider gridProvider;
    late SettingsProvider settingsProvider;

    setUp(() {
      gridProvider = ColorGridProvider();
      settingsProvider = SettingsProvider();

      // Add test colors to provider using addColor
      gridProvider.addColor(const Color(0xFFFF0000), name: 'red', selectNew: false);
      gridProvider.addColor(const Color(0xFF00FF00), name: 'green', selectNew: false);
      gridProvider.addColor(const Color(0xFF0000FF), name: 'blue', selectNew: false);
      gridProvider.addColor(const Color(0xFFFFFF00), name: 'yellow', selectNew: false);
      gridProvider.addColor(const Color(0xFFFF00FF), name: 'magenta', selectNew: false);
      gridProvider.addColor(const Color(0xFF00FFFF), name: 'cyan', selectNew: false);
    });

    Widget createTestWidget({
      required GridLayoutMode layoutMode,
      required BoxHeightMode heightMode,
      double? availableHeight,
    }) {
      settingsProvider.setGridLayoutMode(layoutMode);

      return MaterialApp(
        home: Scaffold(
          body: MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: gridProvider),
              ChangeNotifierProvider.value(value: settingsProvider),
            ],
            child: SizedBox(
              width: 400,
              height: availableHeight ?? 600,
              child: ReorderableColorGridView(
                onReorder: (oldIndex, newIndex) {
                  gridProvider.reorderItems(oldIndex, newIndex);
                },
                onItemTap: (item) {},
                onItemLongPress: (item) {},
                onItemDelete: (item) {},
                onAddColor: () {},
                layoutMode: layoutMode,
                heightMode: heightMode,
                availableHeight: availableHeight,
                bgColor: Colors.white,
                showAddButton: false,
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('Responsive mode with proportional height - reorder forward',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        layoutMode: GridLayoutMode.responsive,
        heightMode: BoxHeightMode.proportional,
      ));
      await tester.pumpAndSettle();

      // Verify initial order
      expect(gridProvider.items[0].name, 'red');
      expect(gridProvider.items[1].name, 'green');
      expect(gridProvider.items[2].name, 'blue');

      // Simulate reorder: move green (index 1) after blue (to index 2)
      gridProvider.reorderItems(1, 2);
      await tester.pumpAndSettle();

      // Verify new order
      expect(gridProvider.items[0].name, 'red');
      expect(gridProvider.items[1].name, 'blue');
      expect(gridProvider.items[2].name, 'green');
    });

    testWidgets('Fixed size mode with proportional height - reorder forward',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        layoutMode: GridLayoutMode.fixedSize,
        heightMode: BoxHeightMode.proportional,
      ));
      await tester.pumpAndSettle();

      // Verify initial order
      expect(gridProvider.items[0].name, 'red');
      expect(gridProvider.items[1].name, 'green');

      // Simulate reorder: move green (index 1) after blue (to index 2)
      gridProvider.reorderItems(1, 2);
      await tester.pumpAndSettle();

      // Verify new order
      expect(gridProvider.items[0].name, 'red');
      expect(gridProvider.items[1].name, 'blue');
      expect(gridProvider.items[2].name, 'green');
    });

    testWidgets('Responsive mode with fillContainer height - reorder forward',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        layoutMode: GridLayoutMode.responsive,
        heightMode: BoxHeightMode.fillContainer,
        availableHeight: 500,
      ));
      await tester.pumpAndSettle();

      // Verify initial order
      expect(gridProvider.items[0].name, 'red');
      expect(gridProvider.items[1].name, 'green');

      // Simulate reorder: move green (index 1) after blue (to index 2)
      gridProvider.reorderItems(1, 2);
      await tester.pumpAndSettle();

      // Verify new order
      expect(gridProvider.items[0].name, 'red');
      expect(gridProvider.items[1].name, 'blue');
      expect(gridProvider.items[2].name, 'green');
    });

    testWidgets(
        'Fixed size mode with fillContainer height - reorder forward (CRITICAL)',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        layoutMode: GridLayoutMode.fixedSize,
        heightMode: BoxHeightMode.fillContainer,
        availableHeight: 500,
      ));
      await tester.pumpAndSettle();

      // Verify initial order
      expect(gridProvider.items[0].name, 'red');
      expect(gridProvider.items[1].name, 'green');
      expect(gridProvider.items[2].name, 'blue');

      // Simulate reorder: move green (index 1) after blue (to index 2)
      gridProvider.reorderItems(1, 2);
      await tester.pumpAndSettle();

      // Verify new order
      expect(gridProvider.items[0].name, 'red');
      expect(gridProvider.items[1].name, 'blue');
      expect(gridProvider.items[2].name, 'green');
    });

    testWidgets(
        'Fixed size mode with fillContainer height - reorder backward (CRITICAL)',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        layoutMode: GridLayoutMode.fixedSize,
        heightMode: BoxHeightMode.fillContainer,
        availableHeight: 500,
      ));
      await tester.pumpAndSettle();

      // Verify initial order
      expect(gridProvider.items[0].name, 'red');
      expect(gridProvider.items[2].name, 'blue');
      expect(gridProvider.items[3].name, 'yellow');

      // Simulate reorder: move yellow (index 3) before green (to index 1)
      gridProvider.reorderItems(3, 1);
      await tester.pumpAndSettle();

      // Verify new order
      expect(gridProvider.items[0].name, 'red');
      expect(gridProvider.items[1].name, 'yellow');
      expect(gridProvider.items[2].name, 'green');
      expect(gridProvider.items[3].name, 'blue');
    });

    testWidgets(
        'Fixed size mode with fillContainer height - multiple reorders (CRITICAL)',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        layoutMode: GridLayoutMode.fixedSize,
        heightMode: BoxHeightMode.fillContainer,
        availableHeight: 500,
      ));
      await tester.pumpAndSettle();

      // Initial: red, green, blue, yellow, magenta, cyan

      // Move red to end
      gridProvider.reorderItems(0, 5);
      await tester.pumpAndSettle();
      expect(gridProvider.items.map((e) => e.name).toList(),
          ['green', 'blue', 'yellow', 'magenta', 'cyan', 'red']);

      // Move cyan to start
      gridProvider.reorderItems(4, 0);
      await tester.pumpAndSettle();
      expect(gridProvider.items.map((e) => e.name).toList(),
          ['cyan', 'green', 'blue', 'yellow', 'magenta', 'red']);

      // Move magenta after blue
      gridProvider.reorderItems(4, 3);
      await tester.pumpAndSettle();
      expect(gridProvider.items.map((e) => e.name).toList(),
          ['cyan', 'green', 'blue', 'magenta', 'yellow', 'red']);
    });

    testWidgets('Horizontal mode with fillContainer height - reorder',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        layoutMode: GridLayoutMode.horizontal,
        heightMode: BoxHeightMode.fillContainer,
        availableHeight: 500,
      ));
      await tester.pumpAndSettle();

      // Verify initial order
      expect(gridProvider.items[0].name, 'red');
      expect(gridProvider.items[1].name, 'green');

      // Simulate reorder
      gridProvider.reorderItems(1, 2);
      await tester.pumpAndSettle();

      // Verify new order
      expect(gridProvider.items[0].name, 'red');
      expect(gridProvider.items[1].name, 'blue');
      expect(gridProvider.items[2].name, 'green');
    });

    testWidgets('Fixed size mode with fixed height - reorder',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        layoutMode: GridLayoutMode.fixedSize,
        heightMode: BoxHeightMode.fixed,
      ));
      await tester.pumpAndSettle();

      // Verify initial order
      expect(gridProvider.items[0].name, 'red');
      expect(gridProvider.items[1].name, 'green');

      // Simulate reorder
      gridProvider.reorderItems(1, 2);
      await tester.pumpAndSettle();

      // Verify new order
      expect(gridProvider.items[0].name, 'red');
      expect(gridProvider.items[1].name, 'blue');
      expect(gridProvider.items[2].name, 'green');
    });

    testWidgets(
        'Edge case: Reorder first to last in fillContainer + fixedSize',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        layoutMode: GridLayoutMode.fixedSize,
        heightMode: BoxHeightMode.fillContainer,
        availableHeight: 500,
      ));
      await tester.pumpAndSettle();

      // Move first item to last position
      gridProvider.reorderItems(0, 5);
      await tester.pumpAndSettle();

      expect(gridProvider.items[0].name, 'green');
      expect(gridProvider.items[5].name, 'red');
    });

    testWidgets(
        'Edge case: Reorder last to first in fillContainer + fixedSize',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        layoutMode: GridLayoutMode.fixedSize,
        heightMode: BoxHeightMode.fillContainer,
        availableHeight: 500,
      ));
      await tester.pumpAndSettle();

      // Move last item to first position
      gridProvider.reorderItems(5, 0);
      await tester.pumpAndSettle();

      expect(gridProvider.items[0].name, 'cyan');
      expect(gridProvider.items[5].name, 'magenta');
    });
  });
}
