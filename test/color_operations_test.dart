import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../lib/color_operations.dart';
import 'dart:math';

void main() {
  group('OKLCH Color Operations Tests', () {
    
    // ========================================================================
    // Test 1: Basic OKLCH to RGB conversion
    // ========================================================================
    group('Basic OKLCH → RGB Conversion', () {
      test('Mid-blue color (L=0.7, C=0.15, H=240)', () {
        final color = colorFromOklch(0.7, 0.15, 240.0);
        
        // With JND-optimized gamut mapping: rgb(38, 169, 241)
        expect(color.red, closeTo(38, 2), reason: 'Red channel');
        expect(color.green, closeTo(169, 2), reason: 'Green channel');
        expect(color.blue, closeTo(241, 2), reason: 'Blue channel');
      });
      
      test('Pure red (L=0.6, C=0.25, H=0)', () {
        final color = colorFromOklch(0.6, 0.25, 0.0);
        
        // Gamut mapped to rgb(233, 0, 122) - magenta-red due to sRGB gamut limits
        expect(color.red, closeTo(233, 2), reason: 'Red should be high');
        expect(color.green, closeTo(0, 2), reason: 'Green should be zero');
        expect(color.blue, closeTo(122, 2), reason: 'Blue is elevated due to gamut mapping');
      });
      
      test('Pure green (L=0.7, C=0.2, H=120)', () {
        final color = colorFromOklch(0.7, 0.2, 120.0);
        
        // Should be a strong green
        expect(color.green > 150, true, reason: 'Green should be dominant');
      });
    });
    
    // ========================================================================
    // Test 2: Edge cases - Pure colors
    // ========================================================================
    group('Edge Cases', () {
      test('Pure white (L=1.0, C=0, H=any)', () {
        final color = colorFromOklch(1.0, 0.0, 0.0);
        
        expect(color.red, equals(255), reason: 'Red should be 255');
        expect(color.green, equals(255), reason: 'Green should be 255');
        expect(color.blue, equals(255), reason: 'Blue should be 255');
      });
      
      test('Pure white with non-zero chroma (L=1.0, C=0.3, H=240)', () {
        final color = colorFromOklch(1.0, 0.3, 240.0);
        
        // Should still be white because L=1.0
        expect(color.red, equals(255), reason: 'Red should be 255');
        expect(color.green, equals(255), reason: 'Green should be 255');
        expect(color.blue, equals(255), reason: 'Blue should be 255');
      });
      
      test('Pure black (L=0.0, C=0, H=any)', () {
        final color = colorFromOklch(0.0, 0.0, 0.0);
        
        expect(color.red, equals(0), reason: 'Red should be 0');
        expect(color.green, equals(0), reason: 'Green should be 0');
        expect(color.blue, equals(0), reason: 'Blue should be 0');
      });
      
      test('Pure black with non-zero chroma (L=0.0, C=0.3, H=120)', () {
        final color = colorFromOklch(0.0, 0.3, 120.0);
        
        // Should still be black because L=0.0
        expect(color.red, equals(0), reason: 'Red should be 0');
        expect(color.green, equals(0), reason: 'Green should be 0');
        expect(color.blue, equals(0), reason: 'Blue should be 0');
      });
      
      test('Mid-gray (L=0.5, C=0, H=any)', () {
        final color = colorFromOklch(0.5, 0.0, 180.0);
        
        // Should be gray (R ≈ G ≈ B)
        final avgColor = (color.red + color.green + color.blue) / 3;
        expect((color.red - avgColor).abs(), lessThan(5), reason: 'Should be gray');
        expect((color.green - avgColor).abs(), lessThan(5), reason: 'Should be gray');
        expect((color.blue - avgColor).abs(), lessThan(5), reason: 'Should be gray');
      });
    });
    
    // ========================================================================
    // Test 3: Gamut mapping - Out of gamut colors
    // ========================================================================
    group('Gamut Mapping', () {
      test('Out-of-gamut cyan (L=0.7, C=0.4, H=180)', () {
        final color = colorFromOklch(0.7, 0.4, 180.0);
        
        // Should be valid RGB: rgb(0, 187, 162)
        expect(color.red >= 0 && color.red <= 255, true, reason: 'Red in range');
        expect(color.green >= 0 && color.green <= 255, true, reason: 'Green in range');
        expect(color.blue >= 0 && color.blue <= 255, true, reason: 'Blue in range');
        
        // Convert back to check chroma was reduced
        // JND optimization reduces chroma more aggressively: 0.4 → 0.1299
        final back = srgbToOklch(color);
        expect(back.c < 0.4, true, reason: 'Chroma should be reduced from 0.4');
        expect(back.c > 0.10, true, reason: 'Chroma should still be present');
        
        // Lightness should be preserved
        expect(back.l, closeTo(0.7, 0.05), reason: 'Lightness should be preserved');
        
        // Hue should be preserved
        expect(back.h, closeTo(180.0, 5.0), reason: 'Hue should be preserved');
      });
      
      test('Out-of-gamut red (L=0.5, C=0.5, H=0)', () {
        final color = colorFromOklch(0.5, 0.5, 0.0);
        
        // Should be valid RGB
        expect(color.red >= 0 && color.red <= 255, true, reason: 'Red in range');
        expect(color.green >= 0 && color.green <= 255, true, reason: 'Green in range');
        expect(color.blue >= 0 && color.blue <= 255, true, reason: 'Blue in range');
        
        // Convert back
        final back = srgbToOklch(color);
        expect(back.c < 0.5, true, reason: 'Chroma should be reduced');
      });
    });
    
    // ========================================================================
    // Test 4: Round-trip conversions
    // ========================================================================
    group('Round-trip Conversions', () {
      test('RGB → OKLCH → RGB (Blue)', () {
        final original = Colors.blue;
        final oklch = srgbToOklch(original);
        final back = colorFromOklch(oklch.l, oklch.c, oklch.h, oklch.alpha);
        
        // Should be close to original
        expect(back.red, closeTo(original.red, 3));
        expect(back.green, closeTo(original.green, 3));
        expect(back.blue, closeTo(original.blue, 3));
      });
      
      test('RGB → OKLCH → RGB (Red)', () {
        final original = Colors.red;
        final oklch = srgbToOklch(original);
        final back = colorFromOklch(oklch.l, oklch.c, oklch.h, oklch.alpha);
        
        expect(back.red, closeTo(original.red, 3));
        expect(back.green, closeTo(original.green, 3));
        expect(back.blue, closeTo(original.blue, 3));
      });
      
      test('RGB → OKLCH → RGB (Custom color)', () {
        final original = const Color.fromRGBO(123, 200, 87, 1.0);
        final oklch = srgbToOklch(original);
        final back = colorFromOklch(oklch.l, oklch.c, oklch.h, oklch.alpha);
        
        expect(back.red, closeTo(original.red, 3));
        expect(back.green, closeTo(original.green, 3));
        expect(back.blue, closeTo(original.blue, 3));
      });
    });
    
    // ========================================================================
    // Test 5: OKLCH component conversions
    // ========================================================================
    group('Component Conversions', () {
      test('OKLCH to OKLab conversion', () {
        final oklch = OklchColor(0.7, 0.2, 240.0);
        final oklab = oklchToOklab(oklch);
        
        // Check values are reasonable
        expect(oklab.l, closeTo(0.7, 0.001), reason: 'Lightness preserved');
        expect(oklab.a.abs() <= 0.5, true, reason: 'a in reasonable range');
        expect(oklab.b.abs() <= 0.5, true, reason: 'b in reasonable range');
        
        // Check chroma: c = sqrt(a² + b²)
        final calculatedC = sqrt(oklab.a * oklab.a + oklab.b * oklab.b);
        expect(calculatedC, closeTo(0.2, 0.001), reason: 'Chroma calculation');
      });
      
      test('OKLab to OKLCH conversion', () {
        final oklab = OklabColor(0.7, 0.1, 0.15);
        final oklch = oklabToOklch(oklab);
        
        // Check lightness
        expect(oklch.l, closeTo(0.7, 0.001));
        
        // Check chroma
        final expectedC = sqrt(0.1 * 0.1 + 0.15 * 0.15);
        expect(oklch.c, closeTo(expectedC, 0.001));
        
        // Check hue is in valid range
        expect(oklch.h >= 0.0 && oklch.h < 360.0, true);
      });
    });
    
    // ========================================================================
    // Test 6: Utility functions
    // ========================================================================
    group('Utility Functions', () {
      test('isOklchDisplayable - in-gamut color', () {
        // This should be displayable
        final result = isOklchDisplayable(0.7, 0.15, 240.0);
        expect(result, true, reason: 'Should be displayable');
      });
      
      test('isOklchDisplayable - out-of-gamut color', () {
        // This should NOT be displayable (chroma too high)
        final result = isOklchDisplayable(0.7, 0.5, 180.0);
        expect(result, false, reason: 'Should not be displayable');
      });
      
      test('getMaxChroma returns reasonable values', () {
        final maxChroma = getMaxChroma(0.7, 180.0);
        
        // Should be positive
        expect(maxChroma > 0, true, reason: 'Max chroma should be positive');
        
        // Should be less than theoretical max
        expect(maxChroma < 0.5, true, reason: 'Max chroma should be reasonable');
        
        // Should be at the boundary
        expect(isOklchDisplayable(0.7, maxChroma, 180.0), true, 
               reason: 'Max chroma should be displayable');
        expect(isOklchDisplayable(0.7, maxChroma + 0.01, 180.0), false, 
               reason: 'Slightly above max should not be displayable');
      });
      
      test('colorToOklch returns correct keys', () {
        final color = Colors.blue;
        final map = colorToOklch(color);
        
        expect(map.containsKey('l'), true);
        expect(map.containsKey('c'), true);
        expect(map.containsKey('h'), true);
        expect(map.containsKey('alpha'), true);
        
        // Values should be in range
        expect(map['l']! >= 0.0 && map['l']! <= 1.0, true);
        expect(map['c']! >= 0.0, true);
        expect(map['h']! >= 0.0 && map['h']! < 360.0, true);
        expect(map['alpha']! >= 0.0 && map['alpha']! <= 1.0, true);
      });
    });
    
    // ========================================================================
    // Test 7: Alpha channel handling
    // ========================================================================
    group('Alpha Channel', () {
      test('Alpha is preserved through conversions', () {
        final color = colorFromOklch(0.7, 0.15, 240.0, 0.5);
        
        // 0.5 * 255 = 127.5, which rounds to 128
        expect(color.alpha, closeTo(127, 1), reason: 'Alpha should be 127 or 128');
      });
      
      test('Alpha round-trip', () {
        final original = const Color.fromRGBO(100, 150, 200, 0.7);
        final oklch = srgbToOklch(original);
        
        expect(oklch.alpha, closeTo(0.7, 0.01), reason: 'Alpha should be preserved');
      });
    });
    
    // ========================================================================
    // Test 8: Hue angle handling
    // ========================================================================
    group('Hue Angle Handling', () {
      test('Hue 0° (red)', () {
        final color = colorFromOklch(0.6, 0.2, 0.0);
        expect(color.red > color.green, true);
        expect(color.red > color.blue, true);
      });
      
      test('Hue 120° (green)', () {
        final color = colorFromOklch(0.7, 0.2, 120.0);
        expect(color.green > color.red, true);
        expect(color.green > color.blue, true);
      });
      
      test('Hue 240° (blue)', () {
        final color = colorFromOklch(0.6, 0.2, 240.0);
        expect(color.blue > color.red, true);
        expect(color.blue > color.green, true);
      });
      
      test('Hue 360° should equal 0°', () {
        final color0 = colorFromOklch(0.7, 0.15, 0.0);
        final color360 = colorFromOklch(0.7, 0.15, 360.0);
        
        expect(color0.red, closeTo(color360.red, 1));
        expect(color0.green, closeTo(color360.green, 1));
        expect(color0.blue, closeTo(color360.blue, 1));
      });
    });
    
    // ========================================================================
    // Test 9: Gamut boundary tests
    // ========================================================================
    group('Gamut Boundaries', () {
      test('Very high lightness with chroma', () {
        final color = colorFromOklch(0.95, 0.2, 180.0);
        
        // Should be valid and light
        expect(color.red >= 0 && color.red <= 255, true);
        expect(color.green >= 0 && color.green <= 255, true);
        expect(color.blue >= 0 && color.blue <= 255, true);
        
        // Should be bright
        expect((color.red + color.green + color.blue) / 3 > 200, true);
      });
      
      test('Very low lightness with chroma', () {
        final color = colorFromOklch(0.05, 0.2, 180.0);
        
        // Should be valid and dark
        expect(color.red >= 0 && color.red <= 255, true);
        expect(color.green >= 0 && color.green <= 255, true);
        expect(color.blue >= 0 && color.blue <= 255, true);
        
        // Should be dark
        expect((color.red + color.green + color.blue) / 3 < 50, true);
      });
    });
    
    // ========================================================================
    // Test 10: Specific reference values from Culori
    // ========================================================================
    group('Reference Values from Culori', () {
      test('Test case 1: L=0.5, C=0.1, H=180', () {
        final color = colorFromOklch(0.5, 0.1, 180.0);
        
        // Should produce a grayish cyan
        expect(color.green >= color.red, true, reason: 'Green should be >= red for cyan');
        expect(color.blue >= color.red, true, reason: 'Blue should be >= red for cyan');
      });
      
      test('Test case 2: L=0.8, C=0.05, H=60', () {
        final color = colorFromOklch(0.8, 0.05, 60.0);
        
        // Produces rgb(215, 183, 158) - a light peachy/tan color
        expect(color.red, closeTo(215, 5), reason: 'Red channel');
        expect(color.green, closeTo(183, 5), reason: 'Green channel');
        expect(color.blue, closeTo(158, 5), reason: 'Blue channel');
      });
    });
  });
}

