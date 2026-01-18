import 'package:flutter/material.dart';
import '../../domain/entities/entities.dart';
import '../../data/repositories/repositories.dart';

class AppState extends ChangeNotifier {
  User? _currentUser;
  List<Location> _locations = [];
  List<Service> _services = [];
  List<Booking> _bookings = [];
  bool _isLoading = false;

  User? get currentUser => _currentUser;
  List<Location> get locations => _locations;
  List<Service> get services => _services;
  List<Booking> get bookings => _bookings;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;

  final AuthRepositoryImpl _authRepository = AuthRepositoryImpl();
  final LocationRepositoryImpl _locationRepository = LocationRepositoryImpl();
  final ServiceRepositoryImpl _serviceRepository = ServiceRepositoryImpl();
  final BookingRepositoryImpl _bookingRepository = BookingRepositoryImpl();

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void setUser(User? user) {
    _currentUser = user;
    notifyListeners();
  }

  Future<void> loadInitialData() async {
    try {
      final results = await Future.wait([
        _locationRepository.getLocations(),
        _serviceRepository.getServices(),
      ]);

      _locations = (results[0] as List<Location>)
          .where((l) => l.isActive)
          .toList();
      _services = (results[1] as List<Service>)
          .where((s) => s.isActive)
          .toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading initial data: $e');
    }
  }

  Future<void> loadBookings() async {
    if (!isLoggedIn) return;
    
    try {
      _bookings = await _bookingRepository.getBookings();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading bookings: $e');
    }
  }

  void addBooking(Booking booking) {
    _bookings.insert(0, booking);
    notifyListeners();
  }

  Future<void> logout() async {
    await _authRepository.logout();
    _currentUser = null;
    _bookings = [];
    notifyListeners();
  }
}

