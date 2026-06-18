import 'package:flutter/material.dart';

enum ScreenEdge { top, bottom, left, right }

/// A pure utility class for calculating window physics, bounds, and snapping.
class PhysicsEngine {
  static bool checkOffScreenHide({
    required Size screenSize,
    required double x,
    required double y,
    required double w,
    required double h,
    required double threshold,
  }) {
    return (x < -w + threshold ||
        x > screenSize.width - threshold ||
        y < -h + threshold ||
        y > screenSize.height - threshold);
  }

  static Map<ScreenEdge, double> detectBoundaries({
    required Size screenSize,
    required double x,
    required double y,
    required double w,
    required double h,
    required double safeBottom,
  }) {
    return {
      ScreenEdge.top: y,
      ScreenEdge.bottom: safeBottom - (y + h),
      ScreenEdge.left: x,
      ScreenEdge.right: screenSize.width - (x + w),
    };
  }

  // 🚀 ADVANCED CORNERING: Now returns a Set of edges!
  // 🚀 FIX 1: Dynamic Hitbox Reduction
  static Set<ScreenEdge> calculateSnapEdges({
    required Map<ScreenEdge, double> distances,
    required double w,
    required double h,
    required double snapThreshold,
    required double snapZoneThickness,
    required bool isWindowHorizontal, // 🚀 NEW PARAMETER
  }) {
    Set<ScreenEdge> activeEdges = {};

    double collisionThresholdX = -(w * snapThreshold);
    double collisionThresholdY = -(h * snapThreshold);

    // 🚀 Half the detection size on the sides if the window is horizontal
    double zoneX = isWindowHorizontal
        ? (snapZoneThickness / 2)
        : snapZoneThickness;
    double zoneY = snapZoneThickness;

    // Evaluate X Axis
    if (distances[ScreenEdge.left]! <= zoneX &&
        distances[ScreenEdge.left]! >= collisionThresholdX) {
      activeEdges.add(ScreenEdge.left);
    } else if (distances[ScreenEdge.right]! <= zoneX &&
        distances[ScreenEdge.right]! >= collisionThresholdX) {
      activeEdges.add(ScreenEdge.right);
    }

    // Evaluate Y Axis
    if (distances[ScreenEdge.top]! <= zoneY &&
        distances[ScreenEdge.top]! >= collisionThresholdY) {
      activeEdges.add(ScreenEdge.top);
    } else if (distances[ScreenEdge.bottom]! <= zoneY &&
        distances[ScreenEdge.bottom]! >= collisionThresholdY) {
      activeEdges.add(ScreenEdge.bottom);
    }

    return activeEdges;
  }

  // 🚀 FIX 2: Assigned Docking Locations
  static Offset executeSnap({
    required Set<ScreenEdge> edges,
    required Size screenSize,
    required double w,
    required double h,
    required double currentX,
    required double currentY,
    required double edgePadding,
    required double safeBottom,
    double? exactTopSnapX, // 🚀 NEW: Assigned top location
    double? exactBottomSnapX, // 🚀 NEW: Assigned bottom location
  }) {
    double newX = currentX;
    double newY = currentY;

    // Apply Top/Bottom Snaps (Forces exact location or Centers by default)
    if (edges.contains(ScreenEdge.top)) {
      newY = edgePadding;
      newX = exactTopSnapX ?? (screenSize.width - w) / 2;
    }
    if (edges.contains(ScreenEdge.bottom)) {
      newY = safeBottom - h - edgePadding;
      newX = exactBottomSnapX ?? (screenSize.width - w) / 2;
    }

    // Apply Side Snaps
    if (edges.contains(ScreenEdge.left)) newX = edgePadding;
    if (edges.contains(ScreenEdge.right))
      newX = screenSize.width - w - edgePadding;

    // Auto-clamp Y if snapped to a side to prevent corner bleeding
    if (edges.contains(ScreenEdge.left) || edges.contains(ScreenEdge.right)) {
      if (newY < edgePadding) newY = edgePadding;
      if (newY > safeBottom - h - edgePadding)
        newY = safeBottom - h - edgePadding;
    }

    return Offset(newX, newY);
  }

  static Offset clampToScreen({
    required Size screenSize,
    required double w,
    required double h,
    required double currentX,
    required double currentY,
    required double edgePadding,
    required double safeBottom,
  }) {
    double newX = currentX;
    double newY = currentY;

    if (newX < edgePadding) newX = edgePadding;
    if (newX > screenSize.width - w - edgePadding) {
      newX = screenSize.width - w - edgePadding;
    }
    if (newY < edgePadding) newY = edgePadding;
    if (newY > safeBottom - h - edgePadding) {
      newY = safeBottom - h - edgePadding;
    }

    return Offset(newX, newY);
  }

  static Offset clampWithDrawerBleed({
    required Size screenSize,
    required double w,
    required double h,
    required double currentX,
    required double currentY,
    required double drawerVisibleRatio,
    required double safeBottom,
    required double edgePadding,
  }) {
    double newX = currentX;
    double newY = currentY;
    double minVisibleW = w * drawerVisibleRatio;
    double minVisibleH = h * drawerVisibleRatio;

    // Allow X to bleed off screen (Left and Right walls)
    if (newX < -w + minVisibleW) newX = -w + minVisibleW;
    if (newX > screenSize.width - minVisibleW)
      newX = screenSize.width - minVisibleW;

    // Allow Y to bleed off the TOP of the screen
    if (newY < -h + minVisibleH) newY = -h + minVisibleH;

    // 🚀 THE LAZY FIX: Absolute hard-clamp on the BOTTOM for ALL windows.
    // It can never touch the border and can never hide off the bottom.
    if (newY > safeBottom - h - edgePadding) {
      newY = safeBottom - h - edgePadding;
    }

    return Offset(newX, newY);
  }
}
