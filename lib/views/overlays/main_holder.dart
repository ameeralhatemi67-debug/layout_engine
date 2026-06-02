import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/layout_controller.dart';

class MainHolder extends StatelessWidget {
  const MainHolder({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<LayoutController>();

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: Row(
          mainAxisSize: MainAxisSize.min, // Shrinks the card to fit the buttons
          children: [
            // Undo Button (Listens reactively)
            Obx(
              () => IconButton(
                icon: const Icon(Icons.undo),
                color: controller.canUndo.value ? Colors.black : Colors.grey,
                onPressed: controller.canUndo.value ? controller.undo : null,
                tooltip: 'Undo',
              ),
            ),

            // Redo Button (Listens reactively)
            Obx(
              () => IconButton(
                icon: const Icon(Icons.redo),
                color: controller.canRedo.value ? Colors.black : Colors.grey,
                onPressed: controller.canRedo.value ? controller.redo : null,
                tooltip: 'Redo',
              ),
            ),

            const SizedBox(width: 8),
            Container(
              width: 1,
              height: 24,
              color: Colors.grey.shade300,
            ), // Divider
            const SizedBox(width: 8),

            // Copy Code Button
            // Copy Code Button
            IconButton(
              icon: const Icon(Icons.code),
              color: Colors.blueAccent,
              onPressed: () => controller.copyCodeToClipboard(), // Connected!
              tooltip: 'Copy Code',
            ),
          ],
        ),
      ),
    );
  }
}
