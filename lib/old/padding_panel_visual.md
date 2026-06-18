import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:layout_engine/controllers/layout_controller.dart';
import 'package:layout_engine/controllers/base_window_interactions.dart';

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

  /// Task 4: The Color Cycler Logic
  void _cycleColor(String nodeId, LayoutController ctrl, int direction) {
    final node = ctrl
        .activeLayout; // Need deep search if nested, but assuming singleSelectedNode
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

  /// Handles single taps for selecting the outer padding sides
  void _handleSingleTap(Offset localPosition, Size size) {
    final double dx = localPosition.dx - (size.width / 2);
    final double dy = localPosition.dy - (size.height / 2);

    // If the user clicked the center square, completely ignore the single tap!
    if (dx.abs() < 25 && dy.abs() < 25) return;

    // Check Quadrants (Trapezoids)
    String clickedSide;
    if (dx.abs() > dy.abs()) {
      clickedSide = dx > 0 ? 'right' : 'left';
    } else {
      clickedSide = dy > 0 ? 'bottom' : 'top';
    }

    // Apply Global/Exclusive Selection Logic
    setState(() {
      // 🚀 THE FIX: Clone the set to force a memory reference change for the CustomPainter!
      Set<String> nextSides = Set<String>.from(activeSides);

      if (isGlobal) {
        if (nextSides.contains(clickedSide)) {
          nextSides.remove(clickedSide);
        } else {
          nextSides.add(clickedSide);
        }
      } else {
        // Exclusive Mode (Global OFF)
        nextSides.clear();
        nextSides.add(clickedSide);
      }

      // Overwrite the old variable with the brand new memory reference
      activeSides = nextSides;
    });
  }

  /// Handles double taps strictly for toggling Manual Mode in the center
  void _handleDoubleTap(Offset localPosition, Size size) {
    final double dx = localPosition.dx - (size.width / 2);
    final double dy = localPosition.dy - (size.height / 2);

    // 🚀 NEW: Only trigger if the double tap was inside the center square
    // Increased the hitbox to 30 so it's very easy to double-click!
    if (dx.abs() < 30 && dy.abs() < 30) {
      setState(() {
        isManualMode = !isManualMode;
        if (isManualMode && activeSides.isEmpty) {
          activeSides = {
            'left',
            'right',
            'top',
            'bottom',
          }; // Select all for manual
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

        // Task 2: Calculate Dynamic Max for Standard Mode
        double standardSliderValue = 0.0;
        int activeCount = activeSides.length;
        double maxSliderValue = 100.0;

        if (!isManualMode) {
          if (activeCount > 0) {
            maxSliderValue = 100.0 / activeCount;
            // Get average or highest of currently active sides to set the slider thumb
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

        // Fetch UI Scale
        final scale = Get.find<BaseWindowInteractions>(
          tag: 'Padding',
        ).windowScale;

        return Card(
          elevation: 8,
          color: const Color.fromARGB(255, 247, 244, 255),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16 * scale),
          ),
          child: Container(
            padding: EdgeInsets.all(12 * scale),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ==========================================
                // TASK 1: The Interactive Square UI
                // ==========================================
                GestureDetector(
                  // 🚀 NEW: Bind the two separate gesture events
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

                // ==========================================
                // TASK 2: The Slider Engine
                // ==========================================
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Toolbar Row (Global Toggle & Color)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Task 4: The Color Cycler
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

                        // Task 3: Global Toggle
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

                    // 🚀 FIXED: The Rigid Slider Container
                    // This forces the height to permanently accommodate 4 sliders,
                    // preventing the window from physically "jumping" or resizing!
                    SizedBox(
                      height: 96 * scale, // Exactly 4 sliders * 24 height
                      child: !isManualMode
                          // STANDARD MODE (Single Slider Centered)
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
                          // MANUAL MODE (4 Stacked Sliders)
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                _buildManualSlider(
                                  'left',
                                  'L',
                                  padding,
                                  node.id,
                                  layoutCtrl,
                                  scale,
                                ),
                                _buildManualSlider(
                                  'right',
                                  'R',
                                  padding,
                                  node.id,
                                  layoutCtrl,
                                  scale,
                                ),
                                _buildManualSlider(
                                  'top',
                                  'U',
                                  padding,
                                  node.id,
                                  layoutCtrl,
                                  scale,
                                ),
                                _buildManualSlider(
                                  'bottom',
                                  'D',
                                  padding,
                                  node.id,
                                  layoutCtrl,
                                  scale,
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

  /// Helper to build the stacked manual sliders with their clamped maximums
  Widget _buildManualSlider(
    String side,
    String label,
    Map<String, dynamic> padding,
    String nodeId,
    LayoutController layoutCtrl,
    double scale,
  ) {
    double currentVal = (padding[side] as num?)?.toDouble() ?? 0.0;
    double maxVal = 100.0;

    // Mathematically clamp sliders against their opposite sides
    if (side == 'left')
      maxVal = 100.0 - ((padding['right'] as num?)?.toDouble() ?? 0.0);
    if (side == 'right')
      maxVal = 100.0 - ((padding['left'] as num?)?.toDouble() ?? 0.0);
    if (side == 'top')
      maxVal = 100.0 - ((padding['bottom'] as num?)?.toDouble() ?? 0.0);
    if (side == 'bottom')
      maxVal = 100.0 - ((padding['top'] as num?)?.toDouble() ?? 0.0);

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

// ==========================================================
// TASK 1: The Interactive Square Painter (Place at bottom of file)
// ==========================================================
class InteractiveSquarePainter extends CustomPainter {
  final Set<String> activeSides;
  final bool isManualMode;
  final Color centerColor;

  InteractiveSquarePainter({
    required this.activeSides,
    required this.isManualMode,
    required this.centerColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paintStroke = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeJoin = StrokeJoin.miter;

    final paintActive = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.fill;

    // Inner Square Bounds
    final double innerW = size.width * 0.45;
    final double innerH = size.height * 0.45;
    final Rect innerRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: innerW,
      height: innerH,
    );

    // Outer Square Bounds
    final Rect outerRect = Rect.fromLTWH(0, 0, size.width, size.height);

    // Coordinate Points for the Trapezoids
    final Offset tlO = outerRect.topLeft;
    final Offset trO = outerRect.topRight;
    final Offset blO = outerRect.bottomLeft;
    final Offset brO = outerRect.bottomRight;

    final Offset tlI = innerRect.topLeft;
    final Offset trI = innerRect.topRight;
    final Offset blI = innerRect.bottomLeft;
    final Offset brI = innerRect.bottomRight;

    // Helper to draw filled trapezoids if active
    void drawTrapezoid(
      Offset p1,
      Offset p2,
      Offset p3,
      Offset p4,
      String side,
    ) {
      if (activeSides.contains(side) && !isManualMode) {
        final path = Path()
          ..moveTo(p1.dx, p1.dy)
          ..lineTo(p2.dx, p2.dy)
          ..lineTo(p3.dx, p3.dy)
          ..lineTo(p4.dx, p4.dy)
          ..close();
        canvas.drawPath(path, paintActive);
      }
    }

    // Draw active fills FIRST so borders draw cleanly on top
    drawTrapezoid(tlO, trO, trI, tlI, 'top');
    drawTrapezoid(blO, brO, brI, blI, 'bottom');
    drawTrapezoid(tlO, blO, blI, tlI, 'left');
    drawTrapezoid(trO, brO, brI, trI, 'right');

    // Draw the structural wireframe borders
    canvas.drawRect(outerRect, paintStroke);
    canvas.drawRect(innerRect, paintStroke);
    canvas.drawLine(tlO, tlI, paintStroke); // Top-Left diagonal
    canvas.drawLine(trO, trI, paintStroke); // Top-Right diagonal
    canvas.drawLine(blO, blI, paintStroke); // Bottom-Left diagonal
    canvas.drawLine(brO, brI, paintStroke); // Bottom-Right diagonal

    // Fill the center if Manual Mode is active
    // Fill the center if Manual Mode is active
    if (isManualMode) {
      final centerPaint = Paint()
        ..color = Colors.lightBlueAccent
        ..style = PaintingStyle.fill;
      canvas.drawRect(innerRect, centerPaint);
    }
    // 🚀 FIXED: Removed the else block!
    // Now, if isManualMode is false, the center remains completely transparent
    // and decoupled from the theme color.
  }

  @override
  bool shouldRepaint(covariant InteractiveSquarePainter oldDelegate) {
    return oldDelegate.activeSides != activeSides ||
        oldDelegate.isManualMode != isManualMode ||
        oldDelegate.centerColor != centerColor;
  }
}
