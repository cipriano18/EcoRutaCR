import 'package:flutter/material.dart';

import '../../../services/dashboard_home_service.dart';
import '../shared/dashboard_mock_ui.dart';
import 'home_support_widgets.dart';

class DashboardHomeSection extends StatefulWidget {
  const DashboardHomeSection({super.key});

  @override
  State<DashboardHomeSection> createState() => _DashboardHomeSectionState();
}

class _DashboardHomeSectionState extends State<DashboardHomeSection> {
  late final DashboardHomeService _service;
  late Future<DashboardHomeSnapshot> _snapshotFuture;

  @override
  void initState() {
    super.initState();
    _service = DashboardHomeService();
    _snapshotFuture = _service.loadSnapshot();
  }

  @override
  Widget build(BuildContext context) {
    final dividerColor = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF1B4332)
        : dashboardBorder;

    return FutureBuilder<DashboardHomeSnapshot>(
      future: _snapshotFuture,
      builder: (context, snapshot) {
        final data = snapshot.data;
        final hasError = snapshot.hasError;
        final isLoading = snapshot.connectionState == ConnectionState.waiting;

        final metrics = _buildMetrics(data);
        final sponsorshipMetrics = [metrics[0], metrics[3]];
        final userMetrics = [metrics[1], metrics[2]];
        final routeMetrics = [metrics[4]];
        final topAdInteractions =
            data?.topAdInteractions ?? const <DashboardAdInteractionData>[];
        final recentActivity =
            data?.recentActivity ?? const <DashboardActivityItem>[];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dashboard General',
              style: Theme.of(
                context,
              ).textTheme.headlineLarge?.copyWith(fontSize: 34),
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Text(
                'Resumen operativo y actividad reciente del ecosistema EcoRutaCR.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            const SizedBox(height: 24),
            Divider(height: 1, thickness: 1, color: dividerColor),
            const SizedBox(height: 24),
            HomeMetricSections(
              sponsorshipMetrics: sponsorshipMetrics,
              userMetrics: userMetrics,
              routeMetrics: routeMetrics,
            ),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 860;

                if (wide) {
                  return IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          flex: 3,
                          child: DashboardSectionCard(
                            title: 'Interacciones',
                            subtitle:
                                'Lista de anuncios más populares en EcoRutaCR.',
                            child: topAdInteractions.isNotEmpty
                                ? HomeAdInteractionsList(
                                    items: topAdInteractions,
                                  )
                                : HomeEmptyState(
                                    label: isLoading
                                        ? 'Preparando interacciones de anuncios...'
                                        : 'Sin interacciones de anuncios disponibles.',
                                  ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          flex: 3,
                          child: DashboardSectionCard(
                            title: 'Actividad reciente',
                            subtitle:
                                'Resumen de movimientos y registros recientes dentro de la plataforma.',
                            expandChild: true,
                            child: recentActivity.isNotEmpty
                                ? DashboardRecentActivityList(
                                    items: recentActivity,
                                  )
                                : HomeEmptyState(
                                    label: isLoading
                                        ? 'Cargando actividad reciente...'
                                        : 'Sin actividad reciente disponible.',
                                  ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: [
                    DashboardSectionCard(
                      title: 'Interacciones',
                      subtitle: 'Lista de anuncios mas populares en EcoRutaCR.',
                      child: topAdInteractions.isNotEmpty
                          ? HomeAdInteractionsList(items: topAdInteractions)
                          : HomeEmptyState(
                              label: isLoading
                                  ? 'Preparando interacciones de anuncios...'
                                  : 'Sin interacciones de anuncios disponibles.',
                            ),
                    ),
                    const SizedBox(height: 20),
                    DashboardSectionCard(
                      title: 'Actividad reciente',
                      subtitle:
                          'Resumen de movimientos y registros recientes dentro de la plataforma.',
                      child: recentActivity.isNotEmpty
                          ? DashboardRecentActivityList(items: recentActivity)
                          : HomeEmptyState(
                              label: isLoading
                                  ? 'Cargando actividad reciente...'
                                  : 'Sin actividad reciente disponible.',
                            ),
                    ),
                  ],
                );
              },
            ),
            if (hasError) ...[
              const SizedBox(height: 20),
              DashboardSectionCard(
                title: 'Siguiente implementación recomendada',
                subtitle:
                    'Esto es lo que convendría agregar para que Interacciones y Actividad reciente queden completos.',
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RecommendationLine(
                      text:
                          'Agregar una colección de anuncios con título, patrocinador, clicks y estado para reemplazar la lista mock por datos reales.',
                    ),
                    RecommendationLine(
                      text:
                          'Guardar eventos administrativos en una colección activity_logs para no inferir actividad solo a partir de documentos recientes.',
                    ),
                    RecommendationLine(
                      text:
                          'Persistir estatus o moderación de rutas públicas para poder mostrar aprobaciones, bloqueos y revisiones reales.',
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  List<DashboardMetricData> _buildMetrics(DashboardHomeSnapshot? data) {
    return [
      DashboardMetricData(
        title: 'Total de patrocinadores',
        value: '${data?.totalSponsors ?? 0}',
        changeLabel: 'Próximamente',
        icon: Icons.handshake_outlined,
        accentColor: dashboardSoftGreen,
      ),
      DashboardMetricData(
        title: 'Total de clientes',
        value: '${data?.totalClients ?? 0}',
        icon: Icons.groups_2_outlined,
        accentColor: dashboardBrandGreen,
      ),
      DashboardMetricData(
        title: 'Total de administradores',
        value: '${data?.totalAdmins ?? 0}',
        icon: Icons.admin_panel_settings_outlined,
        accentColor: dashboardSupportGreen,
      ),
      DashboardMetricData(
        title: 'Publicidades activas',
        value: '${data?.totalAds ?? 0}',
        changeLabel: 'Próximamente',
        icon: Icons.campaign_outlined,
        accentColor: dashboardAccentOrange,
      ),
      DashboardMetricData(
        title: 'Total de rutas públicas',
        value: '${data?.totalPublicRoutes ?? 0}',
        icon: Icons.route_outlined,
        accentColor: dashboardSoftGreen,
      ),
    ];
  }
}
