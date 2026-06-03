import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/layout_controller.dart';
import '../../models/layout_node.dart';

class CanvasView extends StatelessWidget {
  const CanvasView({super.key});

  @override
  Widget build(BuildContext context) {
    // GetBuilder listens for the update() command from LayoutController
    return GetBuilder<LayoutController>(
      builder: (controller) {
        return Container(
          // Optional: Make the root background transparent in Preview Mode
          color: controller.isWireframeMode.value
              ? Colors.white
              : Colors.transparent,
          // We now pass the controller down into the recursive engine
          child: _buildNode(controller.activeLayout, controller, isRoot: true),
        );
      },
    );
  }

  /// The Recursive Rendering Engine
  Widget _buildNode(
    LayoutNode node,
    LayoutController controller, {
    bool isRoot = false,
  }) {
    Widget content;

    // Read the global wireframe state
    final isWireframe = controller.isWireframeMode.value;

    // 1. Structural Mapping (Row vs Column)
    if (node.type == 'RowNode') {
      content = Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        // Pass the controller down to the children recursively
        children: node.children
            .map((child) => _buildNode(child, controller))
            .toList(),
      );
    } else if (node.type == 'ColumnNode') {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: node.children
            .map((child) => _buildNode(child, controller))
            .toList(),
      );
    } else {
      // 2. Leaf Node / Placeholder Mapping
      content = Container(
        // Conditionally strip the borders and background color
        decoration: isWireframe
            ? BoxDecoration(
                border: Border.all(color: Colors.grey.shade300, width: 1),
                color: Colors.grey.shade50,
              )
            : null,
        // Conditionally hide the placeholder text so it looks like a real blank app
        child: isWireframe
            ? Center(
                child: Text(
                  node.properties['layer_name'] ?? node.id.substring(0, 4),
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                ),
              )
            : null,
      );
    }

    // 3. The Viewport Mapping (LockEdit)
    final isLocked = node.properties['is_locked'] == true;
    if (isLocked) {
      content = SingleChildScrollView(child: content);
    }

    // 4. Boundary Protection
    if (isRoot) {
      return content;
    }

    // 5. Apply the 1000-Unit Math Engine flex values
    final flexValue = node.properties['flex_value'] as int? ?? 1000;

    return Expanded(flex: flexValue, child: content);
  }
}
