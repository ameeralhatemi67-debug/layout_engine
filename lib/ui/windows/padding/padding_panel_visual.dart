import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:layout_engine/controllers/layout_controller.dart';
import 'package:layout_engine/controllers/base_window_interactions.dart';
import 'package:layout_engine/views/components/interactive_square_painter.dart';
import 'package:layout_engine/views/components/manual_padding_slider.dart';

class PaddingPanelVisual extends StatefulWidget {
  const PaddingPanelVisual({super.key});

  @override
  State<PaddingPanelVisual> createState() => _PaddingPanelVisualState();
}

class _PaddingPanelVisualState extends State<PaddingPanelVisual> {
  // Local UI State
  Set<String> activeSides = {'left'};
  bool isGlobal = true;
  bool isManualMode = false;

  final List<String> themeColors = [
    'light_orange',
    'light_yellow',
    'light_red',
    'light_green',
    'light_purple',
  ];

  void _cycleColor(String nodeId, LayoutController ctrl, int direction) {
    final activeNode = ctrl.singleSelectedNode;
    if (activeNode == null) return;

    String currentColor =
        activeNode.properties['padding_color'] ?? 'light_orange';
    int idx = themeColors.indexOf(currentColor);
    if (idx == -1) idx = 0;

    int newIdx = (idx + direction) % themeColors.length;
    if (newIdx < 0) newIdx = themeColors.length - 1;

    ctrl.updatePaddingColor(activeNode.id, themeColors[newIdx]);
  }

  Color _getColorFromName(String name) {
    switch (name) {
      case 'light_yellow':
        return Colors.yellowAccent.shade700;
      case 'light_red':
        return Colors.redAccent;
      case 'light_green':
        return Colors.greenAccent.shade700;
      case 'light_purple':
        return Colors.purpleAccent;
      case 'light_orange':
      default:
        return Colors.orangeAccent;
    }
  }

  void _handleSingleTap(Offset localPosition, Size size) {
    final double dx = localPosition.dx - (size.width / 2);
    final double dy = localPosition.dy - (size.height / 2);

    if (dx.abs() < 25 && dy.abs() < 25) return;

    String clickedSide;
    if (dx.abs() > dy.abs()) {
      clickedSide = dx > 0 ? 'right' : 'left';
    } else {
      clickedSide = dy > 0 ? 'bottom' : 'top';
    }

    setState(() {
      Set<String> nextSides = Set<String>.from(activeSides);
      if (isGlobal) {
        if (nextSides.contains(clickedSide))
          nextSides.remove(clickedSide);
        else
          nextSides.add(clickedSide);
      } else {
        nextSides.clear();
        nextSides.add(clickedSide);
      }
      activeSides = nextSides;
    });
  }

