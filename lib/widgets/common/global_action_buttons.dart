import 'package:flutter/material.dart';
import '../../cyclop_eyedropper/eyedropper_button.dart';
import '../../services/clipboard_service.dart';

/// Global action buttons for copy, paste, and eyedropper
/// 
/// Features:
/// - Copy current color to clipboard with preview
/// - Paste color from clipboard with preview
/// - Eyedropper for picking colors from screen
class GlobalActionButtons extends StatefulWidget {
  /// Current color being edited
  final Color? currentColor;
  
  /// Callback when color is pasted or picked
  final Function(Color) onColorSelected;
  
  /// Callback when copy action is performed
  final VoidCallback? onCopy;
  
  const GlobalActionButtons({
    super.key,
    required this.currentColor,
    required this.onColorSelected,
    this.onCopy,
  });
  
  @override
  State<GlobalActionButtons> createState() => _GlobalActionButtonsState();
}

class _GlobalActionButtonsState extends State<GlobalActionButtons> {
  /// Color currently in clipboard
  Color? _clipboardColor;
  
  /// Whether we're checking clipboard
  bool _isCheckingClipboard = false;
  
  @override
  void initState() {
    super.initState();
    _checkClipboard();
  }
  
  /// Check if clipboard has a valid color
  Future<void> _checkClipboard() async {
    if (_isCheckingClipboard) return;
    
    setState(() {
      _isCheckingClipboard = true;
    });
    
    final color = await ClipboardService.getColorFromClipboard();
    
    if (mounted) {
      setState(() {
        _clipboardColor = color;
        _isCheckingClipboard = false;
      });
    }
  }
  
  /// Handle copy action
  Future<void> _handleCopy() async {
    if (widget.currentColor != null) {
      await ClipboardService.copyColorToClipboard(widget.currentColor!);
      widget.onCopy?.call();
      
      // Update clipboard preview
      setState(() {
        _clipboardColor = widget.currentColor;
      });
      
      // Show feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Copied ${ClipboardService.colorToHex(widget.currentColor!)}'),
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.black87,
          ),
        );
      }
    }
  }
  
  /// Handle paste action
  Future<void> _handlePaste() async {
    final color = await ClipboardService.getColorFromClipboard();
    if (color != null) {
      widget.onColorSelected(color);
      
      // Show feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pasted ${ClipboardService.colorToHex(color)}'),
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.black87,
          ),
        );
      }
    } else {
      // Show error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No valid color in clipboard'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Copy button
          _buildActionButton(
            icon: Icons.copy,
            label: 'Copy',
            onPressed: widget.currentColor != null ? _handleCopy : null,
            previewColor: widget.currentColor,
            tooltip: widget.currentColor != null 
                ? 'Copy ${ClipboardService.colorToHex(widget.currentColor!)}'
                : 'No color to copy',
          ),
          
          const SizedBox(width: 12),
          
          // Paste button
          _buildActionButton(
            icon: Icons.paste,
            label: 'Paste',
            onPressed: _clipboardColor != null ? _handlePaste : null,
            previewColor: _clipboardColor,
            tooltip: _clipboardColor != null 
                ? 'Paste ${ClipboardService.colorToHex(_clipboardColor!)}'
                : 'No color in clipboard',
            onTap: _checkClipboard, // Check clipboard on tap if disabled
          ),
          
          const SizedBox(width: 12),
          
          // Eyedropper button
          _buildEyedropperButton(),
        ],
      ),
    );
  }
  
  /// Build a single action button with color preview
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    Color? previewColor,
    String? tooltip,
    VoidCallback? onTap,
  }) {
    final isEnabled = onPressed != null;
    
    return Tooltip(
      message: tooltip ?? label,
      child: GestureDetector(
        onTap: isEnabled ? onPressed : onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isEnabled 
                ? Colors.white.withValues(alpha: 0.15)
                : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isEnabled 
                  ? Colors.white.withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Color preview indicator
              if (previewColor != null) ...[
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: previewColor,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.5),
                      width: 1,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              
              // Icon
              Icon(
                icon,
                color: isEnabled ? Colors.white : Colors.white.withValues(alpha: 0.3),
                size: 18,
              ),
              
              const SizedBox(width: 6),
              
              // Label
              Text(
                label,
                style: TextStyle(
                  color: isEnabled ? Colors.white : Colors.white.withValues(alpha: 0.3),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  /// Build eyedropper button with Cyclop integration
  Widget _buildEyedropperButton() {
    return Tooltip(
      message: 'Pick color from screen',
      child: EyedropperButton(
        onColor: (color) {
          widget.onColorSelected(color);
          
          // Show feedback
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Picked ${ClipboardService.colorToHex(color)}'),
                duration: const Duration(seconds: 1),
                behavior: SnackBarBehavior.floating,
                backgroundColor: Colors.black87,
              ),
            );
          }
        },
        icon: Icons.colorize,
        iconColor: Colors.white,
      ),
    );
  }
}
