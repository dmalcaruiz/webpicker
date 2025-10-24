# Mixer Extremes Refactor - Product Requirements Document

## Overview
Simplify the mixer extreme controls by replacing the complex arrow button system (⬇️ takeIn / ⬆️ giveTo / disconnect) with simple circle widgets that behave exactly like palette boxes.

## Current System (Overcomplicated)
- Arrow buttons (⬇️⬆️) for each extreme
- Three actions per extreme: takeIn, giveTo, disconnect
- Tracking state managed separately from palette selection
- No visual indication of which extreme is selected
- Users can't copy/paste extreme colors using global actions

## Proposed System (Simple & Unified)
Two circles below the mixer slider that:
- **Look like palette boxes** (circular instead of rounded squares)
- **Tap to select** - deselects any selected palette box
- **Integrated with global copy/paste buttons** - no separate menus needed
- **Only one selection at a time** - tapping a circle deselects boxes, tapping a box deselects circles
- **Visual feedback** - selected circle shows same border/highlight as selected boxes

## User Interaction Flow

### Selection Behavior
1. **Tap left circle** → Deselect any box, select left extreme, sliders show left extreme color
2. **Tap right circle** → Deselect any box, select right extreme, sliders show right extreme color
3. **Tap any palette box** → Deselect both circles, select box, sliders show box color
4. **Tap selected circle again** → Deselect it (sliders return to neutral state)

### Copy/Paste Behavior (Using Existing Global Buttons)
1. **With left circle selected** → Copy button copies left extreme color to clipboard
2. **With right circle selected** → Copy button copies right extreme color to clipboard
3. **With left circle selected + Paste** → Updates left extreme color from clipboard
4. **With right circle selected + Paste** → Updates right extreme color from clipboard

### Slider Behavior (Unchanged)
- Dragging mixer slider still interpolates between left/right extremes in OKLCH
- Slider value still updates as you drag
- Sliders disconnect from extremes when you manually adjust L/C/H sliders

## Technical Architecture

### 1. New Model: `ExtremeColorItem`
**File**: `lib/models/extreme_color_item.dart`

```dart
/// Represents a mixer extreme color (left or right)
class ExtremeColorItem {
  final String id;  // 'left' or 'right'
  final Color color;
  final bool isSelected;
  final OklchValues oklchValues;

  // Constructor, copyWith, etc.
}
```

### 2. New Widget: `ExtremeColorCircle`
**File**: `lib/widgets/color_picker/extreme_color_circle.dart`

A simple circular widget that:
- Displays the extreme color
- Shows selection state (border/highlight like palette boxes)
- Handles tap gesture
- Size: ~40-48px diameter

### 3. New Widget: `MixerExtremesRow`
**File**: `lib/widgets/color_picker/mixer_extremes_row.dart`

Container for the two circles:
- Positioned below the mixer slider
- Horizontal layout: [Left Circle] ←slider→ [Right Circle]
- Spacing and alignment
- Passes tap events up to parent

### 4. Updated: `ColorPickerControls`
**File**: `lib/widgets/color_picker/color_picker_controls.dart`

Changes:
- Remove arrow button handlers (`_handleLeftExtremeAction`, `_handleRightExtremeAction`)
- Remove tracking state flags (`isLeftExtremeTracking`, `isRightExtremeTracking`)
- Add new callbacks: `onExtremeSelected`, `onExtremeDeselected`
- Pass extreme selection state to `MixerExtremesRow`

### 5. Updated: `HomeScreen`
**File**: `lib/screens/home_screen.dart`

Changes:
- Add state: `String? selectedExtremeId` (null, 'left', or 'right')
- Add state: `ExtremeColorItem leftExtreme`, `ExtremeColorItem rightExtreme`
- Update `_onPaletteItemTap`: deselect extremes when box is tapped
- Add `_onExtremeTap`: deselect boxes, select extreme, update sliders
- Update copy handler: check if extreme is selected
- Update paste handler: check if extreme is selected

### 6. Updated: `ActionButtonsRow` (Copy/Paste Logic)
**File**: `lib/widgets/home/action_buttons_row.dart`

Changes:
- Accept `selectedExtremeId` parameter
- Copy button: if extreme selected, copy extreme color instead of current color
- Paste button: if extreme selected, update extreme color instead of current color

## Selection State Management

### Unified Selection State (Only One Selected at a Time)
```dart
// In HomeScreen state:
String? selectedPaletteItemId;  // Existing
String? selectedExtremeId;      // New: 'left', 'right', or null

// Selection rules:
// - If selectedPaletteItemId != null → selectedExtremeId = null
// - If selectedExtremeId != null → selectedPaletteItemId = null
// - Both can be null (nothing selected)
```

## Visual Design

### Circle Appearance
- **Size**: 44px diameter (slightly smaller than palette boxes)
- **Unselected**:
  - Border: 2px white with 30% opacity
  - No shadow
- **Selected**:
  - Border: 3px white with 90% opacity
  - Drop shadow: similar to selected palette boxes
- **Position**: Below mixer slider, aligned with slider endpoints

### Layout
```
[Lightness Slider]
[Chroma Slider]
[Hue Slider]
[○ ←————Mixer————→ ○]  ← Left/Right circles
     ⬆                ⬆
  Left Extreme    Right Extreme
```

## Implementation Steps

1. **Create `ExtremeColorItem` model** (simple data class)
2. **Create `ExtremeColorCircle` widget** (stateless, displays one circle)
3. **Create `MixerExtremesRow` widget** (stateless, displays two circles)
4. **Update `HomeScreen`**: Add extreme state, selection handlers, integrate with copy/paste
5. **Update `ColorPickerControls`**: Remove arrow button code, add extreme selection callbacks
6. **Update `MixedChannelSlider`**: Remove arrow button rendering, use `MixerExtremesRow` below slider
7. **Update `ActionButtonsRow`**: Handle extreme copy/paste

## Benefits

1. **Simpler mental model** - extremes work exactly like palette boxes
2. **Unified selection system** - one selection paradigm throughout the app
3. **Less code** - remove complex tracking state and action handlers
4. **Better UX** - visual feedback shows which extreme is selected
5. **Consistent copy/paste** - use existing global buttons instead of separate menus

## Testing Checklist

- [ ] Tap left circle → left extreme selected, boxes deselected, sliders update
- [ ] Tap right circle → right extreme selected, boxes deselected, sliders update
- [ ] Tap palette box → box selected, extremes deselected
- [ ] Copy with left extreme selected → copies left extreme color
- [ ] Paste with left extreme selected → updates left extreme color
- [ ] Copy with right extreme selected → copies right extreme color
- [ ] Paste with right extreme selected → updates right extreme color
- [ ] Drag mixer slider → still interpolates in OKLCH between extremes
- [ ] Adjust L/C/H sliders → disconnects from extremes (if connected)
- [ ] Tap selected circle again → deselects it

## Notes

- **No changes to slider interpolation** - OKLCH interpolation stays as-is
- **No long-press menus** - use existing global copy/paste buttons
- **Extremes persist** - colors don't reset when deselected
- **Independent from palette** - extreme colors are separate from palette items
