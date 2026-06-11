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

          // Helper: Scaled Icon Builder (Upgraded for visual disabled states)
          Widget buildIcon(
            String asset,
            VoidCallback onTap, {
            VoidCallback? onDoubleTap,
            bool isActive = false,
            bool isEnabled = true, // 🚀 NEW: Controls the greyed-out state
          }) {
            return InkWell(
              // If disabled, intercept the tap and show the snackbar immediately
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
                    // Logic to show Grey (Disabled), Blue (Active), or Black (Enabled)
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
                        'assets/icons/Expand.svg',
                        () => layoutCtrl.toggleExpand(
                          layoutCtrl.activeSplitId.value!,
                        ),
                        isActive: layoutCtrl.isNodeExpanded(
                          layoutCtrl.activeSplitId.value,
                        ),
                        // 🚀 NEW: Only awake if a split is selected
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
                        // 🚀 NEW: Only awake if a split is selected
                        isEnabled: layoutCtrl.activeSplitId.value != null,
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: buildIcon(
                        'assets/icons/SpiltEdit.svg',
                        layoutCtrl
                            .toggleEqualizer, // Single Tap: Toggles Equalizer
                        onDoubleTap: layoutCtrl
                            .resetSplitsToEqual, // Double Tap: Resets All
                        isActive: layoutCtrl.isEqualizerOn.value,
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
                        layoutCtrl
                            .toggleEqualizer, // Single Tap: Toggles Equalizer
                        onDoubleTap: layoutCtrl
                            .resetSplitsToEqual, // Double Tap: Resets All
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
                        // 🚀 NEW: Only awake if a split is selected
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
                        // 🚀 NEW: Only awake if a split is selected
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
            // 🚀 NEW: Fetch the states directly from the JSON
            final isLocked = child.properties['is_locked'] == true;
            final isExpanded = child.properties['is_expanded'] == true;

            percentageFields.add(
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onDoubleTap: () => layoutCtrl.toggleActiveSplit(child.id),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isSubSelected
                          ? Colors.lightBlueAccent
                          : Colors.transparent,
                      width: 2.0 * scale,
                    ),
                    borderRadius: BorderRadius.circular(6 * scale),
                  ),
                  padding: EdgeInsets.all(2.0 * scale),
                  // 🚀 REVERTED: Back to just the clean drag field!
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
            color: const Color.fromARGB(255, 247, 244, 255),
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
