import 'package:flutter/material.dart';
import '../../cyclop_eyedropper/eyedropper_button.dart';
import '../../services/clipboard_service.dart';
import '../../cyclop_eyedropper/eye_dropper_layer.dart';

/// Global action buttons for copy, paste, and eyedropper
///
/// Features:
/// - Copy current color to clipboard with preview
/// - Applies ICC filter to copy if "Only Real Pigments" mode is enabled
/// - Paste color from clipboard with preview
/// - Eyedropper for picking colors from screen
class GlobalActionButtons extends StatefulWidget {
  /// Current color being edited (unfiltered)
  final Color? currentColor;

  /// Callback when color is pasted or picked
  final Function(Color) onColorSelected;

  /// Callback when copy action is performed
  final VoidCallback? onCopy;

  /// Optional color filter to apply before copying (e.g., ICC profile filter)
  /// If provided, this transforms the color before copying to clipboard
  final Color Function(Color)? colorFilter;

  const GlobalActionButtons({
    super.key,
    required this.currentColor,
    required this.onColorSelected,
    this.onCopy,
    this.colorFilter,
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
  /// Applies color filter (if provided) before copying to ensure
  /// the copied color matches what's displayed on screen.
  Future<void> _handleCopy() async {
    if (widget.currentColor != null) {
      // Apply filter if provided (e.g., ICC profile filter for "Only Real Pigments")
      final colorToCopy = widget.colorFilter != null
          ? widget.colorFilter!(widget.currentColor!)
          : widget.currentColor!;

      await ClipboardService.copyColorToClipboard(colorToCopy);
      widget.onCopy?.call();

      // Update clipboard preview with the filtered color
      setState(() {
        _clipboardColor = colorToCopy;
      });

      // Show feedback with the actual copied color hex
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Copied ${ClipboardService.colorToHex(colorToCopy)}'),
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

  // New method for eyedropper logic
  Future<void> _handleEyedropper(Color color) async {
    widget.onColorSelected(color);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Picked ${ClipboardService.colorToHex(color)}'),
          duration: const Duration(milliseconds: 100),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.black87,
        ),
      );
    }
  }

  void _startEyedropper() {
    try {
      Future.delayed(
        const Duration(milliseconds: 50),
        () => EyeDrop.of(context).capture(context, _handleEyedropper, null),
      );
    } catch (err) {
      debugPrint('EyeDrop capture error: $err');
      // Optionally show a SnackBar or other feedback if eyedropper fails to start
    }
  }

  /// Determines if a color is light enough to warrant dark text/icons.
  /// This is a simplified check based on perceived lightness (luminance).
  bool _isLightColor(Color color) {
    // Calculate luminance (perceived lightness) using a common formula
    final double luminance = (0.299 * color.red + 0.587 * color.green + 0.114 * color.blue) / 255;
    return luminance > 0.5; // Adjust threshold as needed
  }

  Color _getTextColor(Color backgroundColor) {
    return _isLightColor(backgroundColor) ? Colors.black : Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    // Apply filter to preview color if provided
    final displayColor = widget.currentColor != null && widget.colorFilter != null
        ? widget.colorFilter!(widget.currentColor!)
        : widget.currentColor;

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
            previewColor: displayColor,
            tooltip: displayColor != null
                ? 'Copy ${ClipboardService.colorToHex(displayColor)}'
                : 'No color to copy',
            onPanStart: widget.currentColor != null ? (details) => _startEyedropper() : null,
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
    GestureDragStartCallback? onPanStart,
  }) {
    final isEnabled = onPressed != null;
    
    Color buttonBgColor = const Color.fromARGB(255, 0, 0, 0).withValues(alpha: 0.15); // Default enabled color
    Color buttonBorderColor = const Color.fromARGB(255, 0, 0, 0).withValues(alpha: 0.3);
    Color textColor = Colors.black; // Default text color

    if (previewColor != null && isEnabled) {
      buttonBgColor = previewColor;
      buttonBorderColor = previewColor.withOpacity(0.8); // Slightly different for border
      textColor = _getTextColor(previewColor);
    } else if (!isEnabled) {
      buttonBgColor = const Color.fromARGB(255, 0, 0, 0).withValues(alpha: 0.05); // Disabled color
      buttonBorderColor = const Color.fromARGB(255, 0, 0, 0).withValues(alpha: 0.1);
      textColor = Colors.black.withValues(alpha: 0.3); // Disabled text color
    }

    return Tooltip(
      message: tooltip ?? label,
      child: GestureDetector(
        onTap: isEnabled ? onPressed : onTap,
        onPanStart: onPanStart, // Change this line
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: buttonBgColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: buttonBorderColor,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Icon(
                icon,
                color: textColor,
                size: 18,
              ),
              
              const SizedBox(width: 6),
              
              // Label
              Text(
                label,
                style: TextStyle(
                  color: textColor,
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
        onColor: (color) {_handleEyedropper(color);},
        icon: Icons.colorize,
        iconColor: Colors.black,
        backgroundColor: Colors.white.withOpacity(0.9), // Consistent with other buttons
        borderColor: Colors.black.withOpacity(0.3),     // Consistent with other buttons
        foregroundColor: Colors.black,                   // Consistent with other buttons
      ),
    );
  }
}
