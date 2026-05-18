import 'package:flutter/material.dart';

import '../../../services/dashboard_home_service.dart';
import '../shared/dashboard_mock_ui.dart';

bool _isDarkMode(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark;

Color _homeSoftSurface(BuildContext context) =>
    _isDarkMode(context) ? const Color(0xFF132F25) : const Color(0xFFF8FAF9);

Color _homeHighlightSurface(BuildContext context) =>
    _isDarkMode(context) ? const Color(0xFF17352A) : Colors.white;

Color _homeBorder(BuildContext context) =>
    _isDarkMode(context) ? const Color(0xFF1B4332) : dashboardBorder;

Color _homePrimaryText(BuildContext context) =>
    _isDarkMode(context) ? const Color(0xFFE8F5E9) : const Color(0xFF0D2B20);

class MobileOverviewBlock extends StatelessWidget {
  const MobileOverviewBlock({
    required this.operationCards,
    required this.highlights,
    super.key,
  });

  final List<DashboardOperationalCardData> operationCards;
  final List<(String, String)> highlights;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (operationCards.isNotEmpty)
          HomeInfoCard(
            title: operationCards[0].title,
            value: operationCards[0].value,
            subtitle: operationCards[0].subtitle,
            accentColor: operationCards[0].accentColor,
          )
        else
          const HomeEmptyState(label: 'Sin resumen operativo disponible.'),
        const SizedBox(height: 16),
        if (operationCards.length > 1)
          HomeInfoCard(
            title: operationCards[1].title,
            value: operationCards[1].value,
            subtitle: operationCards[1].subtitle,
            accentColor: operationCards[1].accentColor,
          )
        else
          const HomeEmptyState(
            label: 'Sin datos de rutas públicas disponibles.',
          ),
        const SizedBox(height: 16),
        if (highlights.isNotEmpty)
          HomeHighlightsStrip(items: highlights)
        else
          const HomeEmptyState(label: 'Sin lecturas destacadas disponibles.'),
      ],
    );
  }
}

class HomeAdInteractionsList extends StatelessWidget {
  const HomeAdInteractionsList({required this.items, super.key});

  final List<DashboardAdInteractionData> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const HomeEmptyState(
        label: 'Sin interacciones de anuncios disponibles por ahora.',
      );
    }

    return Column(
      children: items
          .asMap()
          .entries
          .map(
            (entry) => _HomeAdInteractionTile(
              item: entry.value,
              rank: entry.key + 1,
              isLast: entry.key == items.length - 1,
            ),
          )
          .toList(),
    );
  }
}

class HomeMetricSections extends StatelessWidget {
  const HomeMetricSections({
    required this.sponsorshipMetrics,
    required this.userMetrics,
    required this.routeMetrics,
    super.key,
  });

  final List<DashboardMetricData> sponsorshipMetrics;
  final List<DashboardMetricData> userMetrics;
  final List<DashboardMetricData> routeMetrics;

  @override
  Widget build(BuildContext context) {
    final sections = [
      _HomeMetricSectionData(
        title: 'Patrocinio',
        metrics: sponsorshipMetrics,
      ),
      _HomeMetricSectionData(
        title: 'Usuarios',
        metrics: userMetrics,
      ),
      _HomeMetricSectionData(
        title: 'Rutas',
        metrics: routeMetrics,
      ),
    ].where((section) => section.metrics.isNotEmpty).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 960;

        if (stacked) {
          return Column(
            children: sections
                .asMap()
                .entries
                .map(
                  (entry) => Padding(
                    padding: EdgeInsets.only(
                      bottom: entry.key == sections.length - 1 ? 0 : 20,
                    ),
                    child: _HomeMetricSection(
                      title: entry.value.title,
                      metrics: entry.value.metrics,
                    ),
                  ),
                )
                .toList(),
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: sections
              .asMap()
              .entries
              .expand((entry) sync* {
                final section = entry.value;
                yield Expanded(
                  flex: section.metrics.length,
                  child: _HomeMetricSection(
                    title: section.title,
                    metrics: section.metrics,
                  ),
                );

                if (entry.key != sections.length - 1) {
                  yield Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      width: 1,
                      height: 220,
                      color: _homeBorder(context),
                    ),
                  );
                }
              })
              .toList(),
        );
      },
    );
  }
}

class HomeEmptyState extends StatelessWidget {
  const HomeEmptyState({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _homeSoftSurface(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _homeBorder(context)),
        boxShadow: _isDarkMode(context)
            ? const [
                BoxShadow(
                  color: Color(0x40020B08),
                  blurRadius: 16,
                  offset: Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
    );
  }
}

class _HomeMetricSection extends StatelessWidget {
  const _HomeMetricSection({required this.title, required this.metrics});

  final String title;
  final List<DashboardMetricData> metrics;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: _homePrimaryText(context),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final singleColumn = constraints.maxWidth < 420 && metrics.length > 1;

            if (singleColumn) {
              return Column(
                children: metrics
                    .asMap()
                    .entries
                    .map(
                      (entry) => Padding(
                        padding: EdgeInsets.only(
                          bottom: entry.key == metrics.length - 1 ? 0 : 16,
                        ),
                        child: DashboardMetricCard(metric: entry.value),
                      ),
                    )
                    .toList(),
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: metrics
                  .asMap()
                  .entries
                  .map(
                    (entry) => Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: entry.key == metrics.length - 1 ? 0 : 16,
                        ),
                        child: DashboardMetricCard(metric: entry.value),
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _HomeMetricSectionData {
  const _HomeMetricSectionData({
    required this.title,
    required this.metrics,
  });

  final String title;
  final List<DashboardMetricData> metrics;
}

class HomeInfoCard extends StatelessWidget {
  const HomeInfoCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.accentColor,
    super.key,
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
        color: _homeSoftSurface(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _homeBorder(context)),
        gradient: _isDarkMode(context)
            ? LinearGradient(
                colors: [
                  accentColor.withValues(alpha: 0.18),
                  const Color(0xFF132F25),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DashboardStatusChip(label: title, color: accentColor),
          const SizedBox(height: 14),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: _homePrimaryText(context),
              fontSize: 30,
            ),
          ),
          const SizedBox(height: 8),
          Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class HomeHighlightsStrip extends StatelessWidget {
  const HomeHighlightsStrip({required this.items, super.key});

  final List<(String, String)> items;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: items
          .map(
            (item) => Container(
              width: 240,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _homeHighlightSurface(context),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _homeBorder(context)),
                boxShadow: _isDarkMode(context)
                    ? const [
                        BoxShadow(
                          color: Color(0x26020B08),
                          blurRadius: 12,
                          offset: Offset(0, 6),
                        ),
                      ]
                    : null,
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
                      color: _homePrimaryText(context),
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

class RecommendationLine extends StatelessWidget {
  const RecommendationLine({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 6),
            decoration: const BoxDecoration(
              color: dashboardAccentOrange,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _HomeAdInteractionTile extends StatelessWidget {
  const _HomeAdInteractionTile({
    required this.item,
    required this.rank,
    required this.isLast,
  });

  final DashboardAdInteractionData item;
  final int rank;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _homeSoftSurface(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _homeBorder(context)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: dashboardAccentOrange.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: dashboardAccentOrange.withValues(alpha: 0.22),
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              '$rank',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: dashboardAccentOrange,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.adTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: _homePrimaryText(context),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  item.sponsorName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: _homePrimaryText(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${item.clickCount}',
                style: Theme.of(
                  context,
                ).textTheme.headlineSmall?.copyWith(fontSize: 24),
              ),
              const SizedBox(height: 4),
              Text(
                'clicks',
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
