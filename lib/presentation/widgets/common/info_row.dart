import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final String? label;
  final Color? iconColor;

  const InfoRow({
    super.key,
    required this.icon,
    required this.text,
    this.label,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: iconColor ?? AppColors.textSecondary,
          ),
          const SizedBox(width: 8),
          if (label != null)
            Text(
              '$label: ',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

