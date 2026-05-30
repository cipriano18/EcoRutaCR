import 'package:ecoruta/models/geo_node.dart';
import 'package:ecoruta/models/guided_saved_route.dart';
import 'package:ecoruta/models/route_profile.dart';
import 'package:ecoruta/navigation/main_shell.dart';
import 'package:ecoruta/services/routing/a_star_router.dart';
import 'package:ecoruta/services/routing/route_result.dart';
import 'package:ecoruta/services/saved_routes_service.dart';
import 'package:ecoruta/widgets/confirm_dialog.dart';
import 'package:ecoruta/widgets/save_route_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// Presenta la geometria y metricas de una ruta ya calculada.
class RoutePreviewScreen extends StatefulWidget {
  const RoutePreviewScreen({
    super.key,
    required this.title,
    required this.route,
    this.profile,
    this.preference,
    this.startLabel,
    this.endLabel,
    this.allowSave = false,
    this.enableStartAction = false,
    this.guidedRoute,
  });

  final String title;
  final RouteResult route;
  final RouteProfile? profile;
  final RoutingPreference? preference;
  final String? startLabel;
  final String? endLabel;
  final bool allowSave;
  final bool enableStartAction;
  final GuidedSavedRoute? guidedRoute;

  @override
  State<RoutePreviewScreen> createState() => _RoutePreviewScreenState();
}

class _RoutePreviewScreenState extends State<RoutePreviewScreen> {
  static const _primaryColor = Color(0xFF012D1D);
  static const _accentColor = Color(0xFFFF7043);
  static const double _guidedStartRangeMeters = 50;

