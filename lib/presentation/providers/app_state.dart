import 'package:flutter/material.dart';
import '../../core/di/service_locator.dart';
import '../../domain/entities/entities.dart';

class AppState extends ChangeNotifier {
  User? _currentUser;
  List<Location> _locations = [];
  List<Service> _services = [];
  List<Booking> _bookings = [];
  bool _isLoading = false;
  String? _error;

  User? get currentUser => _currentUser;
  List<Location> get locations => _locations;
  List<Service> get services => _services;
  List<Booking> get bookings => _bookings;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _currentUser != null;

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void setUser(User? user) {
    _currentUser = user;
    _error = null;
    notifyListeners();
  }

  void setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> loadInitialData() async {
    if (_isLoading) return;
    
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final results = await Future.wait([
        sl.locationRepository.getLocations(),
        sl.serviceRepository.getServices(),
      ]);

      _locations = (results[0] as List<Location>)
          .where((l) => l.isActive)
          .toList();
      _services = (results[1] as List<Service>)
          .where((s) => s.isActive)
          .toList();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      debugPrint('Error loading initial data: $e');
      notifyListeners();
    }
  }

  Future<void> loadBookings() async {
    if (!isLoggedIn) return;

    try {
      _bookings = await sl.bookingRepository.getBookings();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading bookings: $e');
    }
  }

  void addBooking(Booking booking) {
    _bookings.insert(0, booking);
    notifyListeners();
  }

  Future<bool> cancelBooking(String bookingId, String reason) async {
    try {
      await sl.bookingRepository.cancelBooking(bookingId, reason);
      final index = _bookings.indexWhere((b) => b.id == bookingId);
      if (index != -1) {
        final updatedBooking = _bookings[index].copyWith(status: 'cancelled');
        _bookings[index] = updatedBooking;
        notifyListeners();
      }

      await refreshProfile();
      return true;
    } catch (e) {
      debugPrint('Error cancelling booking: $e');
      return false;
    }
  }

  Future<void> refreshProfile() async {
    if (!isLoggedIn) return;

    try {
      final user = await sl.authRepository.getProfile();
      _currentUser = user;
      notifyListeners();
    } catch (e) {
      debugPrint('Error refreshing profile: $e');
    }
  }

  Future<void> logout() async {
    await sl.authRepository.logout();
    _currentUser = null;
    _bookings = [];
    sl.reset();
    notifyListeners();
  }
}
