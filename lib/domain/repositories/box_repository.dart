import '../entities/box.dart';

abstract class BoxRepository {
  Future<List<Box>> getBoxesByLocation(String locationId);
  Future<List<BoxStatus>> getBoxesStatus(String locationId, {DateTime? date});
  Future<List<Box>> getAvailableBoxes(String locationId, DateTime date, String time, int duration);
}


