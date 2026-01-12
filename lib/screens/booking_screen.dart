import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../providers/app_provider.dart';
import '../services/api_service.dart';
import '../models/models.dart';

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
  
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _carModelController = TextEditingController();
  final _carNumberController = TextEditingController();

  final List<String> _timeSlots = [
    '09:00', '10:00', '11:00', '12:00', '13:00',
    '14:00', '15:00', '16:00', '17:00', '18:00', '19:00', '20:00',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Запись на мойку'),
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          return Column(
            children: [
              _buildStepIndicator(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: _buildCurrentStep(provider),
                ),
              ),
              _buildBottomButtons(provider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          _buildStepDot(0, 'Локация'),
          _buildStepLine(0),
          _buildStepDot(1, 'Услуга'),
          _buildStepLine(1),
          _buildStepDot(2, 'Время'),
          _buildStepLine(2),
          _buildStepDot(3, 'Данные'),
        ],
      ),
    );
  }

  Widget _buildStepDot(int step, String label) {
    final isActive = _currentStep >= step;
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isActive ? AppTheme.primaryColor : AppTheme.surfaceColor,
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive ? AppTheme.primaryColor : AppTheme.borderColor,
              width: 2,
            ),
          ),
          child: Center(
            child: isActive && _currentStep > step
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : Text(
                    '${step + 1}',
                    style: TextStyle(
                      color: isActive ? Colors.white : AppTheme.textSecondary,
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
            color: isActive ? AppTheme.textPrimary : AppTheme.textSecondary,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(int step) {
    final isActive = _currentStep > step;
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 20),
        color: isActive ? AppTheme.primaryColor : AppTheme.borderColor,
      ),
    );
  }

  Widget _buildCurrentStep(AppProvider provider) {
    switch (_currentStep) {
      case 0:
        return _buildLocationStep(provider);
      case 1:
        return _buildServiceStep(provider);
      case 2:
        return _buildTimeStep();
      case 3:
        return _buildDataStep();
      default:
        return const SizedBox();
    }
  }

  Widget _buildLocationStep(AppProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Выберите филиал',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 16),
        ...provider.locations.map((location) => _buildLocationOption(location)),
      ],
    );
  }

  Widget _buildLocationOption(Location location) {
    final isSelected = _selectedLocation?.id == location.id;
    return GestureDetector(
      onTap: () => setState(() => _selectedLocation = location),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : AppTheme.borderColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: (isSelected ? AppTheme.primaryColor : AppTheme.textSecondary).withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.location_on_rounded,
                color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
              ),
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
                    style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: AppTheme.primaryColor),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceStep(AppProvider provider) {
    final categories = provider.services.map((s) => s.category ?? 'Другое').toSet().toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Выберите услугу',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 16),
        ...categories.map((category) {
          final servicesInCategory = provider.services.where((s) => s.category == category).toList();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                category,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 8),
              ...servicesInCategory.map((service) => _buildServiceOption(service)),
              const SizedBox(height: 16),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildServiceOption(Service service) {
    final isSelected = _selectedService?.id == service.id;
    return GestureDetector(
      onTap: () => setState(() => _selectedService = service),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : AppTheme.borderColor,
            width: isSelected ? 2 : 1,
          ),
        ),
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
                      style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded, size: 14, color: AppTheme.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        '${service.duration} мин',
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
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
                  '${service.price.toInt()} ₽',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? AppTheme.primaryColor : AppTheme.successColor,
                  ),
                ),
                if (isSelected)
                  const Icon(Icons.check_circle_rounded, color: AppTheme.primaryColor, size: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Выберите дату и время',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 16),
        _buildDatePicker(),
        const SizedBox(height: 20),
        const Text(
          'Время',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 12),
        _buildTimeSlots(),
      ],
    );
  }

  Widget _buildDatePicker() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_month_rounded, color: AppTheme.primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              DateFormat('d MMMM yyyy', 'ru').format(_selectedDate),
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
          OutlinedButton(
            onPressed: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 30)),
              );
              if (date != null) {
                setState(() => _selectedDate = date);
              }
            },
            child: const Text('Изменить'),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSlots() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _timeSlots.map((time) {
        final isSelected = _selectedTime == time;
        return GestureDetector(
          onTap: () => setState(() => _selectedTime = time),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primaryColor : AppTheme.cardColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? AppTheme.primaryColor : AppTheme.borderColor,
              ),
            ),
            child: Text(
              time,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppTheme.textPrimary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDataStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ваши данные',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Имя *',
            prefixIcon: Icon(Icons.person_outline_rounded),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Телефон *',
            prefixIcon: Icon(Icons.phone_outlined),
            hintText: '+7 (900) 123-45-67',
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _carModelController,
          decoration: const InputDecoration(
            labelText: 'Марка автомобиля',
            prefixIcon: Icon(Icons.directions_car_outlined),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _carNumberController,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            labelText: 'Номер автомобиля',
            prefixIcon: Icon(Icons.pin_outlined),
            hintText: 'А001АА77',
          ),
        ),
        const SizedBox(height: 24),
        _buildSummary(),
      ],
    );
  }

  Widget _buildSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        children: [
          _buildSummaryRow('Филиал', _selectedLocation?.name ?? '—'),
          _buildSummaryRow('Услуга', _selectedService?.name ?? '—'),
          _buildSummaryRow('Дата', DateFormat('d MMMM yyyy', 'ru').format(_selectedDate)),
          _buildSummaryRow('Время', _selectedTime),
          const Divider(color: AppTheme.borderColor, height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Итого',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              Text(
                '${_selectedService?.price.toInt() ?? 0} ₽',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.successColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textSecondary)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildBottomButtons(AppProvider provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        border: Border(top: BorderSide(color: AppTheme.borderColor)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _currentStep--),
                  child: const Text('Назад'),
                ),
              ),
            if (_currentStep > 0) const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _canProceed() ? () => _handleNext(provider) : null,
                child: Text(_currentStep == 3 ? 'Записаться' : 'Далее'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 0:
        return _selectedLocation != null;
      case 1:
        return _selectedService != null;
      case 2:
        return true;
      case 3:
        return _nameController.text.isNotEmpty && _phoneController.text.isNotEmpty;
      default:
        return false;
    }
  }

  void _handleNext(AppProvider provider) async {
    if (_currentStep < 3) {
      setState(() => _currentStep++);
    } else {
      await _submitBooking(provider);
    }
  }

  Future<void> _submitBooking(AppProvider provider) async {
    final api = context.read<ApiService>();

    try {
      // Находим или создаем клиента
      Customer? customer = await api.getCustomerByPhone(_phoneController.text);
      
      if (customer == null) {
        customer = await api.createCustomer({
          'name': _nameController.text,
          'phone': _phoneController.text,
          'car_model': _carModelController.text,
          'car_number': _carNumberController.text,
        });
      }

      // Создаем бронирование
      await api.createBooking({
        'customer_id': customer.id,
        'location_id': _selectedLocation!.id,
        'service_id': _selectedService!.id,
        'booking_date': DateFormat('yyyy-MM-dd').format(_selectedDate),
        'booking_time': _selectedTime,
        'total_price': _selectedService!.price,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Запись успешно создана!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        
        // Сбрасываем форму
        setState(() {
          _currentStep = 0;
          _selectedLocation = null;
          _selectedService = null;
          _selectedDate = DateTime.now();
          _selectedTime = '10:00';
          _nameController.clear();
          _phoneController.clear();
          _carModelController.clear();
          _carNumberController.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }
}

