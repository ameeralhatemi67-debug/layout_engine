import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:layout_engine/views/overlays/layer_window_visual.dart';
import 'package:layout_engine/controllers/base_window_interactions.dart';
import '../../controllers/window_manager.dart';
import 'package:layout_engine/controllers/layout_controller.dart';

class LayerWindow extends StatelessWidget {
  const LayerWindow({super.key});

  @override
  Widget build(BuildContext context) {
    final interactions = Get.put(
      BaseWindowInteractions()..setupAsLayerWindow(),
      tag: 'Layer',
    );

    // 🚀 THE FIX!
    interactions.applyDefaultPosition('Layer', MediaQuery.of(context).size);

    return Obx(() {
      final layoutCtrl = Get.find<LayoutController>();

      if (!layoutCtrl.showLayerWindow.value) {
        return const SizedBox.shrink();
      }

      return Positioned(
        left: interactions.x.value,
        top: interactions.y.value,
        child: Listener(
          onPointerDown: (_) => Get.find<WindowManager>().bringToFront('Layer'),
          child: GestureDetector(
            onPanUpdate: interactions.onPanUpdate,
            onPanEnd: (details) =>
                interactions.onPanEnd(details, MediaQuery.of(context).size),
            child: const LayerWindowVisual(),
          ),
        ),
      );
    });
  }
}
