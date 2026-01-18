import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../widgets/home/app_header.dart';
import '../../widgets/home/promo_card.dart';
import '../../widgets/home/service_category_card.dart';
import '../../widgets/home/location_card.dart';
import '../../widgets/common/section_title.dart';
import '../../widgets/common/loading_indicator.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().loadInitialData();
    });
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
              const AppHeader(),
              const SizedBox(height: 24),
              const PromoCard(),
              const SizedBox(height: 28),
              const SectionTitle(title: 'Наши услуги'),
              const SizedBox(height: 16),
              _buildServicesGrid(),
              const SizedBox(height: 28),
              const SectionTitle(title: 'Филиалы'),
              const SizedBox(height: 16),
              _buildLocationsList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServicesGrid() {
    return Consumer<AppState>(
      builder: (context, state, _) {
        if (state.services.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: LoadingIndicator(size: 30),
            ),
          );
        }

        final categories = state.services
            .map((s) => s.category ?? 'other')
            .toSet()
            .toList();

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
            final servicesInCategory = state.services
                .where((s) => s.category == category)
                .toList();
            final minPrice = servicesInCategory
                .map((s) => s.price)
                .reduce((a, b) => a < b ? a : b);

            return ServiceCategoryCard(
              category: category,
              minPrice: minPrice,
              index: index,
            );
          },
        );
      },
    );
  }

  Widget _buildLocationsList() {
    return Consumer<AppState>(
      builder: (context, state, _) {
        if (state.locations.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: LoadingIndicator(size: 30),
            ),
          );
        }

        return Column(
          children: state.locations
              .map((location) => LocationCard(location: location))
              .toList(),
        );
      },
    );
  }
}

