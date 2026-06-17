import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:layout_engine/controllers/base_window_interactions.dart';
import '../../controllers/window_manager.dart';
import 'mhTools/main_holder_visual.dart';

class MainHolder extends StatelessWidget {
  const MainHolder({super.key});

  @override
  Widget build(BuildContext context) {
    final interactions = Get.find<BaseWindowInteractions>(tag: 'Main');

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
            child: const MainHolderVisual(),
          ),
        ),
      );
    });
  }
}
