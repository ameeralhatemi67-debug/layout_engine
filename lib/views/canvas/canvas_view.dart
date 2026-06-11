import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/layout_controller.dart';
import '../../models/layout_node.dart';

class CanvasView extends StatelessWidget {
  const CanvasView({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<LayoutController>(
      builder: (controller) {
        return Container(
          width: double.infinity,
          height: double.infinity,
          // FIX: Now listens exclusively to the canvas wireframe state
          color: controller.showCanvasWireframes.value
              ? Colors.white
              : Colors.transparent,
          child: _buildNode(controller.activeLayout, controller, isRoot: true),
        );
      },
    );
  }

  Widget _buildNode(
    LayoutNode node,
    LayoutController controller, {
    bool isRoot = false,
  }) {
    Widget content;
    final isWireframe = controller.showCanvasWireframes.value;
    final isHandAdjust = controller.isHandAdjustmentActive.value;

    // NEW: We calculate the selection state at the top so BOTH parents and children can use it!
    final isSelected = controller.selectedNodeIds.contains(node.id);

    // 1. Structural Mapping with Hand Adjustment Injection
    if (node.type == 'RowNode' || node.type == 'ColumnNode') {
      bool isRow = node.type == 'RowNode';
      List<Widget> childrenWidgets = [];

      for (int i = 0; i < node.children.length; i++) {
        // Add the actual child node
        childrenWidgets.add(_buildNode(node.children[i], controller));

        // Inject the Drag Handle if Hand Adjustment is ON and it's not the last child
        if (isHandAdjust && i < node.children.length - 1) {
          childrenWidgets.add(
            _buildDragHandle(node.children[i], isRow, controller),
          );
        }
      }

      content = isRow
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: childrenWidgets,
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: childrenWidgets,
            );

      // VISUAL FEEDBACK FOR PARENTS: If the user long-presses a child,
      // the parent gets selected. We draw a thick blue border around the whole group!
      if (isSelected) {
        content = Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.blueAccent, width: 3.0),
            // We don't add a background tint here so we can still clearly see the children inside
          ),
          child: content,
        );
      }
    } else {
      // 2. Leaf Node Mapping
      content = GestureDetector(
        behavior: HitTestBehavior.opaque,

        // INTERACTION 1: Double tap to exclusively select this specific child
        onDoubleTap: () => controller.exclusiveSelectNode(node.id),

        // INTERACTION 2: Long press to "Select Up" and grab the Parent Row/Column
        onLongPress: () {
          final parent = controller.findParentOf(
            controller.activeLayout,
            node.id,
          );
          if (parent != null) {
            controller.exclusiveSelectNode(parent.id);
          }
        },

        child: Container(
          decoration: isSelected
              ? BoxDecoration(
                  border: Border.all(color: Colors.blueAccent, width: 2.5),
                  color: Colors.blue.withOpacity(
                    0.08,
                  ), // Faint tint for children
                )
              : isWireframe
              ? BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300, width: 1),
                  color: Colors.grey.shade50,
                )
              : null,
          child: isWireframe || isSelected
              ? Center(
                  child: Text(
                    node.properties['layer_name'] ?? node.id.substring(0, 4),
                    style: TextStyle(
                      color: isSelected
                          ? Colors.blueAccent
                          : Colors.grey.shade400,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 12,
                    ),
                  ),
                )
              : null,
        ),
      );
    }

    // 3. Viewport Mapping (LockEdit)
    final isLocked = node.properties['is_locked'] == true;
    if (isLocked) {
      content = SingleChildScrollView(child: content);
    }

    // 4. Boundary Protection
    if (isRoot) return content;

    // 5. Apply Flex Math
    final flexValue = node.properties['flex_value'] as int? ?? 1000;
    return Expanded(flex: flexValue, child: content);
  }

  /// Builds the physical draggable divider between splits
  Widget _buildDragHandle(
    LayoutNode targetNode,
    bool isRow,
    LayoutController controller,
  ) {
    return MouseRegion(
      cursor: isRow
          ? SystemMouseCursors.resizeLeftRight
          : SystemMouseCursors.resizeUpDown,
      child: GestureDetector(
        onPanUpdate: (details) {
          // Placeholder for the Canvas Drag Math!
          // We will connect this to a dedicated pixel-to-flex converter later.
          print("Dragging canvas handle for ${targetNode.id}");
        },
        child: Container(
          width: isRow ? 12.0 : double.infinity,
          height: isRow ? double.infinity : 12.0,
          color: Colors.blueAccent.withOpacity(0.8),
          child: Icon(
            isRow ? Icons.drag_indicator : Icons.horizontal_rule,
            size: 12,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
