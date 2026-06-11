import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../../../controllers/layout_controller.dart';
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
          buildDivider(),
          buildIconBtn(
            icon: buildSvg('assets/icons/CreateColumn.svg'),
            onTap: () => layoutCtrl.attemptSplit(3, 'RowNode'),
            tooltip: 'Create 3 Columns',
          ),
          buildIconBtn(
            icon: buildSvg('assets/icons/CreateRows.svg'),
            onTap: () => layoutCtrl.attemptSplit(3, 'ColumnNode'),
            tooltip: 'Create 3 Rows',
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
          buildDivider(),
          buildIconBtn(
            icon: buildSvg('assets/icons/Square.svg'),
            onTap: () => Get.snackbar('Coming Soon', 'Square Widget'),
            tooltip: 'Add Square',
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

      return Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          padding: const EdgeInsets.all(8.0),
          // Set absolute max boundaries so it knows when to activate the ScrollView
          constraints: BoxConstraints(
            maxWidth: isHorizontal ? screenSize.width - 32 : 60,
            maxHeight: isHorizontal ? 60 : screenSize.height - 100,
          ),
          child: SingleChildScrollView(
            // Dynamically change scroll axis based on the snap orientation!
            scrollDirection: isHorizontal ? Axis.horizontal : Axis.vertical,
            child: Flex(
              direction: isHorizontal ? Axis.horizontal : Axis.vertical,
              mainAxisSize: MainAxisSize.min,
              children: children,
            ),
          ),
        ),
      );
    });
  }
}
