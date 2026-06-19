import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:layout_engine/logic/base_window_interactions.dart';
import 'package:layout_engine/logic/window_manager.dart';
import 'package:layout_engine/ui/windows/create/create_holder_visual.dart';
import 'package:layout_engine/logic/layout_controller.dart';

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
      final layoutCtrl = Get.find<LayoutController>();

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
            // 🚀 The fully mapped Dumb Child
            child: CreateHolderVisual(
              isHorizontal: interactions.isHorizontal.value,
              isOpen: interactions.isOpen.value,
              lastUsedSplitType: layoutCtrl.lastUsedSplitType.value,
              onToggleOpen: () =>
                  interactions.toggleOpen(MediaQuery.of(context).size),
              onSplitOrSwitch: (type, count) {
                final logic = Get.find<BaseWindowInteractions>(tag: 'Split');
                if (logic.isOpen.value) {
                  logic.isOpen.value = false; // Close if already open
                } else {
                  // Execute using the memory tracker!
                  logic.openSplitWindow(MediaQuery.of(context).size);
                  Get.find<WindowManager>().bringToFront('Split');
                }
              },
              onTogglePadding: () {
                // Moved from the visual file!
                final logic = Get.find<BaseWindowInteractions>(tag: 'Padding');
                logic.isOpen.value = !logic.isOpen.value;
                Get.find<WindowManager>().bringToFront('Padding');
              },
            ),
          ),
        ),
      );
    });
  }
}
