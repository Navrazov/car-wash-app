import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/storage/secure_storage.dart';
import '../auth/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _bgAnimController;
  late AnimationController _contentAnimController;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  final List<OnboardingPage> _pages = const [
    OnboardingPage(
      icon: Icons.local_car_wash_rounded,
      iconGradient: [Color(0xFF00E5FF), Color(0xFF00D4FF), Color(0xFF0099CC)],
      title: 'Добро пожаловать!',
      subtitle: 'Лучший сервис для записи\nна автомойку в вашем городе',
      bgColor1: Color(0xFF0A1628),
      bgColor2: Color(0xFF0D2137),
    ),
    OnboardingPage(
      icon: Icons.calendar_month_rounded,
      iconGradient: [Color(0xFFD946EF), Color(0xFFA855F7), Color(0xFF7C3AED)],
      title: 'Удобная запись',
      subtitle: 'Выберите удобное время и филиал\nза несколько секунд',
      bgColor1: Color(0xFF150A28),
      bgColor2: Color(0xFF1A0D37),
    ),
    OnboardingPage(
      icon: Icons.star_rounded,
      iconGradient: [Color(0xFFFCD34D), Color(0xFFF59E0B), Color(0xFFD97706)],
      title: 'Бонусы и скидки',
      subtitle: 'Накапливайте баллы и получайте\nэксклюзивные предложения',
      bgColor1: Color(0xFF1A1508),
      bgColor2: Color(0xFF2D2010),
    ),
    OnboardingPage(
      icon: Icons.phone_iphone_rounded,
      iconGradient: [Color(0xFF34D399), Color(0xFF10B981), Color(0xFF059669)],
      title: 'Быстрая регистрация',
      subtitle: 'Только номер телефона — никаких\nсложных форм и паролей',
      bgColor1: Color(0xFF0A1A15),
      bgColor2: Color(0xFF0D2820),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _bgAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _contentAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _scaleAnim = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _contentAnimController, curve: Curves.elasticOut),
    );

    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _contentAnimController, curve: Curves.easeOut),
    );

    _contentAnimController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _bgAnimController.dispose();
    _contentAnimController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    } else {
      _navigateToLogin();
    }
  }

  void _navigateToLogin() async {
    // Помечаем онбординг как просмотренный
    await SecureStorage().setOnboardingSeen();

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const LoginScreen(isOnboarding: true),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, 0.1),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOut,
              )),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _bgAnimController,
        builder: (context, child) {
          final page = _pages[_currentPage];
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(page.bgColor1, page.bgColor2,
                      _bgAnimController.value)!,
                  Color.lerp(page.bgColor2, page.bgColor1,
                      _bgAnimController.value)!,
                  const Color(0xFF0A0F1E),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
            child: child,
          );
        },
        child: SafeArea(
          child: Column(
            children: [
              // Skip button
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _navigateToLogin,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        backgroundColor: AppColors.surface.withOpacity(0.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Пропустить',
                            style: TextStyle(
                              color: AppColors.textSecondary.withOpacity(0.9),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 18,
                            color: AppColors.textSecondary.withOpacity(0.7),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Page content
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() => _currentPage = index);
                    _contentAnimController.reset();
                    _contentAnimController.forward();
                  },
                  itemCount: _pages.length,
                  itemBuilder: (context, index) {
                    return FadeTransition(
                      opacity: _fadeAnim,
                      child: ScaleTransition(
                        scale: _scaleAnim,
                        child: _buildPageContent(_pages[index]),
                      ),
                    );
                  },
                ),
              ),
              // Bottom section
              _buildBottomSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPageContent(OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon container with glow effect
          _buildAnimatedIcon(page),
          const SizedBox(height: 56),
          // Title
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: page.iconGradient,
            ).createShader(bounds),
            child: Text(
              page.title,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 0.5,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            page.subtitle,
            style: TextStyle(
              fontSize: 17,
              color: AppColors.textSecondary.withOpacity(0.9),
              height: 1.6,
              letterSpacing: 0.3,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedIcon(OnboardingPage page) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer glow
        AnimatedBuilder(
          animation: _bgAnimController,
          builder: (context, _) {
            return Container(
              width: 200 + _bgAnimController.value * 20,
              height: 200 + _bgAnimController.value * 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    page.iconGradient[0].withOpacity(0.15),
                    page.iconGradient[1].withOpacity(0.05),
                    Colors.transparent,
                  ],
                ),
              ),
            );
          },
        ),
        // Middle ring
        AnimatedBuilder(
          animation: _bgAnimController,
          builder: (context, _) {
            return Container(
              width: 160 + _bgAnimController.value * 10,
              height: 160 + _bgAnimController.value * 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: page.iconGradient[1].withOpacity(0.2),
                  width: 1,
                ),
              ),
            );
          },
        ),
        // Icon container
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: page.iconGradient,
            ),
            borderRadius: BorderRadius.circular(42),
            boxShadow: [
              BoxShadow(
                color: page.iconGradient[1].withOpacity(0.5),
                blurRadius: 40,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Icon(
            page.icon,
            size: 70,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomSection() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        children: [
          // Page indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _pages.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
                margin: const EdgeInsets.symmetric(horizontal: 5),
                width: _currentPage == index ? 40 : 10,
                height: 10,
                decoration: BoxDecoration(
                  gradient: _currentPage == index
                      ? LinearGradient(
                          colors: _pages[_currentPage].iconGradient)
                      : null,
                  color: _currentPage == index ? null : AppColors.border,
                  borderRadius: BorderRadius.circular(5),
                  boxShadow: _currentPage == index
                      ? [
                          BoxShadow(
                            color: _pages[_currentPage]
                                .iconGradient[1]
                                .withOpacity(0.5),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          // Next button
          _buildNextButton(),
        ],
      ),
    );
  }

  Widget _buildNextButton() {
    final isLastPage = _currentPage == _pages.length - 1;
    final gradient = _pages[_currentPage].iconGradient;

    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradient),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: gradient[1].withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _nextPage,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isLastPage ? 'Начать' : 'Далее',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 10),
            Icon(
              isLastPage
                  ? Icons.rocket_launch_rounded
                  : Icons.arrow_forward_rounded,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingPage {
  final IconData icon;
  final List<Color> iconGradient;
  final String title;
  final String subtitle;
  final Color bgColor1;
  final Color bgColor2;

  const OnboardingPage({
    required this.icon,
    required this.iconGradient,
    required this.title,
    required this.subtitle,
    required this.bgColor1,
    required this.bgColor2,
  });
}
