import 'package:flutter/material.dart';

const _kPrimaryColor = Color(0xFF012D1D);
const _kAccentColor = Color(0xFFFF825C);

/// Tarjeta de estado para el seguimiento de una ruta guardada.
class GuidedRouteStatusCard extends StatelessWidget {
  const GuidedRouteStatusCard({
    super.key,
    required this.title,
    required this.message,
    required this.distanceLabel,
    required this.isReady,
    this.secondaryLabel,
  });

  /// Título corto del estado actual.
  final String title;

  /// Mensaje explicativo para la siguiente acción.
  final String message;

  /// Distancia restante al punto relevante de la ruta.
  final String distanceLabel;

  /// Indica si la acción principal ya está habilitada.
  final bool isReady;

  /// Información secundaria, como origen y destino de la ruta.
  final String? secondaryLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isReady ? const Color(0xFFB6D3BC) : const Color(0xFFFFD4C7),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isReady ? Icons.check_circle_rounded : Icons.place_rounded,
                color: isReady ? _kPrimaryColor : _kAccentColor,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: isReady ? _kPrimaryColor : _kAccentColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isReady
                      ? const Color(0xFFE9F5EE)
                      : const Color(0xFFFFF3EE),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  distanceLabel,
                  style: TextStyle(
                    color: isReady ? _kPrimaryColor : _kAccentColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            message,
            style: const TextStyle(
              color: Color(0xFF414844),
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          if (secondaryLabel != null) ...[
            const SizedBox(height: 10),
            Text(
              secondaryLabel!,
              style: const TextStyle(
                color: _kPrimaryColor,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
