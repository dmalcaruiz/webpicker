import 'package:flutter/material.dart';
import '../common/global_action_buttons.dart';
import '../common/undo_redo_buttons.dart';
import '../../services/undo_redo_manager.dart';

/// Row containing global action buttons and undo/redo controls
class ActionButtonsRow extends StatelessWidget {
  /// Current color for copy/paste operations
  final Color? currentColor;
  
  /// Callback when a color is selected via eyedropper or paste
  final Function(Color) onColorSelected;
  
  /// Undo/redo manager instance
  final UndoRedoManager undoRedoManager;
  
  /// Callback for undo action
  final VoidCallback onUndo;
  
  /// Callback for redo action
  final VoidCallback onRedo;
  
  const ActionButtonsRow({
    super.key,
    required this.currentColor,
    required this.onColorSelected,
    required this.undoRedoManager,
    required this.onUndo,
    required this.onRedo,
  });
  
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Copy/Paste/Eyedropper buttons
        Expanded(
          child: GlobalActionButtons(
            currentColor: currentColor,
            onColorSelected: onColorSelected,
          ),
        ),
        
        // Undo/Redo buttons
        UndoRedoButtons(
          undoRedoManager: undoRedoManager,
          onUndo: onUndo,
          onRedo: onRedo,
        ),
      ],
    );
  }
}

