import '../../core/network/api_client.dart';
import '../../domain/entities/service.dart';
import '../../domain/repositories/service_repository.dart';
import '../models/service_model.dart';

class ServiceRepositoryImpl implements ServiceRepository {
  final ApiClient _apiClient;

  ServiceRepositoryImpl({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  @override
  Future<List<Service>> getServices() async {
    final response = await _apiClient.get<List<dynamic>>(
      '/public/services',
      auth: false,
    );
    return response.map((json) => ServiceModel.fromJson(json)).toList();
  }

  @override
  Future<Service> getServiceById(String id) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/public/services/$id',
      auth: false,
    );
    return ServiceModel.fromJson(response);
  }
}

