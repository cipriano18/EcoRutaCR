import 'package:flutter/material.dart';

/// Presenta una métrica de ruta con icono, valor y unidad.
class RouteMetric extends StatelessWidget {
  /// Ícono que refuerza visualmente el tipo de métrica.
  final IconData icon;

  /// Etiqueta corta de la métrica.
  final String label;

  /// Valor principal a destacar.
  final String value;

  /// Unidad que contextualiza el valor mostrado.
  final String unit;

  const RouteMetric({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Label ──
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: Colors.grey,
            letterSpacing: 1,
          ),
        ),

        const SizedBox(height: 4),

        // ── Icon + Value ──
        Row(
          children: [
            Icon(icon, color: Colors.green.shade700, size: 18),
            const SizedBox(width: 6),

            RichText(
              text: TextSpan(
                style: const TextStyle(color: Color(0xFF191C1D)),
                children: [
                  TextSpan(
                    text: value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  TextSpan(
                    text: unit,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
