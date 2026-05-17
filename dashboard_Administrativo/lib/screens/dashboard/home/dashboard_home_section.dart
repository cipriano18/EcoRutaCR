import 'package:flutter/material.dart';

import '../../../services/dashboard_home_service.dart';
import 'home_support_widgets.dart';
import '../shared/dashboard_mock_ui.dart';

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
    return FutureBuilder<DashboardHomeSnapshot>(
      future: _snapshotFuture,
      builder: (context, snapshot) {
        final data = snapshot.data;
        final hasError = snapshot.hasError;
        final isLoading = snapshot.connectionState == ConnectionState.waiting;

        final metrics = _buildMetrics(data);
        final operationCards =
            data?.operationCards ?? const <DashboardOperationalCardData>[];
        final highlights = data?.highlights ?? const <(String, String)>[];
        final recentActivity =
            data?.recentActivity ?? const <DashboardActivityItem>[];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DashboardHeroCard(
              title: 'Dashboard General',
              subtitle:
                  'Vista principal del panel administrativo EcoRutaCR con indicadores operativos, estado institucional y actividad reciente.',
              badges: [
                const DashboardHeroBadge(
                  label: 'Panel principal',
                  icon: Icons.home_outlined,
                ),
                DashboardHeroBadge(
                  label: isLoading
                      ? 'Cargando Firestore'
                      : hasError
                      ? 'Lectura parcial'
                      : 'Datos en tiempo real',
                  icon: isLoading
                      ? Icons.sync_rounded
                      : hasError
                      ? Icons.warning_amber_rounded
                      : Icons.cloud_done_outlined,
                ),
              ],
            ),
            const SizedBox(height: 24),
            DashboardMetricGrid(metrics: metrics),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 860;

                if (wide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: DashboardSectionCard(
                          title: 'Resumen operativo',
                          subtitle:
                              'Panorama de lectura real sobre clientes, administradores y rutas públicas disponibles en Firestore.',
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: operationCards.isNotEmpty
                                        ? HomeInfoCard(
                                            title: operationCards[0].title,
                                            value: operationCards[0].value,
                                            subtitle:
                                                operationCards[0].subtitle,
                                            accentColor:
                                                operationCards[0].accentColor,
                                          )
                                        : HomeEmptyState(
                                            label: isLoading
                                                ? 'Cargando resumen operativo...'
                                                : 'Sin resumen operativo disponible.',
                                          ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: operationCards.length > 1
                                        ? HomeInfoCard(
                                            title: operationCards[1].title,
                                            value: operationCards[1].value,
                                            subtitle:
                                                operationCards[1].subtitle,
                                            accentColor:
                                                operationCards[1].accentColor,
                                          )
                                        : HomeEmptyState(
                                            label: isLoading
                                                ? 'Cargando rutas públicas...'
                                                : 'Sin datos de rutas públicas disponibles.',
                                          ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              highlights.isNotEmpty
                                  ? HomeHighlightsStrip(items: highlights)
                                  : HomeEmptyState(
                                      label: isLoading
                                          ? 'Cargando lecturas destacadas...'
                                          : 'Sin lecturas destacadas disponibles.',
                                    ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        flex: 2,
                        child: DashboardSectionCard(
                          title: 'Actividad reciente',
                          subtitle:
                              'Eventos inferidos desde las colecciones reales disponibles del proyecto.',
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
                  );
                }

                return Column(
                  children: [
                    DashboardSectionCard(
                      title: 'Resumen operativo',
                      subtitle:
                          'Panorama de lectura real sobre clientes, administradores y rutas públicas disponibles en Firestore.',
                      child: MobileOverviewBlock(
                        operationCards: operationCards,
                        highlights: highlights,
                      ),
                    ),
                    const SizedBox(height: 20),
                    DashboardSectionCard(
                      title: 'Actividad reciente',
                      subtitle:
                          'Eventos inferidos desde las colecciones reales disponibles del proyecto.',
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
                title: 'Siguiente implementacion recomendada',
                subtitle:
                    'Esto es lo que convendria agregar para que Resumen operativo y Actividad reciente queden completos.',
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RecommendationLine(
                      text:
                          'Agregar en routes campos estables como name, createdAt, activityType, isPublic, originLabel y destinationLabel.',
                    ),
                    RecommendationLine(
                      text:
                          'Guardar eventos administrativos en una coleccion activity_logs para no inferir actividad solo a partir de documentos recientes.',
                    ),
                    RecommendationLine(
                      text:
                          'Persistir estatus o moderacion de rutas públicas para poder mostrar aprobaciones, bloqueos y revisiones reales.',
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
