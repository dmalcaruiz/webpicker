# Architecture Overview

This document explains the architecture decisions for the webpicker app.

## Architecture Philosophy

**Keep it simple. Use the right tool for the job.**

- **Coordinators** orchestrate complex operations across providers (like undo/redo)

- **Providers** hold state and notify listeners

- **Controllers** only when you need to handle stateful UI behavior (like drag-drop)

- **Widgets** handle UI and coordinate between providers

- **Services** stateful utilities

- **Utils & Handlers** contain stateless pure utility functions

## Current Structure

### State Management (Providers)

All application state lives in Providers connected via `MultiProvider` in `main.dart`:

- `ColorEditorProvider`: Manages the state related to the color editor, likely including the currently selected color and its properties.
- `ColorGridProvider`: Handles the state of the color grid, such as the colors displayed and their arrangement.
- `ExtremeColorsProvider`: Manages a collection of "extreme" colors, possibly for displaying a palette or color history.
- `BgColorProvider`: Controls the background color of the application or specific elements.
- `SettingsProvider`: Stores and manages user settings and preferences.

### Coordinators

**Coordinators** orchestrate complex operations across multiple providers, ensuring atomicity and consistency. The primary example is the `StateHistoryCoordinator`:

- `StateHistoryCoordinator`: Manages the application's undo/redo functionality. It captures snapshots of the entire application state (across `ColorEditorProvider`, `ColorGridProvider`, `ExtremeColorsProvider`, `BgColorProvider`, and `SettingsProvider`) and restores them when an undo or redo action is performed. This ensures that state changes are synchronized across all relevant parts of the application.

### Services

**Services** are stateful utilities that encapsulate specific functionalities and often interact with external systems or provide core application logic. They are designed to be reusable and independent of UI components.

- `ClipboardService`: Handles interactions with the system clipboard, specifically for copying and pasting color values in various formats (e.g., hex strings).
- `IccColorManager`: A singleton service responsible for ICC profile color transformations. It applies real-time display filters to simulate how colors would appear when printed on a specific device (e.g., Canon ImagePROGRAPH PRO-1000), acting as a surface-level filter without modifying the underlying ideal color state.
- `UndoRedoService`: Manages the undo/redo history for the application by storing and retrieving `AppStateSnapshot` objects. It provides functionality to push new states, undo the last action, redo a previously undone action, and clear the history.

### Utilities & Handlers

**Utilities & Handlers** consist of stateless or minimally stateful pure utility functions and classes that provide common functionalities without managing global application state. They are typically used by providers, services, or widgets to perform specific tasks.

- `ColorGridManager` (`color_grid_operations.dart`): A static class that centralizes operations for managing the color grid, including adding, removing, reordering, selecting, and updating `ColorGridItem` instances. It leverages `color_operations.dart` for color conversions.
- `Color Operations` (`color_operations.dart`): A comprehensive set of pure functions for color space conversions (e.g., OKLCH, OKLab, Linear RGB, CIE Lab, XYZ D65, sRGB), gamut checking, and gamut mapping. It includes the logic for generating perceptually uniform gradients for sliders and interpolating colors in OKLCH space. This utility interacts with `IccColorManager` for advanced color profile filtering.
- `GlobalPointerTracker` (`global_pointer_tracker.dart`): Provides global tracking of pointer events, allowing UI elements like sliders to maintain active tracking even when the pointer moves outside their visual bounds. It's implemented using an `InheritedWidget` to make the tracker state available throughout the widget tree.
- `Mixbox Color Mixing` (`mixbox.dart` and `mixbox_data.dart`): Implements a pigment-based color mixing algorithm (`lerpMixbox`) that simulates how real-world paints mix. It uses a large, pre-calculated 7D lookup table (`mixboxLutData`) and trilinear interpolation to achieve natural and saturated color transitions, including realistic hue shifts.

### Widgets

**Widgets** are the building blocks of the user interface, responsible for rendering UI elements and handling user interactions. The application uses a modular widget structure, organizing widgets into logical categories:

