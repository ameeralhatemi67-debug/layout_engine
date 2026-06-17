import 'package:get/get.dart';
import 'base_window_interactions.dart';

/// Centralizes default values, hard boundaries, and visual scaling math
/// for the Figma-style workspace physics configuration layout.
mixin SnappingConfigManager on GetxController {
  // Hard defaults defined by your application specification
  static const double defaultDetectionDistance = 50.0;
  static const double defaultEdgeDistance = 12.0;

  static const double defaultLineWidthV = 200.0; // Left/Right line height
  static const double defaultLineWidthH = 200.0; // Top/Bottom line width

  static const double defaultLinePosition = 0.0; // Centered by default

  // Maximum runtime constraints enforced by the physics engine
  static const double maxVisualDetection = 50.0;
  static const double maxVisualEdgeDistance = 25.0;

  static const double maxVisualLineWidthLR = 50.0; // Scaled limit for L/R
  static const double maxVisualLineWidthUD = 25.0; // Scaled limit for U/D

  /// Resets a specific property back to its pristine default state when double-tapped
  double getDefaultForField(String edge, String field) {
    switch (field) {
      case 'DETECTION':
        return defaultDetectionDistance;
      case 'ED':
        return defaultEdgeDistance;
      case 'LW':
        return (edge == 'L' || edge == 'R')
            ? defaultLineWidthV
            : defaultLineWidthH;
      case 'LP':
        return defaultLinePosition;
      default:
        return 0.0;
    }
  }

  /// Calculates the visual bounding box clipping offsets for a snapping line.
  /// If the line is translated by LP partially off-screen, this determines how much
  /// it should be visually "eaten by the page" while preserving structural limits.
  Map<String, double> calculateClippedLineBounds({
    required String edge,
    required double lineLength,
    required double positionOffset,
    required double
    constraintSize, // Width for U/D rows, Height for L/R columns
  }) {
    // Determine the center position on the parallel axis
    double halfLength = lineLength / 2;
    double centerline = constraintSize / 2;

    // Apply user translation offset
    double currentStart = (centerline - halfLength) + positionOffset;
    double currentEnd = (centerline + halfLength) + positionOffset;

    double renderStart = currentStart;
    double renderEnd = currentEnd;

    // Clip bounds if they exceed the viewport boundaries
    if (renderStart < 0) renderStart = 0;
    if (renderEnd > constraintSize) renderEnd = constraintSize;

    double renderLength = renderEnd - renderStart;
    if (renderLength < 0) renderLength = 0;

    return {
      'renderStart': renderStart,
      'renderLength': renderLength,
      'isClipped': (currentStart < 0 || currentEnd > constraintSize)
          ? 1.0
          : 0.0,
    };
  }
}
