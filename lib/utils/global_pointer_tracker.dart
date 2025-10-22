import 'package:flutter/material.dart';

/// Global pointer tracker that captures pointer events once a slider is activated
/// This allows tracking finger movement even when it leaves the slider bounds
class GlobalPointerTracker extends InheritedWidget {
  final GlobalPointerTrackerState state;

  const GlobalPointerTracker({
    super.key,
    required this.state,
    required super.child,
  });

  static GlobalPointerTrackerState? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<GlobalPointerTracker>()
        ?.state;
  }

  @override
  bool updateShouldNotify(GlobalPointerTracker oldWidget) => false;
}

class GlobalPointerTrackerState extends ChangeNotifier {
  Function(PointerMoveEvent)? _onPointerMove;
  Function(PointerUpEvent)? _onPointerUp;
  Function(PointerCancelEvent)? _onPointerCancel;
  int? _activePointerId;

  /// Register a slider to receive global pointer events
  void registerSlider({
    required int pointerId,
    required Function(PointerMoveEvent) onMove,
    required Function(PointerUpEvent) onUp,
    required Function(PointerCancelEvent) onCancel,
  }) {
    _activePointerId = pointerId;
    _onPointerMove = onMove;
    _onPointerUp = onUp;
    _onPointerCancel = onCancel;
    print('🌍 Global tracker ACTIVATED for pointer $pointerId');
    notifyListeners(); // Notify that tracking state changed
  }

  /// Unregister the active slider
  void unregisterSlider() {
    print('🌍 Global tracker DEACTIVATED');
    _activePointerId = null;
    _onPointerMove = null;
    _onPointerUp = null;
    _onPointerCancel = null;
    notifyListeners(); // Notify that tracking state changed
  }

  /// Handle global pointer move events
  void handlePointerMove(PointerMoveEvent event) {
    if (_activePointerId == event.pointer) {
      _onPointerMove?.call(event);
    }
  }

  /// Handle global pointer up events
  void handlePointerUp(PointerUpEvent event) {
    if (_activePointerId == event.pointer) {
      _onPointerUp?.call(event);
      unregisterSlider();
    }
  }

  /// Handle global pointer cancel events
  void handlePointerCancel(PointerCancelEvent event) {
    if (_activePointerId == event.pointer) {
      _onPointerCancel?.call(event);
      unregisterSlider();
    }
  }

  bool get isTracking => _activePointerId != null;
}

/// Widget wrapper that provides global pointer tracking
class GlobalPointerTrackerProvider extends StatefulWidget {
  final Widget child;

  const GlobalPointerTrackerProvider({
    super.key,
    required this.child,
  });

  @override
  State<GlobalPointerTrackerProvider> createState() =>
      _GlobalPointerTrackerProviderState();
}

class _GlobalPointerTrackerProviderState
    extends State<GlobalPointerTrackerProvider> {
  final GlobalPointerTrackerState _trackerState = GlobalPointerTrackerState();

  @override
  void initState() {
    super.initState();
    // Listen to tracking state changes to rebuild when needed
    _trackerState.addListener(_onTrackingStateChanged);
  }

  @override
  void dispose() {
    _trackerState.removeListener(_onTrackingStateChanged);
    super.dispose();
  }

  void _onTrackingStateChanged() {
    setState(() {
      // Rebuild when tracking state changes
    });
  }

  @override
  Widget build(BuildContext context) {
    // Only wrap with Listener when actively tracking
    // This prevents interference with SnappingSheet dragging
    if (_trackerState.isTracking) {
      return Listener(
        behavior: HitTestBehavior.translucent,
        onPointerMove: _trackerState.handlePointerMove,
        onPointerUp: _trackerState.handlePointerUp,
        onPointerCancel: _trackerState.handlePointerCancel,
        child: GlobalPointerTracker(
          state: _trackerState,
          child: widget.child,
        ),
      );
    } else {
      // No Listener when not tracking - let SnappingSheet handle events normally
      return GlobalPointerTracker(
        state: _trackerState,
        child: widget.child,
      );
    }
  }
}

