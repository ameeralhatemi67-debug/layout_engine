import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/layout_controller.dart';
import '../../models/layout_node.dart';

class CanvasView extends StatelessWidget {
  const CanvasView({super.key});

  @override
  Widget build(BuildContext context) {
    // GetBuilder listens for the update() command from LayoutController
    // It is much more efficient than Obx for deeply nested trees.
    return GetBuilder<LayoutController>(
      builder: (controller) {
        return Container(
          color: Colors.white,
          // We pass isRoot: true so the very first layer doesn't try to
          // wrap itself in an Expanded widget (which would cause an error).
          child: _buildNode(controller.activeLayout, isRoot: true),
        );
      },
    );
  }

  /// The Recursive Rendering Engine
  Widget _buildNode(LayoutNode node, {bool isRoot = false}) {
    Widget content;

    // 1. Structural Mapping (Row vs Column)
    if (node.type == 'RowNode') {
      content = Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: node.children.map((child) => _buildNode(child)).toList(),
      );
    } else if (node.type == 'ColumnNode') {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: node.children.map((child) => _buildNode(child)).toList(),
      );
    } else {
      // 2. Leaf Node / Placeholder Mapping
      // This represents an empty split where the user hasn't added items yet.
      content = Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300, width: 1),
          color: Colors.grey.shade50,
        ),
        child: Center(
          child: Text(
            node.properties['layer_name'] ?? node.id.substring(0, 4),
            style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
          ),
        ),
      );
    }

    // 3. The Viewport Mapping (LockEdit)
    final isLocked = node.properties['is_locked'] == true;
    if (isLocked) {
      // If a layout is locked, its visual footprint is constrained by the flex,
      // but the internal content becomes a scrollable viewport.
      content = SingleChildScrollView(child: content);
    }

    // 4. Boundary Protection
    if (isRoot) {
      return content; // The root layer takes the full screen
    }

    // 5. Apply the 1000-Unit Math Engine flex values
    final flexValue = node.properties['flex_value'] as int? ?? 1000;

    return Expanded(flex: flexValue, child: content);
  }
}
