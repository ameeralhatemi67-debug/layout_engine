import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:layout_engine/logic/base_window_interactions.dart';

class CreateHolderVisual extends StatelessWidget {
  final bool isHorizontal;
  final bool isOpen;
  final String lastUsedSplitType;
  final VoidCallback onToggleOpen;
  final Function(String, int) onSplitOrSwitch;
  final VoidCallback onTogglePadding;

  const CreateHolderVisual({
    super.key,
    required this.isHorizontal,
    required this.isOpen,
    required this.lastUsedSplitType,
    required this.onToggleOpen,
    required this.onSplitOrSwitch,
    required this.onTogglePadding,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

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
        onTap: onToggleOpen,
        tooltip: 'Drag or Minimize',
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

    // 2. The Expanded Tools
    if (isOpen) {
      children.addAll([
        buildDivider(),
        buildIconBtn(
          icon: buildSvg(
            lastUsedSplitType == 'RowNode'
                ? 'assets/icons/CreateRows.svg'
                : 'assets/icons/CreateColumn.svg',
          ),
          onTap: () {
            onSplitOrSwitch(lastUsedSplitType, 3);
          },
          tooltip: 'Create Split',
        ),

        buildIconBtn(
          icon: buildSvg('assets/icons/Padding.svg'),
          onTap: onTogglePadding,
          tooltip: 'Padding / Alignment',
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
                scrollDirection: isHorizontal ? Axis.horizontal : Axis.vertical,
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
  }
}
