import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import '../../../core/theme/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../data/repositories/auth_repository_impl.dart';
import '../../providers/app_state.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../../main.dart';

class LoginScreen extends StatefulWidget {
  final bool isOnboarding;

  const LoginScreen({
    super.key,
    this.isOnboarding = false,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _phoneController = TextEditingController();
  final _authRepository = AuthRepositoryImpl();
  final List<TextEditingController> _codeControllers = List.generate(
    4,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _codeFocusNodes = List.generate(4, (_) => FocusNode());

  // Маска для телефона: +7 (999) 123-45-67
  final _phoneMaskFormatter = MaskTextInputFormatter(
    mask: '+7 (###) ###-##-##',
    filter: {'#': RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  bool _isCodeSent = false;
  bool _isLoading = false;
  int _countdown = 60;
  Timer? _timer;
  String? _devCode;
  bool _isPhoneValid = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _animController.forward();

    // Слушаем изменения в поле телефона для валидации
    _phoneController.addListener(_validatePhone);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _phoneController.dispose();
    for (var c in _codeControllers) {
      c.dispose();
    }
    for (var f in _codeFocusNodes) {
      f.dispose();
    }
    _animController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _validatePhone() {
    final unmasked = _phoneMaskFormatter.getUnmaskedText();
    setState(() {
      _isPhoneValid = unmasked.length == 10;
    });
  }

  String _getFormattedPhone() {
    // Получаем чистые цифры и добавляем 7 в начало
    final unmasked = _phoneMaskFormatter.getUnmaskedText();
    return '7$unmasked';
  }

  void _startCountdown() {
    _countdown = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_countdown > 0) {
        setState(() => _countdown--);
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _sendCode() async {
    if (!_isPhoneValid) {
      _showError('Введите корректный номер телефона');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final formattedPhone = _getFormattedPhone();
      final apiClient = ApiClient();
      final response = await apiClient.post<Map<String, dynamic>>(
        '/auth/send-code',
        body: {'phone': formattedPhone},
        auth: false,
      );

      if (mounted) {
        setState(() {
          _isCodeSent = true;
          _isLoading = false;
          if (response.containsKey('devCode')) {
            _devCode = response['devCode'].toString();
          }
        });
        _startCountdown();

        // В режиме разработки показываем код и автоматически заполняем
        if (_devCode != null) {
          _showDevCodeBanner(_devCode!);
          _autoFillDevCode(_devCode!);
        } else {
          _showSuccess('Код отправлен на ваш номер');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError(e.toString());
      }
    }
  }

  void _showDevCodeBanner(String code) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.developer_mode_rounded,
                  color: AppColors.warning, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '🔧 Dev режим: SMS отключен',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Ваш код: $code (уже введён)',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1A1A2E),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _autoFillDevCode(String code) {
    Future.delayed(const Duration(milliseconds: 400), () {
      for (int i = 0; i < code.length && i < 4; i++) {
        Future.delayed(Duration(milliseconds: i * 120), () {
          if (mounted) {
            _codeControllers[i].text = code[i];
            setState(() {});
            if (i == 3) {
              // Автоматически отправляем после заполнения
              Future.delayed(const Duration(milliseconds: 300), () {
                if (mounted) _verifyCode();
              });
            }
          }
        });
      }
    });
  }

  String _getFullCode() {
    return _codeControllers.map((c) => c.text).join();
  }

  Future<void> _verifyCode() async {
    final code = _getFullCode();
    if (code.length != 4) {
      _showError('Введите 4-значный код');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final formattedPhone = _getFormattedPhone();
      final user = await _authRepository.verifyCode(formattedPhone, code);

      if (mounted) {
        context.read<AppState>().setUser(user);
        _showSuccess('Добро пожаловать! 🎉');

        await Future.delayed(const Duration(milliseconds: 500));

        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const MainScreen(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.1),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOut,
                    )),
                    child: child,
                  ),
                );
              },
              transitionDuration: const Duration(milliseconds: 400),
            ),
            (route) => false,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError(e.toString());
      }
    }
  }

