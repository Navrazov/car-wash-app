import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math' as math;
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/di/service_locator.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/repositories/box_repository.dart';
import '../../providers/app_state.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/icon_box.dart';
import '../../widgets/common/loading_indicator.dart';
import '../auth/login_screen.dart';
import '../reviews/employee_reviews_screen.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen>
    with SingleTickerProviderStateMixin {
  int _currentStep = 0;
  Location? _selectedLocation;
  Service? _selectedService;
  Employee? _selectedEmployee;
  Box? _selectedBox;
  DateTime _selectedDate = DateTime.now();
  String _selectedTime = '10:00';
  final _notesController = TextEditingController();
  bool _isLoading = false;
  List<Box> _availableBoxes = [];
  List<BoxStatus> _boxStatuses = [];
  bool _loadingBoxes = false;
  Set<String> _occupiedTimeSlots = {};
  List<Employee> _employees = [];
  bool _loadingEmployees = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _notesController.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0D1B2A),
              AppColors.background,
            ],
            stops: [0.0, 0.3],
          ),
        ),
        child: Consumer<AppState>(
          builder: (context, state, _) {
            return Column(
              children: [
                _buildHeader(),
                _StepIndicator(
                  currentStep: _currentStep,
                  skipBoxStep: _selectedEmployee?.boxId != null,
                ),
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: _buildCurrentStep(state),
                    ),
                  ),
                ),
                _BottomButtons(
                  currentStep: _currentStep,
                  canProceed: _canProceed(),
                  isLoading: _isLoading,
                  onBack: () {
                    if (_currentStep == 5 && _selectedEmployee?.boxId != null) {
                      // If we skipped box step, go back to time step
                      setState(() => _currentStep = 3);
                    } else if (_currentStep > 0) {
                      setState(() => _currentStep--);
                    }
                    _animController.reset();
                    _animController.forward();
                  },
                  onNext: () => _handleNext(state),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00E5FF), Color(0xFF0099CC)],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 12,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: const Icon(
                Icons.calendar_month_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Запись на мойку',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Выберите удобное время',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStep(AppState state) {
    switch (_currentStep) {
      case 0:
        return _LocationStep(
          locations: state.locations,
          selected: _selectedLocation,
          onSelect: (l) {
            setState(() {
              _selectedLocation = l;
              _selectedBox = null; // Reset box when location changes
              _selectedEmployee = null; // Reset employee when location changes
            });
            _loadBoxStatuses(l.id);
          },
        );
      case 1:
        return _ServiceStep(
          services: state.services,
          selected: _selectedService,
          onSelect: (s) => setState(() => _selectedService = s),
        );
      case 2:
        return _EmployeeStep(
          employees: _employees,
          selected: _selectedEmployee,
          isLoading: _loadingEmployees,
          onSelect: (e) {
            setState(() {
              _selectedEmployee = e;
              // If employee has boxId, automatically set the box
              if (e?.boxId != null && _selectedLocation != null) {
                _selectedBox = Box(
                  id: e!.boxId!,
                  locationId: _selectedLocation!.id,
                  name: '', // Will be loaded later if needed
                  number: 0,
                );
              } else {
                _selectedBox = null;
              }
            });
          },
        );
      case 3:
        return _TimeStep(
          selectedDate: _selectedDate,
          selectedTime: _selectedTime,
          occupiedTimeSlots: _occupiedTimeSlots,
          onDateChanged: (d) {
            setState(() {
              _selectedDate = d;
              _selectedTime = '10:00'; // Reset time when date changes
            });
            _loadOccupiedTimeSlots();
          },
          onTimeChanged: (t) => setState(() => _selectedTime = t),
        );
      case 4:
        return _BoxStep(
          availableBoxes: _availableBoxes,
          boxStatuses: _boxStatuses,
          selectedBox: _selectedBox,
          selectedTime: _selectedTime,
          serviceDuration: _selectedService?.duration ?? 60,
          isLoading: _loadingBoxes,
          onSelect: (box) => setState(() => _selectedBox = box),
          onRefresh: () => _loadAvailableBoxes(),
        );
      case 5:
        return _ConfirmationStep(
          user: state.currentUser,
          location: _selectedLocation,
          service: _selectedService,
          employee: _selectedEmployee,
          box: _selectedBox,
          date: _selectedDate,
          time: _selectedTime,
          notesController: _notesController,
        );
      default:
        return const SizedBox();
    }
  }

  Future<void> _loadBoxStatuses(String locationId) async {
    setState(() => _loadingBoxes = true);
    try {
      final statuses = await sl.boxRepository.getBoxesStatus(
        locationId,
        date: _selectedDate,
      );
      if (mounted) {
        setState(() {
          _boxStatuses = statuses;
          _loadingBoxes = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingBoxes = false);
      }
    }
  }

  Future<void> _loadAvailableBoxes() async {
    if (_selectedLocation == null || _selectedService == null) return;
    
    setState(() => _loadingBoxes = true);
    try {
      final boxes = await sl.boxRepository.getAvailableBoxes(
        _selectedLocation!.id,
        _selectedDate,
        _selectedTime,
        _selectedService!.duration,
      );
      
      // Also load all box statuses to show which are busy
      final statuses = await sl.boxRepository.getBoxesStatus(
        _selectedLocation!.id,
        date: _selectedDate,
      );
      
      if (mounted) {
        setState(() {
          _availableBoxes = boxes;
          _boxStatuses = statuses;
          _loadingBoxes = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingBoxes = false);
      }
    }
  }

  Future<void> _loadEmployees() async {
    if (_selectedLocation == null) return;
    
    setState(() => _loadingEmployees = true);
    try {
      final employees = await sl.employeeRepository.getEmployeesByLocation(
        _selectedLocation!.id,
      );
      if (mounted) {
        setState(() {
          _employees = employees;
          _loadingEmployees = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingEmployees = false);
      }
    }
  }

  Future<void> _loadOccupiedTimeSlots() async {
    if (_selectedLocation == null || _selectedService == null) return;
    
    try {
      // Determine which box to check availability for
      String? targetBoxId;
      if (_selectedEmployee?.boxId != null) {
        targetBoxId = _selectedEmployee!.boxId;
      } else if (_selectedBox != null) {
        targetBoxId = _selectedBox!.id;
      }
      
      // Use efficient batch endpoint to get all occupied slots at once
      final occupiedSlots = await sl.boxRepository.getOccupiedTimeSlots(
        _selectedLocation!.id,
        _selectedDate,
        _selectedService!.duration,
        boxId: targetBoxId,
      );
      
      // Also load box statuses for display
      final statuses = await sl.boxRepository.getBoxesStatus(
        _selectedLocation!.id,
        date: _selectedDate,
      );
      
      if (mounted) {
        setState(() {
          _occupiedTimeSlots = occupiedSlots.toSet();
          _boxStatuses = statuses;
        });
      }
    } catch (e) {
      // Ignore errors
    }
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 0:
        return _selectedLocation != null;
      case 1:
        return _selectedService != null;
      case 2:
        return true; // Employee step (optional)
      case 3:
        return true; // Time step
      case 4:
        // Box step - skip if employee has boxId
        if (_selectedEmployee?.boxId != null) {
          return true;
        }
        return _selectedBox != null;
      case 5:
        return true; // Confirmation
      default:
        return false;
    }
  }

  Future<void> _handleNext(AppState state) async {
    if (_currentStep < 5) {
      // After selecting service, load employees
      if (_currentStep == 1 && _selectedLocation != null) {
        await _loadEmployees();
      }
      // After selecting employee, load occupied time slots and set box if employee has boxId
      if (_currentStep == 2 && _selectedLocation != null && _selectedService != null) {
        if (_selectedEmployee?.boxId != null) {
          // Load box details if employee has boxId
          final boxes = await sl.boxRepository.getBoxesByLocation(_selectedLocation!.id);
          final employeeBox = boxes.firstWhere(
            (box) => box.id == _selectedEmployee!.boxId,
            orElse: () => Box(
              id: _selectedEmployee!.boxId!,
              locationId: _selectedLocation!.id,
              name: 'Бокс',
              number: 0,
            ),
          );
          setState(() {
            _selectedBox = employeeBox;
          });
        }
        _loadOccupiedTimeSlots();
      }
      // Load available boxes when moving to box selection step (only if employee doesn't have boxId)
      if (_currentStep == 3 && _selectedLocation != null && _selectedService != null) {
        // Skip box step if employee has boxId
        if (_selectedEmployee?.boxId != null) {
          setState(() => _currentStep = 5); // Skip to confirmation
          _animController.reset();
          _animController.forward();
          return;
        }
        await _loadAvailableBoxes();
      }
      setState(() => _currentStep++);
      _animController.reset();
      _animController.forward();
    } else {
      await _submitBooking(state);
    }
  }

  Future<void> _submitBooking(AppState state) async {
    if (!state.isLoggedIn) {
      final result = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppColors.card,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (context) => _buildLoginPrompt(),
      );

      if (result == true && mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
        if (state.isLoggedIn) {
          await _submitBooking(state);
        }
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Use boxId from employee if available, otherwise use selected box
      final boxId = _selectedEmployee?.boxId ?? _selectedBox?.id;
      if (boxId == null) {
        throw Exception('Бокс не выбран');
      }
      
      await sl.bookingRepository.createBooking({
        'locationId': _selectedLocation!.id,
        'boxId': boxId,
        'serviceId': _selectedService!.id,
        'employeeId': _selectedEmployee?.id,
        'bookingDate': DateFormat('yyyy-MM-dd').format(_selectedDate),
        'bookingTime': _selectedTime,
        'notes':
            _notesController.text.isNotEmpty ? _notesController.text : null,
      });

      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded,
                    color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text('Ошибка: $e')),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  Widget _buildLoginPrompt() {
    return Container(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00E5FF), Color(0xFF0099CC)],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.4),
                  blurRadius: 25,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: const Icon(Icons.person_rounded, color: Colors.white, size: 40),
          ),
          const SizedBox(height: 24),
          const Text(
            'Требуется авторизация',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Войдите, чтобы создать запись\nи отслеживать свои визиты',
            style: TextStyle(
              fontSize: 15,
              color: AppColors.textSecondary.withOpacity(0.9),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Отмена'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.login_rounded, size: 20),
                      SizedBox(width: 8),
                      Text('Войти'),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF34D399), Color(0xFF10B981)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.success.withOpacity(0.4),
                    blurRadius: 25,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 44),
            ),
            const SizedBox(height: 24),
            const Text(
              'Запись создана! 🎉',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Мы ждём вас\n${Formatters.formatDate(_selectedDate)} в $_selectedTime',
              style: TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary.withOpacity(0.9),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  setState(() {
                    _currentStep = 0;
                    _selectedLocation = null;
                    _selectedService = null;
                    _selectedBox = null;
                    _selectedDate = DateTime.now();
                    _selectedTime = '10:00';
                    _notesController.clear();
                    _isLoading = false;
                    _availableBoxes = [];
                    _boxStatuses = [];
                    _occupiedTimeSlots = {};
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Отлично!'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final int currentStep;
  final bool skipBoxStep;

  const _StepIndicator({required this.currentStep, this.skipBoxStep = false});

  @override
  Widget build(BuildContext context) {
    // Adjust step numbers if box step is skipped
    final adjustedStep = skipBoxStep && currentStep > 3 ? currentStep + 1 : currentStep;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: Row(
        children: [
          _StepDot(step: 0, currentStep: adjustedStep, label: 'Филиал'),
          _StepLine(isActive: adjustedStep > 0),
          _StepDot(step: 1, currentStep: adjustedStep, label: 'Услуга'),
          _StepLine(isActive: adjustedStep > 1),
          _StepDot(step: 2, currentStep: adjustedStep, label: 'Сотрудник'),
          _StepLine(isActive: adjustedStep > 2),
          _StepDot(step: 3, currentStep: adjustedStep, label: 'Время'),
          _StepLine(isActive: adjustedStep > 3),
          if (!skipBoxStep) ...[
            _StepDot(step: 4, currentStep: adjustedStep, label: 'Бокс'),
            _StepLine(isActive: adjustedStep > 4),
          ],
          _StepDot(step: skipBoxStep ? 4 : 5, currentStep: adjustedStep, label: 'Подтверждение'),
        ],
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  final int step;
  final int currentStep;
  final String label;

  const _StepDot({
    required this.step,
    required this.currentStep,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = currentStep >= step;
    final isCompleted = currentStep > step;

    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            gradient: isActive
                ? const LinearGradient(
                    colors: [Color(0xFF00E5FF), Color(0xFF0099CC)],
                  )
                : null,
            color: isActive ? null : AppColors.surface,
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive ? AppColors.primary : AppColors.border,
              width: 2,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 10,
                      spreadRadius: 0,
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, size: 18, color: Colors.white)
                : Text(
                    '${step + 1}',
                    style: TextStyle(
                      color: isActive ? Colors.white : AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isActive ? AppColors.textPrimary : AppColors.textSecondary,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _StepLine extends StatelessWidget {
  final bool isActive;

  const _StepLine({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 3,
        margin: const EdgeInsets.only(bottom: 24),
        decoration: BoxDecoration(
          gradient: isActive
              ? const LinearGradient(
                  colors: [Color(0xFF00E5FF), Color(0xFF0099CC)],
                )
              : null,
          color: isActive ? null : AppColors.border,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _LocationStep extends StatefulWidget {
  final List<Location> locations;
  final Location? selected;
  final ValueChanged<Location> onSelect;

  const _LocationStep({
    required this.locations,
    this.selected,
    required this.onSelect,
  });

  @override
  State<_LocationStep> createState() => _LocationStepState();
}

class _LocationStepState extends State<_LocationStep> {
  bool _showMap = false;
  final MapController _mapController = MapController();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Выберите филиал',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
            ),
            // Toggle buttons
            Container(
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                children: [
                  _buildToggleButton(
                    icon: Icons.map_rounded,
                    isActive: _showMap,
                    onTap: () => setState(() => _showMap = true),
                  ),
                  _buildToggleButton(
                    icon: Icons.list_rounded,
                    isActive: !_showMap,
                    onTap: () => setState(() => _showMap = false),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Найдите ближайший к вам',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary.withOpacity(0.9),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.5,
          child: _showMap ? _buildMapView() : _buildListView(),
        ),
      ],
    );
  }

  Widget _buildToggleButton({
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Icon(
          icon,
          color: isActive ? AppColors.primary : AppColors.textSecondary,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildListView() {
    return SingleChildScrollView(
      child: Column(
        children: widget.locations.map(
          (l) => _LocationOption(
            location: l,
            isSelected: widget.selected?.id == l.id,
            onTap: () => widget.onSelect(l),
          ),
        ).toList(),
      ),
    );
  }

  Widget _buildMapView() {
    if (widget.locations.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: LoadingIndicator(size: 36),
        ),
      );
    }

    // Add test coordinates for locations without them
    final locationsWithCoords = widget.locations.map((location) {
      if (location.latitude == null || location.longitude == null) {
        final testCoords = _getTestCoordinates(location.id);
        return Location(
          id: location.id,
          name: location.name,
          address: location.address,
          phone: location.phone,
          workingHours: location.workingHours,
          description: location.description,
          isActive: location.isActive,
          latitude: testCoords['lat'],
          longitude: testCoords['lng'],
        );
      }
      return location;
    }).toList();

    // Center map on first location or default to Moscow
    final centerLatLng = locationsWithCoords.isNotEmpty
        ? LatLng(locationsWithCoords.first.latitude!, locationsWithCoords.first.longitude!)
        : LatLng(55.7558, 37.6176); // Moscow

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        center: centerLatLng,
        zoom: 12.0,
        maxZoom: 18.0,
        minZoom: 3.0,
        onTap: (tapPosition, point) {
          // Find nearest location to tap point
          Location? nearestLocation;
          double minDistance = double.infinity;
          for (final location in locationsWithCoords) {
            if (location.latitude != null && location.longitude != null) {
              final distance = _calculateDistance(
                point.latitude,
                point.longitude,
                location.latitude!,
                location.longitude!,
              );
              if (distance < minDistance) {
                minDistance = distance;
                nearestLocation = location;
              }
            }
          }
          if (nearestLocation != null) {
            widget.onSelect(nearestLocation);
          }
        },
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.car_wash_app',
        ),
        MarkerLayer(
          markers: locationsWithCoords.map((location) {
            final isSelected = widget.selected?.id == location.id;
            return Marker(
              point: LatLng(location.latitude!, location.longitude!),
              width: isSelected ? 50 : 40,
              height: isSelected ? 50 : 40,
              child: GestureDetector(
                onTap: () => widget.onSelect(location),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? AppColors.primary.withOpacity(0.9)
                        : AppColors.primary.withOpacity(0.8),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.textPrimary,
                      width: isSelected ? 3 : 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: isSelected ? 12 : 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.location_on_rounded,
                    color: AppColors.textPrimary,
                    size: isSelected ? 28 : 24,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Map<String, double> _getTestCoordinates(String locationId) {
    final testCoordinates = {
      '4': {'lat': 45.021233, 'lng': 39.101607}, // Демченко
    };

    if (testCoordinates.containsKey(locationId)) {
      return testCoordinates[locationId]!;
    }

    return {
      'lat': 45.021233,
      'lng': 39.101607,
    };
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // km
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) * math.cos(_toRadians(lat2)) *
        math.sin(dLon / 2) * math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double degrees) {
    return degrees * (math.pi / 180);
  }
}

class _LocationOption extends StatelessWidget {
  final Location location;
  final bool isSelected;
  final VoidCallback onTap;

  const _LocationOption({
    required this.location,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: 14),
      isSelected: isSelected,
      onTap: onTap,
      child: Row(
        children: [
          IconBox(
            icon: Icons.location_on_rounded,
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
            useGradient: isSelected,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  location.name,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  location.address,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary.withOpacity(0.9),
                  ),
                ),
                if (location.rating > 0) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 12,
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        location.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.warning,
                        ),
                      ),
                      if (location.totalReviews > 0) ...[
                        const SizedBox(width: 4),
                        Text(
                          '(${location.totalReviews})',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (isSelected)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00E5FF), Color(0xFF0099CC)],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 18),
            ),
        ],
      ),
    );
  }
}

class _EmployeeStep extends StatelessWidget {
  final List<Employee> employees;
  final Employee? selected;
  final bool isLoading;
  final ValueChanged<Employee?> onSelect;

  const _EmployeeStep({
    required this.employees,
    this.selected,
    required this.isLoading,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Выберите сотрудника',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          'Или пропустите этот шаг',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary.withOpacity(0.9),
          ),
        ),
        const SizedBox(height: 20),
        if (isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: LoadingIndicator(),
            ),
          )
        else if (employees.isEmpty)
          AppCard(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(
                    Icons.person_outline_rounded,
                    size: 48,
                    color: AppColors.textSecondary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Нет доступных сотрудников',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          )
        else ...[
          AppCard(
            margin: const EdgeInsets.only(bottom: 12),
            borderRadius: 16,
            isSelected: selected == null,
            onTap: () => onSelect(null),
            child: Row(
              children: [
                IconBox(
                  icon: Icons.person_outline_rounded,
                  color: selected == null
                      ? AppColors.primary
                      : AppColors.textSecondary,
                  useGradient: selected == null,
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text(
                    'Любой сотрудник',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (selected == null)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF00E5FF), Color(0xFF0099CC)],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check, color: Colors.white, size: 18),
                  ),
              ],
            ),
          ),
          ...employees.map(
            (e) => _EmployeeOption(
              employee: e,
              isSelected: selected?.id == e.id,
              onTap: () => onSelect(e),
            ),
          ),
        ],
      ],
    );
  }
}

class _EmployeeOption extends StatelessWidget {
  final Employee employee;
  final bool isSelected;
  final VoidCallback onTap;

  const _EmployeeOption({
    required this.employee,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      borderRadius: 16,
      isSelected: isSelected,
      onTap: onTap,
      child: Row(
        children: [
          IconBox(
            icon: Icons.person_rounded,
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
            useGradient: isSelected,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  employee.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (employee.position != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    employee.position!,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary.withOpacity(0.9),
                    ),
                  ),
                ],
                if (employee.rating > 0) ...[
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => EmployeeReviewsScreen(employee: employee),
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 14,
                          color: AppColors.warning,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          employee.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.warning,
                          ),
                        ),
                        if (employee.totalReviews > 0) ...[
                          const SizedBox(width: 4),
                          Text(
                            '(${employee.totalReviews})',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 12,
                            color: AppColors.textSecondary.withOpacity(0.5),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
                if (employee.specialization.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: employee.specialization
                        .take(3)
                        .map(
                          (spec) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              spec,
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
          if (isSelected)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF00E5FF), Color(0xFF0099CC)],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 18),
            ),
        ],
      ),
    );
  }
}

class _ServiceStep extends StatelessWidget {
  final List<Service> services;
  final Service? selected;
  final ValueChanged<Service> onSelect;

  const _ServiceStep({
    required this.services,
    this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final categories =
        services.map((s) => s.category ?? 'other').toSet().toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Выберите услугу',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          'Что мы сделаем для вас?',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary.withOpacity(0.9),
          ),
        ),
        const SizedBox(height: 20),
        ...categories.map((category) {
          final categoryServices =
              services.where((s) => s.category == category).toList();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surface.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  Formatters.getCategoryLabel(category),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ...categoryServices.map(
                (s) => _ServiceOption(
                  service: s,
                  isSelected: selected?.id == s.id,
                  onTap: () => onSelect(s),
                ),
              ),
              const SizedBox(height: 12),
            ],
          );
        }),
      ],
    );
  }
}

