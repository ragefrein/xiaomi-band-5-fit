import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class BrutalContainer extends StatelessWidget {
  final Widget child;
  final Color backgroundColor;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderWidth;
  final double shadowOffset;
  final double borderRadius;
  final Color borderColor;

  const BrutalContainer({
    super.key,
    required this.child,
    this.backgroundColor = AppColors.white,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.borderWidth = 3.0,
    this.shadowOffset = 4.0,
    this.borderRadius = 12.0,
    this.borderColor = AppColors.black,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: borderColor, width: borderWidth),
        boxShadow: [
          BoxShadow(
            color: borderColor,
            offset: Offset(shadowOffset, shadowOffset),
            blurRadius: 0,
            spreadRadius: 0,
          ),
        ],
      ),
      child: child,
    );
  }
}