  Future<void> _loginWithTelegram() async {
    // Telegram Bot для авторизации
    // В реальном приложении здесь будет интеграция с Telegram Login Widget
    // Для демо открываем Telegram бота
    const botUsername = 'CarWashAuthBot'; // Замените на своего бота
    final telegramUrl = Uri.parse('https://t.me/$botUsername?start=auth');

    try {
      if (await canLaunchUrl(telegramUrl)) {
        await launchUrl(telegramUrl, mode: LaunchMode.externalApplication);
        _showInfo(
          'Перейдите в Telegram и нажмите "Start" для авторизации',
        );
      } else {
        _showError('Не удалось открыть Telegram');
      }
    } catch (e) {
      _showError('Ошибка: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.error_outline_rounded,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.check_circle_outline_rounded,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showInfo(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.info_outline_rounded,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
      ),
    );
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
            _buildDecorations(),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (!widget.isOnboarding)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: _buildBackButton(),
                          ),
                        SizedBox(height: widget.isOnboarding ? 40 : 20),
                        _buildLogo(),
                        const SizedBox(height: 32),
                        _buildTitle(),
                        const SizedBox(height: 40),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 400),
                          transitionBuilder: (child, animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0.15, 0),
                                  end: Offset.zero,
                                ).animate(CurvedAnimation(
                                  parent: animation,
                                  curve: Curves.easeOut,
                                )),
                                child: child,
                              ),
                            );
                          },
                          child:
                              !_isCodeSent ? _buildPhoneStep() : _buildCodeStep(),
                        ),
                        const SizedBox(height: 32),
                        _buildTermsText(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDecorations() {
    return Stack(
      children: [
        Positioned(
          top: -100,
          right: -100,
          child: AnimatedBuilder(
            animation: _pulseAnim,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnim.value,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.primary.withOpacity(0.15),
                        AppColors.primary.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Positioned(
          bottom: 100,
          left: -80,
          child: AnimatedBuilder(
            animation: _pulseAnim,
            builder: (context, child) {
              return Transform.scale(
                scale: 1.2 - _pulseAnim.value * 0.2,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.purple.withOpacity(0.1),
                        AppColors.purple.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBackButton() {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface.withOpacity(0.5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border.withOpacity(0.5)),
        ),
        child: const Icon(
          Icons.arrow_back_rounded,
          color: AppColors.textPrimary,
          size: 22,
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Center(
      child: Hero(
        tag: 'app_logo',
        child: Container(
          width: 110,
          height: 110,
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
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.5),
                blurRadius: 40,
                spreadRadius: 5,
              ),
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 80,
                spreadRadius: 10,
              ),
            ],
          ),
          child: const Icon(
            Icons.local_car_wash_rounded,
            color: Colors.white,
            size: 54,
          ),
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFF00E5FF), AppColors.primaryLight, AppColors.primary],
          ).createShader(bounds),
          child: Text(
            _isCodeSent ? 'Подтверждение' : 'Вход в аккаунт',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _isCodeSent
              ? 'Введите код из SMS\n${_phoneController.text}'
              : 'Введите номер телефона для входа\nили регистрации',
          style: TextStyle(
            fontSize: 15,
            color: AppColors.textSecondary.withOpacity(0.9),
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPhoneStep() {
    return Column(
      key: const ValueKey('phone'),
      children: [
        // Поле ввода телефона с маской
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.surface,
                AppColors.surface.withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _isPhoneValid
                  ? AppColors.success.withOpacity(0.5)
                  : AppColors.border.withOpacity(0.5),
              width: _isPhoneValid ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            inputFormatters: [_phoneMaskFormatter],
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
            decoration: InputDecoration(
              hintText: '+7 (900) 123-45-67',
              hintStyle: TextStyle(
                color: AppColors.textSecondary.withOpacity(0.4),
                fontWeight: FontWeight.w500,
                fontSize: 20,
              ),
              prefixIcon: Container(
                margin: const EdgeInsets.only(left: 16, right: 12),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _isPhoneValid
                        ? AppColors.success.withOpacity(0.15)
                        : AppColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _isPhoneValid ? Icons.check_rounded : Icons.phone_rounded,
                    color: _isPhoneValid ? AppColors.success : AppColors.primary,
                    size: 22,
                  ),
                ),
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 72),
              suffixIcon: _isPhoneValid
                  ? Container(
                      margin: const EdgeInsets.only(right: 16),
                      child: Icon(
                        Icons.verified_rounded,
                        color: AppColors.success.withOpacity(0.8),
                        size: 24,
                      ),
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 20,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        
        // Кнопка отправки кода
        _buildPrimaryButton(
          onPressed: _isLoading || !_isPhoneValid ? null : _sendCode,
          text: 'Получить код',
          isLoading: _isLoading,
          icon: Icons.sms_rounded,
        ),
        
        const SizedBox(height: 24),
        
        // Разделитель
        Row(
          children: [
            Expanded(child: Divider(color: AppColors.border.withOpacity(0.5))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'или войдите через',
                style: TextStyle(
                  color: AppColors.textSecondary.withOpacity(0.7),
                  fontSize: 13,
                ),
              ),
            ),
            Expanded(child: Divider(color: AppColors.border.withOpacity(0.5))),
          ],
        ),
        
        const SizedBox(height: 24),
        
        // Кнопка Telegram
        _buildTelegramButton(),
        
        const SizedBox(height: 20),
        
        // Dev hint
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.warning.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.warning.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.developer_mode_rounded,
                color: AppColors.warning.withOpacity(0.8),
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dev режим',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.warning.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'SMS отключено. Код будет показан и введён автоматически.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTelegramButton() {
    return GestureDetector(
      onTap: _loginWithTelegram,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF0088CC),
              Color(0xFF00AAEE),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0088CC).withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Telegram icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.telegram,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Войти через Telegram',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCodeStep() {
    return Column(
      key: const ValueKey('code'),
      children: [
        // Поля для кода
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (index) {
            return Container(
              margin: EdgeInsets.only(right: index < 3 ? 14 : 0),
              child: _buildCodeField(index),
            );
          }),
        ),
        
        // Dev code badge
        if (_devCode != null) ...[
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.warning.withOpacity(0.15),
                  AppColors.warning.withOpacity(0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.warning.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.code_rounded,
                      color: AppColors.warning, size: 18),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Dev код:',
                      style: TextStyle(
                        color: AppColors.warning,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      _devCode!,
                      style: const TextStyle(
                        color: AppColors.warning,
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                        letterSpacing: 4,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: _devCode!));
                    _showSuccess('Код скопирован');
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.copy_rounded,
                        color: AppColors.warning, size: 18),
                  ),
                ),
              ],
            ),
          ),
        ],
        
        const SizedBox(height: 28),
        _buildPrimaryButton(
          onPressed: _isLoading ? null : _verifyCode,
          text: 'Войти',
          isLoading: _isLoading,
          icon: Icons.login_rounded,
        ),
        const SizedBox(height: 24),
        if (_countdown > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surface.withOpacity(0.4),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.timer_outlined,
                    size: 18, color: AppColors.textSecondary.withOpacity(0.7)),
                const SizedBox(width: 8),
                Text(
                  'Новый код через $_countdown сек',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          )
        else
          TextButton.icon(
            onPressed: _sendCode,
            icon: const Icon(Icons.refresh_rounded, size: 20),
            label: const Text('Отправить код повторно'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
            ),
          ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: () {
            setState(() {
              _isCodeSent = false;
              for (var c in _codeControllers) {
                c.clear();
              }
              _devCode = null;
            });
          },
          icon: const Icon(Icons.edit_rounded, size: 18),
          label: const Text('Изменить номер'),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildCodeField(int index) {
    final hasValue = _codeControllers[index].text.isNotEmpty;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 64,
      height: 76,
      decoration: BoxDecoration(
        gradient: hasValue
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary.withOpacity(0.15),
                  AppColors.primary.withOpacity(0.08),
                ],
              )
            : null,
        color: hasValue ? null : AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: hasValue ? AppColors.primary : AppColors.border,
          width: hasValue ? 2 : 1,
        ),
        boxShadow: hasValue
            ? [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.25),
                  blurRadius: 15,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: TextField(
        controller: _codeControllers[index],
        focusNode: _codeFocusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        style: TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w700,
          color: hasValue ? AppColors.primary : AppColors.textPrimary,
        ),
        decoration: const InputDecoration(
          counterText: '',
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: (value) {
          setState(() {});
          if (value.isNotEmpty && index < 3) {
            _codeFocusNodes[index + 1].requestFocus();
          }
          if (value.isEmpty && index > 0) {
            _codeFocusNodes[index - 1].requestFocus();
          }
          // Авто-отправка при заполнении
          if (_getFullCode().length == 4) {
            Future.delayed(const Duration(milliseconds: 100), () {
              if (mounted) _verifyCode();
            });
          }
        },
      ),
    );
  }

  Widget _buildPrimaryButton({
    required VoidCallback? onPressed,
    required String text,
    bool isLoading = false,
    IconData? icon,
  }) {
    final isEnabled = onPressed != null;
    
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        gradient: isEnabled
            ? const LinearGradient(
                colors: [
                  Color(0xFF00E5FF),
                  Color(0xFF00D4FF),
                  Color(0xFF0099CC),
                ],
              )
            : null,
        color: isEnabled ? null : AppColors.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(18),
        boxShadow: isEnabled
            ? [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: isLoading
            ? const LoadingIndicator(color: Colors.white)
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 22, color: isEnabled ? Colors.white : AppColors.textSecondary),
                    const SizedBox(width: 10),
                  ],
                  Text(
                    text,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: isEnabled ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildTermsText() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        'Продолжая, вы соглашаетесь с условиями\nиспользования и политикой конфиденциальности',
        style: TextStyle(
          fontSize: 12,
          color: AppColors.textSecondary.withOpacity(0.6),
          height: 1.6,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
