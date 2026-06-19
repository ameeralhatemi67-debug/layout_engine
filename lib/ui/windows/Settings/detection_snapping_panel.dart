import 'package:flutter/material.dart';
// Keep your existing math manager!

class DetectionSnappingPanel extends StatelessWidget {
  final double draftDetect;
  final Map<String, Map<String, double>> draftMatrix;
  final Function(double) onDetectChanged;
  final Function(String, String, double) onMatrixChanged;

  const DetectionSnappingPanel({
    super.key,
    required this.draftDetect,
    required this.draftMatrix,
    required this.onDetectChanged,
    required this.onMatrixChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Detection Distance Input Block
          Row(
            children: [
              // 🚀 FIX 2: Pushed inwards to align nicely with the table text
              const SizedBox(width: 30),
              const Text(
                'Detection Distance',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold, // Made bold to match Figma
                ),
              ),
              const SizedBox(width: 24), // Gap between text and input
              // 🚀 FIX 2: Forced wider box, aligned to the left side
              SizedBox(
                width: 60,
                child: _buildDragField(
                  value: draftDetect,
                  maxClamp: 50.0,
                  onChanged: onDetectChanged,
                  onReset: () => onDetectChanged(50.0),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          const Row(
            children: [
              SizedBox(width: 30),
              Text(
                'Snapping Distance',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildMatrixTable(),
          const SizedBox(height: 20),

          // Twin Dual Side-by-Side Canvas Previews
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildMiniPreviewCanvas(showGlobalZones: false),

              // to make them as close or far apart as you want!
              const SizedBox(width: 24),

              _buildMiniPreviewCanvas(showGlobalZones: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMatrixTable() {
    return Column(
      children: [
        // Matrix Column Label Row
        Row(
          children: [
            const SizedBox(width: 30),
            _buildHeaderLabel('ED'),
            _buildHeaderLabel('LW'),
            _buildHeaderLabel('LP'),
            const SizedBox(width: 30),
          ],
        ),
        const SizedBox(height: 6),
        // Generate rows for coordinates L, R, U, D
        ...['L', 'R', 'U', 'D'].map((edge) => _buildMatrixRow(edge)),
      ],
    );
  }

  Widget _buildMatrixRow(String edge) {
    // 🚀 Task 2.2: Apply your specific visual min/max constraints!
    double axisMax = (edge == 'L' || edge == 'R') ? 800.0 : 400.0;
    double lwMin = (edge == 'L' || edge == 'R') ? 5.0 : 3.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text(
              edge,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: _buildDragField(
              value: draftMatrix[edge]!['ED']!,
              minClamp: 0.0,
              maxClamp:
                  25.0, // ED remains strictly 25 as it is a localized padding limit
              onChanged: (v) => onMatrixChanged(edge, 'ED', v),
              onReset: () => onMatrixChanged(edge, 'ED', 12.0),
            ),
          ),
          Expanded(
            child: _buildDragField(
              value: draftMatrix[edge]!['LW']!,
              minClamp: lwMin,
              maxClamp: axisMax, // 🚀 Now uses the massive 800/400 limit
              onChanged: (v) => onMatrixChanged(edge, 'LW', v),
              onReset: () => onMatrixChanged(
                edge,
                'LW',
                (edge == 'L' || edge == 'R') ? 300.0 : 200.0,
              ),
            ),
          ),
          Expanded(
            child: _buildDragField(
              value: draftMatrix[edge]!['LP']!,
              minClamp: 0.0,
              maxClamp: axisMax, // 🚀 Now uses the massive 800/400 limit
              onChanged: (v) => onMatrixChanged(edge, 'LP', v),
              onReset: () => onMatrixChanged(edge, 'LP', 15.0),
            ),
          ),
          SizedBox(
            width: 30,
            child: Center(
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _getEdgeColor(edge),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderLabel(String text) {
    // 1. Map the acronyms to their full hover names
    String fullName = '';
    switch (text) {
      case 'ED':
        fullName = 'Edge Distance';
        break;
      case 'LW':
        fullName = 'Line Width';
        break;
      case 'LP':
        fullName = 'Line Position';
        break;
      default:
        fullName = text;
    }

    return Expanded(
      child: Center(
        // 2. The Native Tooltip Wrapper
        child: Tooltip(
          message: fullName,
          // triggerMode.tap ensures mobile users can tap to see it!
          triggerMode: TooltipTriggerMode.tap,
          showDuration: const Duration(
            seconds: 2,
          ), // Auto-hides after clicking away
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
          margin: const EdgeInsets.only(
            bottom: 8.0,
          ), // Floats slightly above the text
          // 3. The Custom Dark Rounded Styling
          decoration: BoxDecoration(
            color: const Color(0xFF2C2C2C), // Sleek dark grey background
            borderRadius: BorderRadius.circular(6.0), // Rounded edges
            boxShadow: const [
              BoxShadow(
                color: Colors.black45,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          textStyle: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),

          // The actual visible ED/LW/LP text
          child: Text(
            text,
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  // 🚀 Task 2.2: Reusable Drag Field with Strict Limits
  // 🚀 Task 2.2: Reusable Drag Field with Strict Limits & Dynamic Speed
  Widget _buildDragField({
    required double value,
    required Function(double) onChanged,
    required VoidCallback onReset,
    double minClamp = 0.0,
    required double maxClamp,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanUpdate: (details) {
        // 🚀 Dynamic Speed Math:
        // If maxClamp is 800, drag speed is 2.5x normal. If 25, speed is 0.5x normal!
        double speedMultiplier = maxClamp > 100 ? 2.5 : 0.5;

        double newVal = (value + (details.delta.dx * speedMultiplier)).clamp(
          minClamp,
          maxClamp,
        );
        onChanged(newVal);
      },
      onDoubleTap: onReset, // Double tap reset logic
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(
          vertical: 4,
        ), // Slimmer to match Figma
        decoration: BoxDecoration(
          color: const Color(
            0xFFE0E0E0,
          ), // White/Light Grey box from your mockup
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          value.round().toString(),
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  // ===========================================================================
  // 🚀 Task 3.1 & 3.2: The Mini-Map Visualizers
  // ===========================================================================
  Widget _buildMiniPreviewCanvas({required bool showGlobalZones}) {
    // Virtual screen size assumptions for scaling (mimicking a standard phone)
    const double virtualW = 400.0;
    const double virtualH = 800.0;
    const double canvasW = 145.0;
    const double canvasH = 230.0;

    // Scale factors to shrink your massive global variables down to the mini map
    const double scaleX = canvasW / virtualW;
    const double scaleY = canvasH / virtualH;

    return Container(
      width: canvasW,
      height: canvasH,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5), // Light background
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey.shade300, width: 1),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      // 🚀 THE TRUNCATION FIX (Task 3.2):
      // Clip.hardEdge ensures anything pushed outside the canvas by LP offset is visually "eaten"
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          // 🚀 THE DETECTION ZONE (Right Panel Only):
          // Renders the Figma-style diagonal striped border tied directly to `draftDetect`
          if (showGlobalZones)
            Positioned.fill(
              child: CustomPaint(
                painter: StripeBorderPainter(
                  thickness: draftDetect * scaleX * 1.5,
                  stripeColor: const Color(0xFF29B6F6),
                ),
              ),
            ),

          // 🚀 FIX 3: SEPARATED VISUALS
          // The colored lines will NOW ONLY render on the Left Panel (Snapping Guides)!
          if (!showGlobalZones) ...[
            _buildScaledLine('L', scaleX, scaleY),
            _buildScaledLine('R', scaleX, scaleY),
            _buildScaledLine('U', scaleX, scaleY),
            _buildScaledLine('D', scaleX, scaleY),
          ],
        ],
      ),
    );
  }

  // 🚀 Extracted Line Generator: Calculates exactly where the lines sit
  Widget _buildScaledLine(String edge, double scaleX, double scaleY) {
    final double ed = draftMatrix[edge]!['ED']!;
    final double lw = draftMatrix[edge]!['LW']!;
    final double lp = draftMatrix[edge]!['LP']!;

    // Boost ED visually so it doesn't completely merge with the wall when scaled down
    final double visualED = (ed * scaleX) + 2.0;

    // 🚀 Task 3.1: Mathematical Boundary Clamping!
    bool isHorizontalLine = (edge == 'U' || edge == 'D');
    double scale = isHorizontalLine ? scaleX : scaleY;

    // The exact dimensions of your mini-map canvas (Width: 145, Height: 230)
    double maxDimension = isHorizontalLine ? 145.0 : 230.0;

    final double rawLP = lp * scale;
    final double rawLW = lw * scale;

    // Clamping Math: If LP + LW exceeds the canvas, we shrink the LW so it perfectly
    // fits inside the box. This preserves the rounded corners at the edges!
    double clampedLP = rawLP;
    double clampedLW = rawLW;

    if (clampedLP + clampedLW > maxDimension) {
      clampedLW = maxDimension - clampedLP;
    }

    // Safety check: if the user pushes the line completely off screen
    if (clampedLW < 0) clampedLW = 0;

    final Color color = _getEdgeColor(edge);
    const double lineThickness = 3.0;

    // Exact mathematical truncation scaling
    final double scaledLW = lw * (edge == 'U' || edge == 'D' ? scaleX : scaleY);
    final double scaledLP = lp * (edge == 'U' || edge == 'D' ? scaleX : scaleY);

    // We use Positioned to natively inherit Flutter's edge clipping!
    if (edge == 'L') {
      return Positioned(
        left: visualED,
        top: scaledLP,
        width: lineThickness,
        height: scaledLW,
        // FIX: Moved `color: color` inside BoxDecoration
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } else if (edge == 'R') {
      return Positioned(
        right: visualED,
        top: scaledLP,
        width: lineThickness,
        height: scaledLW,
        // FIX: Moved `color: color` inside BoxDecoration
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } else if (edge == 'U') {
      return Positioned(
        top: visualED,
        left: scaledLP,
        height: lineThickness,
        width: scaledLW,
        // FIX: Moved `color: color` inside BoxDecoration
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } else {
      // 'D'
      return Positioned(
        bottom: visualED,
        left: scaledLP,
        height: lineThickness,
        width: scaledLW,
        // FIX: Moved `color: color` inside BoxDecoration
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  Color _getEdgeColor(String edge) {
    switch (edge) {
      case 'L':
        return const Color(0xFFFFD54F);
      case 'R':
        return const Color(0xFFE57373);
      case 'U':
        return const Color(0xFF7986CB);
      case 'D':
        return const Color(0xFF81C784);
      default:
        return Colors.white;
    }
  }
}

// ===========================================================================
// 🚀 Task 3.2: Custom Stripe Painter for the Detection Border
// ===========================================================================
class StripeBorderPainter extends CustomPainter {
  final double thickness;
  final Color stripeColor;

  StripeBorderPainter({required this.thickness, required this.stripeColor});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Setup the paint brush for the diagonal lines
    final paint = Paint()
      ..color = stripeColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    // 2. Mathematically plot diagonal lines across the entire canvas
    final path = Path();
    const double spacing = 12.0; // The gap between the stripes

    for (double i = -size.height; i < size.width + size.height; i += spacing) {
      path.moveTo(i, 0);
      path.lineTo(i - size.height, size.height);
    }

    // 3. Define the border zone (Outer Rect minus Inner Rect)
    final outerRect = Offset.zero & size;
    final innerRect = Rect.fromLTWH(
      thickness,
      thickness,
      size.width - thickness * 2,
      size.height - thickness * 2,
    );

    // 4. Create a "donut hole" path
    final borderPath = Path.combine(
      PathOperation.difference,
      Path()..addRect(outerRect),
      Path()..addRect(innerRect),
    );

    // 5. Clip the canvas so it ONLY draws inside the border thickness!
    canvas.clipPath(borderPath);

    // Fill the background of the border slightly
    canvas.drawRect(outerRect, Paint()..color = stripeColor.withOpacity(0.15));

    // Draw the actual stripes
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant StripeBorderPainter oldDelegate) {
    return oldDelegate.thickness !=
        thickness; // Only redraw if detection distance changes
  }
}
