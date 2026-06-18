import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:layout_engine/controllers/window_manager.dart';
import 'package:layout_engine/controllers/base_window_interactions.dart';
import 'chTools/create_holder_visual.dart';

class CreateHolder extends StatelessWidget {
  const CreateHolder({super.key});

  @override
  Widget build(BuildContext context) {
    final interactions = Get.put(
      BaseWindowInteractions()
        ..setupAsToolbar(length: 360.0)
        ..exactTopSnapX =
            80.0 // 🚀 NEW: Docks 80px from the left
        ..exactBottomSnapX =
            80.0 // 🚀 NEW: Docks 80px from the left
        ..isHidden.value = true,
      tag: 'Create',
    );

    // 🚀 THE FIX!
    interactions.applyDefaultPosition('Create', MediaQuery.of(context).size);

    return Obx(() {
      if (interactions.isHidden.value) {
        return const SizedBox.shrink();
      }

      return Positioned(
        left: interactions.x.value,
        top: interactions.y.value,
        child: Listener(
          onPointerDown: (_) =>
              Get.find<WindowManager>().bringToFront('Create'),
          child: GestureDetector(
            onPanUpdate: interactions.onPanUpdate,
            onPanEnd: (details) =>
                interactions.onPanEnd(details, MediaQuery.of(context).size),
            child: const CreateHolderVisual(),
          ),
        ),
      );
    });
  }
}
