import 'package:flutter/material.dart';

import '../../../services/dashboard_statistics_service.dart';
import '../shared/dashboard_mock_ui.dart';

bool _isDarkMode(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark;

Color _statisticsSoftSurface(BuildContext context) =>
    _isDarkMode(context) ? const Color(0xFF171D1B) : const Color(0xFFF8FAF9);

Color _statisticsBorder(BuildContext context) =>
    _isDarkMode(context) ? const Color(0xFF2D3431) : dashboardBorder;

Color _statisticsPrimaryText(BuildContext context) =>
    _isDarkMode(context) ? const Color(0xFFE7ECE9) : dashboardBrandGreen;

class StatisticsHighlights extends StatelessWidget {
  const StatisticsHighlights({required this.items, super.key});

  final List<DashboardStatisticsHighlight> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _statisticsSoftSurface(context),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _statisticsBorder(context)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: item.color.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(Icons.insights_outlined, color: item.color),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item.value,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontSize: 16,
                                  color: _statisticsPrimaryText(context),
                                ),
                          ),
                        ],
                      ),
                    ),
                    DashboardStatusChip(label: item.badge, color: item.color),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class EmptyStatisticsState extends StatelessWidget {
  const EmptyStatisticsState({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _statisticsSoftSurface(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _statisticsBorder(context)),
      ),
      child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
    );
  }
}
