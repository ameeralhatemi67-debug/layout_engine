import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../../controllers/base_window_interactions.dart';
import '../../controllers/window_manager.dart';
import 'mhTools/main_holder_visual.dart';

class MainHolder extends StatelessWidget {
  const MainHolder({super.key});

  @override
  Widget build(BuildContext context) {
    final interactions = Get.put(
      BaseWindowInteractions()..setupAsToolbar(),
      tag: 'Main',
    );

    // 🚀 THE FIX: This forces the window to read the config coordinates!
    interactions.applyDefaultPosition('Main', MediaQuery.of(context).size);

    return Obx(() {
      if (interactions.isHidden.value) {
        return Positioned(
          top: 16,
          left: 16,
          child: FloatingActionButton.small(
            onPressed: interactions.restoreHolder,
            backgroundColor: Colors.white,
            elevation: 4,
            child: SvgPicture.asset(
              'assets/icons/MainHolder.svg',
              width: 20,
              height: 20,
              colorFilter: const ColorFilter.mode(
                Colors.black87,
                BlendMode.srcIn,
              ),
            ),
          ),
        );
      }

      return Positioned(
        left: interactions.x.value,
        top: interactions.y.value,
        child: Listener(
          onPointerDown: (_) => Get.find<WindowManager>().bringToFront('Main'),
          child: GestureDetector(
            onPanUpdate: interactions.onPanUpdate,
            onPanEnd: (details) =>
                interactions.onPanEnd(details, MediaQuery.of(context).size),
            child: const MainHolderVisual(),
          ),
        ),
      );
    });
  }
}
