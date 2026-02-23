import '../../core/network/api_client.dart';
import '../../domain/entities/location.dart';
import '../../domain/repositories/location_repository.dart';
import '../models/location_model.dart';

class LocationRepositoryImpl implements LocationRepository {
  final ApiClient _apiClient;

  LocationRepositoryImpl({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  @override
  Future<List<Location>> getLocations() async {
    final response = await _apiClient.get<List<dynamic>>(
      '/public/locations',
      auth: false,
    );
    final locations = response.map((json) => LocationModel.fromJson(json)).toList();

    final enriched = await Future.wait(locations.map((location) async {
      if (location.latitude != null && location.longitude != null) return location;
      if (location.address.trim().length < 3) return location;

      try {
        final geocoded = await _apiClient.get<dynamic>(
          '/public/geocoding/forward?address=${Uri.encodeComponent(location.address)}',
          auth: false,
        );
        if (geocoded is Map<String, dynamic>) {
          final lat = (geocoded['lat'] as num?)?.toDouble();
          final lng = (geocoded['lng'] as num?)?.toDouble();
          if (lat != null && lng != null) {
            return Location(
              id: location.id,
              name: location.name,
              address: location.address,
              phone: location.phone,
              workingHours: location.workingHours,
              description: location.description,
              rating: location.rating,
              totalReviews: location.totalReviews,
              isActive: location.isActive,
              latitude: lat,
              longitude: lng,
            );
          }
        }
      } catch (_) {
        // Keep original location without coordinates.
      }
      return location;
    }));

    return enriched;
  }

  @override
  Future<Location> getLocationById(String id) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/public/locations/$id',
      auth: false,
    );
    final location = LocationModel.fromJson(response);
    if (location.latitude != null && location.longitude != null) return location;
    if (location.address.trim().length < 3) return location;

    try {
      final geocoded = await _apiClient.get<dynamic>(
        '/public/geocoding/forward?address=${Uri.encodeComponent(location.address)}',
        auth: false,
      );
      if (geocoded is Map<String, dynamic>) {
        final lat = (geocoded['lat'] as num?)?.toDouble();
        final lng = (geocoded['lng'] as num?)?.toDouble();
        if (lat != null && lng != null) {
          return Location(
            id: location.id,
            name: location.name,
            address: location.address,
            phone: location.phone,
            workingHours: location.workingHours,
            description: location.description,
            rating: location.rating,
            totalReviews: location.totalReviews,
            isActive: location.isActive,
            latitude: lat,
            longitude: lng,
          );
        }
      }
    } catch (_) {
      // Ignore geocode fallback failures.
    }

    return location;
  }
}