  final SavedRoutesService _savedRoutesService = SavedRoutesService();

  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final points = widget.route.path
        .map((node) => LatLng(node.latitude, node.longitude))
        .toList(growable: false);
    final hasRouteGeometry = points.isNotEmpty;
    final bounds = _boundsForRoute(widget.route.path);
    final startPoint = points.isNotEmpty ? points.first : null;
    final endPoint = points.length > 1 ? points.last : startPoint;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FA),
        title: Text(
          widget.title,
          style: const TextStyle(
            color: _primaryColor,
            fontWeight: FontWeight.w800,
          ),
        ),
        iconTheme: const IconThemeData(color: _primaryColor),
        actions: [
          if (widget.allowSave)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                onPressed: _isSaving ? null : _saveRoute,
                icon: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.bookmark_add_outlined),
                label: const Text('Guardar'),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: _centerForBounds(bounds),
                    initialZoom: 14,
                    initialCameraFit: hasRouteGeometry
                        ? CameraFit.bounds(
                            bounds: bounds,
                            padding: const EdgeInsets.all(48),
                          )
                        : null,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.lab2_moviles',
                    ),
                    if (hasRouteGeometry)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: points,
                            strokeWidth: 5,
                            color: _primaryColor,
                          ),
                        ],
                      ),
                    MarkerLayer(
                      markers: [
                        if (startPoint != null)
                          Marker(
                            point: startPoint,
                            width: widget.enableStartAction ? 126 : 52,
                            height: 52,
                            child: _RoutePointMarker(
                              icon: Icons.play_arrow_rounded,
                              color: _primaryColor,
                              label: widget.enableStartAction
                                  ? 'Iniciar'
                                  : null,
                              onTap: widget.enableStartAction
                                  ? _confirmStartRoute
                                  : null,
                            ),
                          ),
                        if (endPoint != null)
                          Marker(
                            point: endPoint,
                            width: 52,
                            height: 52,
                            child: const _RoutePointMarker(
                              icon: Icons.flag_rounded,
                              color: _accentColor,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!hasRouteGeometry)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF1EC),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'No se pudo reconstruir el trazado completo de esta ruta en este dispositivo.',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF721D00),
                        height: 1.35,
                      ),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _MetricTile(
                        label: 'Distancia',
                        value: widget.route.formattedDistance,
                      ),
                      _MetricTile(
                        label: 'Tiempo',
                        value: widget.route.formattedDuration,
                      ),
                      _MetricTile(
                        label: 'Desnivel',
                        value: widget.route.formattedElevationGain,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Guarda la ruta actual en Firestore con los metadatos elegidos por el usuario.
  Future<void> _saveRoute() async {
    if (widget.profile == null || widget.preference == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Faltan datos de la ruta para poder guardarla.'),
        ),
      );
      return;
    }

    final saveData = await showModalBottomSheet<SaveRouteFormResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SaveRouteSheet(
        initialTitle: widget.title,
        startLabel: widget.startLabel ?? 'Origen',
        endLabel: widget.endLabel ?? 'Destino',
      ),
    );

    if (saveData == null || !mounted) return;

    setState(() => _isSaving = true);

    try {
      await _savedRoutesService.saveRoute(
        title: saveData.title,
        description: saveData.description,
        visibility: saveData.visibility,
        activityProfile: widget.profile!,
        routingPreference: widget.preference!,
        startLabel: widget.startLabel ?? 'Origen',
        endLabel: widget.endLabel ?? 'Destino',
        route: widget.route,
      );

      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: const Text('Ruta guardada en Mis rutas.'),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Ver',
            onPressed: () {
              final switched = MainShell.navigateToTab(context, 2);
              if (switched) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
          ),
        ),
      );
    } on SavedRouteException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo guardar la ruta. Intenta de nuevo.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _confirmStartRoute() async {
    final confirmed = await ConfirmDialog.mostrar(
      context,
      titulo: 'Iniciar ruta',
      mensaje:
          'Quieres abrir esta ruta en el mapa principal para seguirla desde el punto de salida?',
      textoConfirmar: 'Comenzar',
    );

    if (!confirmed || !mounted) return;

    final guidedRoute = widget.guidedRoute;
    if (guidedRoute == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No pudimos preparar esta ruta para seguimiento.'),
        ),
      );
      return;
    }

    if (MainShell.hasActiveTrackedRoute(context)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Tienes una ruta en proceso. Terminala o cancelala para poder iniciar otra.',
          ),
        ),
      );
      return;
    }

    final isNearStart = await _isUserNearRouteStart(guidedRoute);
    if (!mounted) return;
    if (!isNearStart) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Acercate un poco mas al inicio de la ruta para poder comenzarla.',
          ),
        ),
      );
      return;
    }

    final didOpen = MainShell.openGuidedSavedRoute(context, guidedRoute);
    if (!didOpen || !mounted) return;
    Navigator.of(context).pop();
  }

  Future<bool> _isUserNearRouteStart(GuidedSavedRoute route) async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return false;
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
      ),
    );

    final distance = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      route.startPoint.latitude,
      route.startPoint.longitude,
    );

    return distance <= _guidedStartRangeMeters;
  }

  LatLngBounds _boundsForRoute(List<GeoNode> path) {
    if (path.isEmpty) {
      return LatLngBounds(
        const LatLng(9.9281, -84.0907),
        const LatLng(9.9281, -84.0907),
      );
    }

    var minLat = path.first.latitude;
    var maxLat = path.first.latitude;
    var minLon = path.first.longitude;
    var maxLon = path.first.longitude;

    for (final node in path.skip(1)) {
      if (node.latitude < minLat) minLat = node.latitude;
      if (node.latitude > maxLat) maxLat = node.latitude;
      if (node.longitude < minLon) minLon = node.longitude;
      if (node.longitude > maxLon) maxLon = node.longitude;
    }

    return LatLngBounds(LatLng(minLat, minLon), LatLng(maxLat, maxLon));
  }

  LatLng _centerForBounds(LatLngBounds bounds) {
    return LatLng(
      (bounds.north + bounds.south) / 2,
      (bounds.east + bounds.west) / 2,
    );
  }
}

/// Marcador simple para senalar inicio o fin del recorrido.
class _RoutePointMarker extends StatelessWidget {
  const _RoutePointMarker({
    required this.icon,
    required this.color,
    this.label,
    this.onTap,
  });

  final IconData icon;
  final Color color;
  final String? label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final marker = Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.24),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    );

    final content = label == null
        ? marker
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Text(
                  label!,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF012D1D),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              marker,
            ],
          );

    return GestureDetector(onTap: onTap, child: content);
  }
}

/// Muestra una metrica resumida dentro de la vista previa.
class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: Colors.grey,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: Color(0xFF012D1D),
          ),
        ),
      ],
    );
  }
}
