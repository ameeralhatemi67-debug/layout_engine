import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:layout_engine/controllers/window_config.dart';

class BaseWindowInteractions extends GetxController {
  var x = 0.0.obs;
  var y = 0.0.obs;
  var isHorizontal = true.obs;
  var isHidden = false.obs;
  var isOpen = true.obs;
  bool _hasInitialized = false;

  void applyDefaultPosition(String tag, Size screenSize) {
    if (screenSize.width <= 0 || screenSize.height <= 0) return;
    if (!_hasInitialized) {
      Offset pos = WindowConfig.getDefaultPosition(tag, screenSize);
      x.value = pos.dx;
      y.value = pos.dy;
      isHorizontal.value = WindowConfig.getDefaultOrientation(tag);
      _hasInitialized = true;
    }
  }

  double windowScale = 1.0;
  double widthH = 100.0;
  double heightH = 100.0;
  double widthV = 100.0;
  double heightV = 100.0;
  double closedSize = 60.0;

  static const double defaultDetectDistance = 50.0;
  static const double defaultED = 12.0; // Edge Distance (Padding)
  static const double defaultLWH = 200.0; // Line Width Horizontal
  static const double defaultLWV = 300.0; // Line Width Vertical
  static const double defaultLP = 15.0; // Line Position (Offset)

  // Global Edge Padding
  var detectDistance = defaultDetectDistance.obs;

  // Individual Distances from the Edge (ED)
  var topPadding = defaultED.obs;
  var bottomPadding = defaultED.obs;
  var leftPadding = defaultED.obs;
  var rightPadding = defaultED.obs;

  // Visual Target Line Lengths (LW)
  var topLength = defaultLWH.obs;
  var bottomLength = defaultLWH.obs;
  var leftLength = defaultLWV.obs;
  var rightLength = defaultLWV.obs;

  // =======================================================
  // 🚀 NEW: LINE POSITIONS / LP (Task 1.2)
  // =======================================================
  var topPosition = defaultLP.obs;
  var bottomPosition = defaultLP.obs;
  var leftPosition = defaultLP.obs;
  var rightPosition = defaultLP.obs;

  // 🚀 NEW: Individual Line Positions (LP translations along parallel axes)
  var leftLinePos = 0.0.obs;
  var rightLinePos = 0.0.obs;
  var topLinePos = 0.0.obs;
  var bottomLinePos = 0.0.obs;

  // The Two Visual Debuggers
  var showDebugSnap = false.obs;
  var showDetectionZones = false.obs;

  double snapThreshold = 0.5;
  double drawerVisibleRatio = 0.2;
  double hideVisibleThreshold = 40.0;

  double? exactTopSnapX;
  double? exactBottomSnapX;

  bool enableSnapping = false;
  bool enableOrientationChange = false;
  bool enableStrictBoundaryClamp = false;
  bool enableDrawerBleed = false;
  bool enableOffScreenHiding = false;
  bool enableKeyboardAvoidance = false;
  bool enableMinimize = false;

  void setupAsToolbar({double length = 280.0}) {
    widthH = length;
    heightH = 60.0;
    widthV = 60.0;
    heightV = length;
    closedSize = 60.0;

    enableSnapping = true;
    enableOrientationChange = true;
    enableStrictBoundaryClamp = false;
    enableOffScreenHiding = false; // 🚀 DISABLED FOR TESTING AS REQUESTED!
    enableMinimize = true;
    enableDrawerBleed = false;
    enableKeyboardAvoidance = false;
  }

  void resetSnappingDefaults() {
    detectDistance.value = defaultDetectDistance;

    topPadding.value = defaultED;
    bottomPadding.value = defaultED;
    leftPadding.value = defaultED;
    rightPadding.value = defaultED;

    topLength.value = defaultLWH;
    bottomLength.value = defaultLWH;
    leftLength.value = defaultLWV;
    rightLength.value = defaultLWV;

    topPosition.value = defaultLP;
    bottomPosition.value = defaultLP;
    leftPosition.value = defaultLP;
    rightPosition.value = defaultLP;
  }

  void setupAsSplitWindow({double scale = 1.0}) {
    windowScale = scale;
    widthH = 340.0 * scale;
    heightH = 120.0 * scale;
    widthV = 120.0 * scale;
    heightV = 380.0 * scale;
    isOpen.value = false;
    enableSnapping = true;
    enableOrientationChange = true;
    enableDrawerBleed = true;
    enableKeyboardAvoidance = true;
    enableStrictBoundaryClamp = false;
    enableOffScreenHiding = false;
    enableMinimize = false;
  }

