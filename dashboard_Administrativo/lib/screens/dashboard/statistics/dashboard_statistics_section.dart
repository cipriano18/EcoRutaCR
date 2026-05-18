import 'package:flutter/material.dart';

import '../../../services/dashboard_statistics_service.dart';
import '../shared/dashboard_mock_ui.dart';
import 'statistics_support_widgets.dart';

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
    final dividerColor = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF1B4332)
        : dashboardBorder;

    return FutureBuilder<DashboardStatisticsSnapshot>(
      future: _snapshotFuture,
      builder: (context, snapshot) {
        final statistics = snapshot.data;

        final barData = statistics?.barData ?? const <DashboardBarDatum>[];
        final lineData = statistics?.lineData ?? const <DashboardLineDatum>[];
        final pieData = statistics?.pieData ?? const <DashboardPieDatum>[];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Estadísticas',
              style: Theme.of(
                context,
              ).textTheme.headlineLarge?.copyWith(fontSize: 34),
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Text(
                'Monitoreo del crecimiento, la actividad y el contenido públicado en EcoRutaCR.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            const SizedBox(height: 24),
            Divider(height: 1, thickness: 1, color: dividerColor),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 860;

                if (wide) {
                  return Column(
                    children: [
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              flex: 3,
                              child: DashboardSectionCard(
                                title: 'Comparativo general',
                                subtitle:
                                    'Conteo actual por módulo visible dentro del panel, utilizando clientes, administradores, rutas y valores en cero para colecciones pendientes.',
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
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              flex: 2,
                              child: DashboardSectionCard(
                                title: 'Distribución de rutas',
                                subtitle:
                                    'Participación estimada por tipo de actividad dentro de las rutas públicas visibles.',
                                child: pieData.isNotEmpty
                                    ? DashboardPieChart(data: pieData)
                                    : EmptyStatisticsState(
                                        label:
                                            snapshot.connectionState ==
                                                ConnectionState.waiting
                                            ? 'Cargando distribución de rutas...'
                                            : 'Sin datos disponibles para la distribución.',
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              flex: 1,
                              child: DashboardSectionCard(
                                title: 'Tendencia de actividad',
                                subtitle:
                                    'Creación de rutas durante los últimos seis meses registrados en la plataforma.',
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
                          'Distribución actual de registros y módulos principales dentro de la plataforma.',
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
                      title: 'Distribución de rutas',
                      subtitle:
                          'Participación estimada por tipo de actividad dentro de las rutas públicas visibles.',
                      child: pieData.isNotEmpty
                          ? DashboardPieChart(data: pieData)
                          : EmptyStatisticsState(
                              label:
                                  snapshot.connectionState ==
                                      ConnectionState.waiting
                                  ? 'Cargando distribución de rutas...'
                                  : 'Sin datos disponibles para la distribución.',
                            ),
                    ),
                    const SizedBox(height: 20),
                    DashboardSectionCard(
                      title: 'Tendencia de actividad',
                      subtitle:
                          'Creación de rutas durante los últimos seis meses registrados en la plataforma.',
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
                );
              },
            ),
            if (snapshot.hasError) ...[
              const SizedBox(height: 20),
              DashboardSectionCard(
                title: 'Lectura parcial',
                subtitle:
                    'La vista encontró un problema leyendo Firebase y mantuvo datos de respaldo para no afectar el dashboard.',
                child: Text(
                  'Revisa la consola del navegador o la terminal para ver el detalle del error y confirmar permisos, nombres de campos y documentos disponibles.',
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
