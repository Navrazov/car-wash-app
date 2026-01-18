import '../entities/service.dart';

abstract class ServiceRepository {
  Future<List<Service>> getServices();
  Future<Service> getServiceById(String id);
}

