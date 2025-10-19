import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Widget for adjusting numeric values with +/- buttons and editable text field
/// 
/// Features:
/// - Black background with white text
/// - Minus button on left, plus button on right
/// - Editable text field in center
/// - Configurable step size and decimal places
class ValueAdjuster extends StatefulWidget {
  /// Current value
  final double value;
  
  /// Minimum allowed value
  final double min;
  
  /// Maximum allowed value
  final double max;
  
  /// Step size for +/- buttons
  final double step;
  
  /// Number of decimal places to display
  final int decimalPlaces;
  
  /// Callback when value changes
  final Function(double) onChanged;
  
  /// Constructor
  /// 
  /// Step 1: Initialize with all required parameters
  const ValueAdjuster({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.step,
    required this.decimalPlaces,
    required this.onChanged,
  });
  
  @override
  State<ValueAdjuster> createState() => _ValueAdjusterState();
}

class _ValueAdjusterState extends State<ValueAdjuster> {
  /// Text controller for the editable field
  late TextEditingController _controller;
  
  /// Focus node to handle text field focus
  final FocusNode _focusNode = FocusNode();
  
  @override
  void initState() {
    super.initState();
    // Step 2: Initialize text controller with current value
    _controller = TextEditingController(
      text: widget.value.toStringAsFixed(widget.decimalPlaces),
    );
  }
  
  @override
  void didUpdateWidget(ValueAdjuster oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Step 3: Update text when value changes externally (e.g., from slider)
    if (widget.value != oldWidget.value && !_focusNode.hasFocus) {
      _controller.text = widget.value.toStringAsFixed(widget.decimalPlaces);
    }
  }
  
  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }
  
  /// Handle increment button press
  /// 
  /// Step 4: Increase value by step, clamping to max
  void _increment() {
    final newValue = (widget.value + widget.step).clamp(widget.min, widget.max);
    widget.onChanged(newValue);
  }
  
  /// Handle decrement button press
  /// 
  /// Step 5: Decrease value by step, clamping to min
  void _decrement() {
    final newValue = (widget.value - widget.step).clamp(widget.min, widget.max);
    widget.onChanged(newValue);
  }
  
  /// Handle text field submission
  /// 
  /// Step 6: Parse entered text and update value
  void _handleTextSubmit() {
    final text = _controller.text.trim();
    final parsed = double.tryParse(text);
    
    if (parsed != null) {
      final clamped = parsed.clamp(widget.min, widget.max);
      widget.onChanged(clamped);
    } else {
      // Reset to current value if parse fails
      _controller.text = widget.value.toStringAsFixed(widget.decimalPlaces);
    }
    
    // Unfocus to hide keyboard
    _focusNode.unfocus();
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Step 7: Minus button
          _buildButton(
            icon: Icons.remove,
            onPressed: _decrement,
          ),
          
          // Step 8: Editable text field
          SizedBox(
            width: 80,
            height: 36,
            child: Center(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1.0,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.-]')),
                ],
                onSubmitted: (_) => _handleTextSubmit(),
                onTapOutside: (_) => _handleTextSubmit(),
              ),
            ),
          ),
          
          // Step 9: Plus button
          _buildButton(
            icon: Icons.add,
            onPressed: _increment,
          ),
        ],
      ),
    );
  }
  
  /// Build +/- button widget
  /// 
  /// Step 10: Create uniform button with icon
  Widget _buildButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 36,
      height: 36,
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 18),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

