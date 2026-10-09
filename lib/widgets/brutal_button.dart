import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class BrutalButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Widget child;
  final Color backgroundColor;
  final double borderWidth;
  final double shadowOffset;
  final double borderRadius;
  final EdgeInsetsGeometry padding;

  const BrutalButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.backgroundColor = AppColors.primaryPink,
    this.borderWidth = 3.0,
    this.shadowOffset = 4.0,
    this.borderRadius = 12.0,
    this.padding = const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
  });

  @override
  State<BrutalButton> createState() => _BrutalButtonState();
}

class _BrutalButtonState extends State<BrutalButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 50),
        transform: Matrix4.translationValues(
          _isPressed ? widget.shadowOffset : 0,
          _isPressed ? widget.shadowOffset : 0,
          0,
        ),
        decoration: BoxDecoration(
          color: widget.backgroundColor,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: Border.all(color: AppColors.black, width: widget.borderWidth),
          boxShadow: [
            if (!_isPressed)
              BoxShadow(
                color: AppColors.black,
                offset: Offset(widget.shadowOffset, widget.shadowOffset),
                blurRadius: 0,
                spreadRadius: 0,
              ),
          ],
        ),
        padding: widget.padding,
        child: Center(child: widget.child),
      ),
    );
  }
}
