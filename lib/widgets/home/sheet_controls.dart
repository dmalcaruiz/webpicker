import 'package:flutter/material.dart';
import 'package:snapping_sheet_2/snapping_sheet.dart';

/// Controls for expanding/collapsing the snapping sheet
class SheetControls extends StatelessWidget {
  /// Sheet controller for programmatic control
  final SnappingSheetController controller;
  
  const SheetControls({
    super.key,
    required this.controller,
  });
  
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => controller.snapToPosition(
              const SnappingPosition.factor(positionFactor: 0.3),
            ),
            icon: const Icon(Icons.keyboard_arrow_down),
            label: const Text('Collapse'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.shade200,
              foregroundColor: Colors.black87,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => controller.snapToPosition(
              const SnappingPosition.factor(positionFactor: 1.0),
            ),
            icon: const Icon(Icons.keyboard_arrow_up),
            label: const Text('Expand'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.shade200,
              foregroundColor: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}

