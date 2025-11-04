import 'dart:io';
import 'dart:typed_data';
import 'package:icc_parser/icc_parser.dart';

// Test ICC profile transformations
void main() async {
  print('=== Testing Canon PRO-1000 ICC Profile ===\n');

  try {
    // Load the ICC profile
    final profilePath = 'reference-icc/Canon ImagePROGRAPH PRO-1000.icc';
    final bytes = ByteData.view(File(profilePath).readAsBytesSync().buffer);
    final stream = DataStream(
      data: bytes,
      offset: 0,
      length: bytes.lengthInBytes,
    );

    final profile = ColorProfile.fromBytes(stream);
    print('✓ Profile loaded successfully');
    print('  Size: ${bytes.lengthInBytes} bytes\n');

    // Create forward transform (Lab → CMYK)
    final forwardTransform = ColorProfileTransform.create(
      profile: profile,
      isInput: false, // Output to printer
      intent: ColorProfileRenderingIntent.perceptual,
      interpolation: ColorProfileInterpolation.tetrahedral,
      lutType: ColorProfileTransformLutType.color,
      useD2BTags: true,
    );

    // Create reverse transform (CMYK → Lab)
    final reverseTransform = ColorProfileTransform.create(
      profile: profile,
      isInput: true, // Input from printer
      intent: ColorProfileRenderingIntent.perceptual,
      interpolation: ColorProfileInterpolation.tetrahedral,
      lutType: ColorProfileTransformLutType.color,
      useD2BTags: true,
    );

    print('✓ Transforms created\n');

    // Create CMMs
    final forwardCmm = ColorProfileCmm();
    final reverseCmm = ColorProfileCmm();

    final forward = forwardCmm.buildTransformations([forwardTransform]);
    final reverse = reverseCmm.buildTransformations([reverseTransform]);

    print('✓ CMMs built\n');

    // Test with some CIE Lab values
    print('Testing Lab → CMYK → Lab round-trip:\n');

    final testColors = [
      {'name': 'Vivid Blue', 'L': 50.0, 'a': 20.0, 'b': -80.0},
      {'name': 'Bright Red', 'L': 50.0, 'a': 80.0, 'b': 60.0},
      {'name': 'Pure Green', 'L': 50.0, 'a': -80.0, 'b': 60.0},
      {'name': 'Mid Gray', 'L': 50.0, 'a': 0.0, 'b': 0.0},
      {'name': 'White', 'L': 100.0, 'a': 0.0, 'b': 0.0},
      {'name': 'Black', 'L': 0.0, 'a': 0.0, 'b': 0.0},
    ];

    for (final test in testColors) {
      final L = test['L'] as double;
      final a = test['a'] as double;
      final b = test['b'] as double;
      final name = test['name'] as String;

      // Normalize Lab values to 0-1 range for ICC parser
      // L: 0-100 → 0-1
      // a: -128 to +127 → 0-1
      // b: -128 to +127 → 0-1
      final normalizedL = L / 100.0;
      final normalizedA = (a + 128.0) / 255.0;
      final normalizedB = (b + 128.0) / 255.0;

      final labInput = Float64List.fromList([normalizedL, normalizedA, normalizedB]);

      // Lab → CMYK
      final cmykOutput = forwardCmm.apply(forward, labInput);

      print('$name:');
      print('  Input Lab:  L=${L.toStringAsFixed(2)}, a=${a.toStringAsFixed(2)}, b=${b.toStringAsFixed(2)}');
      print('  Normalized: L=${normalizedL.toStringAsFixed(3)}, a=${normalizedA.toStringAsFixed(3)}, b=${normalizedB.toStringAsFixed(3)}');

      // Check if we got the expected number of channels
      if (cmykOutput.length < 3) {
        print('  ❌ ERROR: Forward transform returned ${cmykOutput.length} values, expected at least 3');
        print('');
        continue;
      }

      // CMYK → Lab
      final labOutputNormalized = reverseCmm.apply(reverse, cmykOutput);

      // Denormalize Lab values from 0-1 back to standard ranges
      final outputL = labOutputNormalized[0] * 100.0;
      final outputA = labOutputNormalized[1] * 255.0 - 128.0;
      final outputB = labOutputNormalized[2] * 255.0 - 128.0;

      print('  Output Lab: L=${outputL.toStringAsFixed(2)}, a=${outputA.toStringAsFixed(2)}, b=${outputB.toStringAsFixed(2)}');

      // Check if output is pure black (L=0)
      if (outputL < 1.0 && L > 10.0) {
        print('  ❌ ERROR: Output is pure black! This is wrong!');
      } else if ((outputL - L).abs() > 20.0) {
        print('  ⚠️  WARNING: Large lightness shift: ${(outputL - L).toStringAsFixed(2)}');
      } else {
        print('  ✓ Reasonable output');
        final deltaL = (outputL - L).abs();
        final deltaA = (outputA - a).abs();
        final deltaB = (outputB - b).abs();
        print('  Delta: ΔL=${deltaL.toStringAsFixed(2)}, Δa=${deltaA.toStringAsFixed(2)}, Δb=${deltaB.toStringAsFixed(2)}');
      }
      print('');
    }

  } catch (e, stack) {
    print('❌ Error: $e');
    print('Stack trace:');
    print(stack);
  }
}
