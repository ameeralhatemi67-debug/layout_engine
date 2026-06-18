import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/layout_controller.dart';
import '../components/drag_number_field.dart';

class SizeEditPanel extends StatelessWidget {
  const SizeEditPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<LayoutController>(
      builder: (controller) {
        // 1. Fetch the actively selected node safely
        final node = controller.singleSelectedNode;

        // 2. Hide the panel if no single node is selected,
        // OR if the user selected the Root Canvas (the root cannot be resized)
        if (node == null || node.id == controller.activeLayout.id) {
          return const SizedBox.shrink();
        }

        // 3. Extract the current flex value from the JSON properties
        final currentFlex = node.properties['flex_value'] as int? ?? 1000;

        return Card(
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            width: 500,
            padding: const EdgeInsets.symmetric(
              vertical: 12.0,
              horizontal: 16.0,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Size & Flex',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                const Divider(height: 1),
                const SizedBox(height: 12),

                // Task 3: Integrate DragNumberField (Mapped 0 to 1000)
                DragNumberField(
                  label: 'Flex Value',
                  value: currentFlex,
                  min: 0,
                  max: 1000,
                  defaultValue: 1000,
                  onChanged: (newValue) {
                    // Task 3: Pushing the drag slider directly to the MathEngine!
                    controller.updateFlexValue(node.id, newValue);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
