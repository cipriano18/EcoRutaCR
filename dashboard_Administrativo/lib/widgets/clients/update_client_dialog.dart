import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/client_model.dart';
import '../../services/client_service.dart';

bool _isDarkMode(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark;

class UpdateClientDialog extends StatefulWidget {
  const UpdateClientDialog({super.key, required this.client});

  final ClientModel client;

  @override
  State<UpdateClientDialog> createState() => _UpdateClientDialogState();
}

class _UpdateClientDialogState extends State<UpdateClientDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _activityController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(text: widget.client.name);

    _emailController = TextEditingController(text: widget.client.email);

    _activityController = TextEditingController(
      text: widget.client.favoriteActivity,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _activityController.dispose();
    super.dispose();
  }

  Future<void> _updateClient() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await context.read<ClientService>().updateClient(
        uid: widget.client.uid,
        fullName: _nameController.text,
        email: _emailController.text,
        favoriteActivity: _activityController.text,
      );

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (_) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: _isDarkMode(context)
          ? const Color(0xFF0B261D)
          : const Color(0xFFF4F7F5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: const Text('Actualizar cliente'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nombre completo'),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Correo'),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: _activityController,
              decoration: const InputDecoration(
                labelText: 'Actividad favorita',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cancelar'),
        ),

        ElevatedButton(
          onPressed: _isLoading ? null : _updateClient,
          child: _isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Actualizar'),
        ),
      ],
    );
  }
}
