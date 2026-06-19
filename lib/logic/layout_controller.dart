import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:layout_engine/core/math/math_engine.dart';
import 'package:layout_engine/core/mixins/history_manager.dart';
import 'package:layout_engine/core/mixins/padding_manager.dart';
import 'package:layout_engine/data/models/layout_node.dart';
import 'package:layout_engine/logic/base_window_interactions.dart';
import 'package:layout_engine/logic/window_manager.dart';
import 'package:layout_engine/services/code_generator_service.dart';
import 'package:layout_engine/services/error_handling.dart';

class LayoutController extends GetxController
    with HistoryManager, PaddingManager {
  @override
  late LayoutNode activeLayout;

  // --- UI TOGGLE STATES ---
  var showCanvasWireframes = true.obs;
  var showLayerWindow = false.obs;
  var activeSplitId = RxnString();
  var isEqualizerOn = true.obs;
  var isHandAdjustmentActive = false.obs;
  Set<String> selectedNodeIds = {};
  var lastUsedSplitType = 'ColumnNode'.obs;

  @override
  void onInit() {
    super.onInit();
    loadInitialState(); // Pulled directly from HistoryManager!
  }

  // --- TOGGLES & HELPERS ---
  void toggleWireframe() {
    showCanvasWireframes.value = !showCanvasWireframes.value;
    update();
  }

  void toggleLayerWindow() {
    showLayerWindow.value = !showLayerWindow.value;
    if (showLayerWindow.value) {
      if (Get.isRegistered<BaseWindowInteractions>(tag: 'Layer')) {
        final logic = Get.find<BaseWindowInteractions>(tag: 'Layer');
        logic.spawnWithAntiOverlap(
          Size(Get.width, Get.height),
          logic.getActiveWindowRects('Layer'),
          'Layer',
        );
      }
      if (Get.isRegistered<WindowManager>()) {
        Get.find<WindowManager>().bringToFront('Layer');
      }
    }
    update();
  }

  void toggleActiveSplit(String id) {
    if (activeSplitId.value == id)
      activeSplitId.value = null;
    else
      activeSplitId.value = id;
    update();
  }

  void toggleEqualizer() {
    isEqualizerOn.value = !isEqualizerOn.value;
    update();
  }

  void toggleHandAdjustment() {
    isHandAdjustmentActive.value = !isHandAdjustmentActive.value;
    update();
  }

  bool isNodeLocked(String? id) {
    if (id == null) return false;
    final node = findNodeById(activeLayout, id); // Now using the public method
    return node?.properties['is_locked'] == true;
  }

  void toggleLock(String nodeId) {
    final node = findNodeById(activeLayout, nodeId);
    if (node != null) {
      node.properties['is_locked'] = !(node.properties['is_locked'] == true);
      saveState();
      update();
    }
  }

  bool isNodeExpanded(String? id) {
    if (id == null) return false;
    final node = findNodeById(activeLayout, id);
    return node?.properties['is_expanded'] == true;
  }

  void toggleExpand(String nodeId) {
    final node = findNodeById(activeLayout, nodeId);
    if (node == null) return;

    bool currentExpand = node.properties['is_expanded'] == true;
    if (node.children.isNotEmpty && !currentExpand) {
      ErrorHandler.showDestructiveWarning(
        onConfirm: () {
          node.children.clear();
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
      node.properties['expanded_flex'] = node.properties['flex_value'];
    } else {
      final parent = findParentOf(activeLayout, node.id);
      if (parent != null && parent.children.isNotEmpty) {
        _normalizeChildrenFlex(parent);
      }
    }
    saveState();
    update();
  }

  // --- SPLIT & MATH ENGINE ---
  void resetSplitsToEqual() {
    final selected = singleSelectedNode;
    if (selected == null) return;

    final isParent =
        selected.type == 'RowNode' || selected.type == 'ColumnNode';
    final parentNode = isParent
        ? selected
        : findParentOf(activeLayout, selected.id);

    if (parentNode == null || parentNode.children.isEmpty) return;

    final equalFlexes = MathEngine.splitEdit(parentNode.children.length);
    for (int i = 0; i < parentNode.children.length; i++) {
      parentNode.children[i].properties['flex_value'] = equalFlexes[i];
    }
    saveState();
    update();
  }

  void attemptSplit(int numberOfSplits, String nodeType) {
    lastUsedSplitType.value = nodeType;
    List<LayoutNode> targets = [];

    if (selectedNodeIds.length == 1) {
      targets = [findNodeById(activeLayout, selectedNodeIds.first)!];
      if (Get.isRegistered<BaseWindowInteractions>(tag: 'Split')) {
        Get.find<BaseWindowInteractions>(
          tag: 'Split',
        ).openSplitWindow(Size(Get.width, Get.height));
      }
      if (Get.isRegistered<WindowManager>()) {
        Get.find<WindowManager>().bringToFront('Split');
      }
    } else {
      targets = selectedNodeIds
          .map((id) => findNodeById(activeLayout, id))
          .whereType<LayoutNode>()
          .toList();
    }

    bool hasChildren = targets.any((node) => node.children.isNotEmpty);
    if (hasChildren) {
      ErrorHandler.showDestructiveWarning(
        onConfirm: () => _executeSplit(targets, numberOfSplits, nodeType),
      );
    } else {
      _executeSplit(targets, numberOfSplits, nodeType);
    }
    activeSplitId.value = null;
  }

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
      target.type = nodeType;
    }

    if (targets.length != 1) selectedNodeIds.clear();
    saveState();
  }

  // =========================================================
  // SMART ROUTER: Split Blank Child vs Switch Parent Axis
  // =========================================================
  void executeSplitOrSwitch(String newType, int requestedSplits) {
    final selected = singleSelectedNode;
    if (selected == null) return;

    // CREATION MODE: The user selected a completely blank container
    if (selected.type == 'ContainerNode' && selected.children.isEmpty) {
      attemptSplit(requestedSplits, newType); // Create a new split inside it
    }
    // EDIT MODE: The user is modifying an existing layout
    else {
      switchSplitType(newType); // Switch the parent's axis
    }
  }

  // =========================================================
  // 🚀 REVERSE TO BLANK SLATE (Double-Tap Action)
  // =========================================================
  void resetToBlankSlate() {
    final selected = singleSelectedNode;
    if (selected == null) return;

    final isParent =
        selected.type == 'RowNode' || selected.type == 'ColumnNode';
    final parentNode = isParent
        ? selected
        : findParentOf(activeLayout, selected.id);

    // If it is already a clean slate, ignore the double tap
    if (parentNode == null || parentNode.children.isEmpty) return;

    bool hasEdits = false;
    final defaultSplits = MathEngine.splitEdit(parentNode.children.length);

    for (int i = 0; i < parentNode.children.length; i++) {
      final child = parentNode.children[i];

      // 1. Check if the child has its own nested splits (destructive!)
      if (child.children.isNotEmpty) {
        hasEdits = true;
        break;
      }
      // 2. Check if the child has custom flex, lock, or expand edits (destructive!)
      if (child.properties['is_locked'] == true ||
          child.properties['is_expanded'] == true ||
          child.properties['flex_value'] != defaultSplits[i]) {
        hasEdits = true;
        break;
      }
    }

    // The core reset action
    void executeReset() {
      parentNode.type = 'ContainerNode';
      parentNode.children.clear();
      activeSplitId.value = null; // Clear sub-selections
      exclusiveSelectNode(parentNode.id); // Reselect the newly blanked parent
      saveState();
      update();
    }

    if (hasEdits) {
      ErrorHandler.showDestructiveWarning(onConfirm: executeReset);
    } else {
      executeReset(); // Completely clean, wipe it instantly!
    }
  }

  // =========================================================
  // Dynamic Switch Logic & Smart Warning
  // =========================================================
  void switchSplitType(String newType) {
    final selected = singleSelectedNode;
    if (selected == null) return;

    // Find out if we are clicking on the parent Row/Column or one of its children
    final isParent =
        selected.type == 'RowNode' || selected.type == 'ColumnNode';
    final parentNode = isParent
        ? selected
        : findParentOf(activeLayout, selected.id);

    if (parentNode == null || parentNode.children.isEmpty) return;
    if (parentNode.type == newType)
      return; // Ignore if they click the type it already is!

    // Update the memory tracker for the toolbar
    lastUsedSplitType.value = newType;

    // Task 1.3: Smart Destructive Check!
    // We check if any child has been locked, expanded, or has custom flex math
    bool hasEdits = false;
    final defaultSplits = MathEngine.splitEdit(parentNode.children.length);

    for (int i = 0; i < parentNode.children.length; i++) {
      final child = parentNode.children[i];
      if (child.properties['is_locked'] == true ||
          child.properties['is_expanded'] == true ||
          child.properties['flex_value'] != defaultSplits[i]) {
        hasEdits = true;
        break; // Stop checking, we found an edit!
      }
    }

    // If they have customized the layout, warn them before switching axes
    if (hasEdits) {
      ErrorHandler.showDestructiveWarning(
        onConfirm: () =>
            _executeSwitchSplitType(parentNode, newType, defaultSplits),
      );
    } else {
      // If it's a fresh, untouched split, swap it instantly!
      _executeSwitchSplitType(parentNode, newType, defaultSplits);
    }
  }

  void _executeSwitchSplitType(
    LayoutNode parentNode,
    String newType,
    List<int> defaultSplits,
  ) {
    // Swap the core node type
    parentNode.type = newType;

    // Reset all children to a clean, equalized state to prevent visual bugs
    // when moving from horizontal ratios to vertical ratios
    for (int i = 0; i < parentNode.children.length; i++) {
      parentNode.children[i].properties['flex_value'] = defaultSplits[i];
      parentNode.children[i].properties['is_locked'] = false;
      parentNode.children[i].properties['is_expanded'] = false;
    }

    saveState();
    update();
  }

  // --- SELECTION ENGINE ---
  LayoutNode? get singleSelectedNode {
    if (selectedNodeIds.length == 1)
      return findNodeById(activeLayout, selectedNodeIds.first);
    return null;
  }

  void exclusiveSelectNode(String id) {
    selectedNodeIds.clear();
    selectedNodeIds.add(id);
    update();
    _checkBaselineSync();
  }

  void selectNode(String id) {
    if (selectedNodeIds.contains(id)) {
      selectedNodeIds.remove(id);
      if (selectedNodeIds.isEmpty &&
          Get.isRegistered<BaseWindowInteractions>(tag: 'Split')) {
        Get.find<BaseWindowInteractions>(tag: 'Split').closeSplitWindow();
      }
      update();
      return;
    }

    final newPath = _getPathToNode(activeLayout, id);
    if (newPath == null) return;

    bool hasConflict = false;
    for (String selectedId in selectedNodeIds) {
      final selectedPath = _getPathToNode(activeLayout, selectedId);
      if (selectedPath == null) continue;
      if (newPath.any((n) => n.id == selectedId) ||
          selectedPath.any((n) => n.id == id)) {
        hasConflict = true;
        break;
      }
    }

    if (hasConflict) {
      ErrorHandler.showAncestryConflict();
      return;
    }

    selectedNodeIds.add(id);
    update();
    _checkBaselineSync();
  }

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

  void updateLayerName(String id, String newName) {
    final node = findNodeById(activeLayout, id);
    if (node != null) {
      node.properties['layer_name'] = newName;
      saveState();
    }
  }

  void _checkBaselineSync() {
    if (selectedNodeIds.length < 2) return;

    List<LayoutNode> selectedNodes = selectedNodeIds
        .map((id) => findNodeById(activeLayout, id))
        .whereType<LayoutNode>()
        .toList();
    if (selectedNodes.isEmpty) return;

    final firstProps = selectedNodes.first.properties;
    bool mismatch = selectedNodes.any(
      (node) =>
          node.properties['flex_value'] != firstProps['flex_value'] ||
          node.properties['is_locked'] != firstProps['is_locked'],
    );

    if (mismatch) {
      ErrorHandler.showBaselineSyncDialog(
        selectedNodes: selectedNodes,
        onSyncSelected: (baselineId) =>
            _applyBaselineSync(baselineId, selectedNodes),
      );
    }
  }

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

  // 🚀 MADE PUBLIC FOR MIXINS
  @override
  LayoutNode? findNodeById(LayoutNode current, String targetId) {
    if (current.id == targetId) return current;
    for (var child in current.children) {
      final found = findNodeById(child, targetId);
      if (found != null) return found;
    }
    return null;
  }

  LayoutNode? findParentOf(LayoutNode current, String targetId) {
    for (var child in current.children) {
      if (child.id == targetId) return current;
      final found = findParentOf(child, targetId);
      if (found != null) return found;
    }
    return null;
  }

  void updateFlexValue(String id, int newFlex) {
    final parent = findParentOf(activeLayout, id);
    if (parent == null || parent.children.isEmpty) return;

    final targetIndex = parent.children.indexWhere((child) => child.id == id);
    if (targetIndex == -1) return;

    if (parent.children[targetIndex].properties['is_expanded'] == true) {
      int baseFlex =
          parent.children[targetIndex].properties['flex_value'] as int? ?? 1000;
      int clampedFlex = newFlex.clamp(baseFlex, 10000);
      parent.children[targetIndex].properties['expanded_flex'] = clampedFlex;
      update();
      return;
    }

    List<int> currentFlexes = parent.children
        .map((child) => (child.properties['flex_value'] as int?) ?? 1000)
        .toList();
    Set<int> lockedIndices = {};
    for (int i = 0; i < parent.children.length; i++) {
      if (parent.children[i].properties['is_locked'] == true)
        lockedIndices.add(i);
    }

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

    for (int i = 0; i < parent.children.length; i++) {
      parent.children[i].properties['flex_value'] = newFlexes[i];
    }
    update();
  }

  void _normalizeChildrenFlex(LayoutNode parent) {
    int totalFlexSum = 0;
    for (var child in parent.children) {
      totalFlexSum += (child.properties['flex_value'] as int?) ?? 1000;
    }

    if (totalFlexSum == 0 || totalFlexSum == 1000) return;

    int assignedSpace = 0;
    Map<int, double> exactFractions = {};
    List<int> newFlexes = List.filled(parent.children.length, 0);

    for (int i = 0; i < parent.children.length; i++) {
      int currentFlex =
          (parent.children[i].properties['flex_value'] as int?) ?? 1000;
      double exact = (currentFlex * 1000) / totalFlexSum;
      newFlexes[i] = exact.floor();
      assignedSpace += newFlexes[i];
      exactFractions[i] = exact - newFlexes[i];
    }

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

    for (int i = 0; i < parent.children.length; i++) {
      parent.children[i].properties['flex_value'] = newFlexes[i];
    }
  }

  // Inside lib/logic/layout_controller.dart
  void copyCodeToClipboard() {
    // Fetch the new package
    final exportPackage = CodeGeneratorService.generateExportPackage(
      activeLayout,
    );

    // Extract just the monolith string for the quick-copy action
    final String generatedCode = exportPackage.singleMonolith.codeContent;

    Clipboard.setData(ClipboardData(text: generatedCode))
        .then((_) {
          ErrorHandler.showSuccess(
            'Code Exported!',
            'Production-ready Flutter code copied to clipboard.',
          );
        })
        .catchError((error) {
          ErrorHandler.showError(
            'Export Failed',
            'Could not access device clipboard.',
          );
        });
  }
}
