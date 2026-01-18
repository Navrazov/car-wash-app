import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary - яркий циан с неоновым эффектом
  static const Color primary = Color(0xFF00D4FF);
  static const Color primaryDark = Color(0xFF00A8CC);
  static const Color primaryLight = Color(0xFF5DE0FF);
  
  // Background - глубокий темный с синеватым оттенком
  static const Color background = Color(0xFF0A0F1E);
  static const Color card = Color(0xFF111827);
  static const Color surface = Color(0xFF1A2236);
  static const Color border = Color(0xFF2D3748);
  
  // Text
  static const Color textPrimary = Color(0xFFF7FAFC);
  static const Color textSecondary = Color(0xFF9CA3AF);
  
  // Status colors - более яркие и насыщенные
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFF34D399);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFBBF24);
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFF87171);
  
  // Accent colors
  static const Color purple = Color(0xFFA855F7);
  static const Color purpleLight = Color(0xFFC084FC);
  static const Color pink = Color(0xFFEC4899);
  static const Color indigo = Color(0xFF6366F1);
  
  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF00D4FF),
      Color(0xFF0099CC),
      Color(0xFF006699),
    ],
  );
  
  static const LinearGradient promoGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0E7490),
      Color(0xFF0891B2),
      Color(0xFF06B6D4),
    ],
  );
  
  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF059669),
      Color(0xFF10B981),
    ],
  );
  
  static const LinearGradient purpleGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF7C3AED),
      Color(0xFFA855F7),
    ],
  );
  
  static const LinearGradient warningGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFD97706),
      Color(0xFFF59E0B),
    ],
  );
  
  // Shimmer colors for loading states
  static const Color shimmerBase = Color(0xFF1A2236);
  static const Color shimmerHighlight = Color(0xFF2D3748);
}
