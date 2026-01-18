import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../../core/theme/app_colors.dart';
import '../../../data/repositories/auth_repository_impl.dart';
import '../../providers/app_state.dart';
import '../../widgets/common/loading_indicator.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  final _authRepository = AuthRepositoryImpl();
  
  bool _isCodeSent = false;
  bool _isLoading = false;
  int _countdown = 60;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
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
    if (_phoneController.text.isEmpty) {
      _showError('Введите номер телефона');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authRepository.sendVerificationCode(_phoneController.text);
      if (mounted) {
        setState(() {
          _isCodeSent = true;
          _isLoading = false;
        });
        _startCountdown();
        _showSuccess('Код отправлен на ваш номер');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError(e.toString());
      }
    }
  }

  Future<void> _verifyCode() async {
    if (_codeController.text.isEmpty) {
      _showError('Введите код подтверждения');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = await _authRepository.verifyCode(
        _phoneController.text,
        _codeController.text,
      );
      
      if (mounted) {
        context.read<AppState>().setUser(user);
        Navigator.of(context).pop();
        _showSuccess('Вы успешно авторизованы!');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError(e.toString());
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Вход')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              _buildLogo(),
              const SizedBox(height: 40),
              _buildTitle(),
              const SizedBox(height: 32),
              if (!_isCodeSent) _buildPhoneStep() else _buildCodeStep(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Center(
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(
          Icons.local_car_wash_rounded,
          color: Colors.white,
          size: 40,
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Column(
      children: [
        Text(
          _isCodeSent ? 'Введите код' : 'Вход по номеру телефона',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          _isCodeSent
              ? 'Мы отправили код на номер\n${_phoneController.text}'
              : 'Введите номер телефона для входа\nили регистрации',
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPhoneStep() {
    return Column(
      children: [
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Номер телефона',
            prefixIcon: Icon(Icons.phone_outlined),
            hintText: '+7 (900) 123-45-67',
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _sendCode,
            child: _isLoading
                ? const LoadingIndicator()
                : const Text('Получить код'),
          ),
        ),
      ],
    );
  }

  Widget _buildCodeStep() {
    return Column(
      children: [
        TextField(
          controller: _codeController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          decoration: const InputDecoration(
            labelText: 'Код подтверждения',
            prefixIcon: Icon(Icons.lock_outline_rounded),
            hintText: '1234',
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _verifyCode,
            child: _isLoading
                ? const LoadingIndicator()
                : const Text('Войти'),
          ),
        ),
        const SizedBox(height: 16),
        if (_countdown > 0)
          Text(
            'Отправить код повторно через $_countdown сек',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          )
        else
          TextButton(
            onPressed: () {
              setState(() {
                _isCodeSent = false;
                _codeController.clear();
              });
            },
            child: const Text('Отправить код повторно'),
          ),
      ],
    );
  }
}

