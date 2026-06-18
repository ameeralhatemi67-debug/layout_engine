import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:layout_engine/controllers/window_config.dart';

enum ScreenEdge { none, top, bottom, left, right }

/// A unified physics and interaction engine for ALL floating windows.
class BaseWindowInteractions extends GetxController {
  // ===========================================================================
  // 1. CORE STATE
  // ===========================================================================
  var x = 0.0.obs;
  var y = 0.0.obs;
  var isHorizontal = true.obs;
  var isHidden = false.obs;
  var isOpen = true.obs;
  bool _hasInitialized = false; // Prevents overwriting coordinates after boot

  /// Safely injects the default location on the very first boot
  void applyDefaultPosition(String tag, Size screenSize) {
    // 🚀 THE FIX: Abort if Flutter hasn't calculated the real screen size yet!
    if (screenSize.width <= 0 || screenSize.height <= 0) return;

    if (!_hasInitialized) {
      Offset pos = WindowConfig.getDefaultPosition(tag, screenSize);
      x.value = pos.dx;
      y.value = pos.dy;
      isHorizontal.value = WindowConfig.getDefaultOrientation(tag);
      _hasInitialized = true;
    }
  }

  // ===========================================================================
  // 2. DIMENSIONS
  // ===========================================================================
  double windowScale = 1.0;
  double widthH = 100.0;
  double heightH = 100.0;
  double widthV = 100.0;
  double heightV = 100.0;
  double closedSize = 60.0;

  // ===========================================================================
  // 3. CONFIGURATION TWEAKS (Adjust manually until satisfied)
  // ===========================================================================
  double snapZoneThickness =
      30.0; // EDIT THIS: Make it smaller (e.g., 15.0) to give more dragging room!
  var showDebugSnap = false.obs; // Toggles the red striped visual debugger
  double edgePadding = 12.0;
  double snapThreshold = 0.5; // 50% collision rule!
  double drawerVisibleRatio = 0.2; // 20% must remain visible
  double hideVisibleThreshold = 40.0;

  // ===========================================================================
  // 4. FEATURE FLAGS
  // ===========================================================================
  bool enableSnapping = false;
  bool enableOrientationChange = false;
  bool enableStrictBoundaryClamp = false;
  bool enableDrawerBleed = false;
  bool enableOffScreenHiding = false;
  bool enableKeyboardAvoidance = false;
  bool enableMinimize = false;

  // ===========================================================================
  // WINDOW CONFIGURATORS (The Setup Methods)
  // ===========================================================================

  /// Configures the engine for Toolbars (MainHolder & CreateHolder)
  void setupAsToolbar({double length = 280.0}) {
    widthH = length;
    heightH = 60.0;
    widthV = 60.0;
    heightV = length;
    closedSize = 60.0;

    enableSnapping = true;
    enableOrientationChange = true;
    enableStrictBoundaryClamp = true;
    enableOffScreenHiding = true;
    enableMinimize = true;

    enableDrawerBleed = false;
    enableKeyboardAvoidance = false;
  }

  /// Configures the engine for the Split Editor Window
  void setupAsSplitWindow({double scale = 1.0}) {
    windowScale = scale;

    // Strict 17:6 Ratio modified by the scale factor
    widthH = 340.0 * scale;
    heightH = 120.0 * scale;
    widthV = 120.0 * scale;
    heightV = 380.0 * scale;

    isOpen.value = false; // Starts hidden

    enableSnapping = true;
    enableOrientationChange = true;
    enableDrawerBleed = true;
    enableKeyboardAvoidance = true;

    enableStrictBoundaryClamp = false;
    enableOffScreenHiding = false;
    enableMinimize = false;
  }

  /// Configures the engine for the Floating Layer Matrix
  void setupAsLayerWindow({double width = 220.0, double height = 400.0}) {
    widthH = width;
    heightH = height;
    widthV = width;
    heightV = height;

    isOpen.value = true;
    isHidden.value = false;
    isHorizontal.value = false; // Strictly vertical

    // The Specific Physics requested:
    enableDrawerBleed = true; // Enables the 80% off-screen hide
    enableSnapping = false; // Free-floating
    enableOrientationChange = false; // Will never rotate to horizontal

    enableStrictBoundaryClamp = false;
    enableOffScreenHiding = false;
    enableMinimize = false;
    enableKeyboardAvoidance = false;
  }

