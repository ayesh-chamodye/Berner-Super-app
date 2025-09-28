import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

class OTPInput extends StatefulWidget {
  final int length;
  final Function(String) onCompleted;
  final Function(String)? onChanged;
  final TextEditingController? controller;

  const OTPInput({
    super.key,
    this.length = 6,
    required this.onCompleted,
    this.onChanged,
    this.controller,
  });

  @override
  State<OTPInput> createState() => _OTPInputState();
}

class _OTPInputState extends State<OTPInput> {
  late List<FocusNode> _focusNodes;
  late List<TextEditingController> _controllers;
  late TextEditingController _hiddenController;

  @override
  void initState() {
    super.initState();
    _focusNodes = List.generate(widget.length, (index) => FocusNode());
    _controllers = List.generate(widget.length, (index) => TextEditingController());
    _hiddenController = widget.controller ?? TextEditingController();

    // Listen to external controller changes
    _hiddenController.addListener(_onExternalControllerChanged);
  }

  void _onExternalControllerChanged() {
    final text = _hiddenController.text;
    for (int i = 0; i < widget.length; i++) {
      if (i < text.length) {
        _controllers[i].text = text[i];
      } else {
        _controllers[i].clear();
      }
    }
  }

  @override
  void dispose() {
    for (var node in _focusNodes) {
      node.dispose();
    }
    for (var controller in _controllers) {
      controller.dispose();
    }
    _hiddenController.removeListener(_onExternalControllerChanged);
    if (widget.controller == null) {
      _hiddenController.dispose();
    }
    super.dispose();
  }

  void _onChanged(String value, int index) {
    if (value.length == 1) {
      if (index < widget.length - 1) {
        _focusNodes[index + 1].requestFocus();
      }
    } else if (value.isEmpty) {
      if (index > 0) {
        _focusNodes[index - 1].requestFocus();
      }
    }

    // Update the hidden controller
    String completeValue = '';
    for (var controller in _controllers) {
      completeValue += controller.text;
    }
    _hiddenController.text = completeValue;

    widget.onChanged?.call(completeValue);

    if (completeValue.length == widget.length) {
      widget.onCompleted(completeValue);
    }
  }

  void _onKeyEvent(KeyEvent event, int index) {
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.backspace) {
      if (_controllers[index].text.isEmpty && index > 0) {
        _focusNodes[index - 1].requestFocus();
        _controllers[index - 1].clear();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(widget.length, (index) {
        return Container(
          width: 50,
          height: 60,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          child: KeyboardListener(
            focusNode: FocusNode(),
            onKeyEvent: (event) => _onKeyEvent(event, index),
            child: TextField(
              controller: _controllers[index],
              focusNode: _focusNodes[index],
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              maxLength: 1,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              decoration: InputDecoration(
                counterText: '',
                contentPadding: const EdgeInsets.all(0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppColors.secondaryBlue.withValues(alpha: 0.3),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppColors.secondaryBlue.withValues(alpha: 0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppColors.primaryOrange,
                    width: 2,
                  ),
                ),
                fillColor: _controllers[index].text.isNotEmpty
                    ? AppColors.primaryOrange.withValues(alpha: 0.1)
                    : AppColors.surfaceVariant,
                filled: true,
              ),
              onChanged: (value) => _onChanged(value, index),
            ),
          ),
        );
      }),
    );
  }
}