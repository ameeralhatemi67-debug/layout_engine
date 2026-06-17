import 'package:flutter/material.dart';
import '../../controllers/layout_controller.dart';

class ManualPaddingSlider extends StatelessWidget {
  final String side;
  final String label;
  final Map<String, dynamic> padding;
  final String nodeId;
  final LayoutController layoutCtrl;
  final double scale;

  const ManualPaddingSlider({
    super.key,
    required this.side,
    required this.label,
    required this.padding,
    required this.nodeId,
    required this.layoutCtrl,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    double currentVal = (padding[side] as num?)?.toDouble() ?? 0.0;
    double maxVal = 100.0;

    // Mathematically clamp sliders against their opposite sides
    if (side == 'left') {
      maxVal = 100.0 - ((padding['right'] as num?)?.toDouble() ?? 0.0);
    }
    if (side == 'right') {
      maxVal = 100.0 - ((padding['left'] as num?)?.toDouble() ?? 0.0);
    }
    if (side == 'top') {
      maxVal = 100.0 - ((padding['bottom'] as num?)?.toDouble() ?? 0.0);
    }
    if (side == 'bottom') {
      maxVal = 100.0 - ((padding['top'] as num?)?.toDouble() ?? 0.0);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 140 * scale,
          height: 24 * scale, // Squish them closer together
          child: SliderTheme(
            data: SliderThemeData(
              trackHeight: 4 * scale,
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6 * scale),
              thumbColor: Colors.black87,
              activeTrackColor: Colors.black87,
              inactiveTrackColor: Colors.grey.shade300,
            ),
            child: Slider(
              value: currentVal.clamp(0.0, maxVal),
              min: 0,
              max: maxVal == 0 ? 1 : maxVal, // Prevent max=0 error
              onChanged: (val) {
                layoutCtrl.updatePaddingManual(nodeId, side, val.round());
              },
              onChangeEnd: (_) => layoutCtrl.saveState(), // Auto-Save
            ),
          ),
        ),
        SizedBox(
          width: 20 * scale,
          child: Text(
            label,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16 * scale),
          ),
        ),
      ],
    );
  }
}
