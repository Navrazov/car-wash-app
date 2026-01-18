import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class IconBox extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final double iconSize;
  final double borderRadius;
  final bool useGradient;

  const IconBox({
    super.key,
    required this.icon,
    this.color = AppColors.primary,
    this.size = 48,
    this.iconSize = 24,
    this.borderRadius = 14,
    this.useGradient = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: useGradient
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color,
                  color.withOpacity(0.8),
                ],
              )
            : null,
        color: useGradient ? null : color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(borderRadius),
        border: useGradient
            ? null
            : Border.all(color: color.withOpacity(0.2)),
        boxShadow: useGradient
            ? [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 12,
                  spreadRadius: 0,
                ),
              ]
            : null,
      ),
      child: Icon(
        icon,
        color: useGradient ? Colors.white : color,
        size: iconSize,
      ),
    );
  }
}
