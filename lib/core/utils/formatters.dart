import 'package:intl/intl.dart';
import '../constants/app_constants.dart';

class Formatters {
  Formatters._();

  static String formatDate(DateTime date) {
    return DateFormat('d MMMM yyyy', 'ru').format(date);
  }

  static String formatDateTime(DateTime date) {
    return DateFormat('d MMMM yyyy в HH:mm', 'ru').format(date);
  }

  static String formatPrice(double price) {
    return '${price.toInt()} ₽';
  }

  static String formatDuration(int minutes) {
    if (minutes < 60) {
      return '$minutes мин';
    }
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return mins > 0 ? '$hoursч $minsмин' : '$hours ч';
  }

  static String getStatusLabel(String status) {
    return AppConstants.statusLabels[status] ?? status;
  }

  static String getCategoryLabel(String category) {
    return AppConstants.categoryLabels[category] ?? category;
  }
}

