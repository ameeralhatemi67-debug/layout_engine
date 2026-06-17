import 'package:get/get.dart';
import '../../models/layout_node.dart';

/// Handles the mathematical boundary rules for layout offsets
mixin PaddingManager on GetxController {
  // Required properties/methods from the parent controller
  LayoutNode get activeLayout;
  LayoutNode? findNodeById(LayoutNode current, String targetId);
  void saveState();

  bool isPaddingValidTarget(String? id) {
    if (id == null) return false;
    final node = findNodeById(activeLayout, id);
    return node != null && node.children.isEmpty;
  }

  void updatePaddingGlobal(String id, List<String> activeSides, int newValue) {
    final node = findNodeById(activeLayout, id);
    if (node == null || node.children.isNotEmpty) return;

    int maxLimit = 100;
    if (activeSides.contains('top') && activeSides.contains('bottom'))
      maxLimit = 50;
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
    update();
  }

  void updatePaddingManual(String id, String side, int newValue) {
    final node = findNodeById(activeLayout, id);
    if (node == null || node.children.isNotEmpty) return;

    Map<String, dynamic> padding = Map<String, dynamic>.from(
      node.properties['padding'],
    );

    int top = padding['top'] ?? 0;
    int bottom = padding['bottom'] ?? 0;
    int left = padding['left'] ?? 0;
    int right = padding['right'] ?? 0;

    if (side == 'top')
      top = newValue.clamp(0, 100 - bottom);
    else if (side == 'bottom')
      bottom = newValue.clamp(0, 100 - top);
    else if (side == 'left')
      left = newValue.clamp(0, 100 - right);
    else if (side == 'right')
      right = newValue.clamp(0, 100 - left);

    node.properties['padding'] = {
      'top': top,
      'bottom': bottom,
      'left': left,
      'right': right,
    };
    update();
  }

  void updatePaddingColor(String id, String colorName) {
    final node = findNodeById(activeLayout, id);
    if (node != null && node.children.isEmpty) {
      node.properties['padding_color'] = colorName;
      saveState();
      update();
    }
  }
}
