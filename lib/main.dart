import 'package:flutter/material.dart';
import 'package:cyclop/cyclop.dart';
import 'screens/home_screen.dart';
import 'widgets/common/global_gesture_detector.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GlobalGestureDetector(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: EyeDrop(child: const HomeScreen()),
      ),
    );
  }
}