import 'dart:convert';
import 'package:get/get.dart';
import 'package:layout_engine/controllers/math_engine.dart';
import '../models/layout_node.dart';
import '../services/storage_service.dart';

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

  /// Applies a baseline split to the active layout (MVP: targets the root node)
  void applyBaselineSplit(int numberOfSplits, String nodeType) {
    // 1. Calculate the math
    final splits = MathEngine.splitEdit(numberOfSplits);

    // 2. Clear existing children and generate new ones based on the math
    activeLayout.children.clear();
    for (int i = 0; i < numberOfSplits; i++) {
      activeLayout.children.add(
        LayoutNode(
          type: 'ContainerNode', // A generic leaf node waiting for content
          properties: {
            'flex_value': splits[i],
            'is_locked': false,
            'layer_name': 'Split ${i + 1}',
          },
        ),
      );
    }

    // 3. Update the parent type (RowNode or ColumnNode)
    activeLayout.type = nodeType;

    // 4. Save to history and update UI
    saveState();
  }

  // --- ADD THESE VARIABLES ---
  /// Tracks the currently selected node for deep modifications.
  String? selectedNodeId;

  // --- ADD THESE METHODS ---
  /// Selects or deselects a node in the layout tree.
  void selectNode(String? id) {
    selectedNodeId = id;
    update(); // Rebuild the UI to show the selection highlight
  }

  /// Task 2: Implement custom layer naming
  void updateLayerName(String id, String newName) {
    final node = _findNodeById(activeLayout, id);
    if (node != null) {
      node.properties['layer_name'] = newName;
      saveState(); // Saves the new name to Hive and the Undo stack
    }
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
}
