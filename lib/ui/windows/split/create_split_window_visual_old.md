import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:layout_engine/controllers/layout_controller.dart';
import 'package:layout_engine/models/layout_node.dart';

import 'package:layout_engine/controllers/base_window_interactions.dart';
import '../../components/drag_number_field.dart';
import '../../components/percentage_drag_field.dart';

class CreateSplitWindowVisual extends StatelessWidget {
  const CreateSplitWindowVisual({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<LayoutController>(
      builder: (layoutCtrl) {
        final selected = layoutCtrl.singleSelectedNode;
        if (selected == null) {
          return const SizedBox.shrink();
        }

        final isParent =
            selected.type == 'RowNode' || selected.type == 'ColumnNode';

        // 1. Do a temporary nullable lookup
        LayoutNode? tempParent = isParent
            ? selected
            : layoutCtrl.findParentOf(layoutCtrl.activeLayout, selected.id);

        // 2. 🚀 FIX: Lock it into a strict, NON-NULLABLE variable!
        // Dart will now stop complaining because it mathematically guarantees it is never null.
        final LayoutNode parentNode = tempParent ?? selected;

        final children = parentNode.children;

        // 🚀 FIX: Default to 3 splits in the UI if it's a completely blank slate
        final numSplits = children.isEmpty ? 3 : children.length;

        // Determine the active visual state for the layout toggles
        bool isBlankSlate =
            selected.type == 'ContainerNode' && selected.children.isEmpty;
        bool isRowActive = isBlankSlate
            ? layoutCtrl.lastUsedSplitType.value == 'RowNode'
            : parentNode.type == 'RowNode';
        bool isColActive = isBlankSlate
            ? layoutCtrl.lastUsedSplitType.value == 'ColumnNode'
            : parentNode.type == 'ColumnNode';

        // Fetch the God Class explicitly
        final interactions = Get.find<BaseWindowInteractions>(tag: 'Split');

        return Obx(() {
          final isHorizontal = interactions.isHorizontal.value;
          final scale = interactions.windowScale;

          // ==========================================================
          // 🎨 CUSTOMIZABLE STYLE VARIABLES (EDIT THESE!)
          // ==========================================================
          // 1. Cut Counter Styles (Horizontal Mode)
          // 3. Selected Split Highlight Styles (The Clean Toggle Look)
          final Color toggleFillColor = Colors.lightBlueAccent.withOpacity(
            0.15,
          ); // Very light blue fill
          final Color toggleStrokeColor =
              Colors.lightBlueAccent; // Light blue stroke

          // Adaptive Padding: applies uniformly to ALL items so nothing jumps!
          final double uniformPadX = isHorizontal ? 14.0 * scale : 6.0 * scale;
          final double uniformPadY = isHorizontal ? 6.0 * scale : 14.0 * scale;

          // 2. Toolbar Layout Spacing
          // This controls the gap between the 5 icons and the Cut Counter
          final double iconToCounterGap = 16.0 * scale;

          // 3. Selected Split Highlight Styles
          final Color highlightColor = const Color.fromARGB(
            9,
            154,
            217,
            244,
          ).withOpacity(0.80);

          // How much wider/taller the split gets when selected in HORIZONTAL view
          final double hPaddingX = 16.0 * scale; // Width extension
          final double hPaddingY = 4.0 * scale; // Height extension

          // How much wider/taller the split gets when selected in VERTICAL view
          final double vPaddingX = 4.0 * scale; // Width extension
          final double vPaddingY = 16.0 * scale; // Height extension
          // ==========================================================

          // Helper: Scaled Icon Builder
          Widget buildIcon(
            String asset,
            VoidCallback onTap, {
            VoidCallback? onDoubleTap,
            bool isActive = false,
            bool isEnabled = true,
          }) {
            return InkWell(
              onTap: isEnabled
                  ? onTap
                  : () {
                      Get.snackbar(
                        'Select a Split',
                        'Double-click a percentage below to select it first.',
                        snackPosition: SnackPosition.BOTTOM,
                      );
                    },
              onDoubleTap: onDoubleTap,
              customBorder: const CircleBorder(),
              child: Container(
                constraints: BoxConstraints(
                  minWidth: 40 * scale,
                  minHeight: 40 * scale,
                ),
                alignment: Alignment.center,
                padding: EdgeInsets.all(4.0 * scale),
                child: SvgPicture.asset(
                  asset,
                  width: 28 * scale,
                  height: 28 * scale,
                  colorFilter: ColorFilter.mode(
                    !isEnabled
                        ? Colors.grey.withOpacity(0.4)
                        : (isActive ? Colors.blueAccent : Colors.black87),
                    BlendMode.srcIn,
                  ),
                ),
              ),
            );
          }

          // 1. Cut Counter Widget
          Widget cutCounter = Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.black87, width: 1.5 * scale),
              borderRadius: BorderRadius.circular(6 * scale),
            ),
            child: DragNumberField(
              label: '',
              value: numSplits,
              min: 1,
              max: 5,
              onChanged: (newCuts) {
                // 🚀 FIX: Handle cutting on a blank slate vs an existing layout
                if (isBlankSlate) {
                  layoutCtrl.attemptSplit(
                    newCuts,
                    layoutCtrl.lastUsedSplitType.value,
                  );
                } else {
                  layoutCtrl.attemptSplit(newCuts, parentNode!.type);
                }
              },
            ),
          );

          // 2. The 6-Column Control Grid
          Widget controlsGroup = isHorizontal
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // The Icons are now grouped together and distributed evenly!
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          buildIcon(
                            'assets/icons/Expand.svg',
                            () => layoutCtrl.toggleExpand(
                              layoutCtrl.activeSplitId.value!,
                            ),
                            isActive: layoutCtrl.isNodeExpanded(
                              layoutCtrl.activeSplitId.value,
                            ),
                            isEnabled: layoutCtrl.activeSplitId.value != null,
                          ),
                          buildIcon(
                            'assets/icons/lock.svg',
                            () => layoutCtrl.toggleLock(
                              layoutCtrl.activeSplitId.value!,
                            ),
                            isActive: layoutCtrl.isNodeLocked(
                              layoutCtrl.activeSplitId.value,
                            ),
                            isEnabled: layoutCtrl.activeSplitId.value != null,
                          ),
                          buildIcon(
                            'assets/icons/SpiltEdit.svg',
                            layoutCtrl.toggleEqualizer,
                            onDoubleTap: layoutCtrl.resetSplitsToEqual,
                            isActive: layoutCtrl.isEqualizerOn.value,
                          ),
                          buildIcon(
                            'assets/icons/CreateColumn.svg',
                            () => layoutCtrl.executeSplitOrSwitch(
                              'RowNode',
                              numSplits,
                            ),
                            onDoubleTap: layoutCtrl.resetToBlankSlate,
                            isActive: isRowActive,
                            isEnabled: true,
                          ),
                          buildIcon(
                            'assets/icons/CreateRows.svg',
                            () => layoutCtrl.executeSplitOrSwitch(
                              'ColumnNode',
                              numSplits,
                            ),
                            onDoubleTap: layoutCtrl.resetToBlankSlate,
                            isActive: isColActive,
                            isEnabled: true,
                          ),
                        ],
                      ),
                    ),
                    // The custom gap between icons and the counter
                    SizedBox(width: iconToCounterGap),
                    // The customized Cut Counter
                    cutCounter,
                  ],
                )
              : Column(
                  // Vertical stays exactly the same as requested!
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 1,
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: cutCounter,
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: buildIcon(
                        'assets/icons/CreateColumn.svg',
                        () => layoutCtrl.executeSplitOrSwitch(
                          'RowNode',
                          numSplits,
                        ),
                        onDoubleTap: layoutCtrl.resetToBlankSlate,
                        isActive: isRowActive,
                        isEnabled: true,
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: buildIcon(
                        'assets/icons/CreateRows.svg',
                        () => layoutCtrl.executeSplitOrSwitch(
                          'ColumnNode',
                          numSplits,
                        ),
                        onDoubleTap: layoutCtrl.resetToBlankSlate,
                        isActive: isColActive,
                        isEnabled: true,
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: buildIcon(
                        'assets/icons/SpiltEdit.svg',
                        layoutCtrl.toggleEqualizer,
                        onDoubleTap: layoutCtrl.resetSplitsToEqual,
                        isActive: layoutCtrl.isEqualizerOn.value,
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: buildIcon(
                        'assets/icons/Expand.svg',
                        () => layoutCtrl.toggleExpand(
                          layoutCtrl.activeSplitId.value!,
                        ),
                        isActive: layoutCtrl.isNodeExpanded(
                          layoutCtrl.activeSplitId.value,
                        ),
                        isEnabled: layoutCtrl.activeSplitId.value != null,
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: buildIcon(
                        'assets/icons/lock.svg',
                        () => layoutCtrl.toggleLock(
                          layoutCtrl.activeSplitId.value!,
                        ),
                        isActive: layoutCtrl.isNodeLocked(
                          layoutCtrl.activeSplitId.value,
                        ),
                        isEnabled: layoutCtrl.activeSplitId.value != null,
                      ),
                    ),
                  ],
                );
          // 3. The Adaptive Percentages Row
          List<Widget> percentageFields = [];
          for (int i = 0; i < children.length; i++) {
            final child = children[i];
            final isSubSelected = layoutCtrl.activeSplitId.value == child.id;

            percentageFields.add(
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onDoubleTap: () => layoutCtrl.toggleActiveSplit(child.id),
                child: Container(
                  decoration: BoxDecoration(
                    // 🚀 The Clean Toggle Fill
                    color: isSubSelected ? toggleFillColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(6 * scale),
                    // 🚀 The Stroke: We use a transparent stroke when unselected so the physical size never changes!
                    border: Border.all(
                      color: isSubSelected
                          ? toggleStrokeColor
                          : Colors.transparent,
                      width: 1.5 * scale,
                    ),
                  ),
                  // 🚀 Fixed Padding: Applied universally so sibling elements NEVER jump or shift!
                  padding: EdgeInsets.symmetric(
                    horizontal: uniformPadX,
                    vertical: uniformPadY,
                  ),
                  child: PercentageDragField(
                    rawFlexValue: child.properties['is_expanded'] == true
                        ? (child.properties['expanded_flex'] as int? ??
                              child.properties['flex_value'] as int? ??
                              1000)
                        : (child.properties['flex_value'] as int? ?? 1000),
                    onChanged: (newFlex) =>
                        layoutCtrl.updateFlexValue(child.id, newFlex),
                  ),
                ),
              ),
            );

            if (i < children.length - 1) {
              percentageFields.add(
                isHorizontal
                    ? Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4.0 * scale),
                        child: Text(
                          '-',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18 * scale,
                            color: Colors.black54,
                          ),
                        ),
                      )
                    : Container(
                        margin: EdgeInsets.symmetric(vertical: 6.0 * scale),
                        height: 1.5 * scale,
                        width: 32.0 * scale,
                        color: Colors.black87,
                      ),
              );
            }
          }

          // 4. Render Shell
          return Card(
            elevation: 8,
            color: const Color.fromARGB(255, 247, 242, 250),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12 * scale),
            ),
            child: Container(
              width: isHorizontal ? interactions.widthH : interactions.widthV,
              height: isHorizontal
                  ? interactions.heightH
                  : interactions.heightV,
              padding: EdgeInsets.all(14.0 * scale),
              child: Flex(
                direction: isHorizontal ? Axis.vertical : Axis.horizontal,
                children: [
                  Expanded(flex: 1, child: controlsGroup),
                  if (isHorizontal)
                    SizedBox(height: 8 * scale)
                  else
                    SizedBox(width: 8 * scale),
                  Expanded(
                    flex: 1,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final verticalAlignment = numSplits <= 2
                            ? MainAxisAlignment.center
                            : MainAxisAlignment.spaceBetween;
                        return FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.center,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minWidth: isHorizontal
                                  ? constraints.maxWidth
                                  : 0.0,
                              minHeight: isHorizontal
                                  ? 0.0
                                  : constraints.maxHeight,
                            ),
                            child: Flex(
                              direction: isHorizontal
                                  ? Axis.horizontal
                                  : Axis.vertical,
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: isHorizontal
                                  ? MainAxisAlignment.spaceBetween
                                  : verticalAlignment,
                              children: percentageFields,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }
}