class _ServiceOption extends StatelessWidget {
  final Service service;
  final bool isSelected;
  final VoidCallback onTap;

  const _ServiceOption({
    required this.service,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      borderRadius: 16,
      isSelected: isSelected,
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.name,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
                if (service.description != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    service.description!,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary.withOpacity(0.9),
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 14,
                            color: AppColors.textSecondary.withOpacity(0.8),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            Formatters.formatDuration(service.duration),
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                Formatters.formatPrice(service.price),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: isSelected ? AppColors.primary : AppColors.success,
                ),
              ),
              if (isSelected)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00E5FF), Color(0xFF0099CC)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child:
                      const Icon(Icons.check, color: Colors.white, size: 14),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TimeStep extends StatelessWidget {
  final DateTime selectedDate;
  final String selectedTime;
  final Set<String> occupiedTimeSlots;
  final ValueChanged<DateTime> onDateChanged;
  final ValueChanged<String> onTimeChanged;

  const _TimeStep({
    required this.selectedDate,
    required this.selectedTime,
    required this.occupiedTimeSlots,
    required this.onDateChanged,
    required this.onTimeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Выберите дату и время',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          'Когда вам удобно?',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary.withOpacity(0.9),
          ),
        ),
        const SizedBox(height: 20),
        _DatePicker(
          selectedDate: selectedDate,
          onChanged: onDateChanged,
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Text(
              'Доступное время',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary.withOpacity(0.9),
              ),
            ),
            if (occupiedTimeSlots.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Красные - заняты',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.error.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 14),
        _TimeSlots(
          selectedTime: selectedTime,
          occupiedTimeSlots: occupiedTimeSlots,
          onChanged: onTimeChanged,
        ),
      ],
    );
  }
}

