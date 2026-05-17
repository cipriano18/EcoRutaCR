import 'package:flutter/material.dart';

import '../../models/admin_model.dart';
import 'admin_role_badge.dart';
import 'package:provider/provider.dart';
import 'admin_details_dialog.dart';
import '../../services/admin_service.dart';
import 'admin_action_button.dart';
import 'update_admin_dialog.dart';
class AdminCard extends StatelessWidget {
  const AdminCard({
    super.key,
    required this.admin,
  });

  final AdminModel admin;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE7E8E9)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 24,
            backgroundColor: Color(0xFFC1ECD4),
            child: Icon(
              Icons.admin_panel_settings_outlined,
              color: Color(0xFF012D1D),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  admin.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: const Color(0xFF012D1D),
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  admin.email,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
         Row(
  mainAxisSize: MainAxisSize.min,
  children: [
    AdminRoleBadge(role: admin.role),

    const SizedBox(width: 12),

    AdminActionButton(
      icon: Icons.visibility_outlined,
      color: const Color(0xFF8D5B5B),
      onPressed: () {
        showDialog(
          context: context,
          builder: (_) => AdminDetailsDialog(
            admin: admin,
          ),
        );
      },
    ),

    const SizedBox(width: 10),

    AdminActionButton(
      icon: Icons.edit_outlined,
      color: const Color(0xFF8D5B5B),
      onPressed: () {
        showDialog(
          context: context,
          builder: (_) => UpdateAdminDialog(
            admin: admin,
          ),
        );
      },
    ),

    const SizedBox(width: 10),

    AdminActionButton(
      icon: Icons.delete_outline,
      color: Colors.redAccent,
      onPressed: () async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (_) {
            return AlertDialog(
              title: const Text('Eliminar administrador'),
              content: Text(
                '¿Deseas eliminar a ${admin.name}?',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context, false);
                  },
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, true);
                  },
                  child: const Text('Eliminar'),
                ),
              ],
            );
          },
        );

        if (confirm == true) {
          await context
              .read<AdminService>()
              .deleteAdmin(admin.uid);
        }
      },
    ),
  ],
),
        ],
      ),
    );
  }
}