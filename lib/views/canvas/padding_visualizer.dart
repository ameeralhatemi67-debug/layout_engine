import 'package:flutter/material.dart';

class PaddingHachurePainter extends CustomPainter {
  final double top;
  final double bottom;
  final double left;
  final double right;
  final String colorName;

  PaddingHachurePainter({
    required this.top,
    required this.bottom,
    required this.left,
    required this.right,
    required this.colorName,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // If there is no padding, do not paint anything
    if (top == 0 && bottom == 0 && left == 0 && right == 0) return;

    // 1. Convert percentages (0-100) to actual physical pixels
    final pxTop = size.height * (top / 100);
    final pxBottom = size.height * (bottom / 100);
    final pxLeft = size.width * (left / 100);
    final pxRight = size.width * (right / 100);

    // 2. Decode the dynamic padding color
    Color baseColor;
    switch (colorName) {
      case 'light_yellow':
        baseColor = Colors.yellowAccent.shade700;
        break;
      case 'light_red':
        baseColor = Colors.redAccent;
        break;
      case 'light_green':
        baseColor = Colors.greenAccent.shade700;
        break;
      case 'light_purple':
        baseColor = Colors.purpleAccent;
        break;
      case 'light_orange':
      default:
        baseColor = Colors.orangeAccent;
        break;
    }

    final hachureColor = baseColor.withOpacity(0.6);

    // 3. Define the physical boundaries
    final outerRect = Rect.fromLTWH(0, 0, size.width, size.height);

    // The inner content area (Safe Area)
    final innerRect = Rect.fromLTRB(
      pxLeft,
      pxTop,
      size.width - pxRight,
      size.height - pxBottom,
    );

    // 4. Create the Padding Mask (Outer Rect MINUS Inner Rect)
    final paddingPath = Path.combine(
      PathOperation.difference,
      Path()..addRect(outerRect),
      Path()..addRect(innerRect),
    );

    canvas.save();

    // 5. CLIP the canvas! Everything drawn after this will ONLY appear in the padding margins.
    canvas.clipPath(paddingPath);

    // Draw the 45-degree Hachure lines
    final stripePaint = Paint()
      ..color = hachureColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    const double spacing = 12.0;

    // Draw diagonal lines starting well outside the bounds to cover the entire canvas
    for (double i = -size.height; i < size.width; i += spacing) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        stripePaint,
      );
    }

    canvas.restore(); // Remove the clip

    // 6. Draw the "Safe Area" inner block (from your Checkpoint 11 Roadmap)
    final safeAreaPaint = Paint()
      ..color = Colors.lightBlueAccent.withOpacity(0.15)
      ..style = PaintingStyle.fill;
    canvas.drawRect(innerRect, safeAreaPaint);

    final safeAreaBorderPaint = Paint()
      ..color = Colors.lightBlueAccent.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRect(innerRect, safeAreaBorderPaint);
  }

  @override
  bool shouldRepaint(covariant PaddingHachurePainter oldDelegate) {
    return oldDelegate.top != top ||
        oldDelegate.bottom != bottom ||
        oldDelegate.left != left ||
        oldDelegate.right != right ||
        oldDelegate.colorName != colorName;
  }
}