  void _handleDoubleTap(Offset localPosition, Size size) {
    final double dx = localPosition.dx - (size.width / 2);
    final double dy = localPosition.dy - (size.height / 2);

    if (dx.abs() < 30 && dy.abs() < 30) {
      setState(() {
        isManualMode = !isManualMode;
        if (isManualMode && activeSides.isEmpty) {
          activeSides = {'left', 'right', 'top', 'bottom'};
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<LayoutController>(
      builder: (layoutCtrl) {
        final node = layoutCtrl.singleSelectedNode;
        if (node == null) return const SizedBox.shrink();

        final padding =
            node.properties['padding'] as Map<String, dynamic>? ?? {};
        final currentColor =
            node.properties['padding_color'] as String? ?? 'light_orange';

        double standardSliderValue = 0.0;
        int activeCount = activeSides.length;
        double maxSliderValue = 100.0;

        if (!isManualMode) {
          if (activeCount > 0) {
            maxSliderValue = 100.0 / activeCount;
            double sum = 0;
            for (String side in activeSides) {
              sum += (padding[side] as num?)?.toDouble() ?? 0.0;
            }
            standardSliderValue = (sum / activeCount).clamp(
              0.0,
              maxSliderValue,
            );
          }
        }

        final scale = Get.find<BaseWindowInteractions>(
          tag: 'Padding',
        ).windowScale;

        return Card(
          elevation: 8,
          color: const Color.fromARGB(255, 247, 242, 250),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12 * scale),
          ),
          child: Container(
            padding: EdgeInsets.all(12 * scale),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTapUp: (details) => _handleSingleTap(
                    details.localPosition,
                    Size(80 * scale, 80 * scale),
                  ),
                  onDoubleTapDown: (details) => _handleDoubleTap(
                    details.localPosition,
                    Size(80 * scale, 80 * scale),
                  ),
                  child: CustomPaint(
                    size: Size(80 * scale, 80 * scale),
                    painter: InteractiveSquarePainter(
                      activeSides: activeSides,
                      isManualMode: isManualMode,
                      centerColor: _getColorFromName(currentColor),
                    ),
                  ),
                ),
                SizedBox(width: 16 * scale),

                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () => _cycleColor(node.id, layoutCtrl, 1),
                          onDoubleTap: () =>
                              _cycleColor(node.id, layoutCtrl, -1),
                          onLongPress: () => Get.snackbar(
                            'Color Palette',
                            'Coming soon!',
                            snackPosition: SnackPosition.BOTTOM,
                          ),
                          child: Container(
                            width: 24 * scale,
                            height: 24 * scale,
                            decoration: BoxDecoration(
                              color: _getColorFromName(currentColor),
                              borderRadius: BorderRadius.circular(4 * scale),
                              border: Border.all(
                                color: Colors.black87,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12 * scale),
                        GestureDetector(
                          onTap: () => setState(() => isGlobal = !isGlobal),
                          child: SvgPicture.asset(
                            'assets/icons/global.svg',
                            width: 28 * scale,
                            height: 28 * scale,
                            colorFilter: ColorFilter.mode(
                              isGlobal ? Colors.black87 : Colors.grey.shade400,
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8 * scale),

                    SizedBox(
                      height: 96 * scale,
                      child: !isManualMode
                          ? Align(
                              alignment: Alignment.centerRight,
                              child: SizedBox(
                                width: 160 * scale,
                                child: SliderTheme(
                                  data: SliderThemeData(
                                    trackHeight: 6 * scale,
                                    thumbColor: Colors.black87,
                                    activeTrackColor: Colors.black87,
                                    inactiveTrackColor: Colors.grey.shade300,
                                  ),
                                  child: Slider(
                                    value: standardSliderValue,
                                    min: 0,
                                    max: maxSliderValue,
                                    onChanged: activeSides.isEmpty
                                        ? null
                                        : (val) {
                                            layoutCtrl.updatePaddingGlobal(
                                              node.id,
                                              activeSides.toList(),
                                              val.round(),
                                            );
                                          },
                                    onChangeEnd: (_) => layoutCtrl.saveState(),
                                  ),
                                ),
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                ManualPaddingSlider(
                                  side: 'left',
                                  label: 'L',
                                  padding: padding,
                                  nodeId: node.id,
                                  layoutCtrl: layoutCtrl,
                                  scale: scale,
                                ),
                                ManualPaddingSlider(
                                  side: 'right',
                                  label: 'R',
                                  padding: padding,
                                  nodeId: node.id,
                                  layoutCtrl: layoutCtrl,
                                  scale: scale,
                                ),
                                ManualPaddingSlider(
                                  side: 'top',
                                  label: 'U',
                                  padding: padding,
                                  nodeId: node.id,
                                  layoutCtrl: layoutCtrl,
                                  scale: scale,
                                ),
                                ManualPaddingSlider(
                                  side: 'bottom',
                                  label: 'D',
                                  padding: padding,
                                  nodeId: node.id,
                                  layoutCtrl: layoutCtrl,
                                  scale: scale,
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
