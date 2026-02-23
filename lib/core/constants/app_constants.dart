import 'package:flutter/foundation.dart';

class AppConstants {
  AppConstants._();

  // API
  // For real devices pass --dart-define=API_BASE_URL=http://<your-lan-ip>:3001/api
  static String get apiBaseUrl {
    const fromEnv = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (fromEnv.isNotEmpty) return fromEnv;

    if (kIsWeb) {
      final base = Uri.base;
      final host = base.host.isEmpty ? 'localhost' : base.host;
      final scheme = base.scheme.isEmpty ? 'http' : base.scheme;
      return '$scheme://$host:3001/api';
    }

    return 'http://localhost:3001/api';
  }

  // Storage keys
  static const String accessTokenKey = 'accessToken';
  static const String refreshTokenKey = 'refreshToken';

  // Time slots
  static const List<String> timeSlots = [
    '09:00',
    '10:00',
    '11:00',
    '12:00',
    '13:00',
    '14:00',
    '15:00',
    '16:00',
    '17:00',
    '18:00',
    '19:00',
    '20:00',
  ];

  // Booking statuses
  static const Map<String, String> statusLabels = {
    'pending': 'Ожидает оплаты',
    'confirmed': 'Подтверждена',
    'in_progress': 'В процессе',
    'completed': 'Завершена',
    'cancelled': 'Отменена',
  };

  // Service categories
  static const Map<String, String> categoryLabels = {
    'wash': 'Мойка',
    'detailing': 'Детейлинг',
    'maintenance': 'Обслуживание',
    'other': 'Другое',
  };
}