  // ===========================================================================
  // SPECIFIC UX ACTIONS
  // ===========================================================================

  // --- Toolbar Actions ---
  void toggleOpen(Size screenSize) {
    isOpen.value = !isOpen.value;
    if (isOpen.value) {
      onPanEnd(DragEndDetails(velocity: Velocity.zero), screenSize);
    }
  }

  void restoreHolder() {
    isHidden.value = false;
    isOpen.value = true;
    isHorizontal.value = true;
    x.value = 20.0;
    y.value = 20.0;
  }

  void openSplitWindow(Size screenSize) {
    isOpen.value = true;
    List<Rect> activeWindows = getActiveWindowRects('Split');
    spawnWithAntiOverlap(screenSize, activeWindows, 'Split'); // Passed tag
  }

  void closeSplitWindow() {
    isOpen.value = false;
  }

  void updateDimensions(int numberOfSplits) {
    widthH = 340.0;
    heightH = 120.0;
    widthV = 120.0;
    heightV = 340.0;
  }

  /// NEW HELPER: Scans the OS and returns the exact Rect (hit-box) of every open window!
  List<Rect> getActiveWindowRects(String excludeTag) {
    List<String> knownTags = ['Main', 'Create', 'Split', 'Layer'];
    List<Rect> rects = [];

    for (String tag in knownTags) {
      if (tag == excludeTag) continue;
      if (Get.isRegistered<BaseWindowInteractions>(tag: tag)) {
        final logic = Get.find<BaseWindowInteractions>(tag: tag);
        if (logic.isOpen.value && !logic.isHidden.value) {
          double w = logic.isHorizontal.value ? logic.widthH : logic.widthV;
          double h = logic.isHorizontal.value ? logic.heightH : logic.heightV;
          rects.add(Rect.fromLTWH(logic.x.value, logic.y.value, w, h));
        }
      }
    }
    return rects;
  }

  // --- Smart Window Spawning ---
  void spawnWithAntiOverlap(
    Size screenSize,
    List<Rect> openWindows,
    String tag,
  ) {
    // 1. Get Defaults from Central Config
    Offset defaultPos = WindowConfig.getDefaultPosition(tag, screenSize);
    bool defaultIsHorizontal = WindowConfig.getDefaultOrientation(tag);

    // HELPER: Attempts to cascade and fit the window without colliding
    bool tryFit(bool testHorizontal) {
      isHorizontal.value = testHorizontal;
      double w = testHorizontal ? widthH : widthV;
      double h = testHorizontal ? heightH : heightV;
      double shiftOffset = 30.0;

      for (int i = 0; i < 15; i++) {
        // SMART CASCADE: If default is on the right side of the screen, cascade LEFT and DOWN
        // If it is on the left side, cascade RIGHT and DOWN
        double dirX = (defaultPos.dx > screenSize.width / 2) ? -1 : 1;

        double proposedX = defaultPos.dx + (i * shiftOffset * dirX);
        double proposedY = defaultPos.dy + (i * shiftOffset);

        // Keep it strictly inside the screen bounds
        if (proposedX < 16.0) proposedX = 16.0;
        if (proposedX + w > screenSize.width)
          proposedX = screenSize.width - w - 16.0;
        if (proposedY + h > screenSize.height)
          proposedY = screenSize.height - h - 16.0;

        Rect proposedRect = Rect.fromLTWH(proposedX, proposedY, w, h);
        bool hasCollision = openWindows.any(
          (win) => win.overlaps(proposedRect),
        );

        if (!hasCollision) {
          x.value = proposedX;
          y.value = proposedY;
          return true; // Success!
        }
      }
      return false; // Failed to fit
    }

    // 2. Attempt 1: Try to fit using the preferred Default Orientation
    if (tryFit(defaultIsHorizontal)) return;

    // 3. Attempt 2: Try the Alternate Orientation (if the window supports it)
    if (enableOrientationChange) {
      if (tryFit(!defaultIsHorizontal)) return;
    }

    // 4. Fallback: No space found anywhere. Force it exactly to its default position and orientation!
    isHorizontal.value = defaultIsHorizontal;
    x.value = defaultPos.dx;
    y.value = defaultPos.dy;
  }

