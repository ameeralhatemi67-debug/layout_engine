import 'package:flutter/material.dart';

class PercentageDragField extends StatefulWidget {
  final int rawFlexValue;
  final ValueChanged<int> onChanged;
  final int max;

  const PercentageDragField({
    super.key,
    required this.rawFlexValue,
    required this.onChanged,
    this.max = 1000,
  });

  @override
  State<PercentageDragField> createState() => _PercentageDragFieldState();
}

class _PercentageDragFieldState extends State<PercentageDragField> {
  late int _currentFlex;
  double _dragAccumulator = 0.0;

  @override
  void initState() {
    super.initState();
    _currentFlex = widget.rawFlexValue;
  }

  @override
  void didUpdateWidget(covariant PercentageDragField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rawFlexValue != widget.rawFlexValue) {
      _currentFlex = widget.rawFlexValue;
    }
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    double speed = details.delta.dx.abs();
    _dragAccumulator += details.delta.dx;

    // --- THE VIRTUAL GEARBOX ---
    int flexStep = 10; // Medium Gear: Changes by 1% (10 units)
    double requiredPhysicalDrag = 2.0;

    if (speed < 1.0) {
      // Slow Gear: Micro-adjustments. Changes by 0.1% (1 unit).
      // Requires a longer physical drag to prevent accidental slips.
      flexStep = 1;
      requiredPhysicalDrag = 4.0;
    } else if (speed > 8.0) {
      // Fast Gear: Macro-adjustments. Changes by 5% (50 units).
      flexStep = 50;
      requiredPhysicalDrag = 1.0;
    }

    if (_dragAccumulator.abs() >= requiredPhysicalDrag) {
      int direction = _dragAccumulator.sign.toInt();
      int newValue = _currentFlex + (flexStep * direction);

      if (newValue > widget.max) newValue = widget.max;
      if (newValue < 50) newValue = 50; // 5% absolute minimum

      if (newValue != _currentFlex) {
        setState(() {
          _currentFlex = newValue;
        });
        widget.onChanged(_currentFlex);
        _dragAccumulator = 0.0; // Reset accumulator after a clean step
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeLeftRight,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (_) => _dragAccumulator = 0.0,
        onPanUpdate: _handlePanUpdate,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: const BoxDecoration(
            color: Colors.transparent,
            border: Border(
              bottom: BorderSide(color: Colors.transparent, width: 1.5),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${(_currentFlex / 10).round()}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black87,
                  fontFamily: 'Courier',
                ),
              ),
              const Text(
                '%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
