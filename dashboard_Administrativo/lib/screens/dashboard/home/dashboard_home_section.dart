import 'package:flutter/material.dart';

import '../shared/dashboard_mock_ui.dart';

class DashboardHomeSection extends StatelessWidget {
  const DashboardHomeSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DashboardHeroCard(
          title: 'Dashboard General',
          subtitle:
              'Vista principal del panel administrativo EcoRutaCR con indicadores operativos, estado institucional y actividad reciente.',
          badges: const [
            DashboardHeroBadge(
              label: 'Panel principal',
              icon: Icons.home_outlined,
            ),
            DashboardHeroBadge(
              label: 'Datos simulados',
              icon: Icons.auto_awesome_mosaic_outlined,
            ),
          ],
          trailing: Container(
            constraints: const BoxConstraints(minWidth: 220, maxWidth: 280),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F8F5),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: dashboardBrandGreen,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.eco_outlined, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Estado del panel',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  'Operativo',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: dashboardBrandGreen,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Los modulos principales reportan actividad estable y una administracion lista para seguimiento diario.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        const DashboardMetricGrid(metrics: dashboardOverviewMetrics),
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
                          'Panorama general mock de rendimiento, cobertura y crecimiento del ecosistema administrativo.',
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _InfoCard(
                                  title: 'Cobertura en mapa',
                                  value: '24 zonas',
                                  subtitle:
                                      'Distribuidas en corredores urbanos y rutas publicas de mayor impacto.',
                                  accentColor: dashboardSoftGreen,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _InfoCard(
                                  title: 'Publicacion promedio',
                                  value: '87%',
                                  subtitle:
                                      'Nivel simulado de anuncios activos y visibles sobre el total cargado.',
                                  accentColor: dashboardAccentOrange,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _HighlightsStrip(),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  const Expanded(
                    flex: 2,
                    child: DashboardSectionCard(
                      title: 'Actividad reciente',
                      subtitle:
                          'Eventos simulados del sistema y acciones administrativas mas recientes.',
                      child: DashboardRecentActivityList(
                        items: dashboardRecentActivity,
                      ),
                    ),
                  ),
                ],
              );
            }

            return const Column(
              children: [
                DashboardSectionCard(
                  title: 'Resumen operativo',
                  subtitle:
                      'Panorama general mock de rendimiento, cobertura y crecimiento del ecosistema administrativo.',
                  child: _MobileOverviewBlock(),
                ),
                SizedBox(height: 20),
                DashboardSectionCard(
                  title: 'Actividad reciente',
                  subtitle:
                      'Eventos simulados del sistema y acciones administrativas mas recientes.',
                  child: DashboardRecentActivityList(
                    items: dashboardRecentActivity,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _MobileOverviewBlock extends StatelessWidget {
  const _MobileOverviewBlock();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        _InfoCard(
          title: 'Cobertura en mapa',
          value: '24 zonas',
          subtitle:
              'Distribuidas en corredores urbanos y rutas publicas de mayor impacto.',
          accentColor: dashboardSoftGreen,
        ),
        SizedBox(height: 16),
        _InfoCard(
          title: 'Publicacion promedio',
          value: '87%',
          subtitle:
              'Nivel simulado de anuncios activos y visibles sobre el total cargado.',
          accentColor: dashboardAccentOrange,
        ),
        SizedBox(height: 16),
        _HighlightsStrip(),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.accentColor,
  });

  final String title;
  final String value;
  final String subtitle;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAF9),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DashboardStatusChip(label: title, color: accentColor),
          const SizedBox(height: 14),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: dashboardBrandGreen,
              fontSize: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _HighlightsStrip extends StatelessWidget {
  const _HighlightsStrip();

  @override
  Widget build(BuildContext context) {
    const items = [
      ('Clientes con mayor actividad', 'Ruta Norte'),
      ('Patrocinador mas reciente', 'Verde Urbano'),
      ('Modulo con mayor uso', 'Publicidades'),
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: items
          .map(
            (item) => Container(
              width: 240,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: dashboardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.$1, style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 10),
                  Text(
                    item.$2,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: 16,
                      color: dashboardBrandGreen,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}
