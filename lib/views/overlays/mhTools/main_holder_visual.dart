import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:layout_engine/controllers/window_manager.dart';
import '../../../controllers/layout_controller.dart';
import '../../../controllers/base_window_interactions.dart';

class MainHolderVisual extends StatelessWidget {
  const MainHolderVisual({super.key});

  @override
  Widget build(BuildContext context) {
    final layoutCtrl = Get.find<LayoutController>();
    final interactions = Get.find<BaseWindowInteractions>(tag: 'Main');

    return Obx(() {
      final isHorizontal = interactions.isHorizontal.value;
      final isOpen = interactions.isOpen.value;

      // Helper 1: Draws the dividers dynamically
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

      // Helper 2: Standardizes ALL icons so they are perfectly the same size
      Widget buildIconBtn({
        required Widget icon,
        required VoidCallback? onTap,
        VoidCallback? onLongPress, // ADDED: Long press support!
        required String tooltip,
      }) {
        return Tooltip(
          message: tooltip,
          child: InkWell(
            customBorder:
                const CircleBorder(), // Keeps the circular splash effect
            onTap: onTap,
            onLongPress: onLongPress, // CONNECTED: Triggers the new method
            child: Container(
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              alignment: Alignment.center,
              child: icon,
            ),
          ),
        );
      }

      // Helper 3: Generates standard SVG visuals
      Widget buildSvg(String asset, Color? color) {
        return SvgPicture.asset(
          asset,
          // 🛠️ EDIT THIS: Change the visual size of the SVGs inside the hit-box (Default is 24x24)
          width: 24,
          height: 24,
          fit: BoxFit.contain,
          colorFilter: color != null
              ? ColorFilter.mode(color, BlendMode.srcIn)
              : null,
        );
      }

      // 1. The Main Drag / Minimize Handle
      List<Widget> children = [
        buildIconBtn(
          icon: buildSvg('assets/icons/MainHolder.svg', Colors.black87),
          // Passing screen size for the new Grid Anchor Math
          onTap: () => interactions.toggleOpen(MediaQuery.of(context).size),
          tooltip: 'Drag or Minimize',
        ),
      ];

      // 2. The Expanded Tools
      if (isOpen) {
        children.addAll([
          buildDivider(),

          buildIconBtn(
            icon: buildSvg(
              'assets/icons/Back.svg',
              layoutCtrl.canUndo.value ? Colors.black : Colors.grey,
            ),
            onTap: layoutCtrl.canUndo.value ? layoutCtrl.undo : null,
            tooltip: 'Undo',
          ),

          buildIconBtn(
            icon: Transform.flip(
              flipX: true,
              child: buildSvg(
                'assets/icons/Back.svg',
                layoutCtrl.canRedo.value ? Colors.black : Colors.grey,
              ),
            ),
            onTap: layoutCtrl.canRedo.value ? layoutCtrl.redo : null,
            tooltip: 'Redo',
          ),

          buildDivider(),

          // Fixed Eye Toggle
          buildIconBtn(
            icon: buildSvg(
              layoutCtrl.showCanvasWireframes.value
                  ? 'assets/icons/Look_On.svg'
                  : 'assets/icons/Look_Off.svg',
              layoutCtrl.showCanvasWireframes.value
                  ? Colors.blueAccent
                  : Colors.grey.shade600,
            ),
            onTap: layoutCtrl.toggleWireframe, // Standard Tap
            onLongPress: layoutCtrl.toggleLayerWindow, // Long Press!
            tooltip: 'Tap: Wireframe | Hold: Layer Window',
          ),

          buildDivider(),

          buildIconBtn(
            icon: buildSvg('assets/icons/CreateHolder.svg', Colors.black87),
            onTap: () {
              // 1. Find the Create Interaction Engine
              final createLogic = Get.find<BaseWindowInteractions>(
                tag: 'Create',
              );

              // 2. Toggle its complete visibility
              createLogic.isHidden.value = !createLogic.isHidden.value;

              /// 3. Spawn it dynamically using Anti-Overlap!
              if (!createLogic.isHidden.value) {
                createLogic.isOpen.value = true;

                final screenSize = MediaQuery.of(context).size;
                final activeRects = createLogic.getActiveWindowRects('Create');

                // Uses smart config math
                createLogic.spawnWithAntiOverlap(
                  screenSize,
                  activeRects,
                  'Create',
                );

                // Brings newly opened window to top!
                Get.find<WindowManager>().bringToFront('Create');
              }
            },
            tooltip: 'Toggle Create Tools',
          ),

          buildDivider(),

          buildIconBtn(
            icon: buildSvg('assets/icons/CopyIcon.svg', Colors.blueAccent),
            onTap: layoutCtrl.copyCodeToClipboard,
            tooltip: 'Copy Code',
          ),
        ]);
      }

      // 3. Render
      return Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Flex(
            direction: isHorizontal ? Axis.horizontal : Axis.vertical,
            mainAxisSize: MainAxisSize.min,
            children: children,
          ),
        ),
      );
    });
  }
}
