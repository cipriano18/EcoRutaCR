import 'package:flutter/material.dart';

bool _isDarkMode(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark;

class AdminActionButton extends StatelessWidget {
  const AdminActionButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.color = const Color(0xFF8D5B5B),
  });

  final IconData icon;
  final VoidCallback onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isDark = _isDarkMode(context);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onPressed,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: isDark ? color.withValues(alpha: 0.14) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? color.withValues(alpha: 0.34)
                : color.withValues(alpha: 0.15),
          ),
          boxShadow: isDark
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.16),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Icon(icon, size: 19, color: color),
      ),
    );
  }
}
