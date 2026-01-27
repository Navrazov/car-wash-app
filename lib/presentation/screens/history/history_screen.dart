import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/entities/booking.dart';
import '../../../core/di/service_locator.dart';
import '../../providers/app_state.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/booking/booking_card.dart';
import '../auth/login_screen.dart';
import '../review/review_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().loadBookings();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('История')),
      body: Consumer<AppState>(
        builder: (context, state, _) {
          if (!state.isLoggedIn) {
            return _buildLoginPrompt();
          }

          if (state.bookings.isEmpty) {
            return const EmptyState(
              icon: Icons.event_busy_rounded,
              title: 'Записей пока нет',
              subtitle: 'Создайте первую запись на мойку',
            );
          }

          return RefreshIndicator(
            onRefresh: state.loadBookings,
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: state.bookings.length,
              itemBuilder: (context, index) {
                final booking = state.bookings[index];
                return BookingCard(
                  booking: booking,
                  onCancelTap: booking.canBeCancelled
                      ? () => _showCancelDialog(context, state, booking)
                      : null,
                  onReviewTap: booking.isCompleted
                      ? () => _showReviewScreen(context, booking)
                      : null,
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _showCancelDialog(BuildContext context, AppState state, Booking booking) async {
    String? cancelReason;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Отмена бронирования'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Вы уверены, что хотите отменить бронирование?'),
            const SizedBox(height: 16),
            const Text(
              'Причина отмены (необязательно):',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            TextField(
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Укажите причину отмены...',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.all(12),
              ),
              onChanged: (value) => cancelReason = value,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Отменить бронирование'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        final success = await state.cancelBooking(
          booking.id,
          cancelReason ?? 'Отменено пользователем',
        );

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Бронирование успешно отменено'),
              backgroundColor: Colors.green,
            ),
          );
          // Обновляем список бронирований
          state.loadBookings();
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Не удалось отменить бронирование'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ошибка: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _showReviewScreen(BuildContext context, Booking booking) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReviewScreen(booking: booking),
      ),
    );
    
    if (result == true && mounted) {
      // Refresh bookings to show updated review status
      context.read<AppState>().loadBookings();
    }
  }

  Widget _buildLoginPrompt() {
    return EmptyState(
      icon: Icons.history_rounded,
      title: 'История записей',
      subtitle: 'Войдите, чтобы увидеть\nисторию ваших записей',
      action: ElevatedButton.icon(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        },
        icon: const Icon(Icons.login_rounded, size: 18),
        label: const Text('Войти'),
      ),
    );
  }
}

