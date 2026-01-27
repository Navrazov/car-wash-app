import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/booking.dart';
import '../common/status_badge.dart';
import '../common/info_row.dart';

class BookingCard extends StatelessWidget {
  final Booking booking;
  final VoidCallback? onPayTap;
  final VoidCallback? onCancelTap;
  final VoidCallback? onReviewTap;

  const BookingCard({
    super.key,
    required this.booking,
    this.onPayTap,
    this.onCancelTap,
    this.onReviewTap,
  });

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 12),
          if (booking.service != null) ...[
            Text(
              booking.service!.name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (booking.location != null)
            InfoRow(
              icon: Icons.location_on_outlined,
              text: booking.location!.name,
            ),
          InfoRow(
            icon: Icons.calendar_today_outlined,
            text: '${Formatters.formatDate(booking.bookingDate)} в ${booking.bookingTime}',
          ),
          if (booking.notes != null && booking.notes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              booking.notes!,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          if (booking.needsPayment) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onPayTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.warning,
                ),
                child: const Text('Оплатить'),
              ),
            ),
          ],
          if (booking.isCompleted && onReviewTap != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onReviewTap,
                icon: const Icon(Icons.star_outline_rounded, size: 18),
                label: const Text('Оставить отзыв'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
          if (booking.canBeCancelled && onCancelTap != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onCancelTap,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.error),
                  foregroundColor: AppColors.error,
                ),
                child: const Text('Отменить бронирование'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        StatusBadge(status: booking.status),
        Text(
          Formatters.formatPrice(booking.totalPrice),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.success,
          ),
        ),
      ],
    );
  }
}

