import 'package:flutter/material.dart';

/// Tarjeta seleccionable para elegir un tipo de actividad.
class ActivityTypeCard extends StatelessWidget {
  static const _primaryColor = Color(0xFF012D1D);

  /// Ícono representativo de la actividad.
  final IconData icon;

  /// Texto principal mostrado en la tarjeta.
  final String label;

  /// Indica si la tarjeta está activa en el contexto actual.
  final bool selected;

  /// Acción ejecutada al tocar la tarjeta.
  final VoidCallback onTap;

  /// Ancho configurable para adaptarse a distintos layouts.
  final double width;

  const ActivityTypeCard({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.width = 132,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: width,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? _primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? _primaryColor : Colors.grey.shade200,
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: selected ? Colors.white : const Color(0xFF2C694E),
              size: 24,
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: selected ? Colors.white : const Color(0xFF191C1D),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
