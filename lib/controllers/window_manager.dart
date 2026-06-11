import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// A dynamic OS-level Window Registry and Z-Index Manager
class WindowManager extends GetxController {
  // The dynamic order of windows
  var windowOrder = <String>[].obs;

  // The registry holding the actual UI for each window
  final Map<String, Widget> _windows = {};

  /// Registers a new window into the OS dynamically.
  /// You can call this for as many new windows as you create!
  void registerWindow(String tag, Widget widget) {
    if (!_windows.containsKey(tag)) {
      _windows[tag] = widget;

      // Ensure 'Main' is ALWAYS at the absolute end of the list (drawn on top)
      if (tag == 'Main') {
        windowOrder.add(tag);
      } else {
        int mainIndex = windowOrder.indexOf('Main');
        if (mainIndex != -1) {
          windowOrder.insert(mainIndex, tag);
        } else {
          windowOrder.add(tag);
        }
      }
    }
  }

  /// Brings the tapped window to the front (right behind Main)
  void bringToFront(String tag) {
    if (tag == 'Main') return; // Main is permanently locked to the top
    if (!windowOrder.contains(tag)) return;

    windowOrder.remove(tag); // Pull it out of its current slot

    // Find Main and insert this window directly beneath it
    int mainIndex = windowOrder.indexOf('Main');
    if (mainIndex != -1) {
      windowOrder.insert(mainIndex, tag);
    } else {
      windowOrder.add(tag);
    }
  }

  /// Returns the list of active widgets in their perfectly stacked Z-index order
  List<Widget> get orderedWindows {
    return windowOrder.map((tag) => _windows[tag]!).toList();
  }
}
