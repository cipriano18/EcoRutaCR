import 'package:flutter/material.dart';

const _kPanelAccent = Color(0xFFFFB59F);
const _kPanelMuted = Color(0xFF86AF99);

/// Panel compacto con métricas de una ruta en registro.
class RouteMetricsPanel extends StatelessWidget {
  const RouteMetricsPanel({
    super.key,
    required this.distanceMeters,
    required this.duration,
    required this.elevationGainMeters,
  });

  /// Distancia acumulada del recorrido en metros.
  final double distanceMeters;

  /// Duración registrada desde el inicio de la sesión.
  final Duration duration;

  /// Ascenso positivo acumulado en metros.
  final double elevationGainMeters;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 360;

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 16 : 20,
            vertical: compact ? 16 : 18,
          ),
          decoration: BoxDecoration(
            color: const Color(0xE61B4332),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.16),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.radar_rounded,
                    color: _kPanelAccent,
                    size: compact ? 16 : 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Registro en vivo',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                      fontSize: compact ? 13 : 14,
                    ),
                  ),
                ],
              ),
              SizedBox(height: compact ? 14 : 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _MetricItem(
                      label: 'DISTANCIA',
                      value: (distanceMeters / 1000).toStringAsFixed(1),
                      unit: 'km',
                      compact: compact,
                    ),
                  ),
                  _MetricDivider(compact: compact),
                  Expanded(
                    child: _MetricItem(
                      label: 'TIEMPO',
                      value: formatRouteDuration(duration),
                      unit: '',
                      centered: true,
                      compact: compact,
                    ),
                  ),
                  _MetricDivider(compact: compact),
                  Expanded(
                    child: _MetricItem(
                      label: 'ELEVACION',
                      value: elevationGainMeters.round().toString(),
                      unit: 'm',
                      alignEnd: true,
                      compact: compact,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Formatea una duración de ruta como `HH:mm:ss`.
String formatRouteDuration(Duration value) {
  final hours = value.inHours.toString().padLeft(2, '0');
  final minutes = (value.inMinutes % 60).toString().padLeft(2, '0');
  final seconds = (value.inSeconds % 60).toString().padLeft(2, '0');
  return '$hours:$minutes:$seconds';
}

class _MetricItem extends StatelessWidget {
  const _MetricItem({
    required this.label,
    required this.value,
    required this.unit,
    this.centered = false,
    this.alignEnd = false,
    this.compact = false,
  });

  final String label;
  final String value;
  final String unit;
  final bool centered;
  final bool alignEnd;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.start;
    if (centered) {
      crossAxisAlignment = CrossAxisAlignment.center;
    } else if (alignEnd) {
      crossAxisAlignment = CrossAxisAlignment.end;
    }

    return Column(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        SizedBox(
          height: compact ? 14 : 16,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: centered
                ? Alignment.center
                : alignEnd
                ? Alignment.centerRight
                : Alignment.centerLeft,
            child: Text(
              label,
              maxLines: 1,
              style: TextStyle(
                color: _kPanelAccent,
                fontSize: compact ? 8.5 : 10,
                fontWeight: FontWeight.w800,
                letterSpacing: compact ? 0.8 : 1.4,
              ),
            ),
          ),
        ),
        SizedBox(height: compact ? 4 : 6),
        if (unit.isEmpty)
          SizedBox(
            height: compact ? 26 : 30,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: centered
                  ? Alignment.center
                  : alignEnd
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
              child: Text(
                value,
                maxLines: 1,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: compact ? 20 : 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: compact ? -0.4 : -0.8,
                ),
              ),
            ),
          )
        else
          SizedBox(
            height: compact ? 28 : 32,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: centered
                  ? Alignment.center
                  : alignEnd
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: compact ? 22 : 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: compact ? -0.4 : -0.8,
                    ),
                  ),
                  SizedBox(width: compact ? 2 : 4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      unit,
                      style: TextStyle(
                        color: _kPanelMuted,
                        fontSize: compact ? 11 : 13,
                        fontWeight: FontWeight.w700,
                      ),
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

class _MetricDivider extends StatelessWidget {
  const _MetricDivider({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: compact ? 40 : 44,
      margin: EdgeInsets.symmetric(horizontal: compact ? 10 : 16),
      color: Colors.white.withValues(alpha: 0.14),
    );
  }
}
