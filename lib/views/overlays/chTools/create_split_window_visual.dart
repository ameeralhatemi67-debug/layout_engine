import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../../../controllers/layout_controller.dart';
import '../../../controllers/base_window_interactions.dart';
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
        final parentNode = isParent
            ? selected
            : layoutCtrl.findParentOf(layoutCtrl.activeLayout, selected.id);

        if (parentNode == null) return const SizedBox.shrink();

        final children = parentNode.children;
        final numSplits = children.length;

        // Fetch the God Class explicitly
        final interactions = Get.find<BaseWindowInteractions>(tag: 'Split');

        return Obx(() {
          final isHorizontal = interactions.isHorizontal.value;
          final scale = interactions.windowScale; // Uniform scaling factor

          // Helper: Scaled Icon Builder
          Widget buildIcon(
            String asset,
            VoidCallback onTap, {
            bool isActive = false,
          }) {
            return IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: SvgPicture.asset(
                asset,
                width: 28 * scale, // Dynamically scales icon size
                height: 28 * scale,
                colorFilter: ColorFilter.mode(
                  isActive ? Colors.blueAccent : Colors.black87,
                  BlendMode.srcIn,
                ),
              ),
              onPressed: onTap,
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
                layoutCtrl.attemptSplit(newCuts, parentNode.type);
              },
            ),
          );

          // 2. The 6-Column Control Grid
          Widget controlsGroup = isHorizontal
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 1,
                      child: buildIcon(
                        'assets/icons/Dragger.svg',
                        layoutCtrl.toggleHandAdjustment,
                        isActive: layoutCtrl.isHandAdjustmentActive.value,
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: buildIcon(
                        'assets/icons/lock.svg',
                        () => layoutCtrl.toggleLock(selected.id),
                        isActive: selected.properties['is_locked'] == true,
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: buildIcon(
                        'assets/icons/SpiltEdit.svg',
                        () {},
                        isActive: true,
                      ),
                    ),
                    // FIX: Reduced empty space to 1, gave cutCounter flex 2
                    const Expanded(flex: 1, child: SizedBox.shrink()),
                    Expanded(
                      flex: 2,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: cutCounter,
                      ),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 1,
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: cutCounter,
                      ),
                    ),
                    const Expanded(
                      flex: 2,
                      child: SizedBox.shrink(),
                    ), // Empty space from diagram
                    Expanded(
                      flex: 1,
                      child: buildIcon(
                        'assets/icons/SpiltEdit.svg',
                        () {},
                        isActive: true,
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: buildIcon(
                        'assets/icons/lock.svg',
                        () => layoutCtrl.toggleLock(selected.id),
                        isActive: selected.properties['is_locked'] == true,
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: buildIcon(
                        'assets/icons/Dragger.svg',
                        layoutCtrl.toggleHandAdjustment,
                        isActive: layoutCtrl.isHandAdjustmentActive.value,
                      ),
                    ),
                  ],
                );

          // 3. The Adaptive Percentages Row
          List<Widget> percentageFields = [];
          for (int i = 0; i < children.length; i++) {
            percentageFields.add(
              PercentageDragField(
                rawFlexValue:
                    children[i].properties['flex_value'] as int? ?? 1000,
                onChanged: (newFlex) =>
                    layoutCtrl.updateFlexValue(children[i].id, newFlex),
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
                        // NEW: Draws the horizontal separator lines seen in your vertical design!
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
            color: const Color(0xFFF2F2F2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16 * scale),
            ),
            child: Container(
              // Scale the outer box directly
              width: isHorizontal ? interactions.widthH : interactions.widthV,
              height: isHorizontal
                  ? interactions.heightH
                  : interactions.heightV,
              // Scale the 14px padding directly
              padding: EdgeInsets.all(14.0 * scale),
              child: Flex(
                direction: isHorizontal ? Axis.vertical : Axis.horizontal,
                children: [
                  // Top Half (Controls)
                  Expanded(flex: 1, child: controlsGroup),

                  // Divider Space
                  if (isHorizontal)
                    SizedBox(height: 8 * scale)
                  else
                    SizedBox(width: 8 * scale),

                  // Bottom Half (Percentages scaling via FittedBox)
                  Expanded(
                    flex: 1,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        // NEW: Center 2 splits, but evenly space 3, 4, and 5 splits!
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
                                  : verticalAlignment, // Applied dynamic alignment here!
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
