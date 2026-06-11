import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PercentageDragField extends StatefulWidget {
  final int rawFlexValue; // The 1000-scale value (e.g., 333)
  final ValueChanged<int> onChanged;

  const PercentageDragField({
    super.key,
    required this.rawFlexValue,
    required this.onChanged,
  });

  @override
  State<PercentageDragField> createState() => _PercentageDragFieldState();
}

class _PercentageDragFieldState extends State<PercentageDragField> {
  late int _currentFlex;
  bool _isEditing = false;
  late TextEditingController _textController;
  late FocusNode _focusNode;

  double _dragAccumulator = 0.0;
  final double _sensitivity = 1.5; // Slightly faster dragging for percentages

  @override
  void initState() {
    super.initState();
    _currentFlex = widget.rawFlexValue;
    // Format display text (e.g., 333 becomes "33.3")
    _textController = TextEditingController(
      text: (_currentFlex / 10).toStringAsFixed(1),
    );
    _focusNode = FocusNode();

    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _textController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _textController.text.length,
        );
      } else {
        _submitManualEntry();
      }
    });
  }

  @override
  void didUpdateWidget(covariant PercentageDragField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rawFlexValue != widget.rawFlexValue && !_isEditing) {
      _currentFlex = widget.rawFlexValue;
      _textController.text = (_currentFlex / 10).toStringAsFixed(1);
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submitManualEntry() {
    if (!_isEditing) return;

    // Use int instead of double since we dropped decimals
    int? parsed = int.tryParse(_textController.text);
    if (parsed != null) {
      int newFlex = parsed * 10;

      if (newFlex > 1000) newFlex = 1000;
      if (newFlex < 50)
        newFlex = 50; // CHANGED: Absolute minimum is now 5% (50 units)

      if (newFlex != _currentFlex) {
        setState(() => _currentFlex = newFlex);
        widget.onChanged(_currentFlex);
      } else {
        _textController.text = (_currentFlex / 10).round().toString();
      }
    } else {
      _textController.text = (_currentFlex / 10).round().toString();
    }
    setState(() => _isEditing = false);
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (_isEditing) return;
    _dragAccumulator += details.delta.dx;

    if (_dragAccumulator.abs() >= _sensitivity) {
      // 1 drag step = 1 unit on the 1000 scale (0.1%)
      int step = (_dragAccumulator / _sensitivity).truncate();
      int newValue = _currentFlex + step;

      if (newValue > 1000) newValue = 1000;
      if (newValue < 50)
        newValue = 50; // CHANGED: Absolute minimum is now 5% (50 units)

      if (newValue != _currentFlex) {
        setState(() {
          _currentFlex = newValue;
          // CHANGED: Use .round() to remove decimals!
          _textController.text = (_currentFlex / 10).round().toString();
        });
        widget.onChanged(_currentFlex);
        _dragAccumulator = _dragAccumulator.remainder(_sensitivity);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: _isEditing
          ? SystemMouseCursors.text
          : SystemMouseCursors.resizeLeftRight,
      child: GestureDetector(
        onPanStart: (_) => _dragAccumulator = 0.0,
        onPanUpdate: _handlePanUpdate,
        onTap: () {
          if (!_isEditing) {
            setState(() => _isEditing = true);
            _focusNode.requestFocus();
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.transparent,
            border: Border(
              bottom: BorderSide(
                color: _isEditing ? Colors.blue : Colors.transparent,
                width: 1.5,
              ),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _isEditing
                  ? IntrinsicWidth(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minWidth: 40),
                        child: TextField(
                          controller: _textController,
                          focusNode: _focusNode,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                            border: InputBorder.none,
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d*'),
                            ),
                          ],
                          onSubmitted: (_) => _submitManualEntry(),
                        ),
                      ),
                    )
                  : Text(
                      // CHANGED: Use .round() to remove decimals!
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
