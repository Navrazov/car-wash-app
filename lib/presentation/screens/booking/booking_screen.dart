import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/di/service_locator.dart';
import '../../../domain/entities/entities.dart';
import '../../providers/app_state.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/icon_box.dart';
import '../../widgets/common/loading_indicator.dart';
import '../auth/login_screen.dart';

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
  DateTime _selectedDate = DateTime.now();
  String _selectedTime = '10:00';
  final _notesController = TextEditingController();
  bool _isLoading = false;

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
                _StepIndicator(currentStep: _currentStep),
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
                    setState(() => _currentStep--);
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
          onSelect: (l) => setState(() => _selectedLocation = l),
        );
      case 1:
        return _ServiceStep(
          services: state.services,
          selected: _selectedService,
          onSelect: (s) => setState(() => _selectedService = s),
        );
      case 2:
        return _TimeStep(
          selectedDate: _selectedDate,
          selectedTime: _selectedTime,
          onDateChanged: (d) => setState(() => _selectedDate = d),
          onTimeChanged: (t) => setState(() => _selectedTime = t),
        );
      case 3:
        return _ConfirmationStep(
          user: state.currentUser,
          location: _selectedLocation,
          service: _selectedService,
          date: _selectedDate,
          time: _selectedTime,
          notesController: _notesController,
        );
      default:
        return const SizedBox();
    }
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 0:
        return _selectedLocation != null;
      case 1:
        return _selectedService != null;
      case 2:
      case 3:
        return true;
      default:
        return false;
    }
  }

  Future<void> _handleNext(AppState state) async {
    if (_currentStep < 3) {
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
      await sl.bookingRepository.createBooking({
        'locationId': _selectedLocation!.id,
        'serviceId': _selectedService!.id,
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
                    _selectedDate = DateTime.now();
                    _selectedTime = '10:00';
                    _notesController.clear();
                    _isLoading = false;
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

  const _StepIndicator({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Row(
        children: [
          _StepDot(step: 0, currentStep: currentStep, label: 'Филиал'),
          _StepLine(isActive: currentStep > 0),
          _StepDot(step: 1, currentStep: currentStep, label: 'Услуга'),
          _StepLine(isActive: currentStep > 1),
          _StepDot(step: 2, currentStep: currentStep, label: 'Время'),
          _StepLine(isActive: currentStep > 2),
          _StepDot(step: 3, currentStep: currentStep, label: 'Готово'),
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

class _LocationStep extends StatelessWidget {
  final List<Location> locations;
  final Location? selected;
  final ValueChanged<Location> onSelect;

  const _LocationStep({
    required this.locations,
    this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Выберите филиал',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
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
        ...locations.map(
          (l) => _LocationOption(
            location: l,
            isSelected: selected?.id == l.id,
            onTap: () => onSelect(l),
          ),
        ),
      ],
    );
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
  final ValueChanged<DateTime> onDateChanged;
  final ValueChanged<String> onTimeChanged;

  const _TimeStep({
    required this.selectedDate,
    required this.selectedTime,
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
        Text(
          'Доступное время',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary.withOpacity(0.9),
          ),
        ),
        const SizedBox(height: 14),
        _TimeSlots(
          selectedTime: selectedTime,
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
  final ValueChanged<String> onChanged;

  const _TimeSlots({
    required this.selectedTime,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: AppConstants.timeSlots.map((time) {
        final isSelected = selectedTime == time;
        return GestureDetector(
          onTap: () => onChanged(time),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? const LinearGradient(
                      colors: [Color(0xFF00E5FF), Color(0xFF0099CC)],
                    )
                  : null,
              color: isSelected ? null : AppColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.border,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 10,
                        spreadRadius: 0,
                      ),
                    ]
                  : null,
            ),
            child: Text(
              time,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ConfirmationStep extends StatelessWidget {
  final dynamic user;
  final Location? location;
  final Service? service;
  final DateTime date;
  final String time;
  final TextEditingController notesController;

  const _ConfirmationStep({
    this.user,
    this.location,
    this.service,
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
  final DateTime date;
  final String time;

  const _Summary({
    this.location,
    this.service,
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
                            Text(currentStep == 3 ? 'Записаться' : 'Далее'),
                            const SizedBox(width: 8),
                            Icon(
                              currentStep == 3
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
