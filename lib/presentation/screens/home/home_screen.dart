import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/app_state.dart';
import '../../widgets/home/app_header.dart';
import '../../widgets/home/promo_card.dart';
import '../../widgets/home/service_category_card.dart';
import '../../widgets/common/section_title.dart';
import '../../widgets/common/loading_indicator.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _animController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().loadInitialData();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0D1B2A),
              AppColors.background,
              AppColors.background,
            ],
            stops: [0.0, 0.3, 1.0],
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () => context.read<AppState>().loadInitialData(),
            color: AppColors.primary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: AppHeader(),
                    ),
                    const SizedBox(height: 24),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: PromoCard(),
                    ),
                    const SizedBox(height: 32),
                    _buildQuickActions(),
                    const SizedBox(height: 32),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildSectionHeader('Наши услуги', Icons.car_repair_rounded),
                    ),
                    const SizedBox(height: 16),
                    _buildServicesGrid(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
        const Spacer(),
        TextButton(
          onPressed: () {},
          style: TextButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Все', style: TextStyle(fontSize: 14)),
              SizedBox(width: 4),
              Icon(Icons.arrow_forward_ios_rounded, size: 14),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _QuickActionChip(
            icon: Icons.schedule_rounded,
            label: 'Записаться',
            color: AppColors.primary,
            onTap: () {
              // Переключиться на вкладку записи
            },
          ),
          const SizedBox(width: 12),
          _QuickActionChip(
            icon: Icons.star_rounded,
            label: 'Бонусы',
            color: AppColors.warning,
            onTap: () {},
          ),
          const SizedBox(width: 12),
          _QuickActionChip(
            icon: Icons.card_giftcard_rounded,
            label: 'Акции',
            color: AppColors.purple,
            onTap: () {},
          ),
          const SizedBox(width: 12),
          _QuickActionChip(
            icon: Icons.support_agent_rounded,
            label: 'Поддержка',
            color: AppColors.success,
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildServicesGrid() {
    return Consumer<AppState>(
      builder: (context, state, _) {
        if (state.services.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: LoadingIndicator(size: 36),
            ),
          );
        }

        final categories = state.services
            .map((s) => s.category ?? 'other')
            .toSet()
            .toList();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 1.05,
            ),
            itemCount: categories.length > 4 ? 4 : categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              final servicesInCategory =
                  state.services.where((s) => s.category == category).toList();
              final minPrice = servicesInCategory
                  .map((s) => s.price)
                  .reduce((a, b) => a < b ? a : b);

              return ServiceCategoryCard(
                category: category,
                minPrice: minPrice,
                index: index,
              );
            },
          ),
        );
      },
    );
  }

}

class _QuickActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
