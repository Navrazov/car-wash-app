class AppConstants {
  AppConstants._();

  // API
  static const String apiBaseUrl = 'http://192.168.31.26:3001/api';
  
  // Storage keys
  static const String accessTokenKey = 'accessToken';
  static const String refreshTokenKey = 'refreshToken';
  
  // Time slots
  static const List<String> timeSlots = [
    '09:00', '10:00', '11:00', '12:00', '13:00',
    '14:00', '15:00', '16:00', '17:00', '18:00', '19:00', '20:00',
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

