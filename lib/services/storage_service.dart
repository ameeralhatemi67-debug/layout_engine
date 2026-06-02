import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

class StorageService {
  static const String _boxName = 'layout_box';
  static const String _layoutKey = 'active_layout';

  /// Task 1: Initialize Hive and open the primary document-store box
  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_boxName);
  }

  /// Task 2: Save the active JSON layout
  /// Serializes the Dart Map into a JSON string and writes it to disk.
  static Future<void> saveLayout(Map<String, dynamic> layoutJson) async {
    final box = Hive.box(_boxName);
    final jsonString = jsonEncode(layoutJson);
    await box.put(_layoutKey, jsonString);
  }

  /// Task 2: Load the active JSON layout
  /// Reads the JSON string from disk and deserializes it back into a Dart Map.
  static Map<String, dynamic>? loadLayout() {
    final box = Hive.box(_boxName);
    final jsonString = box.get(_layoutKey);

    if (jsonString != null) {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    }
    return null; // Returns null if this is the first time the app is opened
  }

  /// Helper to completely wipe the layout (e.g., for a "Start Fresh" feature)
  static Future<void> clearLayout() async {
    final box = Hive.box(_boxName);
    await box.delete(_layoutKey);
  }
}
