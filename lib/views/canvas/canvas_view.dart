import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:layout_engine/controllers/base_window_interactions.dart';
import 'package:layout_engine/views/canvas/expanded_viewport.dart';
import 'package:layout_engine/views/canvas/padding_visualizer.dart';
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
    bool isParentAdjusting = false,
  }) {
    Widget content;
    final isWireframe = controller.showCanvasWireframes.value;
    // NEW: We calculate the selection state at the top so BOTH parents and children can use it!
    final isSelected = controller.selectedNodeIds.contains(node.id);

    // NEW: Define these up here so the whole method can see them!
    final isExpanded = node.properties['is_expanded'] == true;
    final isLocked = node.properties['is_locked'] == true;

    // TASK 1: Smart visibility. Only show handles if the node is selected AND the window is open.
    bool isSplitOpen = false;
    if (Get.isRegistered<BaseWindowInteractions>(tag: 'Split')) {
      isSplitOpen = Get.find<BaseWindowInteractions>(tag: 'Split').isOpen.value;
    }
    final isHandAdjust = isSplitOpen && isSelected;

    // 1. Structural Mapping with Hand Adjustment Injection
    if (node.type == 'RowNode' || node.type == 'ColumnNode') {
      bool isRow = node.type == 'RowNode';
      List<Widget> childrenWidgets = [];

      for (int i = 0; i < node.children.length; i++) {
        // Add the actual child node
        childrenWidgets.add(
          _buildNode(
            node.children[i],
            controller,
            isParentAdjusting: isHandAdjust,
          ),
        );

        // Inject the Drag Handle if Hand Adjustment is ON and it's not the last child
        // Inject the Drag Handle if Hand Adjustment is ON and it's not the last child
        if (isHandAdjust && i < node.children.length - 1) {
          childrenWidgets.add(
            // STRUCTURAL ANCHOR: Strictly bound to 2px so it can't crash the Row
            SizedBox(
              width: isRow ? 1.0 : null,
              height: isRow ? null : 1.0,
              child: _buildDragHandle(node.children[i], isRow, controller),
            ),
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
        onDoubleTap: () => controller.exclusiveSelectNode(node.id),
        onLongPress: () {
          final parent = controller.findParentOf(
            controller.activeLayout,
            node.id,
          );
          if (parent != null) {
            controller.exclusiveSelectNode(parent.id);
          }
        },
        child: CustomPaint(
          // Render the dots only if it's expanded and wireframes are on
          foregroundPainter: (isWireframe && isExpanded)
              ? DottedBackgroundPainter()
              : null,
          child: Container(
            decoration: isSelected
                ? BoxDecoration(
                    border: Border.all(color: Colors.blueAccent, width: 2.5),
                    // DEBUG COLOR 1: A bright pink tint if it's selected AND expanded
                    color: isExpanded
                        ? Colors.pinkAccent.withOpacity(0.3)
                        : Colors.blue.withOpacity(0.08),

                    // Faint tint for children
                  )
                : (isWireframe && !isParentAdjusting)
                ? BoxDecoration(
                    border: Border.all(
                      color: const Color.fromARGB(255, 224, 224, 224),
                      width: 1,
                    ),
                    color: isExpanded
                        ? Colors.yellow.withOpacity(0.3)
                        : const Color.fromARGB(0, 250, 250, 250),
                  )
                : null,
            child: isWireframe || isSelected
                ? CustomPaint(
                    // 🚀 NEW: The Padding Visualizer! Paints under the text but over the background.
                    painter: PaddingHachurePainter(
                      top:
                          (node.properties['padding']?['top'] as num?)
                              ?.toDouble() ??
                          0.0,
                      bottom:
                          (node.properties['padding']?['bottom'] as num?)
                              ?.toDouble() ??
                          0.0,
                      left:
                          (node.properties['padding']?['left'] as num?)
                              ?.toDouble() ??
                          0.0,
                      right:
                          (node.properties['padding']?['right'] as num?)
                              ?.toDouble() ??
                          0.0,
                      colorName:
                          node.properties['padding_color'] as String? ??
                          'light_orange',
                    ),
                    // 🚀 CHANGED: If locked, show ONLY the icon. If unlocked, show ONLY the text.
                    child: isLocked
                        ? SvgPicture.asset(
                            'assets/icons/lock.svg',
                            width:
                                24, // Bumped back up to 16px since it's the only item
                            height: 24,
                            colorFilter: const ColorFilter.mode(
                              Color.fromARGB(118, 0, 0, 0),
                              BlendMode.srcIn,
                            ),
                          )
                        : Text(
                            node.properties['layer_name'] ??
                                node.id.substring(0, 4),
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
        ),
      );
    }

    // 3. Viewport Mapping (LockEdit & Expand)
    content = ExpandedViewport(
      node: node,
      parentNode: controller.findParentOf(controller.activeLayout, node.id),
      content: content,
    );

    // 4. Boundary Protection
    if (isRoot) return content;

    // 5. Apply Flex Math
    final flexValue = node.properties['flex_value'] as int? ?? 1000;
    return Expanded(flex: flexValue, child: content);
  }

  Widget _buildDragHandle(
    LayoutNode targetNode,
    bool isRow,
    LayoutController controller,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double availableSpace = isRow
            ? constraints.maxHeight
            : constraints.maxWidth;
        double iconSize = (availableSpace * 0.3).clamp(15.0, 30.0);
        double touchSquareSize = iconSize * 2.0;

        return Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            // LAYER 1: The thin 2px visual line (Bottom)
            // We absolutely need this! It fills the 2px parent constraints perfectly to draw the line.
            Container(color: Colors.blueAccent.withOpacity(0.4)),

            // LAYER 2: The pure SVG Icon (Middle)
            // Wrapped in an OverflowBox so it can break out of the 2px structural boundary!
            OverflowBox(
              minWidth: iconSize,
              maxWidth: iconSize,
              minHeight: iconSize,
              maxHeight: iconSize,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors
                      .white, // Matches the canvas, breaking the blue line seamlessly
                  shape: BoxShape.circle,
                ),
                child: RotatedBox(
                  quarterTurns: isRow ? 0 : 1,
                  child: SvgPicture.asset(
                    'assets/icons/Dragger.svg',
                    width: iconSize,
                    height: iconSize,
                  ),
                ),
              ),
            ),

            // LAYER 3: The Interactive Touch Square (Top - "Pane of Glass")
            OverflowBox(
              minWidth: touchSquareSize,
              maxWidth: touchSquareSize,
              minHeight: touchSquareSize,
              maxHeight: touchSquareSize,
              child: MouseRegion(
                cursor: isRow
                    ? SystemMouseCursors.resizeLeftRight
                    : SystemMouseCursors.resizeUpDown,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragUpdate: isRow
                      ? (details) => _handleDragMath(
                          details.delta.dx,
                          targetNode,
                          controller,
                          true,
                        )
                      : null,
                  onVerticalDragUpdate: !isRow
                      ? (details) => _handleDragMath(
                          details.delta.dy,
                          targetNode,
                          controller,
                          false,
                        )
                      : null,

                  // This is now purely an overlay layer. It contains NO children.
                  child: Container(
                    width: touchSquareSize,
                    height: touchSquareSize,
                    // Keep your red test color here to visually verify it hovers over the icon!
                    // Change back to Colors.transparent when you are done testing.
                    color: const Color.fromARGB(0, 144, 18, 18),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Your math logic kept completely separate and untouched
  void _handleDragMath(
    double delta,
    LayoutNode targetNode,
    LayoutController controller,
    bool isRow,
  ) {
    double totalSpace = isRow ? (Get.width - 32) : (Get.height - 32);
    double percentage = delta / totalSpace;
    int flexDelta = (percentage * 1000).round();

    if (flexDelta != 0) {
      int currentFlex = targetNode.properties['is_expanded'] == true
          ? (targetNode.properties['expanded_flex'] as int? ?? 1000)
          : (targetNode.properties['flex_value'] as int? ?? 1000);
      controller.updateFlexValue(targetNode.id, currentFlex + flexDelta);
    }
  }
}

class DottedBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // LAYOUT GUARD: Do not attempt to paint if given infinite dimensions!
    if (size.width.isInfinite ||
        size.height.isInfinite ||
        size.width <= 0 ||
        size.height <= 0) {
      return;
    }

    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    const double spacing = 16.0;
    int safetyCounter = 0; // ANR Prevention

    for (double dy = spacing; dy < size.height; dy += spacing) {
      for (double dx = spacing; dx < size.width; dx += spacing) {
        // HARD LIMIT: If it tries to draw more than 50k dots, abort the loop to save the thread!
        if (safetyCounter++ > 50000) return;

        canvas.drawCircle(Offset(dx, dy), 1.5, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false; // Or true if animating
}
