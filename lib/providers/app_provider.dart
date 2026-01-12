import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class AppProvider extends ChangeNotifier {
  Customer? _currentCustomer;
  List<Location> _locations = [];
  List<Service> _services = [];
  List<Booking> _bookings = [];
  bool _isLoading = false;

  Customer? get currentCustomer => _currentCustomer;
  List<Location> get locations => _locations;
  List<Service> get services => _services;
  List<Booking> get bookings => _bookings;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentCustomer != null;

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void setCustomer(Customer? customer) {
    _currentCustomer = customer;
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

  Future<void> saveCustomerId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('customer_id', id);
  }

  Future<String?> getCustomerId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('customer_id');
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('customer_id');
    _currentCustomer = null;
    _bookings = [];
    notifyListeners();
  }
}