  // ===========================================================================
  // INTERACTION MODULES (The Physics)
  // ===========================================================================

  void onPanUpdate(DragUpdateDetails details) {
    x.value += details.delta.dx;
    y.value += details.delta.dy;
  }

  void onPanEnd(DragEndDetails details, Size screenSize) {
    double currentW = (enableMinimize && !isOpen.value)
        ? closedSize
        : (isHorizontal.value ? widthH : widthV);
    double currentH = (enableMinimize && !isOpen.value)
        ? closedSize
        : (isHorizontal.value ? heightH : heightV);

    if (enableOffScreenHiding) {
      if (_checkOffScreenHide(screenSize, currentW, currentH)) {
        isHidden.value = true;
        return;
      }
    }

    if (enableSnapping && (!enableMinimize || isOpen.value)) {
      Map<ScreenEdge, double> distances = _detectBoundaries(
        screenSize,
        currentW,
        currentH,
      );
      ScreenEdge edgeToSnap = _calculateSnapEdge(distances, currentW, currentH);

      if (edgeToSnap != ScreenEdge.none) {
        if (enableOrientationChange) {
          _applyOrientation(edgeToSnap);
          currentW = isHorizontal.value ? widthH : widthV;
          currentH = isHorizontal.value ? heightH : heightV;
        }
        _executeSnap(edgeToSnap, screenSize, currentW, currentH);
      }
    }

    if (enableDrawerBleed) {
      _clampWithDrawerBleed(screenSize, currentW, currentH);
    } else if (enableStrictBoundaryClamp) {
      _clampToScreen(screenSize, currentW, currentH);
    }
  }

  void adjustForKeyboard(double keyboardHeight, Size screenSize) {
    if (!enableKeyboardAvoidance || keyboardHeight == 0) return;
    if (enableMinimize && !isOpen.value) return;

    double currentH = isHorizontal.value ? heightH : heightV;
    double bottomEdgeOfWindow = y.value + currentH;
    double topOfKeyboard = screenSize.height - keyboardHeight;

    if (bottomEdgeOfWindow > topOfKeyboard) {
      y.value = topOfKeyboard - currentH - 16.0;
    }
  }

  // ===========================================================================
  // INTERNAL MATH HELPERS
  // ===========================================================================

  bool _checkOffScreenHide(Size screenSize, double w, double h) {
    return (x.value < -w + hideVisibleThreshold ||
        x.value > screenSize.width - hideVisibleThreshold ||
        y.value < -h + hideVisibleThreshold ||
        y.value > screenSize.height - hideVisibleThreshold);
  }

  Map<ScreenEdge, double> _detectBoundaries(
    Size screenSize,
    double w,
    double h,
  ) {
    // FIX 1: Prevent bottom snapping from going under the phone notch/home bar
    double safeBottom = screenSize.height - Get.mediaQuery.padding.bottom;
    return {
      ScreenEdge.top: y.value,
      ScreenEdge.bottom: safeBottom - (y.value + h),
      ScreenEdge.left: x.value,
      ScreenEdge.right: screenSize.width - (x.value + w),
    };
  }

  ScreenEdge _calculateSnapEdge(
    Map<ScreenEdge, double> distances,
    double w,
    double h,
  ) {
    ScreenEdge closestEdge = ScreenEdge.none;
    double minDistance = double.infinity;

    distances.forEach((edge, distance) {
      if (distance < minDistance) {
        minDistance = distance;
        closestEdge = edge;
      }
    });

    double collisionThreshold =
        (closestEdge == ScreenEdge.left || closestEdge == ScreenEdge.right)
        ? -(w * snapThreshold)
        : -(h * snapThreshold);

    // FIX 2: Smart Snapping.
    // It only snaps if you are within 30px of the edge inside the screen,
    // OR if you are pushing into the wall but haven't crossed the 50% mark yet!
    // If you drag it past 50%, it lets go so the DrawerBleed can hold it off-screen.
    if (minDistance <= snapZoneThickness && minDistance >= collisionThreshold) {
      return closestEdge;
    }

    return ScreenEdge.none;
  }

