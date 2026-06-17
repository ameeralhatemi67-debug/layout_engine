import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:layout_engine/controllers/base_window_interactions.dart';
import 'package:layout_engine/controllers/math_engine.dart';
import 'package:layout_engine/controllers/window_manager.dart';
import '../models/layout_node.dart';
import '../services/storage_service.dart';

import 'package:flutter/services.dart'; // Required for Clipboard access
import '../services/code_generator_service.dart';
import '../services/error_handling.dart';

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

  // --- ADD THESE NEW LINES ---
  /// Visual Toggle State for the Canvas Wireframes
  var showCanvasWireframes = true.obs;

  /// Visual Toggle State for the Layer Window
  var showLayerWindow = true.obs;

  /// Toggles the Wireframe borders on the canvas.
  void toggleWireframe() {
    showCanvasWireframes.value = !showCanvasWireframes.value;
    update(); // Forces the CanvasView to redraw
  }

  /// Toggles the visibility of the Layer Matrix window.
  void toggleLayerWindow() {
    showLayerWindow.value = !showLayerWindow.value;
    if (showLayerWindow.value) {
      // 1. Calculate smart spawn
      if (Get.isRegistered<BaseWindowInteractions>(tag: 'Layer')) {
        final logic = Get.find<BaseWindowInteractions>(tag: 'Layer');
        logic.spawnWithAntiOverlap(
          Size(Get.width, Get.height),
          logic.getActiveWindowRects('Layer'),
          'Layer',
        );
      }
      // 2. Bring to the absolute front!
      if (Get.isRegistered<WindowManager>()) {
        Get.find<WindowManager>().bringToFront('Layer');
      }
    }
    update();
  }

  // --- SPLIT WINDOW STATES ---
  /// Tracks the currently sub-selected split inside the Create Split Window
  var activeSplitId = RxnString();

  /// Sets or toggles the active split for sub-selection
  void toggleActiveSplit(String id) {
    if (activeSplitId.value == id) {
      activeSplitId.value = null; // Deselect on double-tap
    } else {
      activeSplitId.value = id;
    }
    update();
  }

  /// Task 1: Visual Toggle State for the Equalizer
  var isEqualizerOn = true.obs;

  /// Toggles the Proportional (Equalizer) math logic
  void toggleEqualizer() {
    isEqualizerOn.value = !isEqualizerOn.value;
    update();
  }

  /// Resets all children of the active layout split to perfectly equal sizes
  void resetSplitsToEqual() {
    final selected = singleSelectedNode;
    if (selected == null) return;

    // Target the parent container (whether we selected the parent or a child)
    final isParent =
        selected.type == 'RowNode' || selected.type == 'ColumnNode';
    final parentNode = isParent
        ? selected
        : findParentOf(activeLayout, selected.id);

    if (parentNode == null || parentNode.children.isEmpty) return;

    // Apply the perfectly equal math
    final equalFlexes = MathEngine.splitEdit(parentNode.children.length);
    for (int i = 0; i < parentNode.children.length; i++) {
      parentNode.children[i].properties['flex_value'] = equalFlexes[i];
    }

    saveState();
    update();
  }

  /// Helper to check if a specific node is locked (Used for the lock.svg visual)
  bool isNodeLocked(String? id) {
    if (id == null) return false;
    final node = _findNodeById(activeLayout, id);
    return node?.properties['is_locked'] == true;
  }

  /// Visual Toggle State for Canvas-level Hand Adjustments
  var isHandAdjustmentActive = false.obs;

  /// Toggles the draggable dividers directly on the canvas
  void toggleHandAdjustment() {
    isHandAdjustmentActive.value = !isHandAdjustmentActive.value;
    update(); // Redraw canvas to show/hide the hand handles
  }

  /// Toggles the 'is_locked' (LockEdit) property of a specific layout node
  void toggleLock(String nodeId) {
    final node = _findNodeById(activeLayout, nodeId);
    if (node != null) {
      bool currentLock = node.properties['is_locked'] == true;
      node.properties['is_locked'] = !currentLock;

      saveState(); // Saves the lock action to the Undo/Redo stack and Hive
      update(); // Forces UI to redraw
    }
  }

  /// Helper to check if a specific node is expanded
  bool isNodeExpanded(String? id) {
    if (id == null) return false;
    final node = _findNodeById(activeLayout, id);
    return node?.properties['is_expanded'] == true;
  }

  /// Toggles the 'is_expanded' property. Includes a destructive guard.
  void toggleExpand(String nodeId) {
    final node = _findNodeById(activeLayout, nodeId);
    if (node == null) return;

    bool currentExpand = node.properties['is_expanded'] == true;

    // Guard: If it has children and we are trying to expand it, warn them!
    if (node.children.isNotEmpty && !currentExpand) {
      ErrorHandler.showDestructiveWarning(
        onConfirm: () {
          node.children.clear(); // Wipe children to make it a scrolling leaf
          _executeToggleExpand(node, true);
        },
      );
    } else {
      _executeToggleExpand(node, !currentExpand);
    }
  }

  void _executeToggleExpand(LayoutNode node, bool newState) {
    node.properties['is_expanded'] = newState;

    if (newState) {
      // Initialize the internal canvas size to perfectly match the current wall size
      node.properties['expanded_flex'] = node.properties['flex_value'];
    } else {
      // The Normalization Intercept you added previously
      final parent = findParentOf(activeLayout, node.id);
      if (parent != null && parent.children.isNotEmpty) {
        _normalizeChildrenFlex(parent);
      }
    }

    saveState();
    update();
  }

  @override
  void onInit() {
    super.onInit();
    _loadInitialState();
  }

  /// Bootstraps the app by reading from Hive, or creating a fresh layout.
  /// Bootstraps the app by reading from Hive, or creating a fresh layout.
  void _loadInitialState() {
    final savedJson = StorageService.loadLayout();

    if (savedJson != null) {
      activeLayout = LayoutNode.fromJson(savedJson);
      // Push the loaded state to history, but don't re-save to the DB unnecessarily.
      _pushToHistory(saveToStorage: false);
    } else {
      // 🚀 THE FIX: Fresh start must be a ContainerNode so it renders the visual wireframe!
      activeLayout = LayoutNode(
        type: 'ContainerNode',
        properties: {
          'flex_value': 1000,
          'is_locked': false,
          'layer_name': 'Root Canvas',
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

    // FIX: If we only targeted ONE node, pop open the window AND bring to front!
    if (targets.length == 1) {
      selectedNodeIds = {targets.first.id};
      if (Get.isRegistered<BaseWindowInteractions>(tag: 'Split')) {
        Get.find<BaseWindowInteractions>(
          tag: 'Split',
        ).openSplitWindow(Size(Get.width, Get.height));
      }
      if (Get.isRegistered<WindowManager>()) {
        Get.find<WindowManager>().bringToFront(
          'Split',
        ); // Brings newly opened window to top!
      }
    } else {
      targets = selectedNodeIds
          .map((id) => _findNodeById(activeLayout, id))
          .whereType<LayoutNode>()
          .toList();
    }

    // Check if any targeted branch already contains nested children
    bool hasChildren = targets.any((node) => node.children.isNotEmpty);

    if (hasChildren) {
      // NEW: Clean, centralized call!
      ErrorHandler.showDestructiveWarning(
        onConfirm: () => _executeSplit(targets, numberOfSplits, nodeType),
      );
    } else {
      _executeSplit(targets, numberOfSplits, nodeType);
    }
    activeSplitId.value = null;
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

    // FIX: If we only targeted ONE node, keep it selected and pop open the window!
    if (targets.length == 1) {
      selectedNodeIds = {targets.first.id};
      if (Get.isRegistered<BaseWindowInteractions>(tag: 'Split')) {
        Get.find<BaseWindowInteractions>(
          tag: 'Split',
        ).openSplitWindow(Size(Get.width, Get.height));
      }
    } else {
      // If bulk editing, clear selections
      selectedNodeIds.clear();
    }

    saveState();
  }

  // --- UPGRADED SELECTION STATE ---
  /// Tracks multiple selected nodes for bulk editing and synchronization.
  Set<String> selectedNodeIds = {};

  /// Helper: Returns the node ONLY if exactly one node is selected.
  LayoutNode? get singleSelectedNode {
    if (selectedNodeIds.length == 1) {
      return _findNodeById(activeLayout, selectedNodeIds.first);
    }
    return null; // Returns null if multiple or zero nodes are selected
  }

  /// Task 4 & 5: Exclusive Selection
  /// Clears all other selections and selects ONLY this node.
  void exclusiveSelectNode(String id) {
    selectedNodeIds.clear();
    selectedNodeIds.add(id);

    update();
    _checkBaselineSync();
  }

  /// Task 1 & 3: Upgraded Selection with Ancestry Exclusivity
  void selectNode(String id) {
    // 1. Toggle off if already selected
    if (selectedNodeIds.contains(id)) {
      selectedNodeIds.remove(id);

      // NEW: Close the split window if we deselected everything!
      if (selectedNodeIds.isEmpty &&
          Get.isRegistered<BaseWindowInteractions>(tag: 'Split')) {
        Get.find<BaseWindowInteractions>(tag: 'Split').closeSplitWindow();
      }

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
      // NEW: Clean, centralized call!
      ErrorHandler.showAncestryConflict();
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
      // NEW: Clean, centralized call!
      ErrorHandler.showBaselineSyncDialog(
        selectedNodes: selectedNodes,
        onSyncSelected: (baselineId) {
          _applyBaselineSync(baselineId, selectedNodes);
        },
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

  /// Helper: Finds the parent of a specific node so we can access its siblings
  LayoutNode? findParentOf(LayoutNode current, String targetId) {
    for (var child in current.children) {
      if (child.id == targetId) return current;
      final found = findParentOf(
        child,
        targetId,
      ); // Removed underscore here too
      if (found != null) return found;
    }
    return null;
  }

  /// Task 1 & 2: Dynamic Flex Adjustment
  /// Modifies a node's flex value and proportionally resizes its siblings.
  void updateFlexValue(String id, int newFlex) {
    // 1. Find the parent of the targeted node
    final parent = findParentOf(activeLayout, id);
    if (parent == null || parent.children.isEmpty) return;

    // 2. Find the index of the target node among its siblings
    final targetIndex = parent.children.indexWhere((child) => child.id == id);
    if (targetIndex == -1) return;

    // THE EXPAND BYPASS FIX
    if (parent.children[targetIndex].properties['is_expanded'] == true) {
      // 1. Get the structural wall size so it cannot shrink smaller than its container
      int baseFlex =
          parent.children[targetIndex].properties['flex_value'] as int? ?? 1000;

      // 2. Clamp the incoming flex between the base wall and the 10,000 limit (1000%)
      int clampedFlex = newFlex.clamp(baseFlex, 10000);

      // 3. Write the safe value
      parent.children[targetIndex].properties['expanded_flex'] = clampedFlex;
      update();
      return;
    }

    // The Expand Engine Bypass
    // If this node is expanded, it detaches from the 1000-unit limit.
    // It simply takes the new flex value without stealing from siblings!
    if (parent.children[targetIndex].properties['is_expanded'] == true) {
      parent.children[targetIndex].properties['flex_value'] = newFlex;
      update();
      return;
    }

    // 3. Extract the current flex values of all siblings
    List<int> currentFlexes = parent.children.map((child) {
      return (child.properties['flex_value'] as int?) ?? 1000;
    }).toList();

    // 4. NEW: Figure out which siblings are locked so the math engine ignores them
    Set<int> lockedIndices = {};
    for (int i = 0; i < parent.children.length; i++) {
      if (parent.children[i].properties['is_locked'] == true) {
        lockedIndices.add(i);
      }
    }

    // 5. Trigger the MathEngine based on the Equalizer State
    List<int> newFlexes;
    if (isEqualizerOn.value) {
      newFlexes = MathEngine.manualEdit(
        currentSplits: currentFlexes,
        targetIndex: targetIndex,
        targetValue: newFlex,
        lockedIndices: lockedIndices,
      );
    } else {
      newFlexes = MathEngine.neighborEdit(
        currentSplits: currentFlexes,
        targetIndex: targetIndex,
        targetValue: newFlex,
        lockedIndices: lockedIndices,
      );
    }

    // 6. Apply the newly calculated flex values back to the JSON properties
    for (int i = 0; i < parent.children.length; i++) {
      parent.children[i].properties['flex_value'] = newFlexes[i];
    }

    // 7. Force the UI to redraw immediately at 60fps
    update();
  }

  /// The Safety Net: Forces a parent's children back to exactly 1000 units
  /// using Proportional Normalization and the Largest Remainder method.
  void _normalizeChildrenFlex(LayoutNode parent) {
    int totalFlexSum = 0;

    // 1. Find the bloated total sum
    for (var child in parent.children) {
      totalFlexSum += (child.properties['flex_value'] as int?) ?? 1000;
    }

    // If it's already perfectly 1000 (or 0), do nothing.
    if (totalFlexSum == 0 || totalFlexSum == 1000) return;

    int assignedSpace = 0;
    Map<int, double> exactFractions = {};
    List<int> newFlexes = List.filled(parent.children.length, 0);

    // 2. Scale everyone down proportionally to fit inside 1000
    for (int i = 0; i < parent.children.length; i++) {
      int currentFlex =
          (parent.children[i].properties['flex_value'] as int?) ?? 1000;

      double exact = (currentFlex * 1000) / totalFlexSum;
      newFlexes[i] = exact.floor(); // Round down safely
      assignedSpace += newFlexes[i];

      // Track who lost the most space to rounding
      exactFractions[i] = exact - newFlexes[i];
    }

    // 3. Hand out the remaining integer points fairly
    int remainder = 1000 - assignedSpace;
    if (remainder > 0) {
      List<int> sortedIndices = List.generate(parent.children.length, (i) => i);
      sortedIndices.sort(
        (a, b) => exactFractions[b]!.compareTo(exactFractions[a]!),
      );

      for (int i = 0; i < remainder; i++) {
        newFlexes[sortedIndices[i % sortedIndices.length]] += 1;
      }
    }

    // 4. Apply the strictly normalized values back to the JSON tree
    for (int i = 0; i < parent.children.length; i++) {
      parent.children[i].properties['flex_value'] = newFlexes[i];
    }
  }

  // ===========================================================================
  // 🚀 PADDING ENGINE (PHASE 1)
  // ===========================================================================

  /// Guard: Ensures padding is only applied to empty leaf nodes
  bool isPaddingValidTarget(String? id) {
    if (id == null) return false;
    final node = _findNodeById(activeLayout, id);
    return node != null && node.children.isEmpty;
  }

  /// Boundary Engine: Global Slider
  /// Adjusts all selected sides simultaneously. Caps the max value if opposites are selected.
  void updatePaddingGlobal(String id, List<String> activeSides, int newValue) {
    final node = _findNodeById(activeLayout, id);
    if (node == null || node.children.isNotEmpty) return;

    int maxLimit = 100;

    // MATHEMATICAL GUARD: If both Top and Bottom are selected, they cannot exceed 50% each
    if (activeSides.contains('top') && activeSides.contains('bottom'))
      maxLimit = 50;

    // MATHEMATICAL GUARD: If both Left and Right are selected, they cannot exceed 50% each
    if (activeSides.contains('left') && activeSides.contains('right')) {
      if (50 < maxLimit) maxLimit = 50;
    }

    int safeValue = newValue.clamp(0, maxLimit);

    Map<String, dynamic> padding = Map<String, dynamic>.from(
      node.properties['padding'],
    );
    if (activeSides.contains('top')) padding['top'] = safeValue;
    if (activeSides.contains('bottom')) padding['bottom'] = safeValue;
    if (activeSides.contains('left')) padding['left'] = safeValue;
    if (activeSides.contains('right')) padding['right'] = safeValue;

    node.properties['padding'] = padding;
    update(); // Redraws UI immediately (No saveState here to prevent Undo flooding)
  }

  /// Boundary Engine: Manual Slider Adjustments
  /// Enforces that Opposite Sides (L+R, T+B) dynamically clamp each other below 100%.
  void updatePaddingManual(String id, String side, int newValue) {
    final node = _findNodeById(activeLayout, id);
    if (node == null || node.children.isNotEmpty) return;

    Map<String, dynamic> padding = Map<String, dynamic>.from(
      node.properties['padding'],
    );

    int top = padding['top'] ?? 0;
    int bottom = padding['bottom'] ?? 0;
    int left = padding['left'] ?? 0;
    int right = padding['right'] ?? 0;

    // MATHEMATICAL GUARD: Dynamically calculate the maximum space left based on the opposite side
    if (side == 'top') {
      top = newValue.clamp(0, 100 - bottom);
    } else if (side == 'bottom') {
      bottom = newValue.clamp(0, 100 - top);
    } else if (side == 'left') {
      left = newValue.clamp(0, 100 - right);
    } else if (side == 'right') {
      right = newValue.clamp(0, 100 - left);
    }

    node.properties['padding'] = {
      'top': top,
      'bottom': bottom,
      'left': left,
      'right': right,
    };

    update(); // Redraws UI immediately (No saveState here to prevent Undo flooding)
  }

  /// Updates the canvas padding theme color
  void updatePaddingColor(String id, String colorName) {
    final node = _findNodeById(activeLayout, id);
    if (node != null && node.children.isEmpty) {
      node.properties['padding_color'] = colorName;
      saveState(); // Colors are single clicks, so we CAN save directly to history
      update();
    }
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
          // NEW: Clean, centralized call!
          ErrorHandler.showSuccess(
            'Code Exported!',
            'Production-ready Flutter code copied to clipboard.',
          );
        })
        .catchError((error) {
          // NEW: Clean, centralized call!
          ErrorHandler.showError(
            'Export Failed',
            'Could not access device clipboard.',
          );
        });
  }
}
