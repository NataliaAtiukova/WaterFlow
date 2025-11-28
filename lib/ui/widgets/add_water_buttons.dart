import 'package:flutter/material.dart';

class AddWaterButtons extends StatelessWidget {
  const AddWaterButtons({
    super.key,
    required this.options,
    required this.onAdd,
    required this.onAddCustom,
  });

  final List<int> options;
  final ValueChanged<int> onAdd;
  final VoidCallback onAddCustom;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final option in options)
          _BounceButton(
            onPressed: () => onAdd(option),
            outlined: false,
            child: Text('+${option.toString()} мл'),
          ),
        _BounceButton(
          onPressed: onAddCustom,
          outlined: true,
          child: const Text('Другое'),
        ),
      ],
    );
  }
}

class _BounceButton extends StatefulWidget {
  const _BounceButton({
    required this.onPressed,
    required this.child,
    this.outlined = false,
  });

  final VoidCallback onPressed;
  final Widget child;
  final bool outlined;

  @override
  State<_BounceButton> createState() => _BounceButtonState();
}

class _BounceButtonState extends State<_BounceButton> {
  double _scale = 1;

  void _pressDown(_) => setState(() => _scale = 0.94);
  void _pressUp([_]) => setState(() => _scale = 1);

  @override
  Widget build(BuildContext context) {
    final button = widget.outlined
        ? OutlinedButton(onPressed: widget.onPressed, child: widget.child)
        : ElevatedButton(onPressed: widget.onPressed, child: widget.child);
    return GestureDetector(
      onTapDown: _pressDown,
      onTapUp: _pressUp,
      onTapCancel: _pressUp,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        child: button,
      ),
    );
  }
}
