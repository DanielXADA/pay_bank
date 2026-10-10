import 'package:flutter/material.dart';

class BouncingButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final ButtonStyle style;

  const BouncingButton({
    super.key,
    this.onPressed,
    required this.child,
    required this.style,
  });

  @override
  State<BouncingButton> createState() => _BouncingButtonState();
}

class _BouncingButtonState extends State<BouncingButton> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _scale,
      duration: const Duration(milliseconds: 100),
      child: Listener(
        onPointerDown: widget.onPressed != null ? (_) => setState(() => _scale = 0.95) : null,
        onPointerUp: widget.onPressed != null ? (_) => setState(() => _scale = 1.0) : null,
        onPointerCancel: widget.onPressed != null ? (_) => setState(() => _scale = 1.0) : null,
        child: ElevatedButton(
          style: widget.style,
          onPressed: widget.onPressed,
          child: widget.child,
        ),
      ),
    );
  }
}