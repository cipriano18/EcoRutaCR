import 'package:flutter/material.dart';

import '../../shared/dashboard_mock_ui.dart';

enum DashboardReportType { users, sponsors, ads, publicRoutes }

class DashboardReportFilter {
  const DashboardReportFilter({required this.label, required this.matches});

  final String label;
  final bool Function(DashboardReportRow row) matches;
}

class DashboardReportRow {
  const DashboardReportRow({
    required this.primary,
    required this.secondary,
    required this.detail,
    required this.status,
    required this.activity,
    required this.actionLabel,
  });

  final String primary;
  final String secondary;
  final String detail;
  final String status;
  final String activity;
  final String actionLabel;
}

class DashboardReportMetric extends DashboardMetricData {
  const DashboardReportMetric({
    required super.title,
    required super.value,
    required super.changeLabel,
    required super.icon,
    required super.accentColor,
  });
}

typedef DashboardReportHighlight = (String, String, Color);

class DashboardReportConfig {
  const DashboardReportConfig({
    required this.title,
    required this.shortLabel,
    required this.description,
    required this.icon,
    required this.metrics,
    required this.filters,
    required this.primaryColumnLabel,
    required this.secondaryColumnLabel,
    required this.detailColumnLabel,
    required this.activityColumnLabel,
    required this.showStatusColumn,
    required this.rows,
    required this.asideTitle,
    required this.asideSubtitle,
    required this.timeline,
    required this.highlights,
  });

  final String title;
  final String shortLabel;
  final String description;
  final IconData icon;
  final List<DashboardMetricData> metrics;
  final List<DashboardReportFilter> filters;
  final String primaryColumnLabel;
  final String secondaryColumnLabel;
  final String detailColumnLabel;
  final String activityColumnLabel;
  final bool showStatusColumn;
  final List<DashboardReportRow> rows;
  final String asideTitle;
  final String asideSubtitle;
  final List<DashboardActivityItem> timeline;
  final List<DashboardReportHighlight> highlights;

  DashboardReportConfig copyWith({
    List<DashboardMetricData>? metrics,
    List<DashboardReportRow>? rows,
    List<DashboardActivityItem>? timeline,
    List<DashboardReportHighlight>? highlights,
  }) {
    return DashboardReportConfig(
      title: title,
      shortLabel: shortLabel,
      description: description,
      icon: icon,
      metrics: metrics ?? this.metrics,
      filters: filters,
      primaryColumnLabel: primaryColumnLabel,
      secondaryColumnLabel: secondaryColumnLabel,
      detailColumnLabel: detailColumnLabel,
      activityColumnLabel: activityColumnLabel,
      showStatusColumn: showStatusColumn,
      rows: rows ?? this.rows,
      asideTitle: asideTitle,
      asideSubtitle: asideSubtitle,
      timeline: timeline ?? this.timeline,
      highlights: highlights ?? this.highlights,
    );
  }

  DashboardReportConfig withLiveEmptyState() {
    return copyWith(
      metrics: const [],
      rows: const [],
      timeline: const [],
      highlights: const [],
    );
  }
}