- **`color_picker`**: Contains widgets related to color selection and manipulation, such as individual color items, color picker controls, color preview boxes, extreme color indicators, mixer extreme rows, OKLCH gradient sliders, and the reorderable color grid view.
- **`common`**: Houses reusable UI components that are shared across different parts of the application, including global action buttons, gradient painters, plus/minus adjuster buttons, and undo/redo buttons.
- **`home`**: Includes widgets specific to the home screen layout and functionality, such as action button rows, the bottom action bar, delete zone overlays, drag-delete zones, the home app bar, real pigments toggle, and sheet grabbing handles.
- **`sliders`**: Provides specialized widgets for interactive sliders, including diamond slider thumbs, invisible sliders, and mixer sliders.

### Models and Data Flow

**Models** define the structure of the data used throughout the application. They are typically immutable and represent the core entities and their properties. The data flow primarily involves these models being managed by providers and services, and then consumed by widgets for display.

- `AppStateSnapshot` (`app_state_snapshot.dart`): An immutable record of the entire application state at a specific point in time. It includes lists of `ColorGridItem`s, `ExtremeColorItem`s, the current color being edited, background color details, and selection states. This model is crucial for the undo/redo mechanism coordinated by the `StateHistoryCoordinator`.
- `ColorGridItem` (`color_grid_item.dart`): Represents an individual color entry within the color grid. Each item has a unique ID, an sRGB `Color` value, `OklchValues` (as the source of truth), an optional name, creation and modification timestamps, and a selection status. It includes factories for creation from either `Color` or `OklchValues`.
- `ColorGridState` (`color_grid_state.dart`): An immutable aggregate of the current state of the color grid, containing a list of `ColorGridItem`s and the ID of the currently selected item. It offers convenient getters for accessing grid properties and the selected item.
- `ExtremeColorItem` (`extreme_color_item.dart`): A specialized color item model representing the 'left' or 'right' extreme colors used in the color mixer. Similar to `ColorGridItem`, it includes an ID, sRGB `Color`, selection status, and `OklchValues`, facilitating consistent data handling with grid items.

### Home Screen Flow (`home_screen.dart`)

`HomeScreen` acts as the main orchestrator for the application's UI and state interactions. It's a `StatefulWidget` that manages several widget-scoped objects and local UI state, connecting them to the global providers and services.

Key aspects of its flow:

- **Widget-Scoped Objects**: `HomeScreen` initializes and holds instances of `DragDropController` (for UI-specific drag-drop logic), `StateHistoryCoordinator` (to orchestrate undo/redo across all providers), and `UndoRedoService` (to manage the history stack). These objects are scoped to the `HomeScreen`'s lifecycle.
- **Local UI State**: It manages UI-specific state such as `SnappingSheetController` for the bottom sheet, `_currentSheetHeight`, `ScrollController`, and flags like `_isInteractingWithSlider` to control UI behavior.
- **Initialization (`initState`)**: During initialization, `HomeScreen` sets up the `StateHistoryCoordinator` by providing it with references to all the application's providers (`ColorEditorProvider`, `ColorGridProvider`, `ExtremeColorsProvider`, `BgColorProvider`, `SettingsProvider`). It also initializes the `DragDropController`, loads initial data (like sample grid colors), and asynchronously initializes the `IccColorManager`.
- **Provider Interactions**: `HomeScreen` uses `Provider.of` or `context.read` to access and interact with various providers, updating their state based on user actions or internal logic. It listens to changes in providers to rebuild its UI where necessary.
- **Event Handling**: It contains methods to handle various user interactions, such as adding colors, selecting colors, deleting colors (via drag-drop), and managing undo/redo actions. These methods often involve calling `_coordinator.saveState` to record changes for undo/redo.
- **UI Composition**: The `build` method composes the main application layout, including the `HomeAppBar`, `ReorderableColorGridView`, `SnappingSheet` (which contains the `ColorPickerControls`), and `BottomActionBar`. It also overlays the `DeleteZoneOverlay` when a drag operation is active.
- **EyeDropper Integration**: The `EyeDrop` widget (from `cyclop_eyedropper`) wraps the `HomeScreen`, enabling the global eye-dropper functionality.
