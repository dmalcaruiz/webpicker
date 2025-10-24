import 'package:flutter/material.dart';
import 'cyclop_eyedropper/eye_dropper_layer.dart';
import 'screens/home_screen.dart';
import 'utils/global_pointer_tracker.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: GlobalPointerTrackerProvider(
        child: EyeDrop(child: const HomeScreen()),
      ),
    );
  }
}