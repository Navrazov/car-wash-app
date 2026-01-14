import 'package:flutter/material.dart';
import '../models/models.dart';

class AppProvider extends ChangeNotifier {
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

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void setUser(User? user) {
    _currentUser = user;
    notifyListeners();
  }

  void setLocations(List<Location> locations) {
    _locations = locations;
    notifyListeners();
  }

  void setServices(List<Service> services) {
    _services = services;
    notifyListeners();
  }

  void setBookings(List<Booking> bookings) {
    _bookings = bookings;
    notifyListeners();
  }

  void addBooking(Booking booking) {
    _bookings.insert(0, booking);
    notifyListeners();
  }

  Future<void> logout() async {
    _currentUser = null;
    _bookings = [];
    notifyListeners();
  }
}

