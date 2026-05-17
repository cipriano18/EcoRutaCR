import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/admin_model.dart';
import '../../services/admin_service.dart';
import 'admin_card.dart';
import 'create_admin_dialog.dart';

bool _isDarkMode(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark;

Color _moduleSurface(BuildContext context) =>
    _isDarkMode(context) ? const Color(0xFF0B261D) : Colors.white;

Color _moduleBorder(BuildContext context) =>
    _isDarkMode(context) ? const Color(0xFF1B4332) : const Color(0xFFE7E8E9);

Color _buttonBackground(BuildContext context) =>
    _isDarkMode(context) ? const Color(0xFF17352A) : const Color(0xFF8D5B5B);

Color _buttonForeground(BuildContext context) =>
    _isDarkMode(context) ? const Color(0xFFE8F5E9) : Colors.white;

class AdminListModule extends StatelessWidget {
  const AdminListModule({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AdminModel>>(
      stream: context.read<AdminService>().getAdmins(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return _AdminMessageCard(
            icon: Icons.error_outline,
            title: 'Error al cargar administradores',
            message: snapshot.error.toString(),
          );
        }

        final admins = snapshot.data ?? [];

        if (admins.isEmpty) {
          return const _AdminMessageCard(
            icon: Icons.group_off_outlined,
            title: 'No hay administradores registrados',
            message: 'Cuando agregues administradores apareceran aqui.',
          );
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _moduleSurface(context),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: _moduleBorder(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Lista de administradores',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => const CreateAdminDialog(),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Nuevo administrador'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _buttonBackground(context),
                      foregroundColor: _buttonForeground(context),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                        side: BorderSide(
                          color: _isDarkMode(context)
                              ? const Color(0xFF2A5A46)
                              : Colors.transparent,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Administradores activos del panel EcoRutaCR.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 22),
              ...admins.map(
                (admin) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AdminCard(admin: admin),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AdminMessageCard extends StatelessWidget {
  const _AdminMessageCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: _moduleSurface(context),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _moduleBorder(context)),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 48,
            color: _isDarkMode(context)
                ? const Color(0xFF75DAA8)
                : const Color(0xFFFF7043),
          ),
          const SizedBox(height: 12),
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}
