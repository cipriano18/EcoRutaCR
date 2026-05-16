import 'dart:math' as math;

import 'package:flutter/material.dart';

const dashboardBrandGreen = Color(0xFF012D1D);
const dashboardSupportGreen = Color(0xFF2C694E);
const dashboardSoftGreen = Color(0xFF4EAC7F);
const dashboardLightGreen = Color(0xFFC1ECD4);
const dashboardAccentOrange = Color(0xFFFF7043);
const dashboardBorder = Color(0xFFE7E8E9);

class DashboardMetricData {
  const DashboardMetricData({
    required this.title,
    required this.value,
    required this.changeLabel,
    required this.icon,
    required this.accentColor,
  });

  final String title;
  final String value;
  final String changeLabel;
  final IconData icon;
  final Color accentColor;
}

class DashboardBarDatum {
  const DashboardBarDatum({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;
}

class DashboardLineDatum {
  const DashboardLineDatum({required this.label, required this.value});

  final String label;
  final double value;
}

class DashboardPieDatum {
  const DashboardPieDatum({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;
}

class DashboardActivityItem {
  const DashboardActivityItem({
    required this.title,
    required this.detail,
    required this.timeLabel,
    required this.icon,
    required this.accentColor,
  });

  final String title;
  final String detail;
  final String timeLabel;
  final IconData icon;
  final Color accentColor;
}

const dashboardOverviewMetrics = [
  DashboardMetricData(
    title: 'Total de patrocinadores',
    value: '128',
    changeLabel: '+12 este mes',
    icon: Icons.handshake_outlined,
    accentColor: dashboardSoftGreen,
  ),
  DashboardMetricData(
    title: 'Total de clientes',
    value: '2,450',
    changeLabel: '+8.4% semanal',
    icon: Icons.groups_2_outlined,
    accentColor: dashboardBrandGreen,
  ),
  DashboardMetricData(
    title: 'Total de administradores',
    value: '18',
    changeLabel: '2 nuevos activos',
    icon: Icons.admin_panel_settings_outlined,
    accentColor: dashboardSupportGreen,
  ),
  DashboardMetricData(
    title: 'Publicidades activas',
    value: '74',
    changeLabel: '91% en linea',
    icon: Icons.campaign_outlined,
    accentColor: dashboardAccentOrange,
  ),
  DashboardMetricData(
    title: 'Puntos registrados en mapa',
    value: '316',
    changeLabel: '+24 agregados',
    icon: Icons.location_on_outlined,
    accentColor: dashboardSoftGreen,
  ),
];

const dashboardBarData = [
  DashboardBarDatum(label: 'Patroc.', value: 72, color: dashboardBrandGreen),
  DashboardBarDatum(label: 'Clientes', value: 96, color: dashboardSoftGreen),
  DashboardBarDatum(label: 'Admins', value: 34, color: dashboardSupportGreen),
  DashboardBarDatum(label: 'Ads', value: 80, color: dashboardAccentOrange),
  DashboardBarDatum(label: 'Mapa', value: 62, color: dashboardLightGreen),
];

const dashboardLineData = [
  DashboardLineDatum(label: 'Ene', value: 28),
  DashboardLineDatum(label: 'Feb', value: 36),
  DashboardLineDatum(label: 'Mar', value: 32),
  DashboardLineDatum(label: 'Abr', value: 48),
  DashboardLineDatum(label: 'May', value: 58),
  DashboardLineDatum(label: 'Jun', value: 54),
];

const dashboardPieData = [
  DashboardPieDatum(label: 'Activas', value: 52, color: dashboardBrandGreen),
  DashboardPieDatum(label: 'Programadas', value: 28, color: dashboardSoftGreen),
  DashboardPieDatum(label: 'Revision', value: 20, color: dashboardAccentOrange),
];

const dashboardRecentActivity = [
  DashboardActivityItem(
    title: 'Nuevo patrocinador registrado',
    detail: 'Verde Urbano se incorporo a la red comercial.',
    timeLabel: 'Hace 12 min',
    icon: Icons.handshake_outlined,
    accentColor: dashboardSoftGreen,
  ),
  DashboardActivityItem(
    title: 'Publicidad actualizada',
    detail: 'Campana de temporada para Ruta Central ajustada.',
    timeLabel: 'Hace 32 min',
    icon: Icons.campaign_outlined,
    accentColor: dashboardAccentOrange,
  ),
  DashboardActivityItem(
    title: 'Administrador agregado',
    detail: 'Se habilito acceso operativo para gestion interna.',
    timeLabel: 'Hace 1 h',
    icon: Icons.admin_panel_settings_outlined,
    accentColor: dashboardBrandGreen,
  ),
  DashboardActivityItem(
    title: 'Nuevo punto agregado al mapa',
    detail: 'Zona Norte recibio un nuevo punto promocional.',
    timeLabel: 'Hace 2 h',
    icon: Icons.location_on_outlined,
    accentColor: dashboardSupportGreen,
  ),
];

class DashboardSurfaceCard extends StatelessWidget {
  const DashboardSurfaceCard({
    required this.child,
    this.padding = const EdgeInsets.all(24),
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: dashboardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A012D1D),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class DashboardHeroCard extends StatelessWidget {
  const DashboardHeroCard({
    required this.title,
    required this.subtitle,
    this.badges = const [],
    this.trailing,
    super.key,
  });

  final String title;
  final String subtitle;
  final List<Widget> badges;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return DashboardSurfaceCard(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 700;
          final textBlock = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.headlineLarge?.copyWith(fontSize: 34),
              ),
              const SizedBox(height: 12),
              Text(subtitle, style: Theme.of(context).textTheme.bodyLarge),
              if (badges.isNotEmpty) ...[
                const SizedBox(height: 18),
                Wrap(spacing: 10, runSpacing: 10, children: badges),
              ],
            ],
          );

          if (compact || trailing == null) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                textBlock,
                if (trailing != null) ...[
                  const SizedBox(height: 20),
                  trailing!,
                ],
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: textBlock),
              const SizedBox(width: 20),
              trailing!,
            ],
          );
        },
      ),
    );
  }
}

