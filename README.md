# Car Wash App

Мобильное приложение для записи на автомойку.

## Установка

```bash
flutter pub get
```

## Запуск

```bash
flutter run
```

## Функционал

- **Главная** — обзор услуг и филиалов
- **Запись** — пошаговая форма записи на мойку
- **История** — история записей
- **Профиль** — личные данные и настройки

## Настройка API

Откройте `lib/services/api_service.dart` и измените `baseUrl` на адрес вашего сервера:

```dart
static const String baseUrl = 'http://YOUR_IP:3001/api';
```

Для работы на реальном устройстве используйте IP-адрес компьютера вместо `localhost`.

## Технологии

- Flutter 3.x
- Provider (state management)
- HTTP (API requests)
- Shared Preferences (local storage)

