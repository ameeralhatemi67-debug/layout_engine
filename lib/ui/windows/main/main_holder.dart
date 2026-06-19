import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:layout_engine/logic/base_window_interactions.dart';
import 'package:layout_engine/logic/layout_controller.dart';
import 'package:layout_engine/logic/window_manager.dart';
import 'package:layout_engine/ui/windows/main/main_holder_visual.dart';

class MainHolder extends StatelessWidget {
  const MainHolder({super.key});

  @override
  Widget build(BuildContext context) {
    final interactions = Get.find<BaseWindowInteractions>(tag: 'Main');
    final layoutCtrl = Get.find<LayoutController>();

    // This forces the window to read the config coordinates!
    interactions.applyDefaultPosition('Main', MediaQuery.of(context).size);

    return Obx(() {
      // =====================================================================
      // 🚀 THE ULTRA-MINIMIZED FAILSAFE GRAPHIC (SVG VERSION)
      // =====================================================================
      if (interactions.isHidden.value) {
        return Positioned(
          // 🛠️ EDIT LOCATION HERE:
          // Distance from the top and left edges of the screen.
          top: 3,
          left: 3,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              // Recovers the MainHolder to safety!
              interactions.restoreHolder();
            },
            child: Container(
              // 🛠️ EDIT HIT-BOX SIZE HERE:
              // Make this slightly larger than the SVG so it's easy to tap with a finger
              width: 48,
              height: 48,
              color: Colors.transparent,
              alignment: Alignment.topLeft,
              child: SvgPicture.asset(
                'assets/icons/ultraMini.svg', // Ensure your file is exactly named this
                // 🛠️ EDIT SVG SIZE HERE:
                width: 24,
                height: 24,
                fit: BoxFit.contain,
                // 🛠️ EDIT COLOR AND OPACITY HERE:
                colorFilter: ColorFilter.mode(
                  const Color.fromARGB(255, 10, 10, 10).withOpacity(0.8),
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
        );
      }

      // =====================================================================
      // NORMAL MAIN HOLDER RENDERING
      // =====================================================================
      return Positioned(
        left: interactions.x.value,
        top: interactions.y.value,
        child: Listener(
          onPointerDown: (_) => Get.find<WindowManager>().bringToFront('Main'),
          child: GestureDetector(
            onPanUpdate: interactions.onPanUpdate,
            onPanEnd: (details) =>
                interactions.onPanEnd(details, MediaQuery.of(context).size),
            // Ensure you are importing your visual file at the top!
            child: MainHolderVisual(
              isHorizontal: interactions.isHorizontal.value,
              isOpen: interactions.isOpen.value, // ADDED
              canUndo: layoutCtrl.canUndo.value,
              canRedo: layoutCtrl.canRedo.value,
              showCanvasWireframes: layoutCtrl.showCanvasWireframes.value,
              onUndo: layoutCtrl.undo,
              onRedo: layoutCtrl.redo,
              onToggleWireframe: layoutCtrl.toggleWireframe,
              onToggleLayerWindow: layoutCtrl.toggleLayerWindow,
              onCopyCode:
                  layoutCtrl.copyCodeToClipboard, // FIX: Properly mapped
              onToggleOpen: () =>
                  interactions.toggleOpen(MediaQuery.of(context).size), // ADDED
              onToggleCreateTools: () {
                // ADDED: Moved all Get.find logic here!
                final createLogic = Get.find<BaseWindowInteractions>(
                  tag: 'Create',
                );
                createLogic.isHidden.value = !createLogic.isHidden.value;
                if (!createLogic.isHidden.value) {
                  createLogic.isOpen.value = true;
                  final screenSize = MediaQuery.of(context).size;
                  final activeRects = createLogic.getActiveWindowRects(
                    'Create',
                  );
                  createLogic.spawnWithAntiOverlap(
                    screenSize,
                    activeRects,
                    'Create',
                  );
                  Get.find<WindowManager>().bringToFront('Create');
                }
              },
            ),
          ),
        ),
      );
    });
  }
}
