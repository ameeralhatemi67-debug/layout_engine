import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:layout_engine/controllers/layout_controller.dart';
import 'package:layout_engine/controllers/window_manager.dart';
import 'package:layout_engine/controllers/base_window_interactions.dart';

class CreateHolderVisual extends StatelessWidget {
  const CreateHolderVisual({super.key});

  @override
  Widget build(BuildContext context) {
    final layoutCtrl = Get.find<LayoutController>();

    // Notice the 'Create' tag!
    final interactions = Get.find<BaseWindowInteractions>(tag: 'Create');

    return Obx(() {
      final isHorizontal = interactions.isHorizontal.value;
      final isOpen = interactions.isOpen.value;

      // Helper 1: Build Divider
      Widget buildDivider() {
        return Container(
          width: isHorizontal ? 1 : 24,
          height: isHorizontal ? 24 : 1,
          color: Colors.grey.shade300,
          margin: EdgeInsets.symmetric(
            horizontal: isHorizontal ? 8.0 : 0.0,
            vertical: isHorizontal ? 0.0 : 8.0,
          ),
        );
      }

      // Helper 2: Standardizes icons, but allows us to override the size!
      Widget buildIconBtn({
        required Widget icon,
        required VoidCallback? onTap,
        required String tooltip,
        double boxSize = 40, // NEW: Defaults to 40, but can be made larger
      }) {
        return IconButton(
          constraints: BoxConstraints(minWidth: boxSize, minHeight: boxSize),
          padding: EdgeInsets.zero,
          icon: icon,
          onPressed: onTap,
          tooltip: tooltip,
        );
      }

      // Helper 3: Renders SVGs, with a custom size parameter
      Widget buildSvg(String asset, {double size = 24}) {
        return SvgPicture.asset(
          asset,
          width: size,
          height: size,
          fit: BoxFit.contain,
          colorFilter: const ColorFilter.mode(Colors.black87, BlendMode.srcIn),
        );
      }

      // 1. The Main Drag / Minimize Handle
      List<Widget> children = [
        buildIconBtn(
          boxSize: 48, // Make the hit-box bigger
          tooltip: 'Drag or Minimize',
          onTap: () => interactions.toggleOpen(MediaQuery.of(context).size),
          icon: RotatedBox(
            // If it is NOT horizontal (meaning it's vertical on the right/left), rotate 90 degrees (1 quarter turn)
            quarterTurns: isHorizontal ? 0 : 1,
            child: buildSvg(
              'assets/icons/MainHolder.svg',
              size: 28,
            ), // Make the SVG visually bigger
          ),
        ),
      ];

      if (isOpen) {
        children.addAll([
          // 🚀 Task 2.1: The Dynamic Split Button
          // Automatically reads the last used type to display the correct SVG and logic
          buildIconBtn(
            icon: buildSvg(
              layoutCtrl.lastUsedSplitType.value == 'RowNode'
                  ? 'assets/icons/CreateColumn.svg'
                  : 'assets/icons/CreateRows.svg',
            ),
            onTap: () {
              final logic = Get.find<BaseWindowInteractions>(tag: 'Split');
              if (logic.isOpen.value) {
                logic.isOpen.value = false; // Close if already open
              } else {
                // Execute using the memory tracker!
                logic.openSplitWindow(MediaQuery.of(context).size);
                if (Get.isRegistered<WindowManager>()) {
                  Get.find<WindowManager>().bringToFront('Split');
                }
              }
            },
            tooltip: layoutCtrl.lastUsedSplitType.value == 'RowNode'
                ? 'Create 3 Columns'
                : 'Create 3 Rows',
          ),
          buildIconBtn(
            icon: buildSvg('assets/icons/Padding.svg'),
            onTap: () {
              final selectedId = layoutCtrl.singleSelectedNode?.id;

              if (layoutCtrl.isPaddingValidTarget(selectedId)) {
                if (Get.isRegistered<BaseWindowInteractions>(tag: 'Padding')) {
                  final logic = Get.find<BaseWindowInteractions>(
                    tag: 'Padding',
                  );

                  if (logic.isOpen.value) {
                    logic.isOpen.value = false;
                  } else {
                    logic.openSplitWindow(MediaQuery.of(context).size);
                    if (Get.isRegistered<WindowManager>()) {
                      Get.find<WindowManager>().bringToFront('Padding');
                    }
                  }
                }
              } else {
                Get.snackbar(
                  'Invalid Target',
                  'Padding can only be applied to empty leaf nodes. Select a single empty container.',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.redAccent,
                  colorText: Colors.white,
                );
              }
            },
            tooltip: 'Toggle Padding',
          ),
          buildDivider(),
          buildIconBtn(
            icon: buildSvg('assets/icons/Text.svg'),
            onTap: () => Get.snackbar('Coming Soon', 'Text Widget'),
            tooltip: 'Add Text',
          ),
          buildIconBtn(
            icon: buildSvg('assets/icons/image.svg'),
            onTap: () => Get.snackbar('Coming Soon', 'Image Widget'),
            tooltip: 'Add Image',
          ),
          buildIconBtn(
            icon: buildSvg('assets/icons/Square.svg'),
            onTap: () {
              // 🚀 NEW: Toggles the Blue/Red Outer Detection Zones!
              Get.find<BaseWindowInteractions>(
                tag: 'Main',
              ).showDetectionZones.toggle();
            },
            tooltip: 'Toggle Detection Limits',
          ),

          buildIconBtn(
            icon: buildSvg('assets/icons/Triangle.svg'),
            // <--- CONNECTED THE TOGGLE HERE!
            onTap: () {
              // We target 'Main' because the overlay listens to the Main controller instance
              Get.find<BaseWindowInteractions>(
                tag: 'Main',
              ).showDebugSnap.toggle();
            },
            tooltip: 'Toggle Snapping Zones',
          ),
          buildDivider(),
          buildIconBtn(
            icon: buildSvg('assets/icons/AddIcon.svg'),
            onTap: () => Get.snackbar('Coming Soon', 'Custom Widget'),
            tooltip: 'Add Custom',
          ),
        ]);
      }

      // 3. Render with Scrollable Bounds
      final screenSize = MediaQuery.of(context).size;

      // 🚀 THE FIX: Split the children list!
      // The first item becomes the solid drag handle. The rest go into the scroll view.
      final fixedChild = children.first;
      final scrollableChildren = children.sublist(1);

      return Card(
        elevation: 8,
        color: const Color.fromARGB(255, 247, 242, 250),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          padding: const EdgeInsets.all(8.0),
          constraints: BoxConstraints(
            maxWidth: isHorizontal ? screenSize.width - 32 : 60,
            maxHeight: isHorizontal ? 60 : screenSize.height - 100,
          ),
          child: Flex(
            direction: isHorizontal ? Axis.horizontal : Axis.vertical,
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. The Solid First Icon (Does not scroll)
              fixedChild,

              // 2. The Scrollable Tools
              Flexible(
                child: SingleChildScrollView(
                  scrollDirection: isHorizontal
                      ? Axis.horizontal
                      : Axis.vertical,
                  child: Flex(
                    direction: isHorizontal ? Axis.horizontal : Axis.vertical,
                    mainAxisSize: MainAxisSize.min,
                    children: scrollableChildren,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
