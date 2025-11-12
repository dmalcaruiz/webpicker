import 'package:flutter/material.dart';
import '../../utils/ui_color_utils.dart';
import '../home/action_buttons_row.dart';
import '../../models/extreme_color_item.dart';
import '../../services/undo_redo_service.dart';

// Bottom action bar with background color button and action buttons
class BottomActionBar extends StatelessWidget {
  final Color bgColor;
  final bool isBgColorSelected;
  final Color? currentColor;
  final String? selectedExtremeId;
  final ExtremeColorItem leftExtreme;
  final ExtremeColorItem rightExtreme;
  final VoidCallback onBgColorBoxTap;
  final void Function(DragStartDetails) onBgColorPanStart;
  final void Function(Color) onColorSelected;
  final UndoRedoService undoRedoManager;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final VoidCallback onGenerateColors;
  final Color Function(Color) colorFilter;
  final double bgLightness;
  final double bgChroma;
  final double bgHue;
  final double bgAlpha;

  const BottomActionBar({
    super.key,
    required this.bgColor,
    required this.isBgColorSelected,
    required this.currentColor,
    required this.selectedExtremeId,
    required this.leftExtreme,
    required this.rightExtreme,
    required this.onBgColorBoxTap,
    required this.onBgColorPanStart,
    required this.onColorSelected,
    required this.undoRedoManager,
    required this.onUndo,
    required this.onRedo,
    required this.onGenerateColors,
    required this.colorFilter,
    required this.bgLightness,
    required this.bgChroma,
    required this.bgHue,
    required this.bgAlpha,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background color box that ignores pointer events
        Positioned.fill(
          child: IgnorePointer(
            ignoring: true,
            child: Container(
              color: bgColor,
            ),
          ),
        ),

        // Interactive buttons on top
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          child: Row(
            children: [
              // Other action buttons
              Expanded(
                child: ActionButtonsRow(
                  currentColor: currentColor,
                  selectedExtremeId: selectedExtremeId,
                  leftExtreme: leftExtreme,
                  rightExtreme: rightExtreme,
                  onColorSelected: onColorSelected,
                  undoRedoManager: undoRedoManager,
                  onUndo: onUndo,
                  onRedo: onRedo,
                  onGenerateColors: onGenerateColors,
                  colorFilter: colorFilter,
                  bgColor: bgColor,
                ),
              ),

              // Background color button (acts like a grid box)
              GestureDetector(
                onTap: onBgColorBoxTap,
                onPanStart: onBgColorPanStart,
                child: Container(
                  width: 48,
                  height: 38,
                  decoration: BoxDecoration(
                    color: colorFilter(bgColor),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isBgColorSelected
                          ? Colors.black
                          : getTextColor(bgColor).withOpacity(0.3),
                      width: isBgColorSelected ? 3 : 2,
                    ),
                  ),
                  child: Icon(
                    Icons.format_paint,
                    color: getTextColor(bgColor).withOpacity(isBgColorSelected ? 0.9 : 0.7),
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
