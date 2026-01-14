import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../providers/app_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
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

    if (!mounted) return;
    setState(() => _isLoading = true);
    final api = context.read<ApiService>();

    try {
      await api.sendVerificationCode(_phoneController.text);
      if (mounted) {
        setState(() {
          _isCodeSent = true;
          _isLoading = false;
        });
        _startCountdown();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Код отправлен на ваш номер'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      _showError(e.toString());
    }
  }

  Future<void> _verifyCode() async {
    if (_codeController.text.isEmpty) {
      _showError('Введите код подтверждения');
      return;
    }

    if (!mounted) return;
    setState(() => _isLoading = true);
    final api = context.read<ApiService>();
    final provider = context.read<AppProvider>();

    try {
      final user = await api.verifyCode(_phoneController.text, _codeController.text);
      provider.setUser(user);
      
      if (mounted) {
        Navigator.of(context).pop(); // Возвращаемся на предыдущий экран
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Вы успешно авторизованы!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      _showError(e.toString());
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Вход'),
      ),
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
          gradient: const LinearGradient(
            colors: [AppTheme.primaryColor, AppTheme.primaryDark],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.local_car_wash_rounded, color: Colors.white, size: 40),
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
            color: AppTheme.textSecondary,
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
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
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
            hintText: '123456',
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _verifyCode,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Войти'),
          ),
        ),
        const SizedBox(height: 16),
        if (_countdown > 0)
          Text(
            'Отправить код повторно через $_countdown сек',
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          )
        else
          TextButton(
            onPressed: () {
              if (mounted) {
                setState(() {
                  _isCodeSent = false;
                  _codeController.clear();
                });
              }
            },
            child: const Text('Отправить код повторно'),
          ),
      ],
    );
  }
}
