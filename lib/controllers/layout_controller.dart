import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:layout_engine/controllers/math_engine.dart';
import '../models/layout_node.dart';
import '../services/storage_service.dart';

import 'package:flutter/services.dart'; // Required for Clipboard access
import '../services/code_generator_service.dart';

class LayoutController extends GetxController {
  /// The maximum number of states allowed in memory to prevent leaks.
  static const int maxHistory = 30;

  /// The active, live layout tree currently rendered on the canvas.
  late LayoutNode activeLayout;

  /// Task 1: The Undo/Redo stack.
  /// We store JSON strings instead of LayoutNode objects to guarantee memory immutability.
  final List<String> _historyStack = [];

  /// The pointer tracking our current position in time.
  int _currentIndex = -1;

  /// Reactive booleans to disable/enable the Undo/Redo UI buttons.
  var canUndo = false.obs;
  var canRedo = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadInitialState();
  }

  /// Bootstraps the app by reading from Hive, or creating a fresh layout.
  void _loadInitialState() {
    final savedJson = StorageService.loadLayout();

    if (savedJson != null) {
      activeLayout = LayoutNode.fromJson(savedJson);
      // Push the loaded state to history, but don't re-save to the DB unnecessarily.
      _pushToHistory(saveToStorage: false);
    } else {
      // Fresh start: Create the base L1 layer taking 100% (1000 units) space.
      activeLayout = LayoutNode(
        type: 'ColumnNode',
        properties: {
          'flex_value': 1000,
          'is_locked': false,
          'layer_name': 'L1',
        },
      );
      _pushToHistory();
    }
  }

  /// Call this method ANY time a user completes a layout action (e.g., releasing a slider).
  void saveState() {
    _pushToHistory();
  }

  /// Task 2: Push new snapshots to the stack and enforce limits.
  void _pushToHistory({bool saveToStorage = true}) {
    // 1. Serialize the current tree
    final jsonString = jsonEncode(activeLayout.toJson());

    // 2. History Truncation: If the user undid 5 steps, then made a new change,
    // we must destroy those 5 alternate future states.
    if (_currentIndex < _historyStack.length - 1) {
      _historyStack.removeRange(_currentIndex + 1, _historyStack.length);
    }

    // 3. Add the new state to the stack
    _historyStack.add(jsonString);

    // 4. Enforce the 30-state memory limit
    if (_historyStack.length > maxHistory) {
      _historyStack.removeAt(0);
      // We don't increment the index because the array shifted left
    } else {
      _currentIndex++;
    }

    _updateButtonStates();

    // 5. Persist the new active layout to the offline Hive database
    if (saveToStorage) {
      StorageService.saveLayout(activeLayout.toJson());
    }

    // 6. Tell GetX to rebuild any UI listening to this controller
    update();
  }

  /// Task 3: Undo pointer traversal
  void undo() {
    if (!canUndo.value) return;

    _currentIndex--;
    _restoreFromIndex();
  }

  /// Task 3: Redo pointer traversal
  void redo() {
    if (!canRedo.value) return;

    _currentIndex++;
    _restoreFromIndex();
  }

  /// Deserializes the JSON at the current pointer and pushes it to the canvas.
  void _restoreFromIndex() {
    final jsonString = _historyStack[_currentIndex];
    final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;

    // Completely replace the active tree
    activeLayout = LayoutNode.fromJson(jsonMap);

    // Save this reverted state to Hive so it persists if the app closes immediately
    StorageService.saveLayout(jsonMap);

    _updateButtonStates();

    // Trigger a UI rebuild
    update();
  }

  /// Updates the reactive GetX variables for the floating UI toolbars.
  void _updateButtonStates() {
    canUndo.value = _currentIndex > 0;
    canRedo.value = _currentIndex < _historyStack.length - 1;
  }

  /// TASK 2: Destructive Action Guards
  void attemptSplit(int numberOfSplits, String nodeType) {
    List<LayoutNode> targets = [];

    // If nothing is selected, default to splitting the root canvas
    if (selectedNodeIds.isEmpty) {
      targets.add(activeLayout);
    } else {
      targets = selectedNodeIds
          .map((id) => _findNodeById(activeLayout, id))
          .whereType<LayoutNode>()
          .toList();
    }

    // Check if any targeted branch already contains nested children
    bool hasChildren = targets.any((node) => node.children.isNotEmpty);

    if (hasChildren) {
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
          _executeSplit(targets, numberOfSplits, nodeType);
        },
      );
    } else {
      _executeSplit(targets, numberOfSplits, nodeType);
    }
  }

  /// Executes the mathematical split on all targeted nodes
  void _executeSplit(
    List<LayoutNode> targets,
    int numberOfSplits,
    String nodeType,
  ) {
    final splits = MathEngine.splitEdit(numberOfSplits);

    for (var target in targets) {
      target.children.clear();
      for (int i = 0; i < numberOfSplits; i++) {
        target.children.add(
          LayoutNode(
            type: 'ContainerNode',
            properties: {
              'flex_value': splits[i],
              'is_locked': false,
              'layer_name': 'Split ${i + 1}',
            },
          ),
        );
      }
      target.type = nodeType; // Transform the parent into a Row or Column
    }

    // Important: Clear selections after a structural change to prevent orphaned IDs
    selectedNodeIds.clear();
    saveState();
  }

  // --- UPGRADED SELECTION STATE ---
  /// Tracks multiple selected nodes for bulk editing and synchronization.
  Set<String> selectedNodeIds = {};

  /// Task 1 & 3: Upgraded Selection with Ancestry Exclusivity
  void selectNode(String id) {
    // 1. Toggle off if already selected
    if (selectedNodeIds.contains(id)) {
      selectedNodeIds.remove(id);
      update();
      return;
    }

    // 2. TASK 1: Ancestry Conflict Check
    final newPath = _getPathToNode(activeLayout, id);
    if (newPath == null) return;

    bool hasConflict = false;
    for (String selectedId in selectedNodeIds) {
      final selectedPath = _getPathToNode(activeLayout, selectedId);
      if (selectedPath == null) continue;

      // If the new node is inside an already selected node, or vice versa, block it.
      if (newPath.any((n) => n.id == selectedId) ||
          selectedPath.any((n) => n.id == id)) {
        hasConflict = true;
        break;
      }
    }

    if (hasConflict) {
      Get.snackbar(
        'Selection Blocked',
        'Ancestry Conflict: Cannot select a parent and a child simultaneously.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return;
    }

    // 3. Add to selection
    selectedNodeIds.add(id);
    update();

    // 4. TASK 3: Trigger Baseline Sync if needed
    _checkBaselineSync();
  }

  /// Helper: Retrieves the exact lineage from the root down to the target node
  List<LayoutNode>? _getPathToNode(
    LayoutNode current,
    String targetId, [
    List<LayoutNode>? currentPath,
  ]) {
    currentPath ??= [];
    currentPath.add(current);
    if (current.id == targetId) return currentPath;

    for (var child in current.children) {
      final path = _getPathToNode(child, targetId, List.from(currentPath));
      if (path != null) return path;
    }
    return null;
  }

  /// Implement custom layer naming
  void updateLayerName(String id, String newName) {
    final node = _findNodeById(activeLayout, id);
    if (node != null) {
      node.properties['layer_name'] = newName;
      saveState(); // Saves the new name to Hive and the Undo stack
    }
  }

  /// TASK 3: Baseline Synchronization Engine
  void _checkBaselineSync() {
    if (selectedNodeIds.length < 2) return;

    // Retrieve the actual node objects for the selected IDs
    List<LayoutNode> selectedNodes = selectedNodeIds
        .map((id) => _findNodeById(activeLayout, id))
        .whereType<LayoutNode>()
        .toList();

    if (selectedNodes.isEmpty) return;

    // Compare properties against the first selected node
    final firstProps = selectedNodes.first.properties;
    bool mismatch = selectedNodes.any(
      (node) =>
          node.properties['flex_value'] != firstProps['flex_value'] ||
          node.properties['is_locked'] != firstProps['is_locked'],
    );

    if (mismatch) {
      // Prompt user to pick a baseline
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
                      _applyBaselineSync(node.id, selectedNodes);
                      Get.back(); // Close dialog
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

  /// Applies the chosen baseline data block to all selected nodes
  void _applyBaselineSync(String baselineId, List<LayoutNode> nodes) {
    final baselineNode = nodes.firstWhere((n) => n.id == baselineId);
    final baselineProps = Map<String, dynamic>.from(baselineNode.properties);

    for (var node in nodes) {
      if (node.id != baselineId) {
        node.properties['flex_value'] = baselineProps['flex_value'];
        node.properties['is_locked'] = baselineProps['is_locked'];
      }
    }
    saveState();
  }

  /// Recursive helper to find a specific node by its UUID
  LayoutNode? _findNodeById(LayoutNode current, String targetId) {
    if (current.id == targetId) return current;
    for (var child in current.children) {
      final found = _findNodeById(child, targetId);
      if (found != null) return found;
    }
    return null;
  }

  /// Task 1 & 2: Export Engine
  /// Generates the code and copies the raw string directly to the device clipboard.
  void copyCodeToClipboard() {
    // 1. Generate the raw string using your custom service
    final String generatedCode = CodeGeneratorService.generateCode(
      activeLayout,
    );

    // 2. Access the device clipboard and set the text
    Clipboard.setData(ClipboardData(text: generatedCode))
        .then((_) {
          // 3. Provide visual feedback that the action succeeded
          Get.snackbar(
            'Code Exported!',
            'Production-ready Flutter code copied to clipboard.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green.shade700,
            colorText: Colors.white,
            duration: const Duration(seconds: 3),
            icon: const Icon(Icons.check_circle, color: Colors.white),
          );
        })
        .catchError((error) {
          Get.snackbar(
            'Export Failed',
            'Could not access device clipboard.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.redAccent,
            colorText: Colors.white,
          );
        });
  }
}
