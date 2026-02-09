import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dropdown_search/dropdown_search.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/di/service_locator.dart';
import '../../../domain/entities/car.dart';
import '../../providers/app_state.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/icon_box.dart';

// ════════════════════════════════════════════════════════════════
//  My Cars Screen — list of user's cars
// ════════════════════════════════════════════════════════════════

class MyCarsScreen extends StatefulWidget {
  const MyCarsScreen({super.key});

  @override
  State<MyCarsScreen> createState() => _MyCarsScreenState();
}

class _MyCarsScreenState extends State<MyCarsScreen> {
  bool _isLoading = false;

  Future<void> _deleteCar(String carId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить автомобиль?'),
        content: const Text('Это действие нельзя отменить.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      final cars = await sl.authRepository.deleteCar(carId);
      if (mounted) {
        final user = context.read<AppState>().currentUser;
        if (user != null) context.read<AppState>().setUser(user.copyWith(cars: cars));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _setDefault(String carId) async {
    setState(() => _isLoading = true);
    try {
      final cars = await sl.authRepository.setDefaultCar(carId);
      if (mounted) {
        final user = context.read<AppState>().currentUser;
        if (user != null) context.read<AppState>().setUser(user.copyWith(cars: cars));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openAddEdit({Car? car}) async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => AddCarScreen(editCar: car)),
    );
    if (ok == true && mounted) context.read<AppState>().refreshProfile();
  }

  // ── build ───────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои автомобили'),
        actions: [
          IconButton(icon: const Icon(Icons.add_rounded), onPressed: () => _openAddEdit()),
        ],
      ),
      body: Consumer<AppState>(
        builder: (context, state, _) {
          final cars = state.currentUser?.cars ?? [];

          if (_isLoading) return const Center(child: LoadingIndicator());

          if (cars.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(color: AppColors.surface, shape: BoxShape.circle),
                    child: Icon(Icons.directions_car_outlined, size: 64, color: AppColors.textSecondary.withOpacity(0.5)),
                  ),
                  const SizedBox(height: 24),
                  const Text('Нет автомобилей', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  const Text('Добавьте свой автомобиль', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _openAddEdit(),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Добавить автомобиль'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: cars.length + 1,
            itemBuilder: (context, i) {
              if (i == cars.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: OutlinedButton.icon(
                    onPressed: () => _openAddEdit(),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Добавить автомобиль'),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  ),
                );
              }
              final car = cars[i];
              return _CarCard(
                car: car,
                onDelete: () => _deleteCar(car.id!),
                onSetDefault: () => _setDefault(car.id!),
                onEdit: () => _openAddEdit(car: car),
              );
            },
          );
        },
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  _CarCard
// ════════════════════════════════════════════════════════════════

class _CarCard extends StatelessWidget {
  final Car car;
  final VoidCallback onDelete;
  final VoidCallback onSetDefault;
  final VoidCallback onEdit;

  const _CarCard({required this.car, required this.onDelete, required this.onSetDefault, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: 14),
      isSelected: car.isDefault,
      child: Column(
        children: [
          Row(children: [
            IconBox(
              icon: Icons.directions_car_rounded,
              color: car.isDefault ? AppColors.primary : AppColors.textSecondary,
              useGradient: car.isDefault,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(car.displayName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
                  if (car.isDefault)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                      child: const Text('Основной', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary)),
                    ),
                ]),
                const SizedBox(height: 6),
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(car.plateNumber, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                  ),
                  if (car.year != null) ...[
                    const SizedBox(width: 10),
                    Text('${car.year} г.', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  ],
                ]),
              ]),
            ),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            if (!car.isDefault)
              Expanded(
                child: OutlinedButton(
                  onPressed: onSetDefault,
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 10)),
                  child: const Text('Сделать основным', style: TextStyle(fontSize: 12)),
                ),
              ),
            if (!car.isDefault) const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: onEdit,
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 10)),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [Icon(Icons.edit_rounded, size: 16), SizedBox(width: 4), Text('Изменить', style: TextStyle(fontSize: 12))],
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 40,
              child: OutlinedButton(
                onPressed: onDelete,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: BorderSide(color: AppColors.error.withOpacity(0.3)),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                child: const Icon(Icons.delete_outline_rounded, size: 18),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  Add / Edit Car Screen
// ════════════════════════════════════════════════════════════════

class AddCarScreen extends StatefulWidget {
  final Car? editCar;
  const AddCarScreen({super.key, this.editCar});

  @override
  State<AddCarScreen> createState() => _AddCarScreenState();
}

class _AddCarScreenState extends State<AddCarScreen> {
  final _formKey = GlobalKey<FormState>();
  final _plateCtl = TextEditingController();
  final _yearCtl = TextEditingController();

  List<String> _brandNames = [];
  bool _loadingBrands = true;
  List<String> _models = [];
  bool _loadingModels = false;

  String? _selectedBrand;
  String? _selectedModel;
  bool _isSaving = false;

  bool get _isEditing => widget.editCar != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _selectedBrand = widget.editCar!.brand;
      _selectedModel = widget.editCar!.model;
      _plateCtl.text = widget.editCar!.plateNumber;
      if (widget.editCar!.year != null) _yearCtl.text = widget.editCar!.year.toString();
    }
    _loadBrands();
  }

