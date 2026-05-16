import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/admin_session_provider.dart';
import '../../services/admin_auth_service.dart';
import '../../widgets/auth_card.dart';

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
        color: const Color(0xFFF8F9FA),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final useColumn = constraints.maxWidth < 980;
                  final children = [
                    Flexible(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 430),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Gestiona EcoRutaCR con una experiencia clara.',
                              style: Theme.of(context).textTheme.headlineLarge,
                            ),
                            const SizedBox(height: 18),
                            Text(
                              'Inicia sesion con tu cuenta administrativa para entrar al panel interno y trabajar sobre Firestore sin salir de la identidad visual de EcoRuta.',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            const SizedBox(height: 28),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: const [
                                _InfoPill(
                                  icon: Icons.forest_outlined,
                                  label: 'Misma base Firestore',
                                ),
                                _InfoPill(
                                  icon: Icons.admin_panel_settings_outlined,
                                  label: 'Acceso solo para admins',
                                ),
                                _InfoPill(
                                  icon: Icons.handshake_outlined,
                                  label: 'Gestion de patrocinadores',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    Flexible(
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
                                  prefixIcon: Icon(
                                    Icons.alternate_email_rounded,
                                  ),
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
                                obscureText: true,
                                autofillHints: const [AutofillHints.password],
                                decoration: const InputDecoration(
                                  hintText: 'Ingresa tu contrasenia',
                                  prefixIcon: Icon(Icons.lock_outline_rounded),
                                ),
                                validator: _validatePassword,
                              ),
                              const SizedBox(height: 24),
                              FilledButton(
                                onPressed: _isSubmitting ? null : _login,
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
                  ];

                  return ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1180),
                    child: Flex(
                      direction: useColumn ? Axis.vertical : Axis.horizontal,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: useColumn
                          ? CrossAxisAlignment.stretch
                          : CrossAxisAlignment.center,
                      children: [
                        children.first,
                        SizedBox(
                          width: useColumn ? 0 : 36,
                          height: useColumn ? 32 : 0,
                        ),
                        children.last,
                      ],
                    ),
                  );
                },
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

    if (normalized.length < 8) {
      return 'La contrasenia debe tener al menos 8 caracteres.';
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
        color: const Color(0xFFC1ECD4),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        message!,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: const Color(0xFF012D1D),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE7E8E9)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF2C694E)),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF012D1D),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