class _DatePicker extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onChanged;

  const _DatePicker({
    required this.selectedDate,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          IconBox(
            icon: Icons.calendar_month_rounded,
            color: AppColors.primary,
            useGradient: true,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  Formatters.formatDate(selectedDate),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  _getDayOfWeek(selectedDate),
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 30)),
              );
              if (date != null) {
                onChanged(date);
              }
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: const Text('Изменить'),
          ),
        ],
      ),
    );
  }

  String _getDayOfWeek(DateTime date) {
    final days = [
      'Понедельник',
      'Вторник',
      'Среда',
      'Четверг',
      'Пятница',
      'Суббота',
      'Воскресенье'
    ];
    return days[date.weekday - 1];
  }
}

class _TimeSlots extends StatelessWidget {
  final String selectedTime;
  final Set<String> occupiedTimeSlots;
  final ValueChanged<String> onChanged;

  const _TimeSlots({
    required this.selectedTime,
    required this.occupiedTimeSlots,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: AppConstants.timeSlots.map((time) {
        final isSelected = selectedTime == time;
        final isOccupied = occupiedTimeSlots.contains(time);
        
        return GestureDetector(
          onTap: isOccupied ? null : () => onChanged(time),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              gradient: isSelected && !isOccupied
                  ? const LinearGradient(
                      colors: [Color(0xFF00E5FF), Color(0xFF0099CC)],
                    )
                  : null,
              color: isOccupied 
                  ? AppColors.error.withOpacity(0.15)
                  : isSelected 
                      ? null 
                      : AppColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isOccupied
                    ? AppColors.error.withOpacity(0.3)
                    : isSelected
                        ? AppColors.primary
                        : AppColors.border,
              ),
              boxShadow: isSelected && !isOccupied
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 10,
                        spreadRadius: 0,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isOccupied) ...[
                  Icon(
                    Icons.block_rounded,
                    size: 14,
                    color: AppColors.error.withOpacity(0.7),
                  ),
                  const SizedBox(width: 4),
                ],
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isOccupied
                        ? AppColors.error.withOpacity(0.7)
                        : isSelected
                            ? Colors.white
                            : AppColors.textPrimary,
                    decoration: isOccupied ? TextDecoration.lineThrough : null,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _BoxStep extends StatelessWidget {
  final List<Box> availableBoxes;
  final List<BoxStatus> boxStatuses;
  final Box? selectedBox;
  final String selectedTime;
  final int serviceDuration;
  final bool isLoading;
  final ValueChanged<Box> onSelect;
  final VoidCallback onRefresh;

  const _BoxStep({
    required this.availableBoxes,
    required this.boxStatuses,
    this.selectedBox,
    required this.selectedTime,
    required this.serviceDuration,
    required this.isLoading,
    required this.onSelect,
    required this.onRefresh,
  });

  String _calculateEndTime(String startTime, int durationMinutes) {
    final parts = startTime.split(':');
    final hours = int.parse(parts[0]);
    final minutes = int.parse(parts[1]);
    final totalMinutes = hours * 60 + minutes + durationMinutes;
    final endHours = (totalMinutes ~/ 60) % 24;
    final endMinutes = totalMinutes % 60;
    return '${endHours.toString().padLeft(2, '0')}:${endMinutes.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final endTime = _calculateEndTime(selectedTime, serviceDuration);
    final availableIds = availableBoxes.map((b) => b.id).toSet();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Выберите бокс',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Время: $selectedTime - $endTime',
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onRefresh,
              icon: Icon(
                Icons.refresh_rounded,
                color: AppColors.textSecondary.withOpacity(0.7),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Свободен',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary.withOpacity(0.9),
                ),
              ),
              const SizedBox(width: 16),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Занят',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary.withOpacity(0.9),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: LoadingIndicator(),
            ),
          )
        else if (boxStatuses.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Icons.inbox_rounded,
                    size: 48,
                    color: AppColors.textSecondary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Нет боксов на этой локации',
                    style: TextStyle(
                      color: AppColors.textSecondary.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 1.0,
            ),
            itemCount: boxStatuses.length,
            itemBuilder: (context, index) {
              final status = boxStatuses[index];
              final isSelected = selectedBox?.id == status.boxId;
              final isAvailable = availableIds.contains(status.boxId);

              return GestureDetector(
                onTap: isAvailable
                    ? () => onSelect(Box(
                          id: status.boxId,
                          locationId: '',
                          name: status.name,
                          number: status.number,
                        ))
                    : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? const LinearGradient(
                            colors: [Color(0xFF00E5FF), Color(0xFF0099CC)],
                          )
                        : null,
                    color: isSelected
                        ? null
                        : isAvailable
                            ? AppColors.card
                            : AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : isAvailable
                              ? AppColors.success.withOpacity(0.5)
                              : AppColors.error.withOpacity(0.3),
                      width: isSelected ? 2 : 1.5,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 15,
                              spreadRadius: 0,
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white.withOpacity(0.2)
                              : isAvailable
                                  ? AppColors.success.withOpacity(0.15)
                                  : AppColors.error.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isAvailable
                              ? Icons.check_circle_rounded
                              : Icons.block_rounded,
                          size: 28,
                          color: isSelected
                              ? Colors.white
                              : isAvailable
                                  ? AppColors.success
                                  : AppColors.error,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        status.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? Colors.white
                              : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isAvailable ? 'Свободен' : 'Занят',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isSelected
                              ? Colors.white.withOpacity(0.8)
                              : isAvailable
                                  ? AppColors.success
                                  : AppColors.error,
                        ),
                      ),
                      if (!isAvailable) ...[
                        const SizedBox(height: 4),
                        if (status.isOccupied && status.currentBooking != null)
                          Text(
                            'занят до ${status.currentBooking!.endTime}',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.error.withOpacity(0.8),
                            ),
                            textAlign: TextAlign.center,
                          )
                        else if (status.nextBooking != null)
                          Text(
                            'запись в ${status.nextBooking!.startTime}',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.error.withOpacity(0.8),
                            ),
                            textAlign: TextAlign.center,
                          )
                        else
                          Text(
                            'недоступен',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.error.withOpacity(0.8),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

class _ConfirmationStep extends StatelessWidget {
  final dynamic user;
  final Location? location;
  final Service? service;
  final Employee? employee;
  final Box? box;
  final DateTime date;
  final String time;
  final TextEditingController notesController;

  const _ConfirmationStep({
    this.user,
    this.location,
    this.service,
    this.employee,
    this.box,
    required this.date,
    required this.time,
    required this.notesController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Подтверждение записи',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          'Проверьте данные и подтвердите',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary.withOpacity(0.9),
          ),
        ),
        const SizedBox(height: 24),
        _Summary(
          location: location,
          service: service,
          employee: employee,
          box: box,
          date: date,
          time: time,
        ),
        const SizedBox(height: 20),
        TextField(
          controller: notesController,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: 'Комментарий',
            hintText: 'Дополнительные пожелания (необязательно)',
            prefixIcon: Container(
              margin: const EdgeInsets.all(12),
              child: Icon(
                Icons.note_alt_outlined,
                color: AppColors.textSecondary.withOpacity(0.7),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Summary extends StatelessWidget {
  final Location? location;
  final Service? service;
  final Employee? employee;
  final Box? box;
  final DateTime date;
  final String time;

  const _Summary({
    this.location,
    this.service,
    this.employee,
    this.box,
    required this.date,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.card,
            AppColors.primary.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          _SummaryRow(
            icon: Icons.location_on_rounded,
            label: 'Филиал',
            value: location?.name ?? '—',
          ),
          _SummaryRow(
            icon: Icons.car_repair_rounded,
            label: 'Услуга',
            value: service?.name ?? '—',
          ),
          if (employee != null)
            _SummaryRow(
              icon: Icons.person_rounded,
              label: 'Сотрудник',
              value: employee!.name,
            ),
          _SummaryRow(
            icon: Icons.garage_rounded,
            label: 'Бокс',
            value: box?.name ?? '—',
          ),
          _SummaryRow(
            icon: Icons.calendar_month_rounded,
            label: 'Дата',
            value: Formatters.formatDate(date),
          ),
          _SummaryRow(
            icon: Icons.access_time_rounded,
            label: 'Время',
            value: time,
          ),
          const SizedBox(height: 16),
          Container(
            height: 1,
            color: AppColors.border.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Итого к оплате',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFF34D399), Color(0xFF10B981)],
                ).createShader(bounds),
                child: Text(
                  Formatters.formatPrice(service?.price ?? 0),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary.withOpacity(0.7)),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: AppColors.textSecondary.withOpacity(0.9),
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _BottomButtons extends StatelessWidget {
  final int currentStep;
  final bool canProceed;
  final bool isLoading;
  final VoidCallback onBack;
  final VoidCallback onNext;

  const _BottomButtons({
    required this.currentStep,
    required this.canProceed,
    required this.isLoading,
    required this.onBack,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        border:
            Border(top: BorderSide(color: AppColors.border.withOpacity(0.3))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (currentStep > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: onBack,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.arrow_back_rounded, size: 20),
                      SizedBox(width: 8),
                      Text('Назад'),
                    ],
                  ),
                ),
              ),
            if (currentStep > 0) const SizedBox(width: 14),
            Expanded(
              flex: 2,
              child: Container(
                height: 56,
                decoration: canProceed && !isLoading
                    ? BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00E5FF), Color(0xFF0099CC)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.4),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      )
                    : null,
                child: ElevatedButton(
                  onPressed: canProceed && !isLoading ? onNext : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        canProceed ? Colors.transparent : AppColors.surface,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: isLoading
                      ? const LoadingIndicator(color: Colors.white)
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(currentStep == 4 ? 'Записаться' : 'Далее'),
                            const SizedBox(width: 8),
                            Icon(
                              currentStep == 4
                                  ? Icons.check_circle_rounded
                                  : Icons.arrow_forward_rounded,
                              size: 20,
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
