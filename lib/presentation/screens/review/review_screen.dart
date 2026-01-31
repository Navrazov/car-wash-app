import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/di/service_locator.dart';
import '../../../domain/entities/booking.dart';
import '../../widgets/common/loading_indicator.dart';

class ReviewScreen extends StatefulWidget {
  final Booking booking;

  const ReviewScreen({super.key, required this.booking});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  int? _employeeRating;
  int _locationRating = 5;
  final TextEditingController _employeeCommentController = TextEditingController();
  final TextEditingController _locationCommentController = TextEditingController();
  bool _isLoading = false;
  bool _hasReview = false;

  @override
  void initState() {
    super.initState();
    _checkExistingReview();
  }

  @override
  void dispose() {
    _employeeCommentController.dispose();
    _locationCommentController.dispose();
    super.dispose();
  }

  Future<void> _checkExistingReview() async {
    try {
      final review = await sl.reviewRepository.getReviewByBooking(widget.booking.id);
      if (review != null && mounted) {
        setState(() {
          _hasReview = true;
          _employeeRating = review.employeeRating;
          _locationRating = review.locationRating;
          _employeeCommentController.text = review.employeeComment ?? '';
          _locationCommentController.text = review.locationComment ?? '';
        });
      }
    } catch (e) {
      // Ignore
    }
  }

  Future<void> _submitReview() async {
    if (_locationRating < 1 || _locationRating > 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Пожалуйста, оцените мойку'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await sl.reviewRepository.createReview({
        'bookingId': widget.booking.id,
        'employeeRating': _employeeRating,
        'locationRating': _locationRating,
        'employeeComment': _employeeCommentController.text.isNotEmpty
            ? _employeeCommentController.text
            : null,
        'locationComment': _locationCommentController.text.isNotEmpty
            ? _locationCommentController.text
            : null,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Спасибо за ваш отзыв!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop(true);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_hasReview ? 'Ваш отзыв' : 'Оставить отзыв'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.booking.location != null) ...[
              Text(
                widget.booking.location!.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${widget.booking.service?.name ?? "Услуга"} • ${widget.booking.bookingDate.day}.${widget.booking.bookingDate.month}.${widget.booking.bookingDate.year}',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
            ],
            if (_hasReview) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.success.withOpacity(0.5)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: AppColors.success, size: 24),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Вы уже оставили отзыв по этому бронированию.',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
            // Location Rating
            _buildRatingSection(
              title: 'Оцените мойку',
              subtitle: 'Как вам понравилось обслуживание?',
              rating: _locationRating,
              onRatingChanged: _hasReview ? (_) {} : (rating) => setState(() => _locationRating = rating),
              commentController: _locationCommentController,
              commentHint: 'Оставьте комментарий о мойке...',
              required: true,
              readOnly: _hasReview,
            ),

            const SizedBox(height: 32),

            // Employee Rating (optional)
            if (widget.booking.employee != null || widget.booking.employeeId != null)
              _buildRatingSection(
                title: 'Оцените мойщика',
                subtitle: 'Как вам понравился мойщик? (необязательно)',
                rating: _employeeRating,
                onRatingChanged: _hasReview ? (_) {} : (rating) => setState(() => _employeeRating = rating),
                commentController: _employeeCommentController,
                commentHint: 'Оставьте комментарий о мойщике...',
                required: false,
                readOnly: _hasReview,
              ),

            if (!_hasReview) ...[
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitReview,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppColors.primary,
                  ),
                  child: _isLoading
                      ? const LoadingIndicator(size: 24)
                      : const Text(
                          'Отправить отзыв',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRatingSection({
    required String title,
    required String subtitle,
    required int? rating,
    required ValueChanged<int> onRatingChanged,
    required TextEditingController commentController,
    required String commentHint,
    required bool required,
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        _buildStarRating(
          rating: rating ?? 0,
          onRatingChanged: onRatingChanged,
          required: required,
          readOnly: readOnly,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: commentController,
          maxLines: 4,
          readOnly: readOnly,
          decoration: InputDecoration(
            hintText: commentHint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: AppColors.surface,
          ),
        ),
      ],
    );
  }

  Widget _buildStarRating({
    required int rating,
    required ValueChanged<int> onRatingChanged,
    required bool required,
    bool readOnly = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final starIndex = index + 1;
        final isSelected = starIndex <= rating;

        return GestureDetector(
          onTap: readOnly ? null : () => onRatingChanged(starIndex),
          behavior: readOnly ? HitTestBehavior.deferToChild : HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Icon(
              isSelected ? Icons.star : Icons.star_border,
              size: 48,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        );
      }),
    );
  }
}
