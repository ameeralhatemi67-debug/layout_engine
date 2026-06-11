import 'package:flutter/material.dart';

class WindowConfig {
  /// Define the default starting positions for all windows here!
  static Offset getDefaultPosition(String tag, Size screenSize) {
    switch (tag) {
      case 'Main':
        return const Offset(10, 10); // Top Left
      case 'Create':
        return Offset(screenSize.width - 80, 70); // Top Right
      case 'Layer':
        // Middle Right (Assuming 220px width)
        return Offset(screenSize.width - 400, (screenSize.height / 2) - 380);
      case 'Split':
        // Middle Right Bottom (Assuming 340px width and 120px height)
        return Offset(screenSize.width - 160, screenSize.height - 360);
      default:
        return const Offset(40, 40);
    }
  }

  /// Define the default orientations (true = Horizontal, false = Vertical)
  static bool getDefaultOrientation(String tag) {
    switch (tag) {
      case 'Main':
        return true; // Horizontal
      case 'Create':
        return false; // Vertical
      case 'Layer':
        return false; // Vertical (Matrix is always vertical)
      case 'Split':
        return true; // Horizontal
      default:
        return true;
    }
  }
}