  void _applyOrientation(ScreenEdge edge) {
    if (edge == ScreenEdge.top || edge == ScreenEdge.bottom) {
      isHorizontal.value = true;
    } else if (edge == ScreenEdge.left || edge == ScreenEdge.right) {
      isHorizontal.value = false;
    }
  }

  void _executeSnap(ScreenEdge edge, Size screenSize, double w, double h) {
    double safeBottom = screenSize.height - Get.mediaQuery.padding.bottom;
    switch (edge) {
      case ScreenEdge.top:
        y.value = edgePadding;
        break;
      case ScreenEdge.bottom:
        y.value = safeBottom - h - edgePadding;
        break;
      case ScreenEdge.left:
        x.value = edgePadding;
        break;
      case ScreenEdge.right:
        x.value = screenSize.width - w - edgePadding;
        break;
      case ScreenEdge.none:
        break;
    }
  }

  void _clampToScreen(Size screenSize, double w, double h) {
    double safeBottom = screenSize.height - Get.mediaQuery.padding.bottom;
    if (x.value < edgePadding) x.value = edgePadding;
    if (x.value > screenSize.width - w - edgePadding)
      x.value = screenSize.width - w - edgePadding;
    if (y.value < edgePadding) y.value = edgePadding;
    if (y.value > safeBottom - h - edgePadding)
      y.value = safeBottom - h - edgePadding;
  }

  void _clampWithDrawerBleed(Size screenSize, double w, double h) {
    double minVisibleW = w * drawerVisibleRatio;
    double minVisibleH = h * drawerVisibleRatio;
    double safeBottom = screenSize.height - Get.mediaQuery.padding.bottom;

    if (x.value < -w + minVisibleW) x.value = -w + minVisibleW;
    if (x.value > screenSize.width - minVisibleW)
      x.value = screenSize.width - minVisibleW;
    if (y.value < -h + minVisibleH) y.value = -h + minVisibleH;
    if (y.value > safeBottom - minVisibleH) y.value = safeBottom - minVisibleH;
  }
}

/// Visual Debugger: Renders light red striped zones to show exact snapping areas.
class DebugSnapZonesOverlay extends StatelessWidget {
  const DebugSnapZonesOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    // Look for ANY registered interactions to read the zone thickness
    if (!Get.isRegistered<BaseWindowInteractions>(tag: 'Main'))
      return const SizedBox.shrink();
    final logic = Get.find<BaseWindowInteractions>(tag: 'Main');

    return Obx(() {
      if (!logic.showDebugSnap.value) return const SizedBox.shrink();

      final thickness = logic.snapZoneThickness;
      final safeBottom = MediaQuery.of(context).padding.bottom;

      Widget stripedBar(double w, double h) {
        return Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: Colors.redAccent.withOpacity(0.2), // Light red
            // A simple CSS-like repeating stripe trick in Flutter
            gradient: const RepeatingLinearGradient(
              colors: [Colors.transparent, Colors.black12],
              stops: [0.0, 0.5],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: Colors.redAccent, width: 1),
          ),
        );
      }

      return IgnorePointer(
        // Lets you click through the visual!
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: stripedBar(double.infinity, thickness),
            ), // Top
            Positioned(
              bottom: safeBottom,
              left: 0,
              right: 0,
              child: stripedBar(double.infinity, thickness),
            ), // Bottom
            Positioned(
              top: 0,
              bottom: 0,
              left: 0,
              child: stripedBar(thickness, double.infinity),
            ), // Left
            Positioned(
              top: 0,
              bottom: 0,
              right: 0,
              child: stripedBar(thickness, double.infinity),
            ), // Right
          ],
        ),
      );
    });
  }
}

// Helper for the stripes
class RepeatingLinearGradient extends LinearGradient {
  const RepeatingLinearGradient({
    required super.colors,
    required super.stops,
    super.begin,
    super.end,
  });
  @override
  Shader createShader(Rect rect, {TextDirection? textDirection}) {
    return super.createShader(
      Rect.fromLTWH(0, 0, 20, 20),
      textDirection: textDirection,
    ); // 20px stripes
  }
}
