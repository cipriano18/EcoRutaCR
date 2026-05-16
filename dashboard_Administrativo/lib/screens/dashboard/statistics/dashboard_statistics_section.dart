import 'package:flutter/material.dart';

import '../shared/dashboard_mock_ui.dart';

class DashboardStatisticsSection extends StatelessWidget {
  const DashboardStatisticsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const DashboardHeroCard(
          title: 'Estadisticas',
          subtitle:
              'Analitica visual del panel EcoRutaCR con graficos administrativos, comportamiento operativo y distribuciones mock.',
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
              return const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      children: [
                        DashboardSectionCard(
                          title: 'Crecimiento mensual',
                          subtitle:
                              'Comparativo mock de volumen administrativo por modulo y comportamiento general del panel.',
                          child: DashboardBarChart(data: dashboardBarData),
                        ),
                        SizedBox(height: 20),
                        DashboardSectionCard(
                          title: 'Tendencia de actividad',
                          subtitle:
                              'Seguimiento simulado de interacciones, movimientos y dinamica operativa por periodo.',
                          child: DashboardLineChart(data: dashboardLineData),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 20),
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        DashboardSectionCard(
                          title: 'Estado de publicidades',
                          subtitle:
                              'Distribucion mock de anuncios activos, programados y en revision.',
                          child: DashboardPieChart(data: dashboardPieData),
                        ),
                        SizedBox(height: 20),
                        DashboardSectionCard(
                          title: 'Lecturas destacadas',
                          subtitle:
                              'Indicadores interpretativos para seguimiento ejecutivo rapido.',
                          child: _StatisticsHighlights(),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            return const Column(
              children: [
                DashboardSectionCard(
                  title: 'Crecimiento mensual',
                  subtitle:
                      'Comparativo mock de volumen administrativo por modulo y comportamiento general del panel.',
                  child: DashboardBarChart(data: dashboardBarData),
                ),
                SizedBox(height: 20),
                DashboardSectionCard(
                  title: 'Estado de publicidades',
                  subtitle:
                      'Distribucion mock de anuncios activos, programados y en revision.',
                  child: DashboardPieChart(data: dashboardPieData),
                ),
                SizedBox(height: 20),
                DashboardSectionCard(
                  title: 'Tendencia de actividad',
                  subtitle:
                      'Seguimiento simulado de interacciones, movimientos y dinamica operativa por periodo.',
                  child: DashboardLineChart(data: dashboardLineData),
                ),
                SizedBox(height: 20),
                DashboardSectionCard(
                  title: 'Lecturas destacadas',
                  subtitle:
                      'Indicadores interpretativos para seguimiento ejecutivo rapido.',
                  child: _StatisticsHighlights(),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _StatisticsHighlights extends StatelessWidget {
  const _StatisticsHighlights();

  @override
  Widget build(BuildContext context) {
    const items = [
      (
        'Mayor crecimiento',
        'Clientes',
        '+8.4% semanal',
        dashboardSoftGreen,
      ),
      (
        'Modulo mas estable',
        'Administradores',
        '98% continuidad',
        dashboardBrandGreen,
      ),
      (
        'Zona con mas puntos',
        'Ruta Central',
        '64 registros',
        dashboardAccentOrange,
      ),
    ];

    return Column(
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAF9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: item.$4.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.insights_outlined,
                        color: item.$4,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.$1,
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item.$2,
                            style: Theme.of(
                              context,
                            ).textTheme.titleMedium?.copyWith(
                              fontSize: 16,
                              color: dashboardBrandGreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                    DashboardStatusChip(label: item.$3, color: item.$4),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}
