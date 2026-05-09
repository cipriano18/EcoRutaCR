import 'package:flutter/material.dart';

/// Muestra una sugerencia de lugar seleccionable en búsquedas geográficas.
class SuggestionItem extends StatelessWidget {
  /// Nombre principal del resultado.
  final String title;

  /// Contexto secundario del resultado, como provincia o distrito.
  final String subtitle;

  /// Acción que aplica la sugerencia seleccionada.
  final VoidCallback onTap;

  const SuggestionItem({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  static const _primaryColor = Color(0xFF012D1D);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.location_on_rounded,
              color: _primaryColor,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF191C1D),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
