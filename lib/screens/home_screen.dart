import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/app_provider.dart';
import '../services/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final api = context.read<ApiService>();
    final provider = context.read<AppProvider>();

    try {
      final locations = await api.getLocations();
      final services = await api.getServices();
      provider.setLocations(locations.where((l) => l.isActive).toList());
      provider.setServices(services.where((s) => s.isActive).toList());
    } catch (e) {
      debugPrint('Ошибка загрузки данных: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildPromoCard(),
              const SizedBox(height: 28),
              _buildSectionTitle('Наши услуги'),
              const SizedBox(height: 16),
              _buildServicesGrid(),
              const SizedBox(height: 28),
              _buildSectionTitle('Филиалы'),
              const SizedBox(height: 16),
              _buildLocationsList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.primaryColor, AppTheme.primaryDark],
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.local_car_wash_rounded, color: Colors.white, size: 26),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'АвтоМойка',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                foreground: Paint()
                  ..shader = const LinearGradient(
                    colors: [AppTheme.primaryLight, AppTheme.primaryColor],
                  ).createShader(const Rect.fromLTWH(0, 0, 150, 30)),
              ),
            ),
            const Text(
              'Чистота вашего авто',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPromoCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0E7490), Color(0xFF0891B2)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '🎉 Акция',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Скидка 20%\nна первую мойку!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Зарегистрируйтесь и получите скидку\nна любую услугу',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildServicesGrid() {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        if (provider.services.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            ),
          );
        }

        final categories = provider.services.map((s) => s.category ?? 'Другое').toSet().toList();
        
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.1,
          ),
          itemCount: categories.length > 4 ? 4 : categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            final servicesInCategory = provider.services.where((s) => s.category == category).toList();
            final minPrice = servicesInCategory.map((s) => s.price).reduce((a, b) => a < b ? a : b);
            
            return _buildServiceCard(
              category,
              _getCategoryIcon(category),
              _getCategoryColor(index),
              'от ${minPrice.toInt()} ₽',
            );
          },
        );
      },
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'мойка':
        return Icons.water_drop_rounded;
      case 'полировка':
        return Icons.auto_awesome_rounded;
      case 'химчистка':
        return Icons.cleaning_services_rounded;
      case 'защита':
        return Icons.shield_rounded;
      default:
        return Icons.car_repair_rounded;
    }
  }

  Color _getCategoryColor(int index) {
    final colors = [
      AppTheme.primaryColor,
      AppTheme.purpleColor,
      AppTheme.successColor,
      AppTheme.warningColor,
    ];
    return colors[index % colors.length];
  }

  Widget _buildServiceCard(String title, IconData icon, Color color, String price) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const Spacer(),
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            price,
            style: TextStyle(
              fontSize: 13,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationsList() {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        if (provider.locations.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            ),
          );
        }

        return Column(
          children: provider.locations.map((location) => _buildLocationCard(location)).toList(),
        );
      },
    );
  }

  Widget _buildLocationCard(location) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.location_on_rounded, color: AppTheme.primaryColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  location.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  location.address,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
                if (location.workingHours != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded, size: 14, color: AppTheme.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        location.workingHours!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppTheme.textSecondary),
        ],
      ),
    );
  }
}

