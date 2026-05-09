import 'package:ecoruta/models/stored_route.dart';
import 'package:ecoruta/models/route_profile.dart';
import 'package:flutter/material.dart';

/// Tarjeta visual para listar rutas guardadas con acciones rápidas.
class MyRouteCard extends StatelessWidget {
  const MyRouteCard({
    super.key,
    required this.route,
    required this.onOpen,
    required this.onDelete,
    this.onEdit,
  });

  static const primaryColor = Color(0xFF012D1D);
  static const accentGreen = Color(0xFFAEEECB);

  final StoredRoute route;
  final VoidCallback onOpen;
  final VoidCallback onDelete;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onOpen,
      child: Container(
        margin: const EdgeInsets.only(bottom: 18),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: accentGreen,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                _iconForProfile(route),
                size: 40,
                color: primaryColor,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              route.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: primaryColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                _PillLabel(text: route.activityLabel),
                                _PillLabel(text: route.visibilityLabel),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 14),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${route.startLabel} -> ${route.endLabel}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _RouteMetric(
                        label: 'Distancia',
                        value: _formatDistance(route.totalDistanceMeters),
                      ),
                      _RouteMetric(
                        label: 'Elevacion',
                        value: '+${route.elevationGainMeters.round()} m',
                      ),
                      _RouteMetric(
                        label: 'Tiempo',
                        value: _formatDuration(route.estimatedDurationSeconds),
                      ),
                    ],
                  ),
                  if (!route.isPublic) ...[
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (onEdit != null)
                          _ActionChipButton(
                            label: 'Editar',
                            icon: Icons.edit_outlined,
                            onTap: onEdit!,
                          ),
                        _ActionChipButton(
                          label: 'Eliminar',
                          icon: Icons.delete_outline_rounded,
                          onTap: onDelete,
                          isDestructive: true,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconForProfile(StoredRoute route) {
    switch (route.activityProfile) {
      case RouteProfile.cycling:
        return Icons.directions_bike;
      case RouteProfile.hiking:
        return Icons.hiking;
      case RouteProfile.running:
        return Icons.directions_run;
    }
  }

  String _formatDistance(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
    return '${meters.round()} m';
  }

  String _formatDuration(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    if (hours > 0) {
      return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
    }
    return '${minutes}m';
  }
}

/// Etiqueta compacta para actividad o visibilidad de la ruta.
class _PillLabel extends StatelessWidget {
  const _PillLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F5),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: MyRouteCard.primaryColor,
        ),
      ),
    );
  }
}

/// Muestra una métrica resumida dentro de la tarjeta de ruta.
class _RouteMetric extends StatelessWidget {
  const _RouteMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Colors.black45,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: MyRouteCard.primaryColor,
          ),
        ),
      ],
    );
  }
}

class _ActionChipButton extends StatelessWidget {
  const _ActionChipButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isDestructive = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final foregroundColor = isDestructive
        ? const Color(0xFF9D1B1E)
        : MyRouteCard.primaryColor;
    final backgroundColor = isDestructive
        ? const Color(0xFFFFECEC)
        : const Color(0xFFF3F4F5);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: foregroundColor.withValues(alpha: 0.12)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: foregroundColor),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: foregroundColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
