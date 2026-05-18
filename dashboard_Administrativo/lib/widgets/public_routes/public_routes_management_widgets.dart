import 'package:flutter/material.dart';

import '../../screens/dashboard/shared/dashboard_mock_ui.dart';
import '../../services/public_routes_service.dart';

bool _isDarkMode(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark;

Color _miniInfoSurface(BuildContext context) =>
    _isDarkMode(context) ? const Color(0xFF17352A) : const Color(0xFFF8FAF9);

Color _miniInfoBorder(BuildContext context) =>
    _isDarkMode(context) ? const Color(0xFF1B4332) : Colors.transparent;

Color _miniInfoValueColor(BuildContext context) =>
    _isDarkMode(context) ? dashboardLightGreen : const Color(0xFF17392D);

Color _routeBadgeColor(BuildContext context) =>
    _isDarkMode(context) ? dashboardSupportGreen : dashboardBrandGreen;

class PublicRoutesToolbar extends StatelessWidget {
  const PublicRoutesToolbar({
    required this.searchController,
    required this.selectedActivity,
    required this.onActivityChanged,
    super.key,
  });

  final TextEditingController searchController;
  final String selectedActivity;
  final ValueChanged<String?> onActivityChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 820;

        final filter = _FilterDropdown(
          label: 'Actividad',
          value: selectedActivity,
          items: const ['Todas', 'Senderismo', 'Ciclismo', 'Running'],
          onChanged: onActivityChanged,
        );

        if (compact) {
          return Column(
            children: [
              TextField(
                controller: searchController,
                decoration: const InputDecoration(
                  hintText: 'Buscar por nombre, origen o destino',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
              const SizedBox(height: 16),
              filter,
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              child: TextField(
                controller: searchController,
                decoration: const InputDecoration(
                  hintText: 'Buscar por nombre, origen o destino',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(width: 190, child: filter),
          ],
        );
      },
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: items
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(),
      onChanged: onChanged,
    );
  }
}

class PublicRouteCard extends StatelessWidget {
  const PublicRouteCard({
    required this.route,
    required this.onEdit,
    required this.onDelete,
    required this.onViewDetail,
    super.key,
  });

  final PublicRouteAdminModel route;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onViewDetail;

  @override
  Widget build(BuildContext context) {
    return DashboardSurfaceCard(
      padding: const EdgeInsets.all(20),
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
                      style: Theme.of(
                        context,
                      ).textTheme.headlineSmall?.copyWith(fontSize: 22),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      route.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color:
                      (_isDarkMode(context)
                              ? dashboardSupportGreen
                              : dashboardLightGreen)
                          .withValues(alpha: 0.20),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color:
                        (_isDarkMode(context)
                                ? dashboardSupportGreen
                                : dashboardLightGreen)
                            .withValues(alpha: 0.24),
                  ),
                ),
                child: Icon(
                  activityIcon(route.activityProfile),
                  color: _routeBadgeColor(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              DashboardStatusChip(
                label: activityLabel(route.activityProfile),
                color: _routeBadgeColor(context),
              ),
              const DashboardStatusChip(
                label: 'pública',
                color: dashboardSoftGreen,
              ),
            ],
          ),
          const SizedBox(height: 16),
          PublicRouteInfoRow(
            icon: Icons.place_outlined,
            label: '${route.originLabel}  ->  ${route.destinationLabel}',
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 14,
            runSpacing: 10,
            children: [
              PublicRouteMiniInfo(
                label: 'Distancia',
                value: formatDistance(route.distanceMeters),
              ),
              PublicRouteMiniInfo(
                label: 'Tiempo',
                value: formatDuration(route.estimatedDurationSeconds),
              ),
              PublicRouteMiniInfo(
                label: 'Elevación',
                value: formatElevation(route.elevationGainMeters),
              ),
            ],
          ),
          const SizedBox(height: 14),
          PublicRouteInfoRow(
            icon: Icons.event_outlined,
            label: 'Creada el ${formatDate(route.createdAt)}',
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              DashboardActionGhostButton(
                label: 'Ver detalle',
                icon: Icons.visibility_outlined,
                onTap: onViewDetail,
              ),
              DashboardActionGhostButton(
                label: 'Editar',
                icon: Icons.edit_outlined,
                onTap: onEdit,
              ),
              DashboardActionGhostButton(
                label: 'Eliminar',
                icon: Icons.delete_outline_rounded,
                onTap: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class PublicRouteMiniInfo extends StatelessWidget {
  const PublicRouteMiniInfo({
    required this.label,
    required this.value,
    super.key,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _miniInfoSurface(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _miniInfoBorder(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: _miniInfoValueColor(context),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class PublicRouteInfoRow extends StatelessWidget {
  const PublicRouteInfoRow({
    required this.icon,
    required this.label,
    super.key,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: dashboardSupportGreen),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }
}

class PublicRouteDetailLine extends StatelessWidget {
  const PublicRouteDetailLine({
    required this.label,
    required this.value,
    super.key,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: _isDarkMode(context)
                    ? dashboardSupportGreen
                    : const Color(0xFF5F746B),
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class PublicRoutesEmptyState extends StatelessWidget {
  const PublicRoutesEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return DashboardSurfaceCard(
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          const Icon(
            Icons.route_outlined,
            size: 46,
            color: dashboardSupportGreen,
          ),
          const SizedBox(height: 14),
          Text(
            'No hay rutas públicas para esos filtros.',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontSize: 22),
          ),
          const SizedBox(height: 8),
          Text(
            'Ajusta la búsqueda o cambia el filtro de actividad para volver a mostrar resultados.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}

class PublicRoutesLoadingState extends StatelessWidget {
  const PublicRoutesLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 40),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class PublicRoutesErrorState extends StatelessWidget {
  const PublicRoutesErrorState({required this.error, super.key});

  final String error;

  @override
  Widget build(BuildContext context) {
    return DashboardSurfaceCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 42,
            color: dashboardAccentOrange,
          ),
          const SizedBox(height: 14),
          Text(
            'No se pudieron cargar las rutas públicas.',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontSize: 22),
          ),
          const SizedBox(height: 8),
          Text(error, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

String activityLabel(String raw) {
  switch (raw.trim().toLowerCase()) {
    case 'cycling':
      return 'Ciclismo';
    case 'running':
      return 'Running';
    case 'hiking':
    default:
      return 'Senderismo';
  }
}

IconData activityIcon(String raw) {
  switch (raw.trim().toLowerCase()) {
    case 'cycling':
      return Icons.directions_bike_outlined;
    case 'running':
      return Icons.directions_run_rounded;
    case 'hiking':
    default:
      return Icons.hiking_outlined;
  }
}

String formatDistance(num meters) {
  final km = meters / 1000;
  return '${km.toStringAsFixed(1)} km';
}

String formatDuration(int seconds) {
  final duration = Duration(seconds: seconds);
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);

  if (hours == 0) {
    return '$minutes min';
  }

  return '$hours h ${minutes.toString().padLeft(2, '0')} min';
}

String formatElevation(num meters) {
  return '${meters.toStringAsFixed(0)} m';
}

String formatDate(DateTime? date) {
  if (date == null) {
    return 'Sin fecha';
  }

  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final year = date.year.toString();
  return '$day/$month/$year';
}
