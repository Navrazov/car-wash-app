import '../network/api_client.dart';
import '../storage/secure_storage.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/repositories/booking_repository_impl.dart';
import '../../data/repositories/box_repository_impl.dart';
import '../../data/repositories/employee_repository_impl.dart';
import '../../data/repositories/location_repository_impl.dart';
import '../../data/repositories/service_repository_impl.dart';
import '../../data/repositories/review_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/booking_repository.dart';
import '../../domain/repositories/box_repository.dart';
import '../../domain/repositories/employee_repository.dart';
import '../../domain/repositories/location_repository.dart';
import '../../domain/repositories/service_repository.dart';
import '../../domain/repositories/review_repository.dart';

/// Simple service locator for dependency injection
class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  factory ServiceLocator() => _instance;
  ServiceLocator._internal();

  static ServiceLocator get instance => _instance;

  // Lazy singletons
  SecureStorage? _storage;
  ApiClient? _apiClient;
  
  AuthRepository? _authRepository;
  BookingRepository? _bookingRepository;
  BoxRepository? _boxRepository;
  EmployeeRepository? _employeeRepository;
  LocationRepository? _locationRepository;
  ServiceRepository? _serviceRepository;
  ReviewRepository? _reviewRepository;

  // Core
  SecureStorage get storage => _storage ??= SecureStorage();
  ApiClient get apiClient => _apiClient ??= ApiClient(storage: storage);

  // Repositories
  AuthRepository get authRepository =>
      _authRepository ??= AuthRepositoryImpl(
        apiClient: apiClient,
        storage: storage,
      );

  BookingRepository get bookingRepository =>
      _bookingRepository ??= BookingRepositoryImpl(apiClient: apiClient);

  BoxRepository get boxRepository =>
      _boxRepository ??= BoxRepositoryImpl(apiClient: apiClient);

  EmployeeRepository get employeeRepository =>
      _employeeRepository ??= EmployeeRepositoryImpl(apiClient: apiClient);

  LocationRepository get locationRepository =>
      _locationRepository ??= LocationRepositoryImpl(apiClient: apiClient);

  ServiceRepository get serviceRepository =>
      _serviceRepository ??= ServiceRepositoryImpl(apiClient: apiClient);

  ReviewRepository get reviewRepository =>
      _reviewRepository ??= ReviewRepositoryImpl(apiClient: apiClient);

  /// Reset all instances (useful for testing or logout)
  void reset() {
    _authRepository = null;
    _bookingRepository = null;
    _boxRepository = null;
    _employeeRepository = null;
    _locationRepository = null;
    _serviceRepository = null;
    _reviewRepository = null;
    // Keep storage and apiClient as they are stateless
  }
}

// Shorthand accessor
ServiceLocator get sl => ServiceLocator.instance;

