import 'dart:ui';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Define cómo se presenta la cabecera reutilizable de selección de puntos.
enum PointsPreviewMode { dualPoint, singleDestination }

/// Previsualiza en pequeño los puntos seleccionados y abre el selector en mapa.
class PointsPreview extends StatelessWidget {
  static const _primaryColor = Color(0xFF012D1D);
  static const _primaryFixed = Color(0xFFC1ECD4);
  static const _surfaceColor = Color(0xFFF8F9FA);
  static const _swapButtonColor = Color(0xFF2C694E);
  static const _tertiaryFixed = Color(0xFFFFB59F);
  static const _fallbackCenter = LatLng(9.9281, -84.0907);

  final MapController mapController;
  final LatLng? startPoint;
  final LatLng? destinationPoint;
  final LatLng? previewCenter;
  final String startLabel;
  final String destinationLabel;
  final VoidCallback? onSwap;
  final VoidCallback onSelectPoints;
  final PointsPreviewMode mode;
  final String actionLabel;
  final double? destinationRadiusKm;

  const PointsPreview({
    super.key,
    required this.mapController,
    required this.startPoint,
    required this.destinationPoint,
    required this.startLabel,
    required this.destinationLabel,
    required this.onSelectPoints,
    this.previewCenter,
    this.onSwap,
    this.mode = PointsPreviewMode.dualPoint,
    this.actionLabel = 'Seleccionar puntos',
    this.destinationRadiusKm,
  });

  bool get _showsDualPoint => mode == PointsPreviewMode.dualPoint;

  @override
  Widget build(BuildContext context) {
    final center = _resolveCenter();
    final initialCameraFit = _initialCameraFit();
    final markers = <Marker>[
      if (_showsDualPoint && startPoint != null)
        Marker(
          point: startPoint!,
          width: 84,
          height: 52,
          alignment: Alignment.topCenter,
          child: const _StartMarker(),
        ),
      if (destinationPoint != null)
        Marker(
          point: destinationPoint!,
          width: 44,
          height: 44,
          alignment: Alignment.center,
          child: const _DestinationMarker(),
        ),
    ];

    return SizedBox(
      height: _showsDualPoint ? 432 : 388,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 320,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: SizedBox.expand(
                      child: Stack(
                        children: [
                          FlutterMap(
                            mapController: mapController,
                            options: MapOptions(
                              initialCenter: center,
                              initialZoom: 11.5,
                              initialCameraFit: initialCameraFit,
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName:
                                    'com.example.lab2_moviles',
                              ),
                              Container(
                                color: _primaryColor.withValues(alpha: 0.08),
                              ),
                              if (destinationPoint != null &&
                                  destinationRadiusKm != null)
                                CircleLayer(
                                  circles: [
                                    CircleMarker(
                                      point: destinationPoint!,
                                      radius: destinationRadiusKm! * 1000,
                                      useRadiusInMeter: true,
                                      color: _tertiaryFixed.withValues(
                                        alpha: 0.20,
                                      ),
                                      borderColor: const Color(0xFF721D00),
                                      borderStrokeWidth: 2,
                                    ),
                                  ],
                                ),
                              MarkerLayer(markers: markers),
                            ],
                          ),
                          Positioned.fill(
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: onSelectPoints,
                                child: const SizedBox.expand(),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: IgnorePointer(
                              child: Container(
                                height: 120,
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Color.fromRGBO(248, 249, 250, 0),
                                      _surfaceColor,
                                    ],
                                    stops: [0, 0.92],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 18,
            right: 18,
            top: 250,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                if (_showsDualPoint) ...[
                                  _LocationRow(
                                    label: 'Inicio',
                                    value: startLabel,
                                    icon: Icons.circle,
                                    iconColor: _primaryFixed,
                                    emphasized: true,
                                  ),
                                  const SizedBox(height: 14),
                                ],
                                _LocationRow(
                                  label: 'Destino',
                                  value: destinationLabel,
                                  icon: Icons.location_on_rounded,
                                  iconColor: _tertiaryFixed,
                                  emphasized: false,
                                ),
                              ],
                            ),
                          ),
                          if (_showsDualPoint && onSwap != null) ...[
                            const SizedBox(width: 12),
                            InkWell(
                              onTap: onSwap,
                              borderRadius: BorderRadius.circular(24),
                              child: Ink(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: _swapButtonColor),
                                ),
                                child: const Icon(
                                  Icons.swap_vert_rounded,
                                  color: _swapButtonColor,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: onSelectPoints,
                          style: FilledButton.styleFrom(
                            backgroundColor: _primaryColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: Text(
                            actionLabel,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  LatLng _resolveCenter() {
    if (_showsDualPoint && startPoint != null && destinationPoint != null) {
      return LatLng(
        (startPoint!.latitude + destinationPoint!.latitude) / 2,
        (startPoint!.longitude + destinationPoint!.longitude) / 2,
      );
    }
    return destinationPoint ?? startPoint ?? previewCenter ?? _fallbackCenter;
  }

  CameraFit? _initialCameraFit() {
    if (!_showsDualPoint &&
        destinationPoint != null &&
        destinationRadiusKm != null) {
      return CameraFit.bounds(
        bounds: _boundsForRadius(destinationPoint!, destinationRadiusKm!),
        padding: const EdgeInsets.all(32),
      );
    }
    return null;
  }

  LatLngBounds _boundsForRadius(LatLng center, double radiusKm) {
    final latDelta = radiusKm / 111.0;
    final lonDelta = radiusKm /
        (111.0 * math.max(math.cos(center.latitude * math.pi / 180).abs(), 0.2));

    return LatLngBounds(
      LatLng(center.latitude - latDelta, center.longitude - lonDelta),
      LatLng(center.latitude + latDelta, center.longitude + lonDelta),
    );
  }
}

/// Fila de texto para mostrar una ubicación seleccionada.
class _LocationRow extends StatelessWidget {
  const _LocationRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.emphasized,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.6,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: emphasized ? FontWeight.w800 : FontWeight.w600,
                  color: const Color(0xFF191C1D),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Marcador visual del punto de inicio en la miniatura del mapa.
class _StartMarker extends StatelessWidget {
  const _StartMarker();

  static const _primaryColor = Color(0xFF012D1D);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: _primaryColor,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: _primaryColor.withValues(alpha: 0.25),
                blurRadius: 10,
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 10,
              ),
            ],
          ),
          child: const Text(
            'Inicio',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: _primaryColor,
            ),
          ),
        ),
      ],
    );
  }
}

/// Marcador visual del punto de destino en la miniatura del mapa.
class _DestinationMarker extends StatelessWidget {
  const _DestinationMarker();

  static const _tertiaryColor = Color(0xFF721D00);
  static const _tertiaryFixed = Color(0xFFFFB59F);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: _tertiaryFixed,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: _tertiaryColor.withValues(alpha: 0.22),
            blurRadius: 10,
          ),
        ],
      ),
      child: const Icon(Icons.flag_rounded, size: 12, color: _tertiaryColor),
    );
  }
}
