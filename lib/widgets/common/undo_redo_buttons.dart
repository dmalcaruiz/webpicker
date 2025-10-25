import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/undo_redo_manager.dart';

/// Undo/Redo buttons with keyboard shortcuts
class UndoRedoButtons extends StatelessWidget {
  /// Undo/Redo manager instance
  final UndoRedoManager undoRedoManager;
  
  /// Callback when undo is triggered
  final VoidCallback onUndo;
  
  /// Callback when redo is triggered
  final VoidCallback onRedo;
  
  const UndoRedoButtons({
    super.key,
    required this.undoRedoManager,
    required this.onUndo,
    required this.onRedo,
  });
  
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: undoRedoManager,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Undo button
            _buildButton(
              icon: Icons.undo,
              tooltip: undoRedoManager.canUndo 
                  ? 'Undo: ${undoRedoManager.getUndoPreview()}'
                  : 'Nothing to undo',
              isEnabled: undoRedoManager.canUndo,
              onPressed: onUndo,
              shortcut: 'Ctrl+Z',
            ),
            
            const SizedBox(width: 8),
            
            // Redo button
            _buildButton(
              icon: Icons.redo,
              tooltip: undoRedoManager.canRedo 
                  ? 'Redo: ${undoRedoManager.getRedoPreview()}'
                  : 'Nothing to redo',
              isEnabled: undoRedoManager.canRedo,
              onPressed: onRedo,
              shortcut: 'Ctrl+Y',
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildButton({
    required IconData icon,
    required String tooltip,
    required bool isEnabled,
    required VoidCallback onPressed,
    required String shortcut,
  }) {
    return Tooltip(
      message: '$tooltip\n$shortcut',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isEnabled ? onPressed : null,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isEnabled 
                  ? Colors.black.withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isEnabled 
                    ? Colors.black.withValues(alpha: 0.3)
                    : Colors.black.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              color: isEnabled ? Colors.black : Colors.black.withValues(alpha: 0.3),
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}

/// Keyboard shortcuts handler for undo/redo
class UndoRedoShortcuts extends StatelessWidget {
  final Widget child;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  
  const UndoRedoShortcuts({
    super.key,
    required this.child,
    required this.onUndo,
    required this.onRedo,
  });
  
  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        // Ctrl+Z for undo
        const SingleActivator(LogicalKeyboardKey.keyZ, control: true): onUndo,
        
        // Ctrl+Y for redo
        const SingleActivator(LogicalKeyboardKey.keyY, control: true): onRedo,
        
        // Ctrl+Shift+Z for redo (alternative)
        const SingleActivator(
          LogicalKeyboardKey.keyZ,
          control: true,
          shift: true,
        ): onRedo,
      },
      child: Focus(
        autofocus: true,
        child: child,
      ),
    );
  }
}
