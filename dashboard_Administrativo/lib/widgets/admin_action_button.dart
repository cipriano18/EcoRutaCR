import 'package:flutter/material.dart';

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
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onPressed,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: color.withValues(alpha: 0.15),
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: color,
        ),
      ),
    );
  }
}