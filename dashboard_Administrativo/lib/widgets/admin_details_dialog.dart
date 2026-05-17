import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/admin_model.dart';

class AdminDetailsDialog extends StatelessWidget {
  const AdminDetailsDialog({
    super.key,
    required this.admin,
  });

  final AdminModel admin;

  @override
  Widget build(BuildContext context) {
    final createdAt = admin.createdAt != null
        ? DateFormat('dd/MM/yyyy hh:mm a').format(admin.createdAt!)
        : 'Sin fecha';

    return AlertDialog(
      backgroundColor: const Color(0xFFF4F7F5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      title: const Text(
        'Detalle del administrador',
        style: TextStyle(
          fontWeight: FontWeight.w800,
          color: Color(0xFF012D1D),
        ),
      ),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircleAvatar(
                radius: 38,
                backgroundColor: Color(0xFFC1ECD4),
                child: Icon(
                  Icons.admin_panel_settings_outlined,
                  size: 38,
                  color: Color(0xFF012D1D),
                ),
              ),

              const SizedBox(height: 18),

              _InfoTile(
                label: 'Nombre',
                value: admin.name,
              ),

              const SizedBox(height: 12),

              _InfoTile(
                label: 'Correo',
                value: admin.email,
              ),

              const SizedBox(height: 12),

              _InfoTile(
                label: 'Rol',
                value: admin.role,
              ),

              const SizedBox(height: 12),

              _InfoTile(
                label: 'Fecha de creación',
                value: createdAt,
              ),
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
  const _InfoTile({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF6B7B75),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF012D1D),
            ),
          ),
        ],
      ),
    );
  }
}