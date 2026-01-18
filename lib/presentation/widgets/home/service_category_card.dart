import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';

class ServiceCategoryCard extends StatefulWidget {
  final String category;
  final double minPrice;
  final int index;

  const ServiceCategoryCard({
    super.key,
    required this.category,
    required this.minPrice,
    required this.index,
  });

  @override
  State<ServiceCategoryCard> createState() => _ServiceCategoryCardState();
}

class _ServiceCategoryCardState extends State<ServiceCategoryCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = _getCategoryConfig(widget.category);

    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _controller.forward();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _controller.reverse();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _controller.reverse();
      },
      child: ScaleTransition(
        scale: _scaleAnim,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.card,
                _isPressed
                    ? config.color.withOpacity(0.08)
                    : AppColors.card.withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _isPressed
                  ? config.color.withOpacity(0.4)
                  : AppColors.border.withOpacity(0.5),
              width: _isPressed ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: _isPressed
                    ? config.color.withOpacity(0.2)
                    : Colors.black.withOpacity(0.15),
                blurRadius: _isPressed ? 20 : 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Background decoration
              Positioned(
                top: -20,
                right: -20,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: config.color.withOpacity(0.08),
                  ),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon container
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: config.gradient,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: config.color.withOpacity(0.4),
                            blurRadius: 12,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: Icon(
                        config.icon,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const Spacer(),
                    // Title
                    Text(
                      Formatters.getCategoryLabel(widget.category),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Price
                    Row(
                      children: [
                        Text(
                          'от ',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary.withOpacity(0.8),
                          ),
                        ),
                        Text(
                          Formatters.formatPrice(widget.minPrice),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: config.color,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _CategoryConfig _getCategoryConfig(String category) {
    switch (category) {
      case 'wash':
        return _CategoryConfig(
          icon: Icons.water_drop_rounded,
          color: AppColors.primary,
          gradient: [
            const Color(0xFF00E5FF),
            const Color(0xFF00D4FF),
            const Color(0xFF0099CC),
          ],
        );
      case 'detailing':
        return _CategoryConfig(
          icon: Icons.auto_awesome_rounded,
          color: AppColors.purple,
          gradient: [
            const Color(0xFFD946EF),
            const Color(0xFFA855F7),
            const Color(0xFF7C3AED),
          ],
        );
      case 'maintenance':
        return _CategoryConfig(
          icon: Icons.build_rounded,
          color: AppColors.warning,
          gradient: [
            const Color(0xFFFCD34D),
            const Color(0xFFF59E0B),
            const Color(0xFFD97706),
          ],
        );
      default:
        return _CategoryConfig(
          icon: Icons.miscellaneous_services_rounded,
          color: AppColors.success,
          gradient: [
            const Color(0xFF34D399),
            const Color(0xFF10B981),
            const Color(0xFF059669),
          ],
        );
    }
  }
}

class _CategoryConfig {
  final IconData icon;
  final Color color;
  final List<Color> gradient;

  _CategoryConfig({
    required this.icon,
    required this.color,
    required this.gradient,
  });
}
