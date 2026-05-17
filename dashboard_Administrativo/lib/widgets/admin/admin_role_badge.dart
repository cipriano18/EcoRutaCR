import 'package:flutter/material.dart';

class AdminRoleBadge extends StatelessWidget {
  const AdminRoleBadge({super.key, required this.role});

  final String role;

  @override
  Widget build(BuildContext context) {
    final bool isSuperAdmin = role == 'super_admin';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: isSuperAdmin
            ? const Color(0xFFFF7043).withValues(alpha: 0.12)
            : const Color(0xFF4EAC7F).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        role.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: isSuperAdmin
              ? const Color(0xFFFF7043)
              : const Color(0xFF2C694E),
        ),
      ),
    );
  }
}
