import 'package:flutter/material.dart';
import '../../models/layout_node.dart';

class ExpandedViewport extends StatelessWidget {
  final LayoutNode node;
  final LayoutNode? parentNode;
  final Widget content;

  const ExpandedViewport({
    super.key,
    required this.node,
    required this.parentNode,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    final isExpanded = node.properties['is_expanded'] == true;
    final isLocked = node.properties['is_locked'] == true;

    // 🚀 STAYS INTACT: If it's a normal node, just return the content as-is to prevent layout crashes
    if (!isExpanded && !isLocked) return content;

    bool isParentRow = parentNode?.type == 'RowNode';

    return LayoutBuilder(
      builder: (context, constraints) {
        // Compute safe boundaries based on what the parent flex layout allocated
        double safeWidth = constraints.maxWidth.isInfinite
            ? 1000.0
            : constraints.maxWidth;
        double safeHeight = constraints.maxHeight.isInfinite
            ? 1000.0
            : constraints.maxHeight;

        double? internalWidth;
        double? internalHeight;

        if (isExpanded) {
          int baseFlex = node.properties['flex_value'] as int? ?? 1000;
          int expFlex = node.properties['expanded_flex'] as int? ?? baseFlex;

          // CRITICAL MATH GUARD: Prevent divide-by-zero
          if (baseFlex <= 0) baseFlex = 1;
          double ratio = expFlex / baseFlex;

          // CRITICAL LAYOUT GUARD: Never multiply by infinity!
          if (isParentRow) {
            internalWidth = constraints.maxWidth.isInfinite
                ? 1000 // Fallback safe width
                : (constraints.maxWidth * ratio);
            internalHeight = safeHeight; // Enforce cross-axis fill
          } else {
            internalWidth = safeWidth; // Enforce cross-axis fill
            internalHeight = constraints.maxHeight.isInfinite
                ? 1000 // Fallback safe height
                : (constraints.maxHeight * ratio);
          }
        } else {
          // 🚀 THE VISUAL FIX: If the node is locked but NOT expanded, force it to fill
          // the exact dimensions passed down by its parent flex layout cell.
          // This prevents SingleChildScrollView from collapsing the box down to the lock icon size!
          internalWidth = safeWidth;
          internalHeight = safeHeight;
        }

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          scrollDirection: isParentRow ? Axis.horizontal : Axis.vertical,
          child: SizedBox(
            width: internalWidth,
            height: internalHeight,
            child: content,
          ),
        );
      },
    );
  }
}
