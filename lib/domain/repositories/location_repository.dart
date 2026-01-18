import '../entities/location.dart';

abstract class LocationRepository {
  Future<List<Location>> getLocations();
  Future<Location> getLocationById(String id);
}

