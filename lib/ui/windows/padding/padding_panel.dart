import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:layout_engine/logic/base_window_interactions.dart';
import 'package:layout_engine/logic/window_manager.dart';
import 'package:layout_engine/ui/windows/padding/padding_panel_visual.dart';

class PaddingPanel extends StatelessWidget {
  const PaddingPanel({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Initialize the interaction engine with the 'Padding' tag
    final interactions = Get.put(
      BaseWindowInteractions()..setupAsSplitWindow(scale: 0.8),
      tag: 'Padding',
    );

    interactions.applyDefaultPosition('Padding', MediaQuery.of(context).size);

    return Obx(() {
      final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
      if (keyboardHeight > 0) {
        interactions.adjustForKeyboard(
          keyboardHeight,
          MediaQuery.of(context).size,
        );
      }

      // Hide completely if closed
      if (!interactions.isOpen.value) {
        return const SizedBox.shrink();
      }

      return Positioned(
        left: interactions.x.value,
        top: interactions.y.value,
        child: Listener(
          // Bring to front on tap
          onPointerDown: (_) =>
              Get.find<WindowManager>().bringToFront('Padding'),
          child: GestureDetector(
            onPanUpdate: interactions.onPanUpdate,
            onPanEnd: (details) =>
                interactions.onPanEnd(details, MediaQuery.of(context).size),
            // The UI we will build in Phase 4
            child: const PaddingPanelVisual(),
          ),
        ),
      );
    });
  }
}
