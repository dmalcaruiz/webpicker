import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Widget for adjusting numeric values with +/- buttons and editable text field
/// 
/// Features:
/// - Black background with white text
/// - Minus button on left, plus button on right
/// - Editable text field in center
/// - Configurable step size and decimal places
/// - Instant gesture detection for sheet dragging prevention
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
  
  /// Callback when interaction with adjuster starts/ends (for sheet dragging prevention)
  final Function(bool)? onInteractionChanged;
  
  /// Constructor
  const ValueAdjuster({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.step,
    required this.decimalPlaces,
    required this.onChanged,
    this.onInteractionChanged,
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
    _controller = TextEditingController(
      text: widget.value.toStringAsFixed(widget.decimalPlaces),
    );
  }
  
  @override
  void didUpdateWidget(ValueAdjuster oldWidget) {
    super.didUpdateWidget(oldWidget);
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
  void _increment() {
    final newValue = (widget.value + widget.step).clamp(widget.min, widget.max);
    widget.onChanged(newValue);
  }
  
  /// Handle decrement button press
  void _decrement() {
    final newValue = (widget.value - widget.step).clamp(widget.min, widget.max);
    widget.onChanged(newValue);
  }
  
  /// Handle text field submission
  void _handleTextSubmit() {
    final text = _controller.text.trim();
    final parsed = double.tryParse(text);
    
    if (parsed != null) {
      final clamped = parsed.clamp(widget.min, widget.max);
      widget.onChanged(clamped);
    } else {
      _controller.text = widget.value.toStringAsFixed(widget.decimalPlaces);
    }
    
    _focusNode.unfocus();
  }
  
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Visual buttons container
          Container(
            height: 36,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildButton(icon: Icons.remove),
                
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
                
                _buildButton(icon: Icons.add),
              ],
            ),
          ),
          
          // Individual invisible sliders for gesture detection
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Minus button slider
              SizedBox(
                width: 36,
                height: 36,
                child: SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: Colors.transparent,
                    inactiveTrackColor: Colors.transparent,
                    trackHeight: 36,
                    trackShape: const RectangularSliderTrackShape(),
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 0),
                    overlayColor: Colors.transparent,
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 0),
                    thumbColor: Colors.transparent,
                    activeTickMarkColor: Colors.transparent,
                    inactiveTickMarkColor: Colors.transparent,
                    valueIndicatorColor: Colors.transparent,
                    valueIndicatorTextStyle: const TextStyle(color: Colors.transparent),
                  ),
                  child: Slider(
                    value: 0.5,
                    min: 0.0,
                    max: 1.0,
                    onChanged: (_) {},
                    onChangeStart: (_) {
                      widget.onInteractionChanged?.call(true);
                      _decrement();
                    },
                    onChangeEnd: (_) => widget.onInteractionChanged?.call(false),
                  ),
                ),
              ),
              
              const SizedBox(width: 80, height: 36),
              
              // Plus button slider
              SizedBox(
                width: 36,
                height: 36,
                child: SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: Colors.transparent,
                    inactiveTrackColor: Colors.transparent,
                    trackHeight: 36,
                    trackShape: const RectangularSliderTrackShape(),
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 0),
                    overlayColor: Colors.transparent,
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 0),
                    thumbColor: Colors.transparent,
                    activeTickMarkColor: Colors.transparent,
                    inactiveTickMarkColor: Colors.transparent,
                    valueIndicatorColor: Colors.transparent,
                    valueIndicatorTextStyle: const TextStyle(color: Colors.transparent),
                  ),
                  child: Slider(
                    value: 0.5,
                    min: 0.0,
                    max: 1.0,
                    onChanged: (_) {},
                    onChangeStart: (_) {
                      widget.onInteractionChanged?.call(true);
                      _increment();
                    },
                    onChangeEnd: (_) => widget.onInteractionChanged?.call(false),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  /// Build button widget (visual only)
  Widget _buildButton({required IconData icon}) {
    return SizedBox(
      width: 36,
      height: 36,
      child: Center(
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}

