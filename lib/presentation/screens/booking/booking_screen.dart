import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/entities.dart';
import '../../../data/repositories/booking_repository_impl.dart';
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

class _BookingScreenState extends State<BookingScreen> {
  int _currentStep = 0;
  Location? _selectedLocation;
  Service? _selectedService;
  DateTime _selectedDate = DateTime.now();
  String _selectedTime = '10:00';
  final _notesController = TextEditingController();
  final _bookingRepository = BookingRepositoryImpl();
  bool _isLoading = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Запись на мойку')),
      body: Consumer<AppState>(
        builder: (context, state, _) {
          return Column(
            children: [
              _StepIndicator(currentStep: _currentStep),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: _buildCurrentStep(state),
                ),
              ),
              _BottomButtons(
                currentStep: _currentStep,
                canProceed: _canProceed(),
                isLoading: _isLoading,
                onBack: () => setState(() => _currentStep--),
                onNext: () => _handleNext(state),
              ),
            ],
          );
        },
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
    } else {
      await _submitBooking(state);
    }
  }

  Future<void> _submitBooking(AppState state) async {
    if (!state.isLoggedIn) {
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Требуется авторизация'),
          content: const Text('Для создания записи необходимо войти в систему'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Войти'),
            ),
          ],
        ),
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
      await _bookingRepository.createBooking({
        'locationId': _selectedLocation!.id,
        'serviceId': _selectedService!.id,
        'bookingDate': DateFormat('yyyy-MM-dd').format(_selectedDate),
        'bookingTime': _selectedTime,
        'notes': _notesController.text.isNotEmpty ? _notesController.text : null,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Запись успешно создана!'),
            backgroundColor: AppColors.success,
          ),
        );

        setState(() {
          _currentStep = 0;
          _selectedLocation = null;
          _selectedService = null;
          _selectedDate = DateTime.now();
          _selectedTime = '10:00';
          _notesController.clear();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

class _StepIndicator extends StatelessWidget {
  final int currentStep;

  const _StepIndicator({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          _StepDot(step: 0, currentStep: currentStep, label: 'Локация'),
          _StepLine(isActive: currentStep > 0),
          _StepDot(step: 1, currentStep: currentStep, label: 'Услуга'),
          _StepLine(isActive: currentStep > 1),
          _StepDot(step: 2, currentStep: currentStep, label: 'Время'),
          _StepLine(isActive: currentStep > 2),
          _StepDot(step: 3, currentStep: currentStep, label: 'Подтверждение'),
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
    
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : AppColors.surface,
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive ? AppColors.primary : AppColors.border,
              width: 2,
            ),
          ),
          child: Center(
            child: isActive && currentStep > step
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : Text(
                    '${step + 1}',
                    style: TextStyle(
                      color: isActive ? Colors.white : AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 6),
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
        height: 2,
        margin: const EdgeInsets.only(bottom: 20),
        color: isActive ? AppColors.primary : AppColors.border,
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
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 16),
        ...locations.map((l) => _LocationOption(
          location: l,
          isSelected: selected?.id == l.id,
          onTap: () => onSelect(l),
        )),
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
      margin: const EdgeInsets.only(bottom: 12),
      isSelected: isSelected,
      onTap: onTap,
      child: Row(
        children: [
          IconBox(
            icon: Icons.location_on_rounded,
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  location.name,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  location.address,
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          if (isSelected)
            const Icon(Icons.check_circle_rounded, color: AppColors.primary),
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
    final categories = services.map((s) => s.category ?? 'other').toSet().toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Выберите услугу',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 16),
        ...categories.map((category) {
          final categoryServices = services.where((s) => s.category == category).toList();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                Formatters.getCategoryLabel(category),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              ...categoryServices.map((s) => _ServiceOption(
                service: s,
                isSelected: selected?.id == s.id,
                onTap: () => onSelect(s),
              )),
              const SizedBox(height: 16),
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
      margin: const EdgeInsets.only(bottom: 10),
      borderRadius: 14,
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
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                if (service.description != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    service.description!,
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      Formatters.formatDuration(service.duration),
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                Formatters.formatPrice(service.price),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? AppColors.primary : AppColors.success,
                ),
              ),
              if (isSelected)
                const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20),
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
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 16),
        _DatePicker(
          selectedDate: selectedDate,
          onChanged: onDateChanged,
        ),
        const SizedBox(height: 20),
        const Text(
          'Время',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
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
          const Icon(Icons.calendar_month_rounded, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              Formatters.formatDate(selectedDate),
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
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
            child: const Text('Изменить'),
          ),
        ],
      ),
    );
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
      spacing: 10,
      runSpacing: 10,
      children: AppConstants.timeSlots.map((time) {
        final isSelected = selectedTime == time;
        return GestureDetector(
          onTap: () => onChanged(time),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : AppColors.card,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.border,
              ),
            ),
            child: Text(
              time,
              style: TextStyle(
                fontSize: 14,
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
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: notesController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Комментарий (необязательно)',
            prefixIcon: Icon(Icons.note_outlined),
            hintText: 'Дополнительные пожелания',
          ),
        ),
        const SizedBox(height: 24),
        _Summary(
          location: location,
          service: service,
          date: date,
          time: time,
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
    return AppCard(
      child: Column(
        children: [
          _SummaryRow('Филиал', location?.name ?? '—'),
          _SummaryRow('Услуга', service?.name ?? '—'),
          _SummaryRow('Дата', Formatters.formatDate(date)),
          _SummaryRow('Время', time),
          const Divider(color: AppColors.border, height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Итого',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              Text(
                Formatters.formatPrice(service?.price ?? 0),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.success,
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
  final String label;
  final String value;

  const _SummaryRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
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
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (currentStep > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: onBack,
                  child: const Text('Назад'),
                ),
              ),
            if (currentStep > 0) const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: canProceed && !isLoading ? onNext : null,
                child: isLoading
                    ? const LoadingIndicator()
                    : Text(currentStep == 3 ? 'Записаться' : 'Далее'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