  void setupAsLayerWindow({double width = 220.0, double height = 400.0}) {
    widthH = width;
    heightH = height;
    widthV = width;
    heightV = height;
    isOpen.value = true;
    isHidden.value = false;
    isHorizontal.value = false;
    enableDrawerBleed = true;
    enableSnapping = false;
    enableOrientationChange = false;
    enableStrictBoundaryClamp = false;
    enableOffScreenHiding = false;
    enableMinimize = false;
    enableKeyboardAvoidance = false;
  }

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
    spawnWithAntiOverlap(screenSize, getActiveWindowRects('Split'), 'Split');
  }

  void closeSplitWindow() => isOpen.value = false;

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

  void spawnWithAntiOverlap(
    Size screenSize,
    List<Rect> openWindows,
    String tag,
  ) {
    Offset defaultPos = WindowConfig.getDefaultPosition(tag, screenSize);
    bool defaultIsHorizontal = WindowConfig.getDefaultOrientation(tag);

    bool tryFit(bool testHorizontal) {
      isHorizontal.value = testHorizontal;
      double w = testHorizontal ? widthH : widthV;
      double h = testHorizontal ? heightH : heightV;
      double shiftOffset = 30.0;

      for (int i = 0; i < 15; i++) {
        double dirX = (defaultPos.dx > screenSize.width / 2) ? -1 : 1;
        double proposedX = defaultPos.dx + (i * shiftOffset * dirX);
        double proposedY = defaultPos.dy + (i * shiftOffset);
        if (proposedX < 16.0) proposedX = 16.0;
        if (proposedX + w > screenSize.width)
          proposedX = screenSize.width - w - 16.0;
        if (proposedY + h > screenSize.height)
          proposedY = screenSize.height - h - 16.0;

        Rect proposedRect = Rect.fromLTWH(proposedX, proposedY, w, h);
        if (!openWindows.any((win) => win.overlaps(proposedRect))) {
          x.value = proposedX;
          y.value = proposedY;
          return true;
        }
      }
      return false;
    }

    if (tryFit(defaultIsHorizontal)) return;
    if (enableOrientationChange && tryFit(!defaultIsHorizontal)) return;
    isHorizontal.value = defaultIsHorizontal;
    x.value = defaultPos.dx;
    y.value = defaultPos.dy;
  }

  void onPanUpdate(DragUpdateDetails details) {
    x.value += details.delta.dx;
    y.value += details.delta.dy;
  }

  void onPanEnd(DragEndDetails details, Size screenSize) {
    double safeBottom = screenSize.height - Get.mediaQuery.padding.bottom;
    double currentW = isHorizontal.value ? widthH : widthV;
    double currentH = isHorizontal.value ? heightH : heightV;

    // =========================================================================
    // 🚀 1. THE HITBOX PHYSICS ENGINE (For Main & Create Holders)
    // =========================================================================
    if (enableMinimize) {
      double hbSize = 48.0; // The physical size of the Drag Handle square

      // Calculate the absolute center of the Drag Handle
      double cx = x.value + (hbSize / 2);
      double cy = y.value + (hbSize / 2);

      // Outward Detection: If dragged completely off-screen, force it back!
      if (cx < 0) cx = 0;
      if (cx > screenSize.width) cx = screenSize.width;
      if (cy < 0) cy = 0;
      if (cy > safeBottom) cy = safeBottom;

      // 🚀 Global Detection Logic (Task 4.1: Hitbox Segment Intersection)
      // Checks if the drag handle is in the detection zone AND physically intersects the [LP, LP + LW] segment
      bool snapR =
          cx > screenSize.width - detectDistance.value &&
          (y.value + hbSize >= rightPosition.value &&
              y.value <= rightPosition.value + rightLength.value);

      bool snapL =
          cx < detectDistance.value &&
          (y.value + hbSize >= leftPosition.value &&
              y.value <= leftPosition.value + leftLength.value);

      bool snapT =
          cy < detectDistance.value &&
          (x.value + hbSize >= topPosition.value &&
              x.value <= topPosition.value + topLength.value);

      bool snapB =
          cy > safeBottom - detectDistance.value &&
          (x.value + hbSize >= bottomPosition.value &&
              x.value <= bottomPosition.value + bottomLength.value);

      if (snapR || snapL || snapT || snapB) {
        if (snapR) {
          x.value = screenSize.width - currentW - rightPadding.value;
          y.value = rightPosition.value; // 🚀 NEW: Snap to LP Offset
          if (enableOrientationChange) isHorizontal.value = false;
        } else if (snapL) {
          x.value = leftPadding.value;
          y.value = leftPosition.value; // 🚀 NEW: Snap to LP Offset
          if (enableOrientationChange) isHorizontal.value = false;
        } else if (snapT) {
          y.value = topPadding.value;
          // 🚀 NEW: Replaced the static center-screen math with LP Offset
          x.value = exactTopSnapX ?? topPosition.value;
          if (enableOrientationChange) isHorizontal.value = true;
        } else if (snapB) {
          y.value = safeBottom - currentH - bottomPadding.value;
          // 🚀 NEW: Replaced the static center-screen math with LP Offset
          x.value = exactBottomSnapX ?? bottomPosition.value;
          if (enableOrientationChange) isHorizontal.value = true;
        }

        currentW = isHorizontal.value ? widthH : widthV;
        currentH = isHorizontal.value ? heightH : heightV;

        // 🚀 THE BEAUTY OF YOUR SYSTEM:
        // This existing clamping code below will naturally "eat" the window
        // if the user slides the LP offset too far past the screen boundaries!
        if (snapR || snapL) {
          if (y.value < topPadding.value) {
            y.value = topPadding.value;
          }
          if (y.value > safeBottom - currentH - bottomPadding.value) {
            y.value = safeBottom - currentH - bottomPadding.value;
          }
        }
        return;
      }
    }

    // =========================================================================
    // 🚀 2. STANDARD WINDOW PHYSICS (For Split, Layer, Padding Windows)
    // =========================================================================
    currentW = isHorizontal.value ? widthH : widthV;
    currentH = isHorizontal.value ? heightH : heightV;

    if (enableSnapping && isOpen.value) {
      double distLeft = x.value;
      double distRight = screenSize.width - (x.value + currentW);
      double distTop = y.value;
      double distBottom = safeBottom - (y.value + currentH);

      if (distLeft < 0) distLeft = 0;
      if (distRight < 0) distRight = 0;
      if (distTop < 0) distTop = 0;
      if (distBottom < 0) distBottom = 0;

      // 🚀 Global Detection Logic (Task 4.2: Standard Window Segment Intersection)
      // Checks if the window edge is in the detection zone AND the window body intersects the [LP, LP + LW] segment
      bool snapR =
          distRight <= detectDistance.value &&
          (y.value + currentH >= rightPosition.value &&
              y.value <= rightPosition.value + rightLength.value);

      bool snapL =
          distLeft <= detectDistance.value &&
          (y.value + currentH >= leftPosition.value &&
              y.value <= leftPosition.value + leftLength.value);

      bool snapT =
          distTop <= detectDistance.value &&
          (x.value + currentW >= topPosition.value &&
              x.value <= topPosition.value + topLength.value);

      bool snapB =
          distBottom <= detectDistance.value &&
          (x.value + currentW >= bottomPosition.value &&
              x.value <= bottomPosition.value + bottomLength.value);

      if (snapR || snapL || snapT || snapB) {
        if (snapR) {
          x.value = screenSize.width - currentW - rightPadding.value;
          if (enableOrientationChange) isHorizontal.value = false;
        } else if (snapL) {
          x.value = leftPadding.value;
          if (enableOrientationChange) isHorizontal.value = false;
        } else if (snapT) {
          y.value = topPadding.value;
          x.value = exactTopSnapX ?? ((screenSize.width / 2) - (currentW / 2));
          if (enableOrientationChange) isHorizontal.value = true;
        } else if (snapB) {
          y.value = safeBottom - currentH - bottomPadding.value;
          x.value =
              exactBottomSnapX ?? ((screenSize.width / 2) - (currentW / 2));
          if (enableOrientationChange) isHorizontal.value = true;
        }

        currentW = isHorizontal.value ? widthH : widthV;
        currentH = isHorizontal.value ? heightH : heightV;

        if (snapR || snapL) {
          if (y.value < topPadding.value) y.value = topPadding.value;
          if (y.value > safeBottom - currentH - bottomPadding.value)
            y.value = safeBottom - currentH - bottomPadding.value;
        }
        return;
      }
    }

    // =======================================================
    // FREE-FLOATING FALLBACKS
    // =======================================================
    if (enableDrawerBleed) {
      double minW = currentW * drawerVisibleRatio;
      double minH = currentH * drawerVisibleRatio;
      if (x.value < -currentW + minW) x.value = -currentW + minW;
      if (x.value > screenSize.width - minW) x.value = screenSize.width - minW;
      if (y.value < -currentH + minH) y.value = -currentH + minH;
    }

    // Always uses bottom padding for failsafe
    if (y.value > safeBottom - currentH - bottomPadding.value) {
      y.value = safeBottom - currentH - bottomPadding.value;
    }
  }

  void adjustForKeyboard(double keyboardHeight, Size screenSize) {
    if (!enableKeyboardAvoidance || keyboardHeight == 0) return;
    double currentH = isHorizontal.value ? heightH : heightV;
    double bottomEdgeOfWindow = y.value + currentH;
    double topOfKeyboard = screenSize.height - keyboardHeight;
    if (bottomEdgeOfWindow > topOfKeyboard)
      y.value = topOfKeyboard - currentH - 16.0;
  }
}
