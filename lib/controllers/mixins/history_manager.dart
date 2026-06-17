import 'dart:convert';
import 'package:get/get.dart';
import '../../models/layout_node.dart';
import '../../services/storage_service.dart';

/// Handles the Undo/Redo Memento Stack and Hive Persistence
mixin HistoryManager on GetxController {
  static const int maxHistory = 30;

  // These abstract properties force the parent controller to provide them
  LayoutNode get activeLayout;
  set activeLayout(LayoutNode value);

  final List<String> _historyStack = [];
  int _currentIndex = -1;

  var canUndo = false.obs;
  var canRedo = false.obs;

  /// Bootstraps the app by reading from Hive, or creating a fresh layout.
  void loadInitialState() {
    final savedJson = StorageService.loadLayout();

    if (savedJson != null) {
      activeLayout = LayoutNode.fromJson(savedJson);
      pushToHistory(saveToStorage: false);
    } else {
      activeLayout = LayoutNode(
        type: 'ContainerNode',
        properties: {
          'flex_value': 1000,
          'is_locked': false,
          'layer_name': 'Root Canvas',
        },
      );
      pushToHistory();
    }
  }

  /// Call this method ANY time a user completes a layout action.
  void saveState() {
    pushToHistory();
  }

  void pushToHistory({bool saveToStorage = true}) {
    final jsonString = jsonEncode(activeLayout.toJson());

    if (_currentIndex < _historyStack.length - 1) {
      _historyStack.removeRange(_currentIndex + 1, _historyStack.length);
    }

    _historyStack.add(jsonString);

    if (_historyStack.length > maxHistory) {
      _historyStack.removeAt(0);
    } else {
      _currentIndex++;
    }

    _updateButtonStates();

    if (saveToStorage) {
      StorageService.saveLayout(activeLayout.toJson());
    }

    update(); // Tells GetX to rebuild the UI
  }

  void undo() {
    if (!canUndo.value) return;
    _currentIndex--;
    _restoreFromIndex();
  }

  void redo() {
    if (!canRedo.value) return;
    _currentIndex++;
    _restoreFromIndex();
  }

  void _restoreFromIndex() {
    final jsonString = _historyStack[_currentIndex];
    final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;

    activeLayout = LayoutNode.fromJson(jsonMap);
    StorageService.saveLayout(jsonMap);

    _updateButtonStates();
    update();
  }

  void _updateButtonStates() {
    canUndo.value = _currentIndex > 0;
    canRedo.value = _currentIndex < _historyStack.length - 1;
  }
}
