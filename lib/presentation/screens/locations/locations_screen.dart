import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/app_state.dart';
import '../../widgets/home/location_card.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../../domain/entities/location.dart';

class LocationsScreen extends StatefulWidget {
  const LocationsScreen({super.key});

  @override
  State<LocationsScreen> createState() => _LocationsScreenState();
}

class _LocationsScreenState extends State<LocationsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  bool _showMap = true;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _animController.forward();
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
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // App Bar
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          'Филиалы',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      // Toggle buttons
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Row(
                          children: [
                            _buildToggleButton(
                              icon: Icons.map_rounded,
                              isActive: _showMap,
                              onTap: () => setState(() => _showMap = true),
                            ),
                            _buildToggleButton(
                              icon: Icons.list_rounded,
                              isActive: !_showMap,
                              onTap: () => setState(() => _showMap = false),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Content
                Expanded(
                  child: _showMap ? _buildMapView() : _buildListView(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToggleButton({
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Icon(
          icon,
          color: isActive ? AppColors.primary : AppColors.textSecondary,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildListView() {
    return RefreshIndicator(
      onRefresh: () => context.read<AppState>().loadInitialData(),
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _buildLocationsList(),
        ),
      ),
    );
  }

  Widget _buildMapView() {
    return Consumer<AppState>(
      builder: (context, state, _) {
        if (state.locations.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: LoadingIndicator(size: 36),
            ),
          );
        }

        // Добавляем тестовые координаты для филиалов без них
        final locationsWithCoords = state.locations.map((location) {
          // Если координаты отсутствуют, добавляем тестовые (Москва)
          if (location.latitude == null || location.longitude == null) {
            // Тестовые координаты разных районов Москвы
            final testCoords = _getTestCoordinates(location.id);
            return Location(
              id: location.id,
              name: location.name,
              address: location.address,
              phone: location.phone,
              workingHours: location.workingHours,
              description: location.description,
              isActive: location.isActive,
              latitude: testCoords['lat'],
              longitude: testCoords['lng'],
            );
          }
          return location;
        }).toList();

        // Центрируем карту на первом филиале или Москве по умолчанию
        final centerLatLng = locationsWithCoords.isNotEmpty
            ? LatLng(locationsWithCoords.first.latitude!, locationsWithCoords.first.longitude!)
            : LatLng(55.7558, 37.6176); // Москва

        return FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            center: centerLatLng,
            zoom: 12.0,
            maxZoom: 18.0,
            minZoom: 3.0,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.car_wash_app',
            ),
            MarkerLayer(
              markers: locationsWithCoords.map((location) {
                return Marker(
                  point: LatLng(location.latitude!, location.longitude!),
                  width: 40,
                  height: 40,
                  child: GestureDetector(
                    onTap: () => _showLocationDetails(location),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.8),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.textPrimary,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.location_on_rounded,
                        color: AppColors.textPrimary,
                        size: 24,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }


  Map<String, double> _getTestCoordinates(String locationId) {
    // Тестовые координаты различных районов Москвы
    final testCoordinates = {
      // Можно расширить для большего количества филиалов
    //   '1': {'lat': 55.7558, 'lng': 37.6176}, // Красная площадь
    //   '2': {'lat': 55.7642, 'lng': 37.6026}, // Тверская
    //   '3': {'lat': 55.7517, 'lng': 37.6177}, // Арбат
      '4': {'lat': 45.021233, 'lng': 39.101607}, // Демченко
    //   '5': {'lat': 55.7267, 'lng': 37.5544}, // Даниловский
    };

    // Если ID есть в списке, возвращаем соответствующие координаты
    if (testCoordinates.containsKey(locationId)) {
      return testCoordinates[locationId]!;
    }

    // Иначе генерируем случайные координаты вокруг центра Москвы
    final random = DateTime.now().millisecondsSinceEpoch % 100;
    return {
      'lat': 45.021233, // ±0.05 градусов
      'lng': 39.101607,
    };
  }

  void _showLocationDetails(Location location) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              location.name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.location_on_rounded,
                  color: AppColors.textSecondary,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    location.address,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            if (location.phone != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.phone_rounded,
                    color: AppColors.textSecondary,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    location.phone!,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
            if (location.workingHours != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    color: AppColors.textSecondary,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    location.workingHours!,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Здесь можно добавить логику записи на выбранный филиал
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Записаться',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationsList() {
    return Consumer<AppState>(
      builder: (context, state, _) {
        if (state.locations.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: LoadingIndicator(size: 36),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            ...state.locations
                .map((location) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: LocationCard(location: location),
                    ))
                .toList(),
            const SizedBox(height: 32),
          ],
        );
      },
    );
  }
}