  @override
  void dispose() {
    _plateCtl.dispose();
    _yearCtl.dispose();
    super.dispose();
  }

  Future<void> _loadBrands() async {
    try {
      final data = await sl.authRepository.getCarBrands();
      if (mounted) {
        setState(() {
          _brandNames = data.map((b) => b['name'] as String).toList();
          _loadingBrands = false;
        });
        if (_selectedBrand != null) _loadModels(_selectedBrand!);
      }
    } catch (_) {
      if (mounted) setState(() => _loadingBrands = false);
    }
  }

  Future<void> _loadModels(String brand) async {
    setState(() {
      _loadingModels = true;
      if (!_isEditing || _selectedBrand != widget.editCar!.brand) _selectedModel = null;
    });
    try {
      final models = await sl.authRepository.getCarModels(brand);
      if (mounted) setState(() { _models = models; _loadingModels = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingModels = false);
    }
  }

  String? _validatePlate(String? value) {
    if (value == null || value.trim().isEmpty) return 'Введите госномер';
    final p = value.trim().toUpperCase();
    final ru = RegExp(r'^[АВЕКМНОРСТУХ]\d{3}[АВЕКМНОРСТУХ]{2}\d{2,3}$');
    final en = RegExp(r'^[ABEKMHOPCTYX]\d{3}[ABEKMHOPCTYX]{2}\d{2,3}$');
    if (!ru.hasMatch(p) && !en.hasMatch(p)) return 'Формат: А123БВ77 или А123БВ777';
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBrand == null || _selectedModel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Выберите марку и модель'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final data = <String, dynamic>{
        'brand': _selectedBrand,
        'model': _selectedModel,
        'plateNumber': _plateCtl.text.trim().toUpperCase(),
        if (_yearCtl.text.isNotEmpty) 'year': int.parse(_yearCtl.text),
      };

      final cars = _isEditing
          ? await sl.authRepository.updateCar(widget.editCar!.id!, data)
          : await sl.authRepository.addCar(data);

      if (mounted) {
        final user = context.read<AppState>().currentUser;
        if (user != null) context.read<AppState>().setUser(user.copyWith(cars: cars));
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(_isEditing ? 'Автомобиль обновлён' : 'Автомобиль добавлен'),
          ]),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Ошибка: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ));
      }
    }
  }

  // ── helpers ─────────────────────────────────────────────────

  InputDecoration _dropdownDecoration(String hint, IconData icon) => InputDecoration(
    hintText: hint,
    prefixIcon: Icon(icon, size: 22),
    prefixIconConstraints: const BoxConstraints(minWidth: 52),
    filled: true,
    fillColor: AppColors.surface,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.border)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.border)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );

  PopupProps<String> _sheetPopup(String title) => PopupProps.modalBottomSheet(
    showSearchBox: true,
    modalBottomSheetProps: const ModalBottomSheetProps(
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    ),
    searchFieldProps: TextFieldProps(
      decoration: InputDecoration(
        hintText: 'Поиск...',
        prefixIcon: const Icon(Icons.search_rounded),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    ),
    title: Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 16),
        Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
      ]),
    ),
    itemBuilder: (ctx, item, isDisabled, isSelected) => ListTile(
      title: Text(item, style: TextStyle(fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500, color: isSelected ? AppColors.primary : AppColors.textPrimary)),
      trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: AppColors.primary) : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
    ),
    constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
  );

  // ── build ───────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Редактировать авто' : 'Добавить авто')),
      body: _loadingBrands
          ? const Center(child: LoadingIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  // illustration
                  Center(
                    child: Container(
                      width: 100, height: 100,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 20)],
                      ),
                      child: const Icon(Icons.directions_car_rounded, size: 48, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── Brand ──
                  const _Label('Марка автомобиля'),
                  const SizedBox(height: 8),
                  DropdownSearch<String>(
                    selectedItem: _selectedBrand,
                    items: (filter, _) => _brandNames
                        .where((b) => b.toLowerCase().contains(filter.toLowerCase()))
                        .toList(),
                    onChanged: (brand) {
                      if (brand != null && brand != _selectedBrand) {
                        setState(() => _selectedBrand = brand);
                        _loadModels(brand);
                      }
                    },
                    decoratorProps: DropDownDecoratorProps(decoration: _dropdownDecoration('Выберите марку', Icons.search_rounded)),
                    popupProps: _sheetPopup('Выберите марку'),
                    validator: (v) => (v == null || v.isEmpty) ? 'Выберите марку' : null,
                  ),
                  const SizedBox(height: 24),

                  // ── Model ──
                  const _Label('Модель'),
                  const SizedBox(height: 8),
                  if (_selectedBrand == null)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.arrow_upward_rounded, size: 18, color: AppColors.textSecondary.withOpacity(0.5)),
                        const SizedBox(width: 8),
                        const Text('Сначала выберите марку', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                      ]),
                    )
                  else if (_loadingModels)
                    const Center(child: Padding(padding: EdgeInsets.all(20), child: LoadingIndicator(size: 24)))
                  else
                    DropdownSearch<String>(
                      selectedItem: _selectedModel,
                      items: (filter, _) => _models
                          .where((m) => m.toLowerCase().contains(filter.toLowerCase()))
                          .toList(),
                      onChanged: (m) => setState(() => _selectedModel = m),
                      decoratorProps: DropDownDecoratorProps(decoration: _dropdownDecoration('Выберите модель', Icons.car_repair_rounded)),
                      popupProps: _sheetPopup('Модели $_selectedBrand'),
                      validator: (v) => (v == null || v.isEmpty) ? 'Выберите модель' : null,
                    ),
                  const SizedBox(height: 24),

                  // ── Plate number ──
                  const _Label('Госномер'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _plateCtl,
                    textCapitalization: TextCapitalization.characters,
                    validator: _validatePlate,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: 2),
                    decoration: InputDecoration(
                      hintText: 'А123БВ777',
                      prefixIcon: const Icon(Icons.credit_card_rounded, size: 22),
                      prefixIconConstraints: const BoxConstraints(minWidth: 52),
                      helperText: 'Формат: А123БВ77 или А123БВ777',
                      helperStyle: TextStyle(fontSize: 12, color: AppColors.textSecondary.withOpacity(0.7)),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Year ──
                  const _Label('Год выпуска (необязательно)'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _yearCtl,
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.isEmpty) return null;
                      final y = int.tryParse(v);
                      if (y == null || y < 1980 || y > DateTime.now().year + 1) return 'Год: 1980-${DateTime.now().year + 1}';
                      return null;
                    },
                    decoration: const InputDecoration(
                      hintText: '2023',
                      prefixIcon: Icon(Icons.calendar_today_rounded, size: 22),
                      prefixIconConstraints: BoxConstraints(minWidth: 52),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Preview card ──
                  if (_selectedBrand != null && _selectedModel != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [AppColors.primary.withOpacity(0.08), AppColors.primary.withOpacity(0.03)]),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                      ),
                      child: Row(children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.directions_car_rounded, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('$_selectedBrand $_selectedModel', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                            if (_plateCtl.text.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(_plateCtl.text.toUpperCase(), style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, letterSpacing: 1)),
                            ],
                          ]),
                        ),
                      ]),
                    ),
                  const SizedBox(height: 32),

                  // ── Save ──
                  SizedBox(
                    width: double.infinity, height: 56,
                    child: Container(
                      decoration: !_isSaving
                          ? BoxDecoration(
                              gradient: const LinearGradient(colors: [Color(0xFF00E5FF), Color(0xFF0099CC)]),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 5))],
                            )
                          : null,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _save,
                        icon: _isSaving ? const SizedBox.shrink() : Icon(_isEditing ? Icons.check_rounded : Icons.add_rounded, size: 22),
                        label: _isSaving
                            ? const LoadingIndicator(size: 22)
                            : Text(_isEditing ? 'Сохранить' : 'Добавить автомобиль', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ]),
              ),
            ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary));
}
