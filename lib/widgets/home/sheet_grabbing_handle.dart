import 'package:flutter/material.dart';
import '../../utils/color_utils.dart'; // Import the new utility file

/// Sheet grabbing handle widget with pin functionality and chips
class SheetGrabbingHandle extends StatelessWidget {
  /// States of the toggleable chips
  final List<bool> chipStates;
  
  /// Callback when a chip is toggled
  final Function(int index) onChipToggle;

  final Color? bgColor;
  
  const SheetGrabbingHandle({
    super.key,
    required this.chipStates,
    required this.onChipToggle,
    this.bgColor,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: bgColor ?? Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: const [
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
              color: getTextColor(bgColor ?? Colors.white).withOpacity(0.4),
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
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), // Added padding
                    decoration: BoxDecoration(
                      color: chipStates[index]
                          ? getTextColor(bgColor ?? Colors.white)
                          : (bgColor ?? Colors.white).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: chipStates[index]
                            ? getTextColor(bgColor ?? Colors.white)
                            : getTextColor(bgColor ?? Colors.white).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        chipStates[index] ? ['My Picks', 'CHL', 'HSB', 'CMYK'][index] : ['My Picks', 'CHL', 'HSB', 'CMYK'][index],
                        style: TextStyle(
                          color: chipStates[index]
                              ? (getTextColor(bgColor ?? Colors.white) == Colors.black ? Colors.white : Colors.black)
                              : getTextColor(bgColor ?? Colors.white).withOpacity(0.7),
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

