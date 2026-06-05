import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

bool _isDarkMode(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark;

Color _borderColor(BuildContext context) =>
    _isDarkMode(context) ? const Color(0xFF1B4332) : const Color(0xFFE7E8E9);

Color _surfaceColor(BuildContext context) =>
    _isDarkMode(context) ? const Color(0xFF132F25) : const Color(0xFFF8F9FA);

class SponsorMapMarkerData {
  const SponsorMapMarkerData({
    required this.point,
    required this.label,
    this.icon = Icons.location_on_rounded,
    this.pinColor = const Color(0xFFFF7043),
    this.iconColor = Colors.white,
    this.size = 42,
  });

  final LatLng point;
  final String label;
  final IconData icon;
  final Color pinColor;
  final Color iconColor;
  final double size;
}

class SponsorMapCanvas extends StatelessWidget {
  const SponsorMapCanvas({
    required this.center,
    this.mapController,
    this.selectedPoint,
    this.markers = const [],
    this.markerBuilder,
    this.zoom = 13,
    this.onTap,
    this.interactionFlags = InteractiveFlag.all,
    this.showLabels = false,
    super.key,
  });

  final LatLng center;
  final MapController? mapController;
  final LatLng? selectedPoint;
  final List<SponsorMapMarkerData> markers;
  final Widget Function(SponsorMapMarkerData marker)? markerBuilder;
  final double zoom;
  final ValueChanged<LatLng>? onTap;
  final int interactionFlags;
  final bool showLabels;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelSurface = _isDarkMode(context)
        ? const Color(0xFF0B261D)
        : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: _surfaceColor(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _borderColor(context)),
      ),
      clipBehavior: Clip.antiAlias,
      child: FlutterMap(
        mapController: mapController,
        options: MapOptions(
          initialCenter: center,
          initialZoom: zoom,
          interactionOptions: InteractionOptions(flags: interactionFlags),
          onTap: onTap == null ? null : (_, point) => onTap!(point),
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.ecoruta.admin.web',
            panBuffer: 1,
          ),
          MarkerLayer(
            markers: [
              ...markers.map((marker) {
                final hasCustomBuilder = markerBuilder != null;
                return Marker(
                  point: marker.point,
                  width: hasCustomBuilder
                      ? 52
                      : (showLabels ? 136 : marker.size),
                  height: hasCustomBuilder
                      ? 52
                      : (showLabels ? 72 : marker.size),
                  alignment: Alignment.topCenter,
                  child:
                      markerBuilder?.call(marker) ??
                      _MapMarkerBubble(
                        label: marker.label,
                        icon: marker.icon,
                        pinColor: marker.pinColor,
                        iconColor: marker.iconColor,
                        size: marker.size,
                        showLabel: showLabels,
                        labelStyle: theme.textTheme.bodySmall,
                        labelSurface: labelSurface,
                        borderColor: _borderColor(context),
                      ),
                );
              }),
              if (selectedPoint != null)
                Marker(
                  point: selectedPoint!,
                  width: 54,
                  height: 54,
                  child: const Icon(
                    Icons.location_on_rounded,
                    size: 46,
                    color: Color(0xFFFF7043),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MapMarkerBubble extends StatelessWidget {
  const _MapMarkerBubble({
    required this.label,
    required this.icon,
    required this.pinColor,
    required this.iconColor,
    required this.size,
    required this.showLabel,
    required this.labelStyle,
    required this.labelSurface,
    required this.borderColor,
  });

  final String label;
  final IconData icon;
  final Color pinColor;
  final Color iconColor;
  final double size;
  final bool showLabel;
  final TextStyle? labelStyle;
  final Color labelSurface;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final pin = Icon(icon, size: size, color: pinColor);

    if (!showLabel) return pin;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          constraints: const BoxConstraints(maxWidth: 130),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: labelSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: labelStyle?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        Transform.translate(
          offset: const Offset(0, -4),
          child: Icon(icon, size: size, color: pinColor),
        ),
      ],
    );
  }
}
