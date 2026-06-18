import 'package:flutter/material.dart';

class DragNumberField extends StatefulWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;
  final int? defaultValue;

  const DragNumberField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 1000,
    this.defaultValue,
  });

  @override
  State<DragNumberField> createState() => _DragNumberFieldState();
}

class _DragNumberFieldState extends State<DragNumberField> {
  late int _currentValue;
  double _dragAccumulator = 0.0;
  final double _sensitivity =
      4.0; // Requires a solid drag to jump whole numbers

  @override
  void initState() {
    super.initState();
    _currentValue = widget.value;
  }

  @override
  void didUpdateWidget(covariant DragNumberField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _currentValue = widget.value;
    }
  }

  void _resetToDefault() {
    int resetTarget = widget.defaultValue ?? widget.min;
    if (_currentValue != resetTarget) {
      setState(() => _currentValue = resetTarget);
      widget.onChanged(_currentValue);
    }
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    _dragAccumulator += details.delta.dx;

    if (_dragAccumulator.abs() >= _sensitivity) {
      int step = (_dragAccumulator / _sensitivity).truncate();
      int newValue = _currentValue + step;

      if (newValue > widget.max) newValue = widget.max;
      if (newValue < widget.min) newValue = widget.min;

      if (newValue != _currentValue) {
        setState(() => _currentValue = newValue);
        widget.onChanged(_currentValue);
        _dragAccumulator = _dragAccumulator.remainder(_sensitivity);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasLabel = widget.label.isNotEmpty;

    return MouseRegion(
      cursor: SystemMouseCursors.resizeLeftRight,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (_) => _dragAccumulator = 0.0,
        onPanUpdate: _handlePanUpdate,
        onDoubleTap: _resetToDefault,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: hasLabel ? 12 : 6,
            vertical: hasLabel ? 8 : 4,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.transparent, width: 1.0),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasLabel) ...[
                Text(
                  '${widget.label}:',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                '$_currentValue',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
