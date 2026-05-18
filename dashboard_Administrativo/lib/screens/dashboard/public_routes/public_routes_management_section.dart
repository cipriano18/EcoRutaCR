import 'package:flutter/material.dart';

import '../../../services/public_routes_service.dart';
import '../../../widgets/public_routes/public_routes_management_widgets.dart';
import '../shared/dashboard_mock_ui.dart';

class PublicRoutesManagementSection extends StatefulWidget {
  const PublicRoutesManagementSection({super.key});

  @override
  State<PublicRoutesManagementSection> createState() =>
      _PublicRoutesManagementSectionState();
}

class _PublicRoutesManagementSectionState
    extends State<PublicRoutesManagementSection> {
  late final TextEditingController _searchController;
  late final PublicRoutesService _service;
  String _selectedActivity = 'Todas';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchController.addListener(() {
      setState(() {});
    });
    _service = PublicRoutesService();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<PublicRouteAdminModel>>(
      stream: _service.streamPublicRoutes(),
      builder: (context, snapshot) {
        final routes = snapshot.data ?? const <PublicRouteAdminModel>[];
        final filteredRoutes = _applyFilters(routes);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const DashboardHeroCard(
              title: 'Manejo de rutas públicas',
              subtitle:
                  'Moderación administrativa de rutas públicas creadas desde EcoRutaCR con revision visual, filtros simples y acciones de mantenimiento.',
              badges: [
                DashboardHeroBadge(
                  label: 'Rutas tipo senderismo, ciclismo y running',
                  icon: Icons.route_outlined,
                ),
              ],
            ),
            const SizedBox(height: 24),
            DashboardMetricGrid(
              metrics: [
                DashboardMetricData(
                  title: 'Rutas públicas',
                  value: '${routes.length}',
                  changeLabel: 'Colección routes',
                  icon: Icons.public_outlined,
                  accentColor: dashboardBrandGreen,
                ),
                DashboardMetricData(
                  title: 'Ciclismo',
                  value:
                      '${routes.where((item) => activityLabel(item.activityProfile) == 'Ciclismo').length}',
                  changeLabel: 'Rutas activas',
                  icon: Icons.directions_bike_outlined,
                  accentColor: dashboardSoftGreen,
                ),
                DashboardMetricData(
                  title: 'Senderismo',
                  value:
                      '${routes.where((item) => activityLabel(item.activityProfile) == 'Senderismo').length}',
                  changeLabel: 'Rutas activas',
                  icon: Icons.hiking_outlined,
                  accentColor: dashboardAccentOrange,
                ),
                DashboardMetricData(
                  title: 'Running',
                  value:
                      '${routes.where((item) => activityLabel(item.activityProfile) == 'Running').length}',
                  changeLabel: 'Rutas activas',
                  icon: Icons.directions_run_rounded,
                  accentColor: dashboardSupportGreen,
                ),
              ],
            ),
            const SizedBox(height: 24),
            DashboardSectionCard(
              title: 'Listado administrativo de rutas públicas',
              subtitle:
                  'Explora, filtra, edita y elimina rutas públicas con una vista limpia, ecológica y coherente con EcoRutaCR.',
              child: Column(
                children: [
                  PublicRoutesToolbar(
                    searchController: _searchController,
                    selectedActivity: _selectedActivity,
                    onActivityChanged: (value) {
                      setState(() {
                        _selectedActivity = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  if (snapshot.hasError)
                    PublicRoutesErrorState(error: '${snapshot.error}')
                  else if (snapshot.connectionState == ConnectionState.waiting)
                    const PublicRoutesLoadingState()
                  else if (filteredRoutes.isEmpty)
                    const PublicRoutesEmptyState()
                  else
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final columns = constraints.maxWidth >= 1100
                            ? 3
                            : constraints.maxWidth >= 760
                            ? 2
                            : 1;
                        final itemWidth =
                            (constraints.maxWidth - ((columns - 1) * 16)) /
                            columns;

                        return Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: filteredRoutes
                              .map(
                                (route) => SizedBox(
                                  width: itemWidth,
                                  child: PublicRouteCard(
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
      },
    );
  }

  List<PublicRouteAdminModel> _applyFilters(
    List<PublicRouteAdminModel> routes,
  ) {
    final query = _searchController.text.trim().toLowerCase();

    return routes.where((route) {
      final activity = activityLabel(route.activityProfile);
      final matchesQuery =
          query.isEmpty ||
          route.title.toLowerCase().contains(query) ||
          route.originLabel.toLowerCase().contains(query) ||
          route.destinationLabel.toLowerCase().contains(query);
      final matchesActivity =
          _selectedActivity == 'Todas' || activity == _selectedActivity;
      return matchesQuery && matchesActivity;
    }).toList();
  }

  Future<void> _openEditDialog(PublicRouteAdminModel route) async {
    final nameController = TextEditingController(text: route.title);
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
                  decoration: const InputDecoration(
                    labelText: 'Nombre de la ruta',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(labelText: 'Descripción'),
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

    try {
      await _service.updateRouteBasicInfo(
        routeId: route.id,
        title: result.name,
        description: result.description,
      );

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ruta publica actualizada correctamente.'),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo actualizar la ruta: $error')),
      );
    }
  }

  Future<void> _confirmDelete(PublicRouteAdminModel route) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text('Eliminar ruta publica'),
          content: const Text('¿Desea eliminar esta ruta publica?'),
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

    try {
      await _service.deleteRoute(routeId: route.id);

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ruta publica eliminada correctamente.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo eliminar la ruta: $error')),
      );
    }
  }

  Future<void> _showDetail(PublicRouteAdminModel route) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(route.title),
          content: SizedBox(
            width: 460,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  route.description,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    DashboardStatusChip(
                      label: activityLabel(route.activityProfile),
                      color: dashboardBrandGreen,
                    ),
                    const DashboardStatusChip(
                      label: 'Publica',
                      color: dashboardSoftGreen,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                PublicRouteDetailLine(
                  label: 'Origen',
                  value: route.originLabel,
                ),
                PublicRouteDetailLine(
                  label: 'Destino',
                  value: route.destinationLabel,
                ),
                PublicRouteDetailLine(
                  label: 'Distancia',
                  value: formatDistance(route.distanceMeters),
                ),
                PublicRouteDetailLine(
                  label: 'Tiempo estimado',
                  value: formatDuration(route.estimatedDurationSeconds),
                ),
                PublicRouteDetailLine(
                  label: 'Elevación',
                  value: formatElevation(route.elevationGainMeters),
                ),
                PublicRouteDetailLine(
                  label: 'Fecha',
                  value: formatDate(route.createdAt),
                ),
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

class _RouteEditResult {
  const _RouteEditResult({required this.name, required this.description});

  final String name;
  final String description;
}