class DashboardHeroBadge extends StatelessWidget {
  const DashboardHeroBadge({
    required this.label,
    required this.icon,
    super.key,
  });

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF5EF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: dashboardSupportGreen),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: dashboardBrandGreen,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class DashboardMetricGrid extends StatelessWidget {
  const DashboardMetricGrid({required this.metrics, super.key});

  final List<DashboardMetricData> metrics;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: metrics
          .map((metric) => DashboardMetricCard(metric: metric))
          .toList(),
    );
  }
}

class DashboardMetricCard extends StatelessWidget {
  const DashboardMetricCard({required this.metric, super.key});

  final DashboardMetricData metric;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: DashboardSurfaceCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    metric.title,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: metric.accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(metric.icon, color: metric.accentColor),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              metric.value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontSize: 30,
              ),
            ),
            const SizedBox(height: 10),
            DashboardStatusChip(
              label: metric.changeLabel,
              color: dashboardSupportGreen,
              backgroundColor: const Color(0xFFF3F8F5),
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardSectionCard extends StatelessWidget {
  const DashboardSectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
    this.actions,
    super.key,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? actions;

  @override
  Widget build(BuildContext context) {
    return DashboardSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(subtitle, style: Theme.of(context).textTheme.bodyLarge),
                  ],
                ),
              ),
              if (actions != null) ...[
                const SizedBox(width: 16),
                actions!,
              ],
            ],
          ),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }
}

class DashboardStatusChip extends StatelessWidget {
  const DashboardStatusChip({
    required this.label,
    required this.color,
    this.backgroundColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    super.key,
  });

  final String label;
  final Color color;
  final Color? backgroundColor;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class DashboardActionGhostButton extends StatelessWidget {
  const DashboardActionGhostButton({
    required this.label,
    required this.icon,
    this.onTap,
    super.key,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF6F7F8),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: dashboardBrandGreen),
              const SizedBox(width: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: dashboardBrandGreen,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DashboardRecentActivityList extends StatelessWidget {
  const DashboardRecentActivityList({required this.items, super.key});

  final List<DashboardActivityItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items
          .asMap()
          .entries
          .map(
            (entry) => _RecentActivityTile(
              item: entry.value,
              isLast: entry.key == items.length - 1,
            ),
          )
          .toList(),
    );
  }
}

class DashboardBarChart extends StatelessWidget {
  const DashboardBarChart({required this.data, super.key});

