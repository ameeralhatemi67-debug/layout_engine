import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:layout_engine/data/models/layout_node.dart';

class ErrorHandler {
  // --- BASE SNACKBARS ---

  /// Standard Error Toast
  static void showError(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.redAccent,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
    );
  }

  /// Standard Success Toast
  static void showSuccess(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green.shade700,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
      icon: const Icon(Icons.check_circle, color: Colors.white),
    );
  }

  // --- SPECIFIC DOMAIN WARNINGS ---

  /// Warns the user when selecting a parent and child simultaneously
  static void showAncestryConflict() {
    showError(
      'Selection Blocked',
      'Ancestry Conflict: Cannot select a parent and a child simultaneously.',
    );
  }

  /// Warns the user before overwriting nested layouts
  static void showDestructiveWarning({required VoidCallback onConfirm}) {
    Get.defaultDialog(
      title: 'Destructive Action Warning',
      middleText:
          'This will permanently overwrite the nested layouts inside the selected branches. Are you sure?',
      textConfirm: 'Overwrite',
      textCancel: 'Cancel',
      confirmTextColor: Colors.white,
      buttonColor: Colors.redAccent,
      onConfirm: () {
        Get.back(); // Close dialog
        onConfirm(); // Execute the passed function
      },
    );
  }

  /// Prompts the user to pick a baseline when multiple selected nodes have conflicting properties
  static void showBaselineSyncDialog({
    required List<LayoutNode> selectedNodes,
    required Function(String baselineId) onSyncSelected,
  }) {
    Get.defaultDialog(
      title: 'Baseline Synchronization',
      middleText:
          'The selected layers have conflicting mathematical properties. Please choose a baseline to sync them.',
      content: Column(
        children: selectedNodes
            .map(
              (node) => Padding(
                padding: const EdgeInsets.all(4.0),
                child: ElevatedButton(
                  onPressed: () {
                    Get.back(); // Close dialog
                    onSyncSelected(node.id);
                  },
                  child: Text(
                    'Sync to: ${node.properties['layer_name'] ?? node.type}',
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
