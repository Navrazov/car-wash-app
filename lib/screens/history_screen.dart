import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('История'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.history_rounded,
                size: 40,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'История записей',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Здесь будут отображаться\nваши прошлые записи',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.login_rounded, size: 18),
              label: const Text('Войти'),
            ),
          ],
        ),
      ),
    );
  }
}

