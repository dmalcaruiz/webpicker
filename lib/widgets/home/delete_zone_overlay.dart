import 'package:flutter/material.dart';

// Drag-to-delete zone overlay
class DeleteZoneOverlay extends StatelessWidget {
  final bool isDragging;
  final bool isInDeleteZone;

  const DeleteZoneOverlay({
    super.key,
    required this.isDragging,
    required this.isInDeleteZone,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: isDragging ? 1.0 : 0.0,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          decoration: BoxDecoration(
            color: isInDeleteZone
                ? Colors.red.shade700.withOpacity(0.95)
                : Colors.red.shade600.withOpacity(0.85),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.4),
              width: 2,
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.delete,
                color: Colors.white,
                size: 32,
              ),
              SizedBox(width: 12),
              Text(
                '',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
