import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/di/service_locator.dart';
import '../../../domain/entities/location.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/home/location_card.dart';

class LocationsRatingsScreen extends StatefulWidget {
  const LocationsRatingsScreen({super.key});

  @override
  State<LocationsRatingsScreen> createState() => _LocationsRatingsScreenState();
}

class _LocationsRatingsScreenState extends State<LocationsRatingsScreen> {
  List<Location> _locations = [];
  bool _isLoading = true;
  String _sortBy = 'rating'; // 'rating' or 'reviews'

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  Future<void> _loadLocations() async {
    setState(() => _isLoading = true);
    try {
      final locations = await sl.locationRepository.getLocations();
      setState(() {
        _locations = locations;
        _sortLocations();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка загрузки: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _sortLocations() {
    _locations.sort((a, b) {
      if (_sortBy == 'rating') {
        final ratingCompare = b.rating.compareTo(a.rating);
        if (ratingCompare != 0) return ratingCompare;
        return b.totalReviews.compareTo(a.totalReviews);
      } else {
        final reviewsCompare = b.totalReviews.compareTo(a.totalReviews);
        if (reviewsCompare != 0) return reviewsCompare;
        return b.rating.compareTo(a.rating);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Рейтинг моек'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort_rounded),
            onSelected: (value) {
              setState(() {
                _sortBy = value;
                _sortLocations();
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'rating',
                child: Text('По рейтингу'),
              ),
              const PopupMenuItem(
                value: 'reviews',
                child: Text('По количеству отзывов'),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: LoadingIndicator())
          : _locations.isEmpty
              ? const EmptyState(
                  icon: Icons.location_off_rounded,
                  title: 'Нет доступных моек',
                  subtitle: 'Мойки появятся позже',
                )
              : RefreshIndicator(
                  onRefresh: _loadLocations,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _locations.length,
                    itemBuilder: (context, index) {
                      final location = _locations[index];
                      return LocationCard(location: location);
                    },
                  ),
                ),
    );
  }
}
