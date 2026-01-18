import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/repositories/auth_repository_impl.dart';
import '../../providers/app_state.dart';
import '../onboarding/onboarding_screen.dart';
import '../auth/login_screen.dart';
import '../../../main.dart';

class SplashScreen extends StatefulWidget {
  final bool hasSeenOnboarding;
  final bool hasToken;

  const SplashScreen({
    super.key,
    required this.hasSeenOnboarding,
    required this.hasToken,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _logoController.forward();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(milliseconds: 2000));

    if (!mounted) return;

    // Если онбординг не просмотрен - показываем онбординг
    if (!widget.hasSeenOnboarding) {
      _navigateTo(const OnboardingScreen());
      return;
    }

    // Если нет токена - показываем экран логина
    if (!widget.hasToken) {
      _navigateTo(const LoginScreen(isOnboarding: true));
      return;
    }

    // Есть токен - пробуем получить профиль
    try {
      final authRepo = AuthRepositoryImpl();
      final user = await authRepo.getProfile();
      if (mounted) {
        context.read<AppState>().setUser(user);
        _navigateTo(const MainScreen());
      }
    } catch (e) {
      // Токен невалиден - идём на логин
      if (mounted) {
        _navigateTo(const LoginScreen(isOnboarding: true));
      }
    }
  }

  void _navigateTo(Widget screen) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.05),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOut,
              )),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  void dispose() {
    _logoController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF050A15),
              Color(0xFF0A0F1E),
              Color(0xFF0D1B2A),
              Color(0xFF0A0F1E),
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Background decorations
            _buildBackgroundDecorations(),
            // Content
            SafeArea(
              child: Center(
                child: AnimatedBuilder(
                  animation: Listenable.merge([_logoController, _pulseController]),
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeAnimation.value,
                      child: Transform.scale(
                        scale: _scaleAnimation.value * _pulseAnimation.value,
                        child: child,
                      ),
                    );
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo
                      _buildLogo(),
                      const SizedBox(height: 32),
                      // Title
                      _buildTitle(),
                      const SizedBox(height: 80),
                      // Loading
                      _buildLoader(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundDecorations() {
    return Stack(
      children: [
        // Top right glow
        Positioned(
          top: -150,
          right: -150,
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, _) {
              return Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.12 + _pulseAnimation.value * 0.03),
                      AppColors.primary.withOpacity(0.0),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        // Bottom left glow
        Positioned(
          bottom: -100,
          left: -100,
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, _) {
              return Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.purple.withOpacity(0.08 + _pulseAnimation.value * 0.02),
                      AppColors.purple.withOpacity(0.0),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLogo() {
    return Hero(
      tag: 'app_logo',
      child: Container(
        width: 130,
        height: 130,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF00E5FF),
              Color(0xFF00D4FF),
              Color(0xFF0099CC),
              Color(0xFF006699),
            ],
          ),
          borderRadius: BorderRadius.circular(38),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.5),
              blurRadius: 50,
              spreadRadius: 10,
            ),
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 100,
              spreadRadius: 20,
            ),
          ],
        ),
        child: const Icon(
          Icons.local_car_wash_rounded,
          size: 70,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [
              Color(0xFF00E5FF),
              AppColors.primaryLight,
              AppColors.primary,
            ],
          ).createShader(bounds),
          child: const Text(
            'АвтоМойка',
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Чистота вашего авто',
          style: TextStyle(
            fontSize: 17,
            color: AppColors.textSecondary.withOpacity(0.8),
            letterSpacing: 1,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildLoader() {
    return Column(
      children: [
        SizedBox(
          width: 50,
          height: 50,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(
              AppColors.primary.withOpacity(0.7),
            ),
          ),
        ),
        const SizedBox(height: 20),
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, _) {
            return Opacity(
              opacity: 0.5 + _pulseAnimation.value * 0.3,
              child: Text(
                'Загрузка...',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary.withOpacity(0.7),
                  letterSpacing: 0.5,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
