import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HoldersInteractions extends GetxController {
  var x = 20.0.obs;
  var y = 20.0.obs;
  var isHorizontal = true.obs;
  var isHidden = false.obs;
  var isOpen = true.obs;

  // Remove the 'final' keyword so we can customize hit-boxes for different holders
  double openWidthH = 280.0;
  double openHeightH = 60.0;
  double openWidthV = 60.0;
  double openHeightV = 280.0;
  double closedSize = 60.0;

  /// Toggles the main toolbar open and closed (Minimization)
  void toggleOpen(Size screenSize) {
    isOpen.value = !isOpen.value;
    if (isOpen.value) {
      // Fix 2: If opening it causes a collision, apply the snapping logic!
      _applySnapping(screenSize);
    }
  }

  void restoreHolder() {
    isHidden.value = false;
    isOpen.value = true;
    isHorizontal.value = true;
    x.value = 20.0;
    y.value = 20.0;
  }

  void onPanUpdate(DragUpdateDetails details) {
    x.value += details.delta.dx;
    y.value += details.delta.dy;
  }

  void onPanEnd(DragEndDetails details, Size screenSize) {
    // 1. Hiding logic
    double currentW = isOpen.value
        ? (isHorizontal.value ? openWidthH : openWidthV)
        : closedSize;
    double currentH = isOpen.value
        ? (isHorizontal.value ? openHeightH : openHeightV)
        : closedSize;

    // FIX: Make the hiding boundary much stricter!
    // The user must drag the widget almost entirely off the screen
    // (leaving only 40 pixels visible) to trigger a hide.
    if (x.value < -currentW + 40 ||
        x.value > screenSize.width - 40 ||
        y.value < -currentH + 40 ||
        y.value > screenSize.height - 40) {
      isHidden.value = true;
      return;
    }

    // Fix 1: If closed, do NOT snap. Let the user drop it anywhere safely on screen.
    if (!isOpen.value) {
      _clampToScreen(screenSize, 16.0);
      return;
    }

    // 3. If open, snap it to the closest edge.
    _applySnapping(screenSize);
  }

  /// Calculates the closest edge and snaps perfectly
  void _applySnapping(Size screenSize) {
    double padding = 16.0;

    // Where is it right now?
    double currentW = isHorizontal.value ? openWidthH : openWidthV;
    double currentH = isHorizontal.value ? openHeightH : openHeightV;

    double distTop = y.value;
    double distBottom = screenSize.height - (y.value + currentH);
    double distLeft = x.value;
    double distRight = screenSize.width - (x.value + currentW);

    double minDist = [
      distTop,
      distBottom,
      distLeft,
      distRight,
    ].reduce((a, b) => a < b ? a : b);

    if (minDist == distTop) {
      y.value = padding;
      isHorizontal.value = true;
    } else if (minDist == distBottom) {
      // Fix 3: Use the FUTURE horizontal height so it sits exactly on the bottom!
      y.value = screenSize.height - openHeightH - padding;
      isHorizontal.value = true;
    } else if (minDist == distLeft) {
      x.value = padding;
      isHorizontal.value = false;
    } else if (minDist == distRight) {
      // Fix 3: Use the FUTURE vertical width so it sits exactly on the right!
      x.value = screenSize.width - openWidthV - padding;
      isHorizontal.value = false;
    }

    _clampToScreen(screenSize, padding);
  }

  /// Helper: Keeps the widget safely inside the screen
  void _clampToScreen(Size screenSize, double padding) {
    double w = isOpen.value
        ? (isHorizontal.value ? openWidthH : openWidthV)
        : closedSize;
    double h = isOpen.value
        ? (isHorizontal.value ? openHeightH : openHeightV)
        : closedSize;

    if (x.value < padding) x.value = padding;
    if (x.value > screenSize.width - w - padding)
      x.value = screenSize.width - w - padding;
    if (y.value < padding) y.value = padding;
    if (y.value > screenSize.height - h - padding)
      y.value = screenSize.height - h - padding;
  }
}
