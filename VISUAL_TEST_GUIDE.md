# 👁️ Visual Comparison Test Guide

## How to Test

1. **Open your Flutter app** at `http://localhost:8080`
2. **Click** the orange "👁️ Visual Comparison Tests" button
3. **Open the reference picker** on another device (the JavaScript one in `/reference`)
4. **Compare each color** side-by-side

## Test Cases to Validate

### ✅ Test 1: Mid-Blue (IN-GAMUT)
- **OKLCH**: L=0.7, C=0.15, H=240
- **What to check**: Should be a pleasant, medium blue
- **Expected**: Exact match (both are in-gamut, no mapping needed)

### ✅ Test 2: Lime Green (IN-GAMUT)
- **OKLCH**: L=0.8, C=0.2, H=130
- **What to check**: Bright lime/yellow-green
- **Expected**: Exact match

### ⚠️ Test 3: Cyan (OUT-OF-GAMUT)
- **OKLCH**: L=0.7, C=0.4, H=180
- **What to check**: Vibrant cyan, but chroma is too high for sRGB
- **Expected**: Colors should look identical. Both implementations reduce chroma to ~0.28
- **Critical**: Hue (cyan-ness) should NOT shift toward blue or green

### ⚠️ Test 4: Red (OUT-OF-GAMUT)
- **OKLCH**: L=0.6, C=0.35, H=25
- **What to check**: Orange-red with high chroma
- **Expected**: Colors should match. Gamut mapping preserves hue.
- **Critical**: Should NOT shift toward pure red or orange

### ✅ Test 5: Gray (ACHROMATIC)
- **OKLCH**: L=0.5, C=0, H=0
- **What to check**: Pure neutral gray (hue should be irrelevant)
- **Expected**: Exact match - perfect gray

### ✅ Test 6: Warm White
- **OKLCH**: L=0.95, C=0.05, H=60
- **What to check**: Very light with subtle yellow tint
- **Expected**: Should look nearly white with a barely perceptible warmth

### ✅ Test 7: Purple (EDGE)
- **OKLCH**: L=0.5, C=0.25, H=300
- **What to check**: Magenta-purple (tests purple gamut boundary)
- **Expected**: Should match closely

### ✅ Test 8: Orange (HIGH CHROMA)
- **OKLCH**: L=0.7, C=0.25, H=50
- **What to check**: Bright, vivid orange
- **Expected**: Should be very saturated and warm

## Pass/Fail Criteria

### ✅ PASS if:
- Colors look **identical** or **imperceptibly different** (< 1-2 RGB units)
- **Hue NEVER shifts** (e.g., cyan doesn't become blue)
- **Lightness** remains very similar
- Out-of-gamut colors are **equally desaturated** in both implementations

### ❌ FAIL if:
- Colors have **visible hue shifts** (different color family)
- **Lightness differs significantly** (one much darker/lighter)
- **Banding or artifacts** appear in gradients
- Achromatic colors (gray) show any **tint**

## What Differences Are Acceptable?

### Acceptable (< 2 RGB units):
- Flutter: `rgb(38, 169, 241)`
- Reference: `rgb(37, 170, 241)` ← Barely perceptible

### NOT Acceptable (hue shift):
- Flutter: `rgb(0, 200, 255)` (cyan)
- Reference: `rgb(50, 180, 255)` (cyan-blue) ← Obvious hue difference

## RGB Values for Reference

Here are the RGB outputs from our implementation for quick comparison:

```dart
Test 1 (L=0.7, C=0.15, H=240):   RGB(38, 169, 241)
Test 2 (L=0.8, C=0.2, H=130):    RGB(149, 239, 119)
Test 3 (L=0.7, C=0.4, H=180):    RGB(0, 243, 215)    // Gamut mapped
Test 4 (L=0.6, C=0.35, H=25):    RGB(255, 129, 0)    // Gamut mapped
Test 5 (L=0.5, C=0, H=0):        RGB(119, 119, 119)
Test 6 (L=0.95, C=0.05, H=60):   RGB(248, 247, 241)
Test 7 (L=0.5, C=0.25, H=300):   RGB(201, 53, 188)
Test 8 (L=0.7, C=0.25, H=50):    RGB(255, 172, 40)
```

## Notes

- The human eye is most sensitive to **hue shifts** (we can detect ~1-2 degree changes)
- Lightness differences < 5% are usually imperceptible
- Chroma differences are hardest to detect (< 10% often goes unnoticed)
- Out-of-gamut colors are the real test - they require complex gamut mapping

## Troubleshooting

**If colors don't match:**

1. **Check the reference is using OKLCH** (not LCH/Lab)
2. **Verify you entered values correctly** (decimal point matters!)
3. **Check display settings** (both displays should be sRGB or color-matched)
4. **Note RGB values** - compare the actual numbers

**Expected edge cases:**

- Very saturated colors (C > 0.3) often require gamut mapping
- Purple/magenta (H=270-330) has smallest gamut
- Cyan (H=180-200) also constrained in sRGB

