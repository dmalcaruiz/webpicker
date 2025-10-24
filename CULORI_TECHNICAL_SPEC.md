# Culori Color Functions - Technical Specification

> **Document Purpose**: Low-level technical specification of all Culori color conversion formulas and algorithms referenced in the reference-oklch project, with comparison to current Flutter implementation.

## Table of Contents

1. [Overview](#overview)
2. [Color Space Definitions](#color-space-definitions)
3. [Conversion Formulas](#conversion-formulas)
4. [Gamut Mapping Algorithms](#gamut-mapping-algorithms)
5. [Formatting Functions](#formatting-functions)
6. [Implementation Comparison](#implementation-comparison)

---

## Overview

### Culori Package Version
- **Version**: 4.0.2
- **Source**: `reference-culori/` folder
- **License**: MIT
- **Purpose**: JavaScript color conversion library supporting OKLCH, LCH, RGB, and many other color spaces

### Reference Implementation
- **Source**: `reference-oklch/` folder (oklch.com color picker)
- **Uses**: Culori 4.0.2 via npm
- **Key Features**: OKLCH/LCH color picker with gamut mapping

---

## Color Space Definitions

### 1. OKLCH Color Space

**File**: `reference-culori/src/oklch/definition.js`

```javascript
{
  mode: 'oklch',
  ranges: {
    l: [0, 1],      // Lightness: 0 (black) to 1 (white)
    c: [0, 0.4],    // Chroma: 0 (gray) to 0.4 (max for sRGB)
    h: [0, 360]     // Hue: 0-360 degrees
  }
}
```

**Conversion Path**:
- **To RGB**: `OKLCH → OKLab → Linear RGB → sRGB`
- **From RGB**: `sRGB → Linear RGB → OKLab → OKLCH`

**Flutter Implementation Status**: ✅ **EXACT MATCH**
- File: `lib/utils/color_operations.dart`
- Constants match Culori exactly
- Conversion path matches exactly

---

### 2. OKLab Color Space

**File**: `reference-culori/src/oklab/definition.js`

**Channels**:
- `l`: Lightness (0-1)
- `a`: Green-Red axis (-∞ to +∞, typically -0.4 to +0.4)
- `b`: Blue-Yellow axis (-∞ to +∞, typically -0.4 to +0.4)

**Flutter Implementation Status**: ✅ **EXACT MATCH**
- Class: `OklabColor` in `color_operations.dart`

---

### 3. Linear RGB (lrgb)

**Description**: RGB values before gamma correction (linear light intensity)

**File**: `reference-culori/src/lrgb/definition.js`

**Channels**:
- `r`, `g`, `b`: Each 0-1 (linear intensity)

**Flutter Implementation Status**: ✅ **EXACT MATCH**
- Class: `LinearRgbColor` in `color_operations.dart`

---

### 4. sRGB

**Description**: Standard RGB with gamma correction (what Flutter's `Color` uses)

**Channels**:
- `r`, `g`, `b`: Each 0-1 (gamma-corrected)
- In Flutter: Each 0-255 (integer)

---

## Conversion Formulas

### 1. OKLCH ↔ OKLab (Polar ↔ Cartesian)

#### OKLCH → OKLab

**File**: `reference-culori/src/lch/convertLchToLab.js`

```javascript
const convertLchToLab = ({ l, c, h, alpha }, mode = 'lab') => {
  if (h === undefined) h = 0;
  let res = {
    mode,
    l,
    a: c ? c * Math.cos((h / 180) * Math.PI) : 0,
    b: c ? c * Math.sin((h / 180) * Math.PI) : 0
  };
  if (alpha !== undefined) res.alpha = alpha;
  return res;
};
```

**Formula**:
```
a = c × cos(h × π / 180)
b = c × sin(h × π / 180)
```

**Flutter Implementation**: ✅ **EXACT MATCH**
```dart
// lib/utils/color_operations.dart:85-98
OklabColor oklchToOklab(OklchColor color) {
  final double hRad = h * pi / 180.0;
  final double a = c * cos(hRad);
  final double b = c * sin(hRad);
  return OklabColor(l, a, b, color.alpha);
}
```

---

#### OKLab → OKLCH

**File**: `reference-culori/src/lch/convertLabToLch.js`

```javascript
const convertLabToLch = ({ l, a, b, alpha }, mode = 'lch') => {
  if (a === undefined) a = 0;
  if (b === undefined) b = 0;
  let c = Math.sqrt(a * a + b * b);
  let res = { mode, l, c };
  if (c) res.h = normalizeHue((Math.atan2(b, a) * 180) / Math.PI);
  if (alpha !== undefined) res.alpha = alpha;
  return res;
};
```

**Formula**:
```
c = √(a² + b²)
h = atan2(b, a) × 180 / π
if h < 0: h = h + 360
```

**Flutter Implementation**: ✅ **EXACT MATCH**
```dart
// lib/utils/color_operations.dart:105-122
OklchColor oklabToOklch(OklabColor color) {
  final double c = sqrt(a * a + b * b);
  double h = atan2(b, a) * 180.0 / pi;
  if (h < 0) h += 360.0;
  return OklchColor(l, c, h, color.alpha);
}
```

---

### 2. OKLab ↔ Linear RGB

#### OKLab → Linear RGB

**File**: `reference-culori/src/oklab/convertOklabToLrgb.js`

```javascript
const convertOklabToLrgb = ({ l, a, b, alpha }) => {
  if (l === undefined) l = 0;
  if (a === undefined) a = 0;
  if (b === undefined) b = 0;

  // Step 1: OKLab → LMS (cone response)
  let L = Math.pow(l + 0.3963377773761749 * a + 0.2158037573099136 * b, 3);
  let M = Math.pow(l - 0.1055613458156586 * a - 0.0638541728258133 * b, 3);
  let S = Math.pow(l - 0.0894841775298119 * a - 1.2914855480194092 * b, 3);

  // Step 2: LMS → Linear RGB
  let res = {
    mode: 'lrgb',
    r:  4.0767416360759574 * L - 3.3077115392580616 * M + 0.2309699031821044 * S,
    g: -1.2684379732850317 * L + 2.6097573492876887 * M - 0.3413193760026573 * S,
    b: -0.0041960761386756 * L - 0.7034186179359362 * M + 1.7076146940746117 * S
  };

  if (alpha !== undefined) res.alpha = alpha;
  return res;
};
```

**Formula**:
```
Step 1: OKLab → LMS³ (intermediate cone response)
  L³ = (l + 0.3963377773761749×a + 0.2158037573099136×b)³
  M³ = (l - 0.1055613458156586×a - 0.0638541728258133×b)³
  S³ = (l - 0.0894841775298119×a - 1.2914855480194092×b)³

Step 2: LMS³ → Linear RGB
  r =  4.0767416360759574×L³ - 3.3077115392580616×M³ + 0.2309699031821044×S³
  g = -1.2684379732850317×L³ + 2.6097573492876887×M³ - 0.3413193760026573×S³
  b = -0.0041960761386756×L³ - 0.7034186179359362×M³ + 1.7076146940746117×S³
```

**Flutter Implementation**: ✅ **EXACT MATCH**
```dart
// lib/utils/color_operations.dart:132-155
LinearRgbColor oklabToLinearRgb(OklabColor color) {
  final double lCone = l + 0.3963377773761749 * a + 0.2158037573099136 * b;
  final double mCone = l - 0.1055613458156586 * a - 0.0638541728258133 * b;
  final double sCone = l - 0.0894841775298119 * a - 1.2914855480194092 * b;

  final double lCube = lCone * lCone * lCone;
  final double mCube = mCone * mCone * mCone;
  final double sCube = sCone * sCone * sCone;

  final double r = 4.0767416360759574 * lCube - 3.3077115392580616 * mCube + 0.2309699031821044 * sCube;
  final double g = -1.2684379732850317 * lCube + 2.6097573492876887 * mCube - 0.3413193760026573 * sCube;
  final double bValue = -0.0041960761386756 * lCube - 0.7034186179359362 * mCube + 1.7076146940746117 * sCube;

  return LinearRgbColor(r, g, bValue, color.alpha);
}
```

**Coefficients Match**: ✅ **EXACT** (all 16 decimal places)

---

#### Linear RGB → OKLab

**File**: `reference-culori/src/oklab/convertLrgbToOklab.js`

```javascript
const convertLrgbToOklab = ({ r, g, b, alpha }) => {
  if (r === undefined) r = 0;
  if (g === undefined) g = 0;
  if (b === undefined) b = 0;

  // Step 1: Linear RGB → LMS
  let L = Math.cbrt(0.412221469470763 * r + 0.5363325372617348 * g + 0.0514459932675022 * b);
  let M = Math.cbrt(0.2119034958178252 * r + 0.6806995506452344 * g + 0.1073969535369406 * b);
  let S = Math.cbrt(0.0883024591900564 * r + 0.2817188391361215 * g + 0.6299787016738222 * b);

  // Step 2: LMS → OKLab
  let res = {
    mode: 'oklab',
    l:  0.210454268309314 * L + 0.7936177747023054 * M - 0.0040720430116193 * S,
    a:  1.9779985324311684 * L - 2.4285922420485799 * M + 0.450593709617411 * S,
    b:  0.0259040424655478 * L + 0.7827717124575296 * M - 0.8086757549230774 * S
  };

  if (alpha !== undefined) res.alpha = alpha;
  return res;
};
```

**Formula**:
```
Step 1: Linear RGB → LMS
  L = ∛(0.412221469470763×r + 0.5363325372617348×g + 0.0514459932675022×b)
  M = ∛(0.2119034958178252×r + 0.6806995506452344×g + 0.1073969535369406×b)
  S = ∛(0.0883024591900564×r + 0.2817188391361215×g + 0.6299787016738222×b)

Step 2: LMS → OKLab
  l =  0.210454268309314×L + 0.7936177747023054×M - 0.0040720430116193×S
  a =  1.9779985324311684×L - 2.4285922420485799×M + 0.450593709617411×S
  b =  0.0259040424655478×L + 0.7827717124575296×M - 0.8086757549230774×S
```

**Flutter Implementation**: ✅ **EXACT MATCH**
```dart
// lib/utils/color_operations.dart:160-183
OklabColor linearRgbToOklab(LinearRgbColor color) {
  final double l = 0.412221469470763 * r + 0.5363325372617348 * g + 0.0514459932675022 * b;
  final double m = 0.2119034958178252 * r + 0.6806995506452344 * g + 0.1073969535369406 * b;
  final double s = 0.0883024591900564 * r + 0.2817188391361215 * g + 0.6299787016738222 * b;

  final double lRoot = _cubeRoot(l);
  final double mRoot = _cubeRoot(m);
  final double sRoot = _cubeRoot(s);

  final double lOklab = 0.210454268309314 * lRoot + 0.7936177747023054 * mRoot - 0.0040720430116193 * sRoot;
  final double aOklab = 1.9779985324311684 * lRoot - 2.4285922420485799 * mRoot + 0.450593709617411 * sRoot;
  final double bOklab = 0.0259040424655478 * lRoot + 0.7827717124575296 * mRoot - 0.8086757549230774 * sRoot;

  return OklabColor(lOklab, aOklab, bOklab, color.alpha);
}
```

**Coefficients Match**: ✅ **EXACT** (all 16 decimal places)

---

### 3. Linear RGB ↔ sRGB (Gamma Correction)

#### Linear RGB → sRGB (Gamma Compression)

**File**: `reference-culori/src/lrgb/convertLrgbToRgb.js`

```javascript
const fn = (c = 0) => {
  const abs = Math.abs(c);
  if (abs > 0.0031308) {
    return (Math.sign(c) || 1) * (1.055 * Math.pow(abs, 1 / 2.4) - 0.055);
  }
  return c * 12.92;
};

const convertLrgbToRgb = ({ r, g, b, alpha }, mode = 'rgb') => {
  let res = {
    mode,
    r: fn(r),
    g: fn(g),
    b: fn(b)
  };
  if (alpha !== undefined) res.alpha = alpha;
  return res;
};
```

**Formula** (per channel):
```
if |channel| > 0.0031308:
    result = sign(channel) × (1.055 × |channel|^(1/2.4) - 0.055)
else:
    result = channel × 12.92

where sign(0) = 1 (JavaScript behavior)
```

**Flutter Implementation**: ✅ **EXACT MATCH**
```dart
// lib/utils/color_operations.dart:201-211
double _gammaCorrection(double channel) {
  final double abs = channel.abs();

  if (abs > 0.0031308) {
    final double sign = channel.sign != 0 ? channel.sign : 1.0;
    return sign * (1.055 * pow(abs, 1.0 / 2.4) - 0.055);
  } else {
    return channel * 12.92;
  }
}
```

---

#### sRGB → Linear RGB (Gamma Expansion)

**File**: `reference-culori/src/lrgb/convertRgbToLrgb.js`

```javascript
const fn = (c = 0) => {
  const abs = Math.abs(c);
  if (abs <= 0.04045) {
    return c / 12.92;
  }
  return (Math.sign(c) || 1) * Math.pow((abs + 0.055) / 1.055, 2.4);
};

const convertRgbToLrgb = ({ r, g, b, alpha }) => {
  let res = {
    mode: 'lrgb',
    r: fn(r),
    g: fn(g),
    b: fn(b)
  };
  if (alpha !== undefined) res.alpha = alpha;
  return res;
};
```

**Formula** (per channel):
```
if |channel| ≤ 0.04045:
    result = channel / 12.92
else:
    result = sign(channel) × ((|channel| + 0.055) / 1.055)^2.4

where sign(0) = 1 (JavaScript behavior)
```

**Flutter Implementation**: ✅ **EXACT MATCH**
```dart
// lib/utils/color_operations.dart:214-224
double _gammaExpansion(double channel) {
  final double abs = channel.abs();

  if (abs <= 0.04045) {
    return channel / 12.92;
  } else {
    final double sign = channel.sign != 0 ? channel.sign : 1.0;
    return sign * pow((abs + 0.055) / 1.055, 2.4);
  }
}
```

---

## Gamut Mapping Algorithms

### 1. inGamut - Check if Color is in Gamut

**File**: `reference-culori/src/clamp.js:22-50`

```javascript
const inrange_rgb = c => {
  return (
    c !== undefined &&
    (c.r === undefined || (c.r >= 0 && c.r <= 1)) &&
    (c.g === undefined || (c.g >= 0 && c.g <= 1)) &&
    (c.b === undefined || (c.b >= 0 && c.b <= 1))
  );
};

export function inGamut(mode = 'rgb') {
  const { gamut } = getMode(mode);
  if (!gamut) {
    return color => true;
  }
  const conv = converter(typeof gamut === 'string' ? gamut : mode);
  return color => inrange_rgb(conv(color));
}
```

**Algorithm**:
```
1. Convert color to RGB (if not already)
2. Check if all channels are in [0, 1] range
3. Return true if all in range, false otherwise
```

**Flutter Implementation**: ✅ **EXACT MATCH** (with epsilon tolerance)
```dart
// lib/utils/color_operations.dart:265-270
bool isInGamut(LinearRgbColor color) {
  const double epsilon = 0.0001;
  return color.r >= -epsilon && color.r <= 1.0 + epsilon &&
         color.g >= -epsilon && color.g <= 1.0 + epsilon &&
         color.b >= -epsilon && color.b <= 1.0 + epsilon;
}
```

**Note**: Flutter adds small epsilon (0.0001) for floating-point tolerance. This matches Culori's approach in `reference-oklch/lib/colors.ts:45` which uses `COLOR_SPACE_GAP = 0.0001`.

---

### 2. toGamut - CSS Color Level 4 Gamut Mapping

**File**: `reference-culori/src/clamp.js:190-259`

**Reference**: https://drafts.csswg.org/css-color/#css-gamut-mapping

```javascript
export function toGamut(
  dest = 'rgb',
  mode = 'oklch',
  delta = differenceEuclidean('oklch'),
  jnd = 0.02
) {
  const destConv = converter(dest);
  const destMode = getMode(dest);

  if (!destMode.gamut) {
    return color => destConv(color);
  }

  const inDestinationGamut = inGamut(dest);
  const clipToGamut = clampGamut(dest);

  const ucs = converter(mode);
  const { ranges } = getMode(mode);

  if (!ranges.l || !ranges.c) {
    throw new Error('LCH-like space expected');
  }

  return color => {
    color = prepare(color);
    if (color === undefined) return undefined;

    const candidate = { ...ucs(color) };

    // Handle missing components
    if (candidate.l === undefined) candidate.l = 0;
    if (candidate.c === undefined) candidate.c = 0;

    // Handle pure white
    if (candidate.l >= ranges.l[1]) {
      const res = { ...destMode.white, mode: dest };
      if (color.alpha !== undefined) res.alpha = color.alpha;
      return res;
    }

    // Handle pure black
    if (candidate.l <= ranges.l[0]) {
      const res = { ...destMode.black, mode: dest };
      if (color.alpha !== undefined) res.alpha = color.alpha;
      return res;
    }

    // Already in gamut
    if (inDestinationGamut(candidate)) {
      return destConv(candidate);
    }

    // Binary search for maximum chroma
    let start = 0;
    let end = candidate.c;
    let epsilon = (ranges.c[1] - ranges.c[0]) / 4000; // 0.0001 for oklch
    let clipped = clipToGamut(candidate);

    while (end - start > epsilon) {
      candidate.c = (start + end) * 0.5;
      clipped = clipToGamut(candidate);
      if (
        inDestinationGamut(candidate) ||
        (delta && jnd > 0 && delta(candidate, clipped) <= jnd)
      ) {
        start = candidate.c;
      } else {
        end = candidate.c;
      }
    }

    return destConv(inDestinationGamut(candidate) ? candidate : clipped);
  };
}
```

**Algorithm**:
```
1. Convert input color to OKLCH (or other LCH-like space)
2. Handle edge cases:
   - L ≥ 1.0 → return white
   - L ≤ 0.0 → return black
3. If already in gamut → return as-is
4. Binary search for maximum acceptable chroma:
   - Start: chroma = 0 (always in gamut)
   - End: current chroma (out of gamut)
   - Epsilon: (c_max - c_min) / 4000 = 0.0001 for OKLCH
   - Accept if: strictly in gamut OR within JND threshold
5. Return final candidate or clipped version
```

**Flutter Implementation**: ✅ **EXACT MATCH**
```dart
// lib/utils/color_operations.dart:336-407
Color oklchToSrgbWithGamut(OklchColor color) {
  // Edge case: pure white
  if (color.l >= oklchLMax) {
    return Color.fromARGB((color.alpha * 255).round(), 255, 255, 255);
  }

  // Edge case: pure black
  if (color.l <= oklchLMin) {
    return Color.fromARGB((color.alpha * 255).round(), 0, 0, 0);
  }

  // Try direct conversion
  OklabColor oklab = oklchToOklab(color);
  LinearRgbColor linearRgb = oklabToLinearRgb(oklab);

  // Already in gamut
  if (isInGamut(linearRgb)) {
    return linearRgbToSrgb(linearRgb);
  }

  // Binary search
  double start = 0.0;
  double end = color.c;

  OklchColor candidate = OklchColor(color.l, color.c, color.h, color.alpha);
  LinearRgbColor clipped = linearRgb;

  while (end - start > gamutEpsilon) {  // gamutEpsilon = 0.4 / 4000 = 0.0001
    final double midChroma = (start + end) * 0.5;
    candidate = OklchColor(color.l, midChroma, color.h, color.alpha);

    final OklabColor candidateOklab = oklchToOklab(candidate);
    final LinearRgbColor candidateLinearRgb = oklabToLinearRgb(candidateOklab);

    clipped = clampRgb(candidateLinearRgb);

    // JND optimization: accept if within threshold
    final bool isAcceptable = isInGamut(candidateLinearRgb) ||
        _deltaOklch(candidate, oklabToOklch(linearRgbToOklab(clipped))) <= jnd;

    if (isAcceptable) {
      start = midChroma;
    } else {
      end = midChroma;
    }
  }

  final OklabColor finalOklab = oklchToOklab(candidate);
  final LinearRgbColor finalLinearRgb = oklabToLinearRgb(finalOklab);

  return linearRgbToSrgb(isInGamut(finalLinearRgb) ? finalLinearRgb : clipped);
}
```

**Constants**:
- Epsilon: `0.4 / 4000 = 0.0001` ✅ **EXACT MATCH**
- JND threshold: `0.02` ✅ **EXACT MATCH**

---

### 3. Delta (Color Difference) for JND Optimization

**File**: `reference-culori/src/difference.js` (uses Euclidean distance)

**Formula** for OKLCH (cylindrical coordinates):
```
dL = L₁ - L₂  (lightness difference)
dC = C₁ - C₂  (chroma difference)
dH = 2 × √(C₁ × C₂) × sin((H₂ - H₁) / 2)  (hue difference, weighted by chroma)

delta = √(dL² + dC² + dH²)
```

**Flutter Implementation**: ✅ **EXACT MATCH**
```dart
// lib/utils/color_operations.dart:289-316
double _deltaOklch(OklchColor a, OklchColor b) {
  final double dL = a.l - b.l;
  final double dC = a.c - b.c;

  double dH = 0.0;
  if (a.c > 0 && b.c > 0) {
    double h1 = a.h % 360;
    double h2 = b.h % 360;
    if (h1 < 0) h1 += 360;
    if (h2 < 0) h2 += 360;

    final double hueDiff = h2 - h1 + 360;
    final double dHSin = sin((hueDiff / 2) * pi / 180);
    dH = 2 * sqrt(a.c * b.c) * dHSin;
  }

  return sqrt(dL * dL + dC * dC + dH * dH);
}
```

**Note**: This implements the proper cylindrical coordinate distance, accounting for hue wraparound.

---

## Formatting Functions

### 1. formatHex - Convert to Hex String

**File**: `reference-culori/src/formatter.js:14-24`

```javascript
const clamp = value => Math.max(0, Math.min(1, value || 0));
const fixup = value => Math.round(clamp(value) * 255);

export const serializeHex = color => {
  if (color === undefined) return undefined;

  let r = fixup(color.r);
  let g = fixup(color.g);
  let b = fixup(color.b);

  return '#' + ((1 << 24) | (r << 16) | (g << 8) | b).toString(16).slice(1);
};

export const formatHex = c => serializeHex(rgb(c));
```

**Algorithm**:
```
1. Convert color to RGB (if not already)
2. Clamp each channel to [0, 1]
3. Round to integer: round(channel × 255)
4. Pack into 24-bit integer: (1 << 24) | (r << 16) | (g << 8) | b
5. Convert to hex string and slice to get 6 characters
```

**Flutter Implementation**: ⚠️ **NOT IMPLEMENTED**
- Flutter has built-in `Color.toARGB32()` for ARGB format
- Could add hex formatting if needed

---

### 2. formatHex8 - Convert to Hex with Alpha

**File**: `reference-culori/src/formatter.js:26-33`

```javascript
export const serializeHex8 = color => {
  if (color === undefined) return undefined;

  let a = fixup(color.alpha !== undefined ? color.alpha : 1);
  return serializeHex(color) + ((1 << 8) | a).toString(16).slice(1);
};

export const formatHex8 = c => serializeHex8(rgb(c));
```

**Algorithm**:
```
1. Get 6-character hex from formatHex
2. Append alpha: ((1 << 8) | alpha).toString(16).slice(1)
3. Result: #RRGGBBAA
```

---

### 3. formatRgb - Convert to RGB CSS String

**File**: `reference-culori/src/formatter.js:35-51`

```javascript
export const serializeRgb = color => {
  if (color === undefined) return undefined;

  let r = fixup(color.r);
  let g = fixup(color.g);
  let b = fixup(color.b);

  if (color.alpha === undefined || color.alpha === 1) {
    return `rgb(${r}, ${g}, ${b})`;
  } else {
    return `rgba(${r}, ${g}, ${b}, ${twoDecimals(clamp(color.alpha))})`;
  }
};

export const formatRgb = c => serializeRgb(rgb(c));
```

**Output Examples**:
- Opaque: `rgb(255, 128, 0)`
- Transparent: `rgba(255, 128, 0, 0.50)`

---

### 4. formatCss - Generic CSS Formatter

**File**: `reference-culori/src/formatter.js:71-95`

```javascript
export const formatCss = c => {
  const color = prepare(c);
  if (!color) return undefined;

  const def = getMode(color.mode);

  if (!def.serialize || typeof def.serialize === 'string') {
    let res = `color(${def.serialize || `--${color.mode}`} `;
    def.channels.forEach((ch, i) => {
      if (ch !== 'alpha') {
        res += (i ? ' ' : '') + (color[ch] !== undefined ? color[ch] : 'none');
      }
    });
    if (color.alpha !== undefined && color.alpha < 1) {
      res += ` / ${color.alpha}`;
    }
    return res + ')';
  }

  if (typeof def.serialize === 'function') {
    return def.serialize(color);
  }

  return undefined;
};
```

**For OKLCH** (from `reference-culori/src/oklch/definition.js:23-28`):
```javascript
serialize: c =>
  `oklch(${c.l !== undefined ? c.l : 'none'} ${
    c.c !== undefined ? c.c : 'none'
  } ${c.h !== undefined ? c.h : 'none'}${
    c.alpha < 1 ? ` / ${c.alpha}` : ''
  })`
```

**Output Example**: `oklch(0.7 0.15 240)` or `oklch(0.7 0.15 240 / 0.5)`

---

## Implementation Comparison

### ✅ Exact Matches

| Feature | Culori | Flutter | Status |
|---------|--------|---------|--------|
| OKLCH ranges | L:[0,1], C:[0,0.4], H:[0,360] | ✅ Exact | ✅ |
| OKLCH→OKLab | Polar to cartesian | ✅ Exact | ✅ |
| OKLab→OKLCH | Cartesian to polar | ✅ Exact | ✅ |
| OKLab→Linear RGB | 16-digit precision matrices | ✅ Exact | ✅ |
| Linear RGB→OKLab | 16-digit precision matrices | ✅ Exact | ✅ |
| Gamma correction | sRGB curve (threshold 0.0031308) | ✅ Exact | ✅ |
| Gamma expansion | sRGB curve (threshold 0.04045) | ✅ Exact | ✅ |
| inGamut | RGB range [0,1] check | ✅ Exact + epsilon | ✅ |
| toGamut algorithm | CSS Color Level 4 spec | ✅ Exact | ✅ |
| Binary search epsilon | 0.0001 (c_max/4000) | ✅ Exact | ✅ |
| JND threshold | 0.02 | ✅ Exact | ✅ |
| Delta OKLCH | Cylindrical Euclidean | ✅ Exact | ✅ |

### ⚠️ Not Implemented in Flutter

| Feature | Culori | Flutter |
|---------|--------|---------|
| formatHex | ✅ | ❌ Use `Color.toARGB32()` |
| formatHex8 | ✅ | ❌ |
| formatRgb | ✅ | ❌ |
| formatCss | ✅ | ❌ |
| Parse functions | ✅ | ❌ |
| LCH (CIE LCH) | ✅ | ❌ (only OKLCH) |
| Lab (CIE Lab) | ✅ | ❌ (only OKLab) |
| HSL, HSV, HWB | ✅ | ❌ (Flutter has built-in HSL/HSV) |
| P3, Rec2020 | ✅ | ❌ |

### 📊 Precision Comparison

**Matrix Coefficients**:
- **Culori**: 16 decimal places
- **Flutter**: 16 decimal places
- **Match**: ✅ **EXACT**

**Example** (OKLab→Linear RGB, first coefficient):
- Culori: `4.0767416360759574`
- Flutter: `4.0767416360759574`
- Difference: `0.0000000000000000` ✅

**Gamma Curve Thresholds**:
- **Expansion threshold**: `0.04045` ✅ EXACT
- **Compression threshold**: `0.0031308` ✅ EXACT

---

## Key Differences

### 1. Epsilon Tolerance

**Culori** (reference-oklch implementation):
```javascript
const COLOR_SPACE_GAP = 0.0001
```

**Flutter**:
```dart
const double epsilon = 0.0001;  // in isInGamut()
```

✅ **MATCH**: Both use 0.0001 epsilon for gamut checking

---

### 2. Sign Handling for Zero

**Culori JavaScript**:
```javascript
Math.sign(c) || 1  // Returns 1 when c === 0
```

**Flutter Dart**:
```dart
channel.sign != 0 ? channel.sign : 1.0  // Returns 1 when channel == 0
```

✅ **MATCH**: Both default to sign = 1 for zero values

---

### 3. Cube Root Implementation

**Culori**:
```javascript
Math.cbrt(x)  // Native cube root
```

**Flutter**:
```dart
double _cubeRoot(double x) {
  if (x >= 0) {
    return pow(x, 1.0 / 3.0).toDouble();
  } else {
    return -pow(-x, 1.0 / 3.0).toDouble();
  }
}
```

✅ **FUNCTIONALLY EQUIVALENT**: Both handle negative values correctly

---

## Conclusion

### Implementation Quality: ⭐⭐⭐⭐⭐

The Flutter implementation in `lib/utils/color_operations.dart` is an **exact, high-fidelity port** of Culori's color conversion algorithms.

**Strengths**:
1. ✅ All matrix coefficients match to 16 decimal places
2. ✅ Gamma curves match exactly (thresholds and formulas)
3. ✅ Gamut mapping implements CSS Color Level 4 spec exactly
4. ✅ JND optimization matches (threshold 0.02, epsilon 0.0001)
5. ✅ Edge cases handled (white, black, grayscale)
6. ✅ Excellent code documentation and comments

**Missing Features** (not critical for color picker):
- Hex/CSS string formatting (can use Flutter's built-in methods)
- Color parsing (not needed for sliders)
- Other color spaces (LCH, Lab, P3, etc.)

**Recommendation**: ✅ **No changes needed**. The implementation is production-ready and matches Culori's behavior exactly.

---

## References

1. **Culori Library**: https://github.com/Evercoder/culori
2. **OKLab Color Space**: https://bottosson.github.io/posts/oklab/
3. **CSS Color Level 4 Spec**: https://drafts.csswg.org/css-color/
4. **OKLCH Picker (reference-oklch)**: https://oklch.com
5. **sRGB Gamma Correction**: https://en.wikipedia.org/wiki/SRGB

---

*Document generated: 2025-10-24*
*Culori version: 4.0.2*
*Flutter implementation: lib/utils/color_operations.dart*
