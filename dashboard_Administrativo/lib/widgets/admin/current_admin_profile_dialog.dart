import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/admin_service.dart';

class CurrentAdminProfileDialog extends StatefulWidget {
  const CurrentAdminProfileDialog({
    super.key,
    required this.initialName,
    required this.initialEmail,
  });

  final String initialName;
  final String initialEmail;

  @override
  State<CurrentAdminProfileDialog> createState() =>
      _CurrentAdminProfileDialogState();
}

class _CurrentAdminProfileDialogState extends State<CurrentAdminProfileDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _emailController;

  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(text: widget.initialName);

    _emailController = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await context.read<AdminService>().updateCurrentAdminProfile(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        currentPassword: _currentPasswordController.text.trim(),
        newPassword: _newPasswordController.text.trim(),
      );

      if (!mounted) return;

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil actualizado correctamente')),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar perfil: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFFF4F7F5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: const Text(
        'Editar mi perfil',
        style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF012D1D)),
      ),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircleAvatar(
                  radius: 38,
                  backgroundColor: Color(0xFFC1ECD4),
                  child: Icon(
                    Icons.person_outline,
                    size: 36,
                    color: Color(0xFF012D1D),
                  ),
                ),

                const SizedBox(height: 20),

                TextFormField(
                  controller: _nameController,
                  decoration: _inputDecoration('Nombre'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'El nombre es obligatorio';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _emailController,
                  decoration: _inputDecoration('Correo'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'El correo es obligatorio';
                    }

                    if (!value.contains('@')) {
                      return 'Correo inválido';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _currentPasswordController,
                  obscureText: true,
                  decoration: _inputDecoration('Contraseña actual'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Debes ingresar tu contraseña actual';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _newPasswordController,
                  obscureText: true,
                  decoration: _inputDecoration('Nueva contraseña'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return null;
                    }

                    if (value.trim().length < 6) {
                      return 'Mínimo 6 caracteres';
                    }

                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text(
            'Cancelar',
            style: TextStyle(color: Color(0xFF012D1D)),
          ),
        ),
        ElevatedButton.icon(
          onPressed: _isSaving ? null : _save,
          icon: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.save),
          label: const Text('Guardar'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF8D5B5B),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
      ],
    );
  }
}
