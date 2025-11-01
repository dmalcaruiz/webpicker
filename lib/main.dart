import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'cyclop_eyedropper/eye_dropper_layer.dart';
import 'screens/home_screen.dart';
import 'state/color_editor_provider.dart';
import 'state/grid_provider.dart';
import 'state/extreme_colors_provider.dart';
import 'state/bg_color_provider.dart';
import 'state/settings_provider.dart';
import 'utils/global_pointer_tracker.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ColorEditorProvider()),
        ChangeNotifierProvider(create: (_) => GridProvider()),
        ChangeNotifierProvider(create: (_) => ExtremeColorsProvider()),
        ChangeNotifierProvider(create: (_) => BgColorProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: GlobalPointerTrackerProvider(
          child: EyeDrop(child: const HomeScreen()),
        ),
      ),
    );
  }
}