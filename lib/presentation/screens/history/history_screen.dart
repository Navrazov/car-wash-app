import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/booking/booking_card.dart';
import '../auth/login_screen.dart';

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
                return BookingCard(booking: state.bookings[index]);
              },
            ),
          );
        },
      ),
    );
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

