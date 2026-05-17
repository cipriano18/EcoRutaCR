import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/admin_model.dart';
import '../../services/admin_service.dart';
import 'admin_action_button.dart';
import 'admin_details_dialog.dart';
import 'admin_role_badge.dart';
import 'update_admin_dialog.dart';

bool _isDarkMode(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark;

Color _cardSurface(BuildContext context) =>
    _isDarkMode(context) ? const Color(0xFF132F25) : Colors.white;

Color _cardBorder(BuildContext context) =>
    _isDarkMode(context) ? const Color(0xFF1B4332) : const Color(0xFFE7E8E9);

Color _titleColor(BuildContext context) =>
    _isDarkMode(context) ? const Color(0xFFE8F5E9) : const Color(0xFF012D1D);

class AdminCard extends StatelessWidget {
  const AdminCard({super.key, required this.admin});

  final AdminModel admin;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _cardSurface(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _cardBorder(context)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: _isDarkMode(context)
                ? const Color(0xFF17352A)
                : const Color(0xFFC1ECD4),
            child: Icon(
              Icons.admin_panel_settings_outlined,
              color: _isDarkMode(context)
                  ? const Color(0xFFE8F5E9)
                  : const Color(0xFF012D1D),
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
                    color: _titleColor(context),
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
                color: _isDarkMode(context)
                    ? const Color(0xFF75DAA8)
                    : const Color(0xFF8D5B5B),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => AdminDetailsDialog(admin: admin),
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
                    builder: (_) => UpdateAdminDialog(admin: admin),
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
                        content: Text('Deseas eliminar a ${admin.name}?'),
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
                    await context.read<AdminService>().deleteAdmin(admin.uid);
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
