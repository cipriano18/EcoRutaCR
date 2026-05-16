import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/admin_model.dart';
import '../../services/admin_service.dart';
import 'admin_card.dart';
import 'create_admin_dialog.dart';
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFFE7E8E9)),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE7E8E9)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: const Color(0xFFFF7043)),
          const SizedBox(height: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
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