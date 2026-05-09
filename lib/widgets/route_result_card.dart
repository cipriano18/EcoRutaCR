import 'package:flutter/material.dart';

/// Tarjeta que resume el resultado de una ruta calculada o destacada.
class RouteResultCard extends StatelessWidget {
  static const _primaryColor = Color(0xFF012D1D);
  static const _secondaryContainer = Color(0xFFAEEECB);
  static const _highlightBadgeColor = Color(0xFFFF825C);
  static const _highlightTextColor = Color(0xFF4C1000);

  final String title;
  final String distance;
  final String duration;
  final String elevationGain;
  final Color accentColor;
  final IconData icon;
  final String? badge;
  final bool isHighlighted;
  final String buttonText;
  final VoidCallback? onPressed;
  final String? secondaryButtonText;
  final VoidCallback? onSecondaryPressed;
  final bool isSecondaryLoading;

  const RouteResultCard({
    super.key,
    required this.title,
    required this.distance,
    required this.duration,
    required this.elevationGain,
    required this.accentColor,
    required this.icon,
    this.badge,
    this.isHighlighted = false,
    this.buttonText = 'Seleccionar',
    this.onPressed,
    this.secondaryButtonText,
    this.onSecondaryPressed,
    this.isSecondaryLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          if (badge != null)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: isHighlighted ? _highlightBadgeColor : _primaryColor,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(28),
                    bottomLeft: Radius.circular(22),
                  ),
                ),
                child: Text(
                  badge!,
                  style: TextStyle(
                    color: isHighlighted ? _highlightTextColor : Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [accentColor, accentColor.withValues(alpha: 0.55)],
                        ),
                      ),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.35),
                                ),
                              ),
                            ),
                          ),
                          const Positioned(
                            left: 12,
                            top: 12,
                            child: Icon(
                              Icons.map_rounded,
                              size: 20,
                              color: _primaryColor,
                            ),
                          ),
                          Center(
                            child: Icon(icon, size: 34, color: _primaryColor),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(top: badge != null ? 8 : 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: _primaryColor,
                                letterSpacing: -0.4,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 14,
                              runSpacing: 8,
                              children: [
                                _MetricChip(
                                  icon: Icons.straighten_rounded,
                                  value: distance,
                                  valueColor: Colors.grey.shade700,
                                ),
                                _MetricChip(
                                  icon: Icons.schedule_rounded,
                                  value: duration,
                                  valueColor: Colors.grey.shade700,
                                ),
                                _MetricChip(
                                  icon: Icons.trending_up_rounded,
                                  value: elevationGain,
                                  iconColor: const Color(0xFF721D00),
                                  valueColor: const Color(0xFF721D00),
                                  emphasized: true,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (secondaryButtonText == null)
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: onPressed,
                      style: FilledButton.styleFrom(
                        backgroundColor: _secondaryContainer,
                        foregroundColor: _primaryColor,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        buttonText,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: isSecondaryLoading
                              ? null
                              : onSecondaryPressed,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _primaryColor,
                            side: BorderSide(
                              color: _primaryColor.withValues(alpha: 0.18),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: isSecondaryLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  secondaryButtonText!,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: onPressed,
                          style: FilledButton.styleFrom(
                            backgroundColor: _secondaryContainer,
                            foregroundColor: _primaryColor,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            buttonText,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Chip compacto para mostrar una métrica secundaria de la ruta.
class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.icon,
    required this.value,
    required this.valueColor,
    this.iconColor = Colors.grey,
    this.emphasized = false,
  });

  final IconData icon;
  final String value;
  final Color iconColor;
  final Color valueColor;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: emphasized ? FontWeight.w800 : FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

/*
Este archivo corresponde a las cards de resultado de busqueda o generaciond de las rutas.
Actualmente se utliza en:

screens/explore/tabs:

 - generate_tab.dart
 - search_tab.dart
*/
