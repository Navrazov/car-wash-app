import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class IconBox extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final double size;
  final double iconSize;

  const IconBox({
    super.key,
    required this.icon,
    this.color,
    this.size = 48,
    this.iconSize = 24,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.primary;
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: effectiveColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(size / 4),
      ),
      child: Icon(
        icon,
        color: effectiveColor,
        size: iconSize,
      ),
    );
  }
}

