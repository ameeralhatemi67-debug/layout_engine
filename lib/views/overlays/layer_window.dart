import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/layout_controller.dart';
import '../../models/layout_node.dart';

class LayerWindow extends StatelessWidget {
  const LayerWindow({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<LayoutController>(
      builder: (controller) {
        return Card(
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            width: 220,
            constraints: const BoxConstraints(maxHeight: 400),
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 4.0,
                  ),
                  child: Text(
                    'Layer Matrix',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                const Divider(),
                Expanded(
                  child: SingleChildScrollView(
                    child: _buildTree(
                      controller.activeLayout,
                      controller,
                      0,
                      context,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Recursively builds the nested list based on tree depth
  Widget _buildTree(
    LayoutNode node,
    LayoutController controller,
    int depth,
    BuildContext context,
  ) {
    final isSelected = controller.selectedNodeId == node.id;
    final layerName = node.properties['layer_name'] ?? node.type;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => controller.selectNode(node.id),
          onDoubleTap: () =>
              _showRenameDialog(context, controller, node.id, layerName),
          child: Container(
            width: double.infinity,
            color: isSelected
                ? Colors.blue.withOpacity(0.15)
                : Colors.transparent,
            padding: EdgeInsets.only(
              left: 16.0 + (depth * 16.0), // Indent based on depth
              right: 16.0,
              top: 8.0,
              bottom: 8.0,
            ),
            child: Row(
              children: [
                Icon(
                  node.children.isNotEmpty
                      ? Icons.folder_open
                      : Icons.insert_drive_file,
                  size: 16,
                  color: isSelected ? Colors.blue : Colors.grey.shade600,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    layerName,
                    style: TextStyle(
                      fontSize: 13,
                      color: isSelected ? Colors.blue.shade700 : Colors.black87,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Recursively render children
        ...node.children.map(
          (child) => _buildTree(child, controller, depth + 1, context),
        ),
      ],
    );
  }

  /// Dialog to handle the custom naming logic
  void _showRenameDialog(
    BuildContext context,
    LayoutController controller,
    String id,
    String currentName,
  ) {
    final textController = TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Layer', style: TextStyle(fontSize: 16)),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(hintText: 'Enter new name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(context), // Changed from onTap to onPressed
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Changed from onTap to onPressed
              if (textController.text.trim().isNotEmpty) {
                controller.updateLayerName(id, textController.text.trim());
              }
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
