import 'package:intl/intl.dart';
import '../../core/network/api_client.dart';
import '../../domain/entities/box.dart';
import '../../domain/repositories/box_repository.dart';

class BoxRepositoryImpl implements BoxRepository {
  final ApiClient _apiClient;

  BoxRepositoryImpl({required ApiClient apiClient}) : _apiClient = apiClient;

  @override
  Future<List<Box>> getBoxesByLocation(String locationId) async {
    final response = await _apiClient.get('/public/locations/$locationId/boxes');
    if (response is List) {
      return response.map((json) => Box.fromJson(json)).toList();
    }
    return [];
  }

  @override
  Future<List<BoxStatus>> getBoxesStatus(String locationId, {DateTime? date}) async {
    String url = '/public/locations/$locationId/boxes/status';
    if (date != null) {
      url += '?date=${DateFormat('yyyy-MM-dd').format(date)}';
    }
    final response = await _apiClient.get(url);
    if (response is List) {
      return response.map((json) => BoxStatus.fromJson(json)).toList();
    }
    return [];
  }

  @override
  Future<List<Box>> getAvailableBoxes(String locationId, DateTime date, String time, int duration) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final response = await _apiClient.get(
      '/public/locations/$locationId/boxes/available?date=$dateStr&time=$time&duration=$duration'
    );
    if (response is List) {
      return response.map((json) => Box.fromJson(json)).toList();
    }
    return [];
  }
}



