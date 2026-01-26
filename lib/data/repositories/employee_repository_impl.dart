import '../../core/network/api_client.dart';
import '../../domain/entities/employee.dart';
import '../../domain/repositories/employee_repository.dart';
import '../models/employee_model.dart';

class EmployeeRepositoryImpl implements EmployeeRepository {
  final ApiClient _apiClient;

  EmployeeRepositoryImpl({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  @override
  Future<List<Employee>> getEmployeesByLocation(String locationId) async {
    final response = await _apiClient.get<List<dynamic>>(
      '/public/employees?locationId=$locationId',
      auth: false,
    );
    return response.map((json) => EmployeeModel.fromJson(json)).toList();
  }
}