  final List<DashboardBarDatum> data;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 240,
          child: CustomPaint(
            painter: _BarChartPainter(data),
            child: const SizedBox.expand(),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: data
              .map(
                (item) => _LegendChip(
                  color: item.color,
                  label: '${item.label} ${item.value}',
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class DashboardLineChart extends StatelessWidget {
  const DashboardLineChart({required this.data, super.key});

  final List<DashboardLineDatum> data;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 270,
      child: CustomPaint(
        painter: _LineChartPainter(data),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class DashboardPieChart extends StatelessWidget {
  const DashboardPieChart({required this.data, super.key});

  final List<DashboardPieDatum> data;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 220,
          child: CustomPaint(
            painter: _PieChartPainter(data),
            child: const SizedBox.expand(),
          ),
        ),
        const SizedBox(height: 20),
        ...data.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: item.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: dashboardBrandGreen,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  '${item.value}%',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: dashboardBrandGreen,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F7F8),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _RecentActivityTile extends StatelessWidget {
  const _RecentActivityTile({required this.item, required this.isLast});

  final DashboardActivityItem item;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: item.accentColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(item.icon, color: item.accentColor),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      color: const Color(0xFFE1E8E4),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAF9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: Theme.of(
                              context,
                            ).textTheme.titleMedium?.copyWith(fontSize: 15),
                          ),
                        ),
                        Text(
                          item.timeLabel,
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(item.detail, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BarChartPainter extends CustomPainter {
  _BarChartPainter(this.data);

  final List<DashboardBarDatum> data;

  @override
  void paint(Canvas canvas, Size size) {
    const leftPadding = 12.0;
    const bottomPadding = 28.0;
    const topPadding = 12.0;
    const gap = 16.0;
    final chartHeight = size.height - bottomPadding - topPadding;
    final chartWidth = size.width - leftPadding;
    final barWidth = (chartWidth - (gap * (data.length - 1))) / data.length;
    final maxValue = data.fold<double>(0, (max, item) => math.max(max, item.value));
    final gridPaint = Paint()
      ..color = const Color(0xFFE9EEEB)
      ..strokeWidth = 1;

    for (int i = 0; i < 4; i++) {
      final dy = topPadding + (chartHeight / 3) * i;
      canvas.drawLine(Offset(leftPadding, dy), Offset(size.width, dy), gridPaint);
    }

    for (int i = 0; i < data.length; i++) {
      final item = data[i];
      final ratio = item.value / maxValue;
      final barHeight = chartHeight * ratio;
      final left = leftPadding + (barWidth + gap) * i;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          left,
          topPadding + chartHeight - barHeight,
          barWidth,
          barHeight,
        ),
        const Radius.circular(14),
      );
      canvas.drawRRect(rect, Paint()..color = item.color);

      final labelPainter = TextPainter(
        text: TextSpan(
          text: item.label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFF5F746B),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: barWidth + 12);

      labelPainter.paint(
        canvas,
        Offset(left + (barWidth - labelPainter.width) / 2, size.height - 20),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) {
    return oldDelegate.data != data;
  }
}

class _LineChartPainter extends CustomPainter {
  _LineChartPainter(this.data);

  final List<DashboardLineDatum> data;

  @override
  void paint(Canvas canvas, Size size) {
    const leftPadding = 12.0;
    const rightPadding = 10.0;
    const topPadding = 16.0;
    const bottomPadding = 30.0;
    final chartWidth = size.width - leftPadding - rightPadding;
    final chartHeight = size.height - topPadding - bottomPadding;
    final maxValue = data.fold<double>(0, (max, item) => math.max(max, item.value));
    final stepX = data.length > 1 ? chartWidth / (data.length - 1) : chartWidth;
    final gridPaint = Paint()
      ..color = const Color(0xFFE9EEEB)
      ..strokeWidth = 1;

    for (int i = 0; i < 4; i++) {
      final dy = topPadding + (chartHeight / 3) * i;
      canvas.drawLine(Offset(leftPadding, dy), Offset(size.width - rightPadding, dy), gridPaint);
    }

    final path = Path();
    final fillPath = Path();

    for (int i = 0; i < data.length; i++) {
      final item = data[i];
      final dx = leftPadding + stepX * i;
      final dy = topPadding + chartHeight - (item.value / maxValue) * chartHeight;
      if (i == 0) {
        path.moveTo(dx, dy);
        fillPath.moveTo(dx, size.height - bottomPadding);
        fillPath.lineTo(dx, dy);
      } else {
        path.lineTo(dx, dy);
        fillPath.lineTo(dx, dy);
      }
    }

    fillPath.lineTo(leftPadding + stepX * (data.length - 1), size.height - bottomPadding);
    fillPath.close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0x334EAC7F), Color(0x004EAC7F)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = dashboardBrandGreen
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke,
    );

    for (int i = 0; i < data.length; i++) {
      final item = data[i];
      final dx = leftPadding + stepX * i;
      final dy = topPadding + chartHeight - (item.value / maxValue) * chartHeight;
      canvas.drawCircle(Offset(dx, dy), 5, Paint()..color = dashboardSoftGreen);
      canvas.drawCircle(Offset(dx, dy), 2.5, Paint()..color = Colors.white);

      final labelPainter = TextPainter(
        text: TextSpan(
          text: item.label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFF5F746B),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      labelPainter.paint(
        canvas,
        Offset(dx - (labelPainter.width / 2), size.height - 22),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.data != data;
  }
}

class _PieChartPainter extends CustomPainter {
  _PieChartPainter(this.data);

  final List<DashboardPieDatum> data;

  @override
  void paint(Canvas canvas, Size size) {
    final total = data.fold<double>(0, (sum, item) => sum + item.value);
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 12;
    final rect = Rect.fromCircle(center: center, radius: radius);
    double startAngle = -math.pi / 2;

    for (final item in data) {
      final sweepAngle = (item.value / total) * math.pi * 2;
      canvas.drawArc(
        rect,
        startAngle,
        sweepAngle,
        true,
        Paint()..color = item.color,
      );
      startAngle += sweepAngle;
    }

    canvas.drawCircle(center, radius * 0.52, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _PieChartPainter oldDelegate) {
    return oldDelegate.data != data;
  }
}
