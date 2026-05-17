import 'package:flutter/material.dart';

import '../../screens/dashboard/reports/models/report_models.dart';
import '../../screens/dashboard/shared/dashboard_mock_ui.dart';

bool _isDarkMode(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark;

Color _reportHighlightSurface(BuildContext context) =>
    _isDarkMode(context) ? const Color(0xFF17352A) : const Color(0xFFF8FAF9);

Color _reportHighlightBorder(BuildContext context) =>
    _isDarkMode(context) ? const Color(0xFF1B4332) : Colors.transparent;

Color _reportValueColor(BuildContext context) =>
    _isDarkMode(context) ? dashboardSupportGreen : const Color(0xFF17392D);

class ReportAside extends StatelessWidget {
  const ReportAside({required this.config, super.key});

  final DashboardReportConfig config;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DashboardSectionCard(
          title: config.asideTitle,
          subtitle: config.asideSubtitle,
          child: Column(
            children: config.highlights
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _reportHighlightSurface(context),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: _reportHighlightBorder(context),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: item.$3,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              item.$1,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                          Text(
                            item.$2,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: _reportValueColor(context),
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 20),
        DashboardSectionCard(
          title: 'Timeline de actividad',
          subtitle:
              'Secuencia visual simulada de eventos recientes asociados a este reporte.',
          child: DashboardRecentActivityList(items: config.timeline),
        ),
      ],
    );
  }
}
