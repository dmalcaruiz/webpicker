import 'package:flutter/material.dart';

/// Sheet grabbing handle widget with pin functionality and chips
class SheetGrabbingHandle extends StatelessWidget {
  /// States of the toggleable chips
  final List<bool> chipStates;
  
  /// Callback when a chip is toggled
  final Function(int index) onChipToggle;
  
  const SheetGrabbingHandle({
    super.key,
    required this.chipStates,
    required this.onChipToggle,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 12,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          
          // Drag handle indicator
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          // Toggleable chips
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(chipStates.length, (index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: GestureDetector(
                  onTap: () => onChipToggle(index),
                  child: Container(
                    width: 32,
                    height: 24,
                    decoration: BoxDecoration(
                      color: chipStates[index] ? Colors.black : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: chipStates[index] ? Colors.black : Colors.grey.shade400,
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: chipStates[index] ? Colors.white : Colors.grey.shade600,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

