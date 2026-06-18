import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:layout_engine/controllers/layout_controller.dart';
import '../../../models/layout_node.dart';

class LayerWindowVisual extends StatelessWidget {
  const LayerWindowVisual({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<LayoutController>(
      builder: (controller) {
        return Card(
          elevation: 8,
          color: const Color.fromARGB(255, 247, 242, 250),
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

  Widget _buildTree(
    LayoutNode node,
    LayoutController controller,
    int depth,
    BuildContext context,
  ) {
    final isSelected = controller.selectedNodeIds.contains(node.id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 8.0),
          child: Row(
            children: [
              SizedBox(width: depth * 16.0),
              Checkbox(
                value: isSelected,
                activeColor: Colors.blueAccent,
                visualDensity: VisualDensity.compact,
                onChanged: (bool? value) => controller.selectNode(node.id),
              ),
              SvgPicture.asset(
                node.children.isNotEmpty
                    ? 'assets/icons/ParentLayer.svg'
                    : 'assets/icons/childLayer.svg',
                width: 16,
                height: 16,
                colorFilter: const ColorFilter.mode(
                  Color.fromARGB(255, 10, 10, 10),
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () => controller.exclusiveSelectNode(node.id),
                  onLongPress: () => _showRenameDialog(
                    context,
                    controller,
                    node.id,
                    node.properties['layer_name'] ?? node.type,
                  ),
                  child: Text(
                    node.properties['layer_name'] ?? node.type,
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected ? Colors.blueAccent : Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
        ...node.children.map(
          (child) => _buildTree(child, controller, depth + 1, context),
        ),
      ],
    );
  }

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
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
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
