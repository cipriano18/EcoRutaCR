import 'package:flutter/material.dart';

import '../../../services/dashboard_statistics_service.dart';
import 'statistics_support_widgets.dart';
import '../shared/dashboard_mock_ui.dart';

class DashboardStatisticsSection extends StatefulWidget {
  const DashboardStatisticsSection({super.key});

  @override
  State<DashboardStatisticsSection> createState() =>
      _DashboardStatisticsSectionState();
}

class _DashboardStatisticsSectionState
    extends State<DashboardStatisticsSection> {
  late final DashboardStatisticsService _service;
  late Future<DashboardStatisticsSnapshot> _snapshotFuture;

  @override
  void initState() {
    super.initState();
    _service = DashboardStatisticsService();
    _snapshotFuture = _service.loadSnapshot();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DashboardStatisticsSnapshot>(
      future: _snapshotFuture,
      builder: (context, snapshot) {
        final statistics = snapshot.data;

        final barData = statistics?.barData ?? const <DashboardBarDatum>[];
        final lineData = statistics?.lineData ?? const <DashboardLineDatum>[];
        final pieData = statistics?.pieData ?? const <DashboardPieDatum>[];
        final highlights =
            statistics?.highlights ?? const <DashboardStatisticsHighlight>[];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const DashboardHeroCard(
              title: 'Estadísticas',
              subtitle:
                  'Analitica visual del panel EcoRutaCR con lecturas reales de usuarios, administradores y rutas públicas disponibles.',
              badges: [
                DashboardHeroBadge(
                  label: 'Graficos del sistema',
                  icon: Icons.bar_chart_rounded,
                ),
                DashboardHeroBadge(
                  label: 'Vista comparativa',
                  icon: Icons.stacked_line_chart_rounded,
                ),
              ],
            ),
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
                        child: Column(
                          children: [
                            DashboardSectionCard(
                              title: 'Comparativo general',
                              subtitle:
                                  'Conteo actual por modulo visible dentro del panel, usando clientes, administradores, rutas y placeholders en cero para colecciones pendientes.',
                              child: barData.isNotEmpty
                                  ? DashboardBarChart(data: barData)
                                  : EmptyStatisticsState(
                                      label:
                                          snapshot.connectionState ==
                                              ConnectionState.waiting
                                          ? 'Cargando comparativo general...'
                                          : 'Sin datos disponibles para el comparativo.',
                                    ),
                            ),
                            const SizedBox(height: 20),
                            DashboardSectionCard(
                              title: 'Tendencia de actividad',
                              subtitle:
                                  'Lectura de los ultimos seis meses segun fechas detectadas en users, admins y rutas públicas.',
                              child: lineData.isNotEmpty
                                  ? DashboardLineChart(data: lineData)
                                  : EmptyStatisticsState(
                                      label:
                                          snapshot.connectionState ==
                                              ConnectionState.waiting
                                          ? 'Cargando tendencia de actividad...'
                                          : 'Sin datos disponibles para la tendencia.',
                                    ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        flex: 2,
                        child: Column(
                          children: [
                            DashboardSectionCard(
                              title: 'Distribucion de rutas',
                              subtitle:
                                  'Participacion estimada por tipo de actividad dentro de las rutas públicas visibles.',
                              child: pieData.isNotEmpty
                                  ? DashboardPieChart(data: pieData)
                                  : EmptyStatisticsState(
                                      label:
                                          snapshot.connectionState ==
                                              ConnectionState.waiting
                                          ? 'Cargando distribucion de rutas...'
                                          : 'Sin datos disponibles para la distribucion.',
                                    ),
                            ),
                            const SizedBox(height: 20),
                            DashboardSectionCard(
                              title: 'Lecturas destacadas',
                              subtitle:
                                  'Interpretaciones ejecutivas construidas con lo que hoy exponen las colecciones reales.',
                              child: highlights.isNotEmpty
                                  ? StatisticsHighlights(items: highlights)
                                  : EmptyStatisticsState(
                                      label:
                                          snapshot.connectionState ==
                                              ConnectionState.waiting
                                          ? 'Cargando lecturas destacadas...'
                                          : 'Sin lecturas destacadas disponibles.',
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }

                return Column(
                  children: [
                    DashboardSectionCard(
                      title: 'Comparativo general',
                      subtitle:
                          'Conteo actual por modulo visible dentro del panel, usando clientes, administradores, rutas y placeholders en cero para colecciones pendientes.',
                      child: barData.isNotEmpty
                          ? DashboardBarChart(data: barData)
                          : EmptyStatisticsState(
                              label:
                                  snapshot.connectionState ==
                                      ConnectionState.waiting
                                  ? 'Cargando comparativo general...'
                                  : 'Sin datos disponibles para el comparativo.',
                            ),
                    ),
                    const SizedBox(height: 20),
                    DashboardSectionCard(
                      title: 'Distribucion de rutas',
                      subtitle:
                          'Participacion estimada por tipo de actividad dentro de las rutas públicas visibles.',
                      child: pieData.isNotEmpty
                          ? DashboardPieChart(data: pieData)
                          : EmptyStatisticsState(
                              label:
                                  snapshot.connectionState ==
                                      ConnectionState.waiting
                                  ? 'Cargando distribucion de rutas...'
                                  : 'Sin datos disponibles para la distribucion.',
                            ),
                    ),
                    const SizedBox(height: 20),
                    DashboardSectionCard(
                      title: 'Tendencia de actividad',
                      subtitle:
                          'Lectura de los ultimos seis meses segun fechas detectadas en users, admins y rutas públicas.',
                      child: lineData.isNotEmpty
                          ? DashboardLineChart(data: lineData)
                          : EmptyStatisticsState(
                              label:
                                  snapshot.connectionState ==
                                      ConnectionState.waiting
                                  ? 'Cargando tendencia de actividad...'
                                  : 'Sin datos disponibles para la tendencia.',
                            ),
                    ),
                    const SizedBox(height: 20),
                    DashboardSectionCard(
                      title: 'Lecturas destacadas',
                      subtitle:
                          'Interpretaciones ejecutivas construidas con lo que hoy exponen las colecciones reales.',
                      child: highlights.isNotEmpty
                          ? StatisticsHighlights(items: highlights)
                          : EmptyStatisticsState(
                              label:
                                  snapshot.connectionState ==
                                      ConnectionState.waiting
                                  ? 'Cargando lecturas destacadas...'
                                  : 'Sin lecturas destacadas disponibles.',
                            ),
                    ),
                  ],
                );
              },
            ),
            if (snapshot.hasError) ...[
              const SizedBox(height: 20),
              DashboardSectionCard(
                title: 'Lectura parcial',
                subtitle:
                    'La vista encontro un problema leyendo Firebase y mantuvo datos de respaldo para no romper el dashboard.',
                child: Text(
                  'Revisa la consola del navegador o terminal para ver el detalle del error y confirmar permisos, nombres de campos y documentos disponibles.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
