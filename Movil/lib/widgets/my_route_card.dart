import 'package:ecoruta/models/route_profile.dart';
import 'package:ecoruta/models/stored_route.dart';
import 'package:flutter/material.dart';

/// Tarjeta visual para listar rutas guardadas con acciones rapidas.
class MyRouteCard extends StatelessWidget {
  const MyRouteCard({
    super.key,
    required this.route,
    required this.onOpen,
    this.onDelete,
    this.onEdit,
    this.creatorText,
    this.showDeleteAction = false,
    this.deleteActionLabel = 'Eliminar',
  });

  static const primaryColor = Color(0xFF012D1D);
  static const secondaryColor = Color(0xFF2C694E);
  static const textMuted = Color(0xFF5E6762);
  static const surfaceTint = Color(0xFFE8F5E9);
  static const errorColor = Color(0xFFBA1A1A);
  static const errorContainer = Color(0xFFFFDAD6);
  static const outlineVariant = Color(0xFFC1C8C2);

  final StoredRoute route;
  final VoidCallback onOpen;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;
  final String? creatorText;
  final bool showDeleteAction;
  final String deleteActionLabel;

  @override
  Widget build(BuildContext context) {
    final routeIcon = _iconForProfile(route);

    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onOpen,
          borderRadius: BorderRadius.circular(28),
          child: Ink(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 32,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 176,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: surfaceTint,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Icon(
                          routeIcon,
                          size: 64,
                          color: primaryColor.withValues(alpha: 0.34),
                        ),
                      ),
                      Positioned(
                        top: 16,
                        left: 16,
                        right: 16,
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _StatusBadge(
                              label: route.isPublic ? 'Publica' : 'Privada',
                              icon: route.isPublic
                                  ? Icons.public_rounded
                                  : Icons.lock_rounded,
                              backgroundColor: route.isPublic
                                  ? primaryColor.withValues(alpha: 0.92)
                                  : textMuted.withValues(alpha: 0.92),
                              foregroundColor: Colors.white,
                            ),
                            _StatusBadge(
                              label: route.activityLabel,
                              icon: routeIcon,
                              backgroundColor: secondaryColor.withValues(
                                alpha: 0.16,
                              ),
                              foregroundColor: secondaryColor,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        route.title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: primaryColor,
                          letterSpacing: -0.4,
                          height: 1.05,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        creatorText ??
                            (route.sourceOwnerName?.trim().isNotEmpty == true
                                ? 'Creada por ${route.sourceOwnerName}'
                                : 'Creada por ti'),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: secondaryColor,
                        ),
                      ),
                      if (route.description.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          route.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: textMuted,
                            height: 1.35,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          border: Border.symmetric(
                            horizontal: BorderSide(
                              color: outlineVariant.withValues(alpha: 0.35),
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _RouteMetric(
                                label: 'Distancia',
                                value: _formatDistance(
                                  route.totalDistanceMeters,
                                ),
                              ),
                            ),
                            Expanded(
                              child: _RouteMetric(
                                label: 'Elevacion',
                                value:
                                    '+${route.elevationGainMeters.round()} m',
                              ),
                            ),
                            Expanded(
                              child: _RouteMetric(
                                label: 'Tiempo',
                                value: _formatDuration(
                                  route.estimatedDurationSeconds,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: textMuted,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '${route.startLabel} -> ${route.endLabel}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                color: textMuted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (onEdit != null ||
                          (showDeleteAction && onDelete != null)) ...[
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            if (onEdit != null)
                              Expanded(
                                child: _ActionButton(
                                  label: 'Editar',
                                  icon: Icons.edit_rounded,
                                  backgroundColor: primaryColor,
                                  foregroundColor: Colors.white,
                                  onTap: onEdit!,
                                ),
                              ),
                            if (onEdit != null) const SizedBox(width: 12),
                            if (showDeleteAction && onDelete != null)
                              Expanded(
                                child: _ActionButton(
                                  label: deleteActionLabel,
                                  icon: Icons.delete_outline_rounded,
                                  backgroundColor: errorContainer,
                                  foregroundColor: errorColor,
                                  borderColor: errorColor.withValues(
                                    alpha: 0.12,
                                  ),
                                  onTap: onDelete!,
                                ),
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
        ),
      ),
    );
  }

  IconData _iconForProfile(StoredRoute route) {
    switch (route.activityProfile) {
      case RouteProfile.cycling:
        return Icons.directions_bike_rounded;
      case RouteProfile.hiking:
        return Icons.hiking_rounded;
      case RouteProfile.running:
        return Icons.directions_run_rounded;
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

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foregroundColor),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: foregroundColor,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.7,
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteMetric extends StatelessWidget {
  const _RouteMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label.toUpperCase(),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: MyRouteCard.textMuted,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: MyRouteCard.primaryColor,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onTap,
    this.label,
    this.borderColor,
  });

  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback onTap;
  final String? label;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(14),
              border: borderColor == null
                  ? null
                  : Border.all(color: borderColor!),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: [
                Icon(icon, size: 20, color: foregroundColor),
                if (label != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    label!,
                    style: TextStyle(
                      color: foregroundColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
