import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/di/service_locator.dart';
import '../../../domain/entities/employee.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/empty_state.dart';

class EmployeesRatingsScreen extends StatefulWidget {
  const EmployeesRatingsScreen({super.key});

  @override
  State<EmployeesRatingsScreen> createState() => _EmployeesRatingsScreenState();
}

class _EmployeesRatingsScreenState extends State<EmployeesRatingsScreen> {
  List<Employee> _employees = [];
  bool _isLoading = true;
  String _sortBy = 'rating'; // 'rating' or 'reviews'

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    setState(() => _isLoading = true);
    try {
      // Get all employees from all locations
      final locations = await sl.locationRepository.getLocations();
      final allEmployees = <Employee>[];
      
      for (final location in locations) {
        try {
          final employees = await sl.employeeRepository.getByLocation(location.id);
          allEmployees.addAll(employees);
        } catch (e) {
          // Skip if error loading employees for this location
        }
      }
      
      setState(() {
        _employees = allEmployees;
        _sortEmployees();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка загрузки: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _sortEmployees() {
    _employees.sort((a, b) {
      if (_sortBy == 'rating') {
        final ratingCompare = b.rating.compareTo(a.rating);
        if (ratingCompare != 0) return ratingCompare;
        return b.totalReviews.compareTo(a.totalReviews);
      } else {
        final reviewsCompare = b.totalReviews.compareTo(a.totalReviews);
        if (reviewsCompare != 0) return reviewsCompare;
        return b.rating.compareTo(a.rating);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Рейтинг сотрудников'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort_rounded),
            onSelected: (value) {
              setState(() {
                _sortBy = value;
                _sortEmployees();
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'rating',
                child: Text('По рейтингу'),
              ),
              const PopupMenuItem(
                value: 'reviews',
                child: Text('По количеству отзывов'),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: LoadingIndicator())
          : _employees.isEmpty
              ? const EmptyState(
                  icon: Icons.person_off_rounded,
                  title: 'Нет доступных сотрудников',
                  subtitle: 'Сотрудники появятся позже',
                )
              : RefreshIndicator(
                  onRefresh: _loadEmployees,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _employees.length,
                    itemBuilder: (context, index) {
                      final employee = _employees[index];
                      return _EmployeeRatingCard(employee: employee);
                    },
                  ),
                ),
    );
  }
}

class _EmployeeRatingCard extends StatelessWidget {
  final Employee employee;

  const _EmployeeRatingCard({required this.employee});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary.withOpacity(0.15),
                  AppColors.primary.withOpacity(0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.person_rounded,
              color: AppColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  employee.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (employee.position != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    employee.position!,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (employee.rating > 0) ...[
                      const Icon(
                        Icons.star_rounded,
                        size: 16,
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        employee.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.warning,
                        ),
                      ),
                      if (employee.totalReviews > 0) ...[
                        const SizedBox(width: 8),
                        Text(
                          '(${employee.totalReviews} отзывов)',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ] else
                      Text(
                        'Нет оценок',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
