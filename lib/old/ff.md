import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CreateSplitInteractions extends GetxController {
  // Reactive Position and State
  var x = 0.0.obs;
  var y = 0.0.obs;
  var isHorizontal = true.obs;
  var isOpen = false.obs; // Hidden by default until summoned

  // FIX: Removed 'final' and renamed to match the dynamic UI expectations
  double openWidthH = 340.0;
  double openHeightH = 120.0;
  double openWidthV = 120.0;
  double openHeightV = 340.0;

  /// Summons the window and places it perfectly centered on the right side
  void openWindow(Size screenSize) {
    isOpen.value = true;
    isHorizontal.value = false; // Spawn as Vertical
    x.value = screenSize.width - openWidthV - 16;
    y.value = (screenSize.height / 2) - (openHeightV / 2);
  }

  /// Closes the window
  void closeWindow() {
    isOpen.value = false;
  }

  /// Drags the window around smoothly
  void onPanUpdate(DragUpdateDetails details) {
    x.value += details.delta.dx;
    y.value += details.delta.dy;
  }

  /// Handles Snapping and the 80% Off-Screen Boundary Math
  void onPanEnd(DragEndDetails details, Size screenSize) {
    _applySnapping(screenSize);
  }

  /// Determines orientation and calculates boundaries
  void _applySnapping(Size screenSize) {
    double padding = 16.0;

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

    // Orientation Logic
    if (minDist == distTop || minDist == distBottom) {
      isHorizontal.value = true;
    } else {
      isHorizontal.value = false;
    }

    _clampWithOffScreenAllowance(screenSize);
  }

  /// The 80% Off-Screen Math Engine
  void _clampWithOffScreenAllowance(Size screenSize) {
    double w = isHorizontal.value ? openWidthH : openWidthV;
    double h = isHorizontal.value ? openHeightH : openHeightV;

    // Minimum visible pixels required (20% of the widget, or about 40-60px)
    double minVisibleW = w * 0.2;
    double minVisibleH = h * 0.2;

    // Left Boundary: Can go negative, but must leave 'minVisibleW' on screen
    if (x.value < -w + minVisibleW) {
      x.value = -w + minVisibleW;
    }
    // Right Boundary: Can bleed past screen width, but must leave 'minVisibleW'
    if (x.value > screenSize.width - minVisibleW) {
      x.value = screenSize.width - minVisibleW;
    }
    // Top Boundary
    if (y.value < -h + minVisibleH) {
      y.value = -h + minVisibleH;
    }
    // Bottom Boundary
    if (y.value > screenSize.height - minVisibleH) {
      y.value = screenSize.height - minVisibleH;
    }
  }

  /// Keyboard Avoidance Engine
  /// Called by the UI when MediaQuery detects a keyboard popping up.
  void adjustForKeyboard(double keyboardHeight, Size screenSize) {
    if (!isOpen.value || keyboardHeight == 0) return;

    double currentH = isHorizontal.value ? openHeightH : openHeightV;
    double bottomEdgeOfWindow = y.value + currentH;
    double topOfKeyboard = screenSize.height - keyboardHeight;

    // If the window is crushed by the keyboard, animate it upwards!
    if (bottomEdgeOfWindow > topOfKeyboard) {
      // Add a 16px safety padding above the keyboard
      y.value = topOfKeyboard - currentH - 16.0;
    }
  }

  /// Updates the physical dimensions of the bounding box so the
  /// 80% off-screen math remains perfectly accurate as the window grows.
  void updateDimensions(int numberOfSplits) {
    // Cap the physical growth at 7 splits
    int physicalSplits = numberOfSplits > 7 ? 7 : numberOfSplits;
    if (physicalSplits < 3) physicalSplits = 3; // Minimum baseline size

    // Base UI padding + (Width of a percentage field * number of splits)
    double calculatedLength = 160.0 + (physicalSplits * 65.0);
    double calculatedThickness = 120.0;

    openWidthH = calculatedLength;
    openHeightH = calculatedThickness;
    openWidthV = calculatedThickness;
    openHeightV = calculatedLength;
  }
}
