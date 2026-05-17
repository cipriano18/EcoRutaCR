import 'package:ecoruta/providers/user_provider.dart';
import 'package:ecoruta/routes/app_routes.dart';
import 'package:ecoruta/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Pantalla de confirmación para eliminar la cuenta de forma permanente.
class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  static const _primary = Color(0xFF012D1D);
  static const _danger = Color(0xFFBA1A1A);
  static const _surface = Color(0xFFF8F9FA);

  final _passwordController = TextEditingController();

  bool _isDeleting = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  /// Reautentica y elimina la cuenta cuando el usuario lo confirma.
  Future<void> _deleteAccount() async {
    final currentPassword = _passwordController.text.trim();
    if (currentPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Confirma tu contraseña actual para eliminar la cuenta',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isDeleting = true;
    });

    try {
      await AuthService().deleteCurrentAccount(
        currentPassword: currentPassword,
      );

      if (!mounted) return;

      Provider.of<UserProvider>(context, listen: false).clear();
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (_) => false);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String message = 'No se pudo eliminar la cuenta.';
      if (e.code == 'wrong-password' ||
          e.code == 'invalid-credential' ||
          e.code == 'invalid-login-credentials') {
        message = 'La contraseña actual no es correcta.';
      } else if (e.code == 'requires-recent-login') {
        message =
            'Por seguridad, debes volver a iniciar sesion antes de eliminar tu cuenta.';
      } else if (e.code == 'missing-password') {
        message = 'Debes confirmar tu contraseña actual.';
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo eliminar la cuenta: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasPassword = _passwordController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        backgroundColor: _surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: _primary,
        title: const Text(
          'Eliminar cuenta',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: _danger.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(
                  Icons.delete_forever_rounded,
                  size: 38,
                  color: _danger,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Esta accion es permanente',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: _primary,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Si eliminas tu cuenta, se borraran tus datos de perfil y toda la informacion asociada a tu experiencia en EcoRutaCR, incluyendo rutas guardadas, rutas completadas, estadisticas y configuraciones. Esta accion no se puede deshacer.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Confirma tu contraseña actual para continuar.',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Contraseña actual',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFEDEEEF),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isDeleting || !hasPassword
                      ? null
                      : _deleteAccount,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _danger,
                    disabledBackgroundColor: _danger.withOpacity(0.35),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: _isDeleting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.4,
                          ),
                        )
                      : const Text(
                          'Si, eliminar',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: OutlinedButton(
                  onPressed: _isDeleting
                      ? null
                      : () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _primary,
                    side: BorderSide(color: _primary.withOpacity(0.18)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
