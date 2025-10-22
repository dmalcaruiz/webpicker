import 'package:flutter/material.dart';

/// Button for toggling between color edit and background edit modes
class BackgroundEditButton extends StatelessWidget {
  /// Whether currently in background edit mode
  final bool isBgEditMode;
  
  /// Callback when button is pressed
  final VoidCallback onPressed;
  
  const BackgroundEditButton({
    super.key,
    required this.isBgEditMode,
    required this.onPressed,
  });
  
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(isBgEditMode ? Icons.palette : Icons.format_paint),
        label: Text(isBgEditMode ? 'Edit Colors' : 'Edit Background'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black.withValues(alpha: 0.3),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

