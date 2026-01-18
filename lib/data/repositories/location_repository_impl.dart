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
    return response.map((json) => LocationModel.fromJson(json)).toList();
  }

  @override
  Future<Location> getLocationById(String id) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/public/locations/$id',
      auth: false,
    );
    return LocationModel.fromJson(response);
  }
}

