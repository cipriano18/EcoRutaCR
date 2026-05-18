import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/admin_session_provider.dart';
import '../../services/admin_auth_service.dart';
import '../../widgets/auth/auth_card.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _loginFormKey = GlobalKey<FormState>(debugLabel: 'admin-login-form');
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isSubmitting = false;
  bool _obscurePassword = true;
  String? _statusMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_loginFormKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _statusMessage = null;
    });

    final authService = context.read<AdminAuthService>();
    final session = context.read<AdminSessionProvider>();

    try {
      session.clearError();
      await authService.login(
        email: _emailController.text,
        password: _passwordController.text,
      );
    } on FirebaseAuthException catch (error) {
      setState(() {
        _statusMessage = error.message ?? 'No se pudo iniciar sesion.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AdminSessionProvider>();

    return Scaffold(
      body: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: AuthCard(
                  title: 'Iniciar sesion',
                  subtitle:
                      'Usa tus credenciales administrativas para acceder al dashboard.',
                  child: Form(
                    key: _loginFormKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'CORREO ELECTRONICO',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _emailController,
                          autofillHints: const [AutofillHints.username],
                          decoration: const InputDecoration(
                            hintText: 'Ingresa tu correo',
                            prefixIcon: Icon(Icons.alternate_email_rounded),
                          ),
                          validator: _validateEmail,
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'CONTRASENIA',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          autofillHints: const [AutofillHints.password],
                          decoration: InputDecoration(
                            hintText: 'Ingresa tu contrasenia',
                            prefixIcon: const Icon(Icons.lock_outline_rounded),
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                            ),
                          ),
                          validator: _validatePassword,
                        ),
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: _isSubmitting ? null : _login,
                          style: FilledButton.styleFrom(
                            foregroundColor: Colors.white,
                          ),
                          child: Text(
                            _isSubmitting
                                ? 'Ingresando...'
                                : 'Entrar al panel',
                          ),
                        ),
                        const SizedBox(height: 16),
                        _StatusMessage(
                          message: _statusMessage ?? session.errorMessage,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String? _validateEmail(String? value) {
    final normalized = value?.trim() ?? '';
    if (normalized.isEmpty) {
      return 'Ingresa un correo electronico.';
    }

    if (!normalized.contains('@')) {
      return 'Ingresa un correo valido.';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    final normalized = value?.trim() ?? '';
    if (normalized.isEmpty) {
      return 'Ingresa una contrasenia.';
    }
    return null;
  }
}

class _StatusMessage extends StatelessWidget {
  const _StatusMessage({required this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    if (message == null || message!.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1B3028)
            : const Color(0xFFC1ECD4),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        message!,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFFE8F3EE)
              : const Color(0xFF012D1D),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
