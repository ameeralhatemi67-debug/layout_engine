import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/layout_controller.dart';

class CreateHolder extends StatelessWidget {
  const CreateHolder({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<LayoutController>();

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Create Layout',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildActionBtn(
                  icon: Icons.view_column,
                  label: '3 Cols',
                  onTap: () => controller.attemptSplit(3, 'RowNode'),
                ),
                const SizedBox(width: 8),
                _buildActionBtn(
                  icon: Icons.table_rows,
                  label: '3 Rows',
                  onTap: () => controller.attemptSplit(3, 'ColumnNode'),
                ),
                const SizedBox(width: 8),
                _buildActionBtn(
                  icon: Icons.grid_view,
                  label: '4 Cols',
                  onTap: () => controller.attemptSplit(4, 'RowNode'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionBtn({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: Colors.black87),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
