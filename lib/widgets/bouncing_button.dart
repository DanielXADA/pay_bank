import 'package:flutter/material.dart';

class BouncingButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Widget child;
  final ButtonStyle style;

  const BouncingButton({
    super.key,
    required this.onPressed,
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
        onPointerDown: (_) => setState(() => _scale = 0.95),
        onPointerUp: (_) => setState(() => _scale = 1.0),
        onPointerCancel: (_) => setState(() => _scale = 1.0),
        child: ElevatedButton(
          style: widget.style,
          onPressed: widget.onPressed,
          child: widget.child,
        ),
      ),
    );
  }
}