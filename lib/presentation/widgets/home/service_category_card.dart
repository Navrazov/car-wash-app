import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';

class ServiceCategoryCard extends StatelessWidget {
  final String category;
  final double minPrice;
  final int index;

  const ServiceCategoryCard({
    super.key,
    required this.category,
    required this.minPrice,
    required this.index,
  });

  IconData get _icon {
    switch (category.toLowerCase()) {
      case 'wash':
      case 'мойка':
        return Icons.water_drop_rounded;
      case 'detailing':
      case 'полировка':
        return Icons.auto_awesome_rounded;
      case 'maintenance':
      case 'химчистка':
        return Icons.cleaning_services_rounded;
      case 'other':
      case 'защита':
        return Icons.shield_rounded;
      default:
        return Icons.car_repair_rounded;
    }
  }

  Color get _color {
    const colors = [
      AppColors.primary,
      AppColors.purple,
      AppColors.success,
      AppColors.warning,
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_icon, color: _color, size: 24),
          ),
          const Spacer(),
          Text(
            Formatters.getCategoryLabel(category),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'от ${Formatters.formatPrice(minPrice)}',
            style: TextStyle(
              fontSize: 13,
              color: _color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

