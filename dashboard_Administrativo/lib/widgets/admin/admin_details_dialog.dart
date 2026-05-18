import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/admin_model.dart';

bool _isDarkMode(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark;

class AdminDetailsDialog extends StatelessWidget {
  const AdminDetailsDialog({super.key, required this.admin});

  final AdminModel admin;

  @override
  Widget build(BuildContext context) {
    final createdAt = admin.createdAt != null
        ? DateFormat('dd/MM/yyyy hh:mm a').format(admin.createdAt!)
        : 'Sin fecha';

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
        'Detalle del administrador',
        style: TextStyle(
          fontWeight: FontWeight.w800,
          color: _isDarkMode(context)
              ? const Color(0xFFE8F5E9)
              : const Color(0xFF012D1D),
        ),
      ),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 38,
                backgroundColor: _isDarkMode(context)
                    ? const Color(0xFF17352A)
                    : const Color(0xFFC1ECD4),
                child: Icon(
                  Icons.admin_panel_settings_outlined,
                  size: 38,
                  color: _isDarkMode(context)
                      ? const Color(0xFFE8F5E9)
                      : const Color(0xFF012D1D),
                ),
              ),
              const SizedBox(height: 18),
              _InfoTile(label: 'Nombre', value: admin.name),
              const SizedBox(height: 12),
              _InfoTile(label: 'Correo', value: admin.email),
              const SizedBox(height: 12),
              _InfoTile(label: 'Rol', value: admin.role),
              const SizedBox(height: 12),
              _InfoTile(label: 'Fecha de creación', value: createdAt),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cerrar'),
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final isDark = _isDarkMode(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF132F25) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF1B4332) : Colors.transparent,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isDark ? const Color(0xFF9FD4B5) : const Color(0xFF6B7B75),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isDark ? const Color(0xFFE8F5E9) : const Color(0xFF012D1D),
            ),
          ),
        ],
      ),
    );
  }
}
