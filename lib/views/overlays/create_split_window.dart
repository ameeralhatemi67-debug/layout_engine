import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:layout_engine/controllers/base_window_interactions.dart';
import 'package:layout_engine/controllers/window_manager.dart';
import 'package:layout_engine/views/overlays/chTools/create_split_window_visual.dart';

class CreateSplitWindow extends StatelessWidget {
  const CreateSplitWindow({super.key});

  @override
  Widget build(BuildContext context) {
    final interactions = Get.put(
      BaseWindowInteractions()..setupAsSplitWindow(scale: 0.8),
      tag: 'Split',
    );

    // 🚀 THE FIX!
    interactions.applyDefaultPosition('Split', MediaQuery.of(context).size);

    return Obx(() {
      final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
      if (keyboardHeight > 0) {
        interactions.adjustForKeyboard(
          keyboardHeight,
          MediaQuery.of(context).size,
        );
      }

      if (!interactions.isOpen.value) {
        return const SizedBox.shrink();
      }

      return Positioned(
        left: interactions.x.value,
        top: interactions.y.value,
        child: Listener(
          onPointerDown: (_) => Get.find<WindowManager>().bringToFront('Split'),
          child: GestureDetector(
            onPanUpdate: interactions.onPanUpdate,
            onPanEnd: (details) =>
                interactions.onPanEnd(details, MediaQuery.of(context).size),
            child: const CreateSplitWindowVisual(),
          ),
        ),
      );
    });
  }
}
