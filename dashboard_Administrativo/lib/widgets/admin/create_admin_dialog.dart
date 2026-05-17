import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/admin_service.dart';

bool _isDarkMode(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark;

class CreateAdminDialog extends StatefulWidget {
  const CreateAdminDialog({super.key});

  @override
  State<CreateAdminDialog> createState() => _CreateAdminDialogState();
}

class _CreateAdminDialogState extends State<CreateAdminDialog> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String _role = 'admin';

  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await context.read<AdminService>().createAdmin(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        role: _role,
      );

      if (!mounted) return;

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Administrador creado correctamente')),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al crear administrador: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: _isDarkMode(context)
          ? const Color(0xFF0B261D)
          : const Color(0xFFF4F7F5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: BorderSide(
          color: _isDarkMode(context)
              ? const Color(0xFF1B4332)
              : Colors.transparent,
        ),
      ),
      title: Text(
        'Nuevo administrador',
        style: TextStyle(
          fontWeight: FontWeight.w800,
          color: _isDarkMode(context)
              ? const Color(0xFFE8F5E9)
              : const Color(0xFF012D1D),
        ),
      ),
      content: SizedBox(
        width: 460,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'Nombre',
                  filled: true,
                  fillColor: _isDarkMode(context)
                      ? const Color(0xFF132F25)
                      : Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),
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
                decoration: InputDecoration(
                  hintText: 'Correo',
                  filled: true,
                  fillColor: _isDarkMode(context)
                      ? const Color(0xFF132F25)
                      : Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El correo es obligatorio';
                  }

                  if (!value.contains('@')) {
                    return 'Ingrese un correo valido';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'Contrasena',
                  filled: true,
                  fillColor: _isDarkMode(context)
                      ? const Color(0xFF132F25)
                      : Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'La contrasena es obligatoria';
                  }

                  if (value.trim().length < 6) {
                    return 'Minimo 6 caracteres';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _role,
                decoration: InputDecoration(
                  labelText: 'Rol',
                  filled: true,
                  fillColor: _isDarkMode(context)
                      ? const Color(0xFF132F25)
                      : Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                  DropdownMenuItem(
                    value: 'super_admin',
                    child: Text('Super Admin'),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) return;

                  setState(() {
                    _role = value;
                  });
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving
              ? null
              : () {
                  Navigator.pop(context);
                },
          child: const Text('Cancelar'),
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
              : const Icon(Icons.add),
          label: const Text('Crear'),
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
