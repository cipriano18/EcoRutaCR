import 'package:flutter/material.dart';

import '../shared/dashboard_mock_ui.dart';

enum PublicRouteActivity { senderismo, ciclismo, running }

class PublicRoutesManagementSection extends StatefulWidget {
  const PublicRoutesManagementSection({super.key});

  @override
  State<PublicRoutesManagementSection> createState() =>
      _PublicRoutesManagementSectionState();
}

class _PublicRoutesManagementSectionState
    extends State<PublicRoutesManagementSection> {
  late final TextEditingController _searchController;
  String _selectedActivity = 'Todas';
  late List<_PublicRouteItem> _routes;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchController.addListener(() {
      setState(() {});
    });
    _routes = _mockRoutes;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_PublicRouteItem> get _filteredRoutes {
    final query = _searchController.text.trim().toLowerCase();

    return _routes.where((route) {
      final matchesQuery =
          query.isEmpty ||
          route.name.toLowerCase().contains(query) ||
          route.origin.toLowerCase().contains(query) ||
          route.destination.toLowerCase().contains(query);
      final matchesActivity =
          _selectedActivity == 'Todas' ||
          route.activity.label == _selectedActivity;

      return matchesQuery && matchesActivity;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredRoutes = _filteredRoutes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DashboardHeroCard(
          title: 'Gestion de rutas publicas',
          subtitle:
              'Moderacion administrativa de rutas publicas creadas desde EcoRutaCR con revision visual, filtros simples y acciones de mantenimiento.',
          badges: const [
            DashboardHeroBadge(
              label: 'Rutas tipo senderismo, ciclismo y running',
              icon: Icons.route_outlined,
            ),
            DashboardHeroBadge(
              label: 'Moderacion institucional',
              icon: Icons.admin_panel_settings_outlined,
            ),
          ],
          trailing: Container(
            constraints: const BoxConstraints(minWidth: 240, maxWidth: 300),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F8F5),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Estado del modulo',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 10),
                Text(
                  'Operativo',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: dashboardBrandGreen,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Gestion simple de nombre y descripcion, sin modificar geometria ni coordenadas.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        DashboardMetricGrid(
          metrics: [
            DashboardMetricData(
              title: 'Rutas publicas',
              value: '${_routes.length}',
              changeLabel: 'Visibles en app',
              icon: Icons.public_outlined,
              accentColor: dashboardBrandGreen,
            ),
            DashboardMetricData(
              title: 'Ciclismo',
              value:
                  '${_routes.where((item) => item.activity == PublicRouteActivity.ciclismo).length}',
              changeLabel: 'Rutas activas',
              icon: Icons.directions_bike_outlined,
              accentColor: dashboardSoftGreen,
            ),
            DashboardMetricData(
              title: 'Senderismo',
              value:
                  '${_routes.where((item) => item.activity == PublicRouteActivity.senderismo).length}',
              changeLabel: 'Rutas activas',
              icon: Icons.hiking_outlined,
              accentColor: dashboardAccentOrange,
            ),
            DashboardMetricData(
              title: 'Running',
              value:
                  '${_routes.where((item) => item.activity == PublicRouteActivity.running).length}',
              changeLabel: 'Rutas activas',
              icon: Icons.directions_run_rounded,
              accentColor: dashboardSupportGreen,
            ),
          ],
        ),
        const SizedBox(height: 24),
        DashboardSectionCard(
          title: 'Listado administrativo de rutas publicas',
          subtitle:
              'Explora, filtra, edita y elimina rutas publicas con una vista limpia, ecologica y coherente con EcoRutaCR.',
          child: Column(
            children: [
              _RoutesToolbar(
                searchController: _searchController,
                selectedActivity: _selectedActivity,
                onActivityChanged: (value) {
                  setState(() {
                    _selectedActivity = value!;
                  });
                },
              ),
              const SizedBox(height: 20),
              if (filteredRoutes.isEmpty)
                const _EmptyRoutesState()
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 1100
                        ? 3
                        : constraints.maxWidth >= 760
                        ? 2
                        : 1;
                    final itemWidth =
                        (constraints.maxWidth - ((columns - 1) * 16)) / columns;

                    return Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: filteredRoutes
                          .map(
                            (route) => SizedBox(
                              width: itemWidth,
                              child: _PublicRouteCard(
                                route: route,
                                onEdit: () => _openEditDialog(route),
                                onDelete: () => _confirmDelete(route),
                                onViewDetail: () => _showDetail(route),
                              ),
                            ),
                          )
                          .toList(),
                    );
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _openEditDialog(_PublicRouteItem route) async {
    final nameController = TextEditingController(text: route.name);
    final descriptionController = TextEditingController(
      text: route.description,
    );

    final result = await showDialog<_RouteEditResult>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text('Editar ruta publica'),
          content: SizedBox(
            width: 460,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nombre de la ruta'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(labelText: 'Descripcion'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop(
                  _RouteEditResult(
                    name: nameController.text.trim(),
                    description: descriptionController.text.trim(),
                  ),
                );
              },
              child: const Text('Guardar cambios'),
            ),
          ],
        );
      },
    );

    nameController.dispose();
    descriptionController.dispose();

    if (result == null || result.name.isEmpty || result.description.isEmpty) {
      return;
    }

    setState(() {
      _routes = _routes
          .map(
            (item) => item.id == route.id
                ? item.copyWith(
                    name: result.name,
                    description: result.description,
                  )
                : item,
          )
          .toList();
    });

    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ruta publica actualizada correctamente.')),
    );
  }

  Future<void> _confirmDelete(_PublicRouteItem route) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text('Eliminar ruta publica'),
          content: const Text('¿Desea eliminar esta ruta pública?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: dashboardAccentOrange,
              ),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    setState(() {
      _routes = _routes.where((item) => item.id != route.id).toList();
    });

    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ruta publica eliminada del listado mock.')),
    );
  }

  Future<void> _showDetail(_PublicRouteItem route) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(route.name),
          content: SizedBox(
            width: 460,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(route.description, style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    DashboardStatusChip(
                      label: route.activity.label,
                      color: dashboardBrandGreen,
                    ),
                    const DashboardStatusChip(
                      label: 'Publica',
                      color: dashboardSoftGreen,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _DetailLine(label: 'Origen', value: route.origin),
                _DetailLine(label: 'Destino', value: route.destination),
                _DetailLine(label: 'Distancia', value: route.distance),
                _DetailLine(label: 'Tiempo estimado', value: route.estimatedTime),
                _DetailLine(label: 'Elevacion', value: route.elevation),
                _DetailLine(label: 'Fecha', value: route.createdAt),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }
}

class _RoutesToolbar extends StatelessWidget {
  const _RoutesToolbar({
    required this.searchController,
    required this.selectedActivity,
    required this.onActivityChanged,
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

class _PublicRouteCard extends StatelessWidget {
  const _PublicRouteCard({
    required this.route,
    required this.onEdit,
    required this.onDelete,
    required this.onViewDetail,
  });

  final _PublicRouteItem route;
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
                      route.name,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontSize: 22,
                      ),
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
                  color: dashboardLightGreen.withValues(alpha: 0.32),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(route.activity.icon, color: dashboardBrandGreen),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              DashboardStatusChip(
                label: route.activity.label,
                color: dashboardBrandGreen,
              ),
              const DashboardStatusChip(
                label: 'Publica',
                color: dashboardSoftGreen,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _InfoRow(
            icon: Icons.place_outlined,
            label: '${route.origin}  ->  ${route.destination}',
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 14,
            runSpacing: 10,
            children: [
              _MiniInfo(label: 'Distancia', value: route.distance),
              _MiniInfo(label: 'Tiempo', value: route.estimatedTime),
              _MiniInfo(label: 'Elevacion', value: route.elevation),
            ],
          ),
          const SizedBox(height: 14),
          _InfoRow(
            icon: Icons.event_outlined,
            label: 'Creada el ${route.createdAt}',
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

class _MiniInfo extends StatelessWidget {
  const _MiniInfo({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAF9),
        borderRadius: BorderRadius.circular(18),
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
              color: dashboardBrandGreen,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label});

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

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.label, required this.value});

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
                color: dashboardSupportGreen,
              ),
            ),
          ),
          Expanded(child: Text(value, style: Theme.of(context).textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

class _EmptyRoutesState extends StatelessWidget {
  const _EmptyRoutesState();

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
            'No hay rutas publicas para esos filtros.',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ajusta la busqueda o cambia el filtro de actividad para volver a mostrar resultados.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}

class _RouteEditResult {
  const _RouteEditResult({required this.name, required this.description});

  final String name;
  final String description;
}

class _PublicRouteItem {
  const _PublicRouteItem({
    required this.id,
    required this.name,
    required this.description,
    required this.activity,
    required this.origin,
    required this.destination,
    required this.distance,
    required this.estimatedTime,
    required this.elevation,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String description;
  final PublicRouteActivity activity;
  final String origin;
  final String destination;
  final String distance;
  final String estimatedTime;
  final String elevation;
  final String createdAt;

  _PublicRouteItem copyWith({
    String? name,
    String? description,
  }) {
    return _PublicRouteItem(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      activity: activity,
      origin: origin,
      destination: destination,
      distance: distance,
      estimatedTime: estimatedTime,
      elevation: elevation,
      createdAt: createdAt,
    );
  }
}

extension on PublicRouteActivity {
  String get label {
    switch (this) {
      case PublicRouteActivity.senderismo:
        return 'Senderismo';
      case PublicRouteActivity.ciclismo:
        return 'Ciclismo';
      case PublicRouteActivity.running:
        return 'Running';
    }
  }

  IconData get icon {
    switch (this) {
      case PublicRouteActivity.senderismo:
        return Icons.hiking_outlined;
      case PublicRouteActivity.ciclismo:
        return Icons.directions_bike_outlined;
      case PublicRouteActivity.running:
        return Icons.directions_run_rounded;
    }
  }
}

const _mockRoutes = [
  _PublicRouteItem(
    id: 'route-1',
    name: 'Ruta Bosque Central',
    description:
        'Recorrido ecologico ideal para senderismo suave con vistas arboladas y puntos de descanso.',
    activity: PublicRouteActivity.senderismo,
    origin: 'Parque Central',
    destination: 'Mirador Verde',
    distance: '6.4 km',
    estimatedTime: '1 h 45 min',
    elevation: '280 m',
    createdAt: '12/04/2026',
  ),
  _PublicRouteItem(
    id: 'route-2',
    name: 'Circuito EcoBike Norte',
    description:
        'Ruta para ciclismo urbano con conexion a puntos turisticos y corredores de baja congestion.',
    activity: PublicRouteActivity.ciclismo,
    origin: 'Terminal Norte',
    destination: 'Plaza EcoRuta',
    distance: '18.2 km',
    estimatedTime: '1 h 20 min',
    elevation: '145 m',
    createdAt: '20/04/2026',
  ),
  _PublicRouteItem(
    id: 'route-3',
    name: 'Running Colinas del Sur',
    description:
        'Tramo panoramico con ritmo intermedio, ideal para running recreativo en entorno natural.',
    activity: PublicRouteActivity.running,
    origin: 'Entrada Sur',
    destination: 'Refugio Alto',
    distance: '9.7 km',
    estimatedTime: '52 min',
    elevation: '210 m',
    createdAt: '02/05/2026',
  ),
  _PublicRouteItem(
    id: 'route-4',
    name: 'Sendero Rio Verde',
    description:
        'Ruta ligera de senderismo publico con zonas familiares, paradas interpretativas y acceso sencillo.',
    activity: PublicRouteActivity.senderismo,
    origin: 'Puente Verde',
    destination: 'Jardin del Rio',
    distance: '4.1 km',
    estimatedTime: '55 min',
    elevation: '60 m',
    createdAt: '07/05/2026',
  ),
  _PublicRouteItem(
    id: 'route-5',
    name: 'Ruta Miradores del Este',
    description:
        'Conecta varios puntos de observacion escenica con perfil ideal para senderismo de media distancia.',
    activity: PublicRouteActivity.senderismo,
    origin: 'Centro Comunitario Este',
    destination: 'Mirador de las Nubes',
    distance: '11.8 km',
    estimatedTime: '3 h 05 min',
    elevation: '430 m',
    createdAt: '10/05/2026',
  ),
];
