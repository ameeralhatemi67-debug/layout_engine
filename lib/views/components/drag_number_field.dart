import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  final double _sensitivity = 2.0;

  bool _isEditing = false;
  late TextEditingController _textController;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.value;
    _textController = TextEditingController(text: '$_currentValue');
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
  void didUpdateWidget(covariant DragNumberField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && !_isEditing) {
      _currentValue = widget.value;
      _textController.text = '$_currentValue';
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

    int? parsed = int.tryParse(_textController.text);
    if (parsed != null) {
      if (parsed > widget.max) parsed = widget.max;
      if (parsed < widget.min) parsed = widget.min;

      if (parsed != _currentValue) {
        setState(() => _currentValue = parsed!);
        widget.onChanged(_currentValue);
      } else {
        _textController.text = '$_currentValue';
      }
    } else {
      _textController.text = '$_currentValue';
    }

    setState(() => _isEditing = false);
  }

  void _resetToDefault() {
    int resetTarget = widget.defaultValue ?? widget.min;
    if (_currentValue != resetTarget) {
      setState(() {
        _currentValue = resetTarget;
        _textController.text = '$_currentValue';
      });
      widget.onChanged(_currentValue);
    }
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (_isEditing) return;

    _dragAccumulator += details.delta.dx;

    if (_dragAccumulator.abs() >= _sensitivity) {
      int step = (_dragAccumulator / _sensitivity).truncate();
      int newValue = _currentValue + step;

      if (newValue > widget.max) newValue = widget.max;
      if (newValue < widget.min) newValue = widget.min;

      if (newValue != _currentValue) {
        setState(() {
          _currentValue = newValue;
          _textController.text = '$_currentValue';
        });
        widget.onChanged(_currentValue);
        _dragAccumulator = _dragAccumulator.remainder(_sensitivity);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // FIX: Conditionally remove padding if there is no label (like in the Split Window)
    final hasLabel = widget.label.isNotEmpty;

    return MouseRegion(
      cursor: _isEditing
          ? SystemMouseCursors.text
          : SystemMouseCursors.resizeLeftRight,
      child: GestureDetector(
        onPanStart: (_) => _dragAccumulator = 0.0,
        onPanUpdate: _handlePanUpdate,
        onDoubleTap: _resetToDefault,
        onTap: () {
          if (!_isEditing) {
            setState(() => _isEditing = true);
            _focusNode.requestFocus();
          }
        },
        child: Container(
          // FIX: Dramatically reduce padding if there is no label
          padding: EdgeInsets.symmetric(
            horizontal: hasLabel ? 12 : 6,
            vertical: hasLabel ? 8 : 4,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              color: _isEditing ? Colors.blue : Colors.transparent,
              width: 1.0,
            ),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // FIX: Only render the label widget if it actually has text!
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

              _isEditing
                  ? IntrinsicWidth(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minWidth: 30),
                        child: TextField(
                          controller: _textController,
                          focusNode: _focusNode,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                            border: InputBorder.none,
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          onSubmitted: (_) => _submitManualEntry(),
                        ),
                      ),
                    )
                  : Text(
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
