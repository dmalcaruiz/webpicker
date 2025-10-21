import 'package:flutter/material.dart';
import '../widgets/sliders/invisible_slider.dart';

/// Example demonstrating the invisible slider with external thumb
class InvisibleSliderExample extends StatefulWidget {
  const InvisibleSliderExample({super.key});

  @override
  State<InvisibleSliderExample> createState() => _InvisibleSliderExampleState();
}

class _InvisibleSliderExampleState extends State<InvisibleSliderExample> {
  double _value = 0.5;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: const Text('Invisible Slider Demo'),
        backgroundColor: Colors.grey[800],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text(
              'Value: ${_value.toStringAsFixed(2)}',
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 40),
            
            // Example 1: Thumb below slider
            const Text(
              'Thumb Below Slider:',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 20),
            InvisibleSliderWithExternalThumb(
              value: _value,
              min: 0.0,
              max: 1.0,
              onChanged: (value) => setState(() => _value = value),
              background: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.red, Colors.blue],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              thumbColor: Color.lerp(Colors.red, Colors.blue, _value)!,
              showCheckerboard: false,
              thumbOffset: 8.0, // 8px below
            ),
            
            const SizedBox(height: 60),
            
            // Example 2: Thumb above slider
            const Text(
              'Thumb Above Slider:',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 20),
            InvisibleSliderWithExternalThumb(
              value: _value,
              min: 0.0,
              max: 1.0,
              onChanged: (value) => setState(() => _value = value),
              background: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.green, Colors.purple],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              thumbColor: Color.lerp(Colors.green, Colors.purple, _value)!,
              showCheckerboard: true,
              thumbOffset: -35.0, // 35px above (negative = above)
            ),
            
            const SizedBox(height: 60),
            
            // Example 3: Custom thumb size
            const Text(
              'Custom Thumb Size:',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 20),
            InvisibleSliderWithExternalThumb(
              value: _value,
              min: 0.0,
              max: 1.0,
              onChanged: (value) => setState(() => _value = value),
              background: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.orange, Colors.cyan],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              thumbColor: Color.lerp(Colors.orange, Colors.cyan, _value)!,
              showCheckerboard: false,
              thumbSize: 40.0, // Larger thumb
              thumbOffset: 12.0, // More spacing
            ),
          ],
        ),
      ),
    );
  }
}
