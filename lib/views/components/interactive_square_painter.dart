import 'package:flutter/material.dart';

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
    if (isManualMode) {
      final centerPaint = Paint()
        ..color = Colors.lightBlueAccent
        ..style = PaintingStyle.fill;
      canvas.drawRect(innerRect, centerPaint);
    }
  }

  @override
  bool shouldRepaint(covariant InteractiveSquarePainter oldDelegate) {
    return oldDelegate.activeSides != activeSides ||
        oldDelegate.isManualMode != isManualMode ||
        oldDelegate.centerColor != centerColor;
  }
}
