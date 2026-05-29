import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:ecoruta/navigation/main_shell.dart';
import 'package:ecoruta/widgets/app_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// Pantalla de mapa en vivo con seguimiento, brujula y elevacion.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const _primaryColor = Color(0xFF012D1D);
  static const _orangeColor = Color(0xFFFF7043);
  static const _elevationApiUserAgent = 'EcoRutaCR/1.0';
  static const LatLng _fallbackCenter = LatLng(9.9281, -84.0907);

  final MapController _mapController = MapController();

  StreamSubscription<Position>? _positionSubscription;
  StreamSubscription<CompassEvent>? _compassSubscription;
  Timer? _elevationRefreshTimer;

  LatLng? _currentPosition;
  bool _loading = true;
  bool _hasCompassSupport = false;
  bool _isCompassModeEnabled = false;
  double? _currentElevation;
  double _heading = 0;
  double _smoothedHeading = 0;

  @override
  void initState() {
    super.initState();
    _initLocation();
    _startCompassTracking();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _compassSubscription?.cancel();
    _elevationRefreshTimer?.cancel();
    super.dispose();
  }

  /// Inicializa permisos, posicion y flujos necesarios para el mapa en vivo.
  Future<void> _initLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        if (!mounted) return;
        setState(() => _loading = false);
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
        ),
      );
      final currentPoint = LatLng(pos.latitude, pos.longitude);

      if (!mounted) return;
      setState(() {
        _currentPosition = currentPoint;
        _loading = false;
      });

      _centerOnUser();
      await _refreshElevation();
      _startLocationTracking();
      _startElevationTimer();
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _startLocationTracking() {
    _positionSubscription?.cancel();
    _positionSubscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.bestForNavigation,
            distanceFilter: 1,
          ),
        ).listen((position) {
          final nextPosition = LatLng(position.latitude, position.longitude);

          if (!mounted) return;
          setState(() {
            _currentPosition = nextPosition;
          });
          _syncLiveMapCamera();
        });
  }

  void _startCompassTracking() {
    _compassSubscription?.cancel();
    final compassEvents = FlutterCompass.events;
    if (compassEvents == null) {
      if (!mounted) return;
      setState(() {
        _hasCompassSupport = false;
        _isCompassModeEnabled = false;
      });
      return;
    }

    setState(() => _hasCompassSupport = true);

    _compassSubscription = compassEvents.listen((event) {
      final rawHeading = event.heading;
      if (!mounted || rawHeading == null) return;

      final sanitized = _sanitizeHeading(rawHeading);
      final smoothed = _smoothHeading(_smoothedHeading, sanitized);

      setState(() {
        _heading = sanitized;
        _smoothedHeading = smoothed;
      });

      if (_isCompassModeEnabled) {
        _syncLiveMapCamera();
      }
    });
  }

  void _startElevationTimer() {
    _elevationRefreshTimer?.cancel();
    _elevationRefreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _refreshElevation(),
    );
  }

  /// Refresca la elevacion visible segun la posicion actual del usuario.
  Future<void> _refreshElevation() async {
    final currentPosition = _currentPosition;
    if (currentPosition == null) return;

    try {
      final elevation = await _fetchElevation(currentPosition);
      if (!mounted) return;
      setState(() => _currentElevation = elevation);
    } catch (_) {
      // Conserva el ultimo valor valido si falla la red.
    }
  }

  /// Consulta elevacion remota para el punto actual del usuario.
  Future<double> _fetchElevation(LatLng point) async {
    final uri = Uri.https('api.open-meteo.com', '/v1/elevation', {
      'latitude': point.latitude.toString(),
      'longitude': point.longitude.toString(),
    });

    final client = HttpClient();
    try {
      final request = await client.getUrl(uri);
      request.headers.set(HttpHeaders.userAgentHeader, _elevationApiUserAgent);
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException('Elevation request failed', uri: uri);
      }

      final data = jsonDecode(responseBody) as Map<String, dynamic>;
      final elevations = data['elevation'] as List<dynamic>?;
      if (elevations == null || elevations.isEmpty) {
        throw const FormatException('Elevation payload empty');
      }

      return (elevations.first as num).toDouble();
    } finally {
      client.close();
    }
  }

  void _centerOnUser() {
    final currentPosition = _currentPosition;
    if (currentPosition == null) return;

    final zoom = _safeZoom();
    if (_isCompassModeEnabled) {
      _mapController.moveAndRotate(currentPosition, zoom, -_smoothedHeading);
    } else {
      _mapController.moveAndRotate(currentPosition, zoom, 0);
    }
  }

  void _toggleCompassMode() {
    if (!_hasCompassSupport) return;
    setState(() => _isCompassModeEnabled = !_isCompassModeEnabled);
    _syncLiveMapCamera();
  }

  void _syncLiveMapCamera() {
    final currentPosition = _currentPosition;
    if (currentPosition == null) return;

    final zoom = _safeZoom();
    if (_isCompassModeEnabled) {
      _mapController.moveAndRotate(currentPosition, zoom, -_smoothedHeading);
    } else {
      _mapController.moveAndRotate(currentPosition, zoom, 0);
    }
  }

  double _safeZoom() {
    final zoom = _mapController.camera.zoom;
    if (zoom.isNaN || zoom.isInfinite || zoom == 0) {
      return 15;
    }
    return zoom;
  }

  double _sanitizeHeading(double rawHeading) {
    if (rawHeading.isNaN || rawHeading.isInfinite) {
      return _heading;
    }
    return (rawHeading % 360 + 360) % 360;
  }

  double _smoothHeading(double current, double target) {
    final delta = ((target - current + 540) % 360) - 180;
    return (current + (delta * 0.18) + 360) % 360;
  }

  void _openExploreTab() {
    MainShell.navigateToTab(context, 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppHeader(),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentPosition ?? _fallbackCenter,
              initialZoom: 15,
              interactionOptions: const InteractionOptions(
                flags:
                    InteractiveFlag.drag |
                    InteractiveFlag.pinchZoom |
                    InteractiveFlag.doubleTapZoom |
                    InteractiveFlag.doubleTapDragZoom |
                    InteractiveFlag.flingAnimation |
                    InteractiveFlag.rotate,
                rotationThreshold: 8,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.tuapp.trails',
              ),
              MarkerLayer(
                markers: [
                  if (_currentPosition != null)
                    Marker(
                      point: _currentPosition!,
                      width: 40,
                      height: 40,
                      child: Transform.rotate(
                        angle: _smoothedHeading * 3.1415926535897932 / 180,
                        child: Container(
                          decoration: BoxDecoration(
                            color: _primaryColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: _primaryColor.withValues(alpha: 0.4),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.navigation_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          if (_loading) const Center(child: CircularProgressIndicator()),
          Positioned(
            right: 10,
            top: 135,
            child: Column(
              children: [
                _MapButton(
                  icon: Icons.my_location_rounded,
                  onTap: _centerOnUser,
                ),
                const SizedBox(height: 12),
                _MapButton(
                  icon: _isCompassModeEnabled
                      ? Icons.explore_rounded
                      : Icons.explore_outlined,
                  onTap: _hasCompassSupport ? _toggleCompassMode : null,
                  isActive: _isCompassModeEnabled,
                  isDisabled: !_hasCompassSupport,
                ),
              ],
            ),
          ),
          Positioned(
            left: 10,
            top: 30,
            child: _CompassCard(heading: _smoothedHeading),
          ),
          Positioned(
            right: 10,
            top: 30,
            child: _ElevationCard(
              elevation: _currentElevation,
              accentColor: _orangeColor,
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 24,
            child: SafeArea(
              child: ElevatedButton.icon(
                onPressed: _openExploreTab,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                icon: const Icon(Icons.explore_rounded),
                label: const Text(
                  'Explorar rutas',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Panel compacto que resume la elevacion actual.
class _ElevationCard extends StatelessWidget {
  const _ElevationCard({required this.elevation, required this.accentColor});

  final double? elevation;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final elevationValue = elevation?.round();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ELEVATION',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: accentColor,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                elevationValue?.toString() ?? '--',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF012D1D),
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                'msnm',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: 100,
            height: 3,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: _progressFactor(elevation),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF012D1D),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _progressFactor(double? value) {
    if (value == null) return 0.2;
    final normalized = (value / 3000).clamp(0.1, 1.0);
    return normalized;
  }
}

/// Boton flotante reutilizable para acciones sobre el mapa.
class _MapButton extends StatelessWidget {
  const _MapButton({
    required this.icon,
    required this.onTap,
    this.isActive = false,
    this.isDisabled = false,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final bool isActive;
  final bool isDisabled;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isDisabled
              ? Colors.grey.shade300
              : isActive
              ? const Color(0xFF012D1D)
              : Colors.white.withValues(alpha: 0.92),
          border: isDisabled ? Border.all(color: Colors.grey.shade400) : null,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
            ),
          ],
        ),
        child: Icon(
          icon,
          color: isDisabled
              ? Colors.grey.shade600
              : isActive
              ? Colors.white
              : const Color(0xFF012D1D),
          size: 22,
        ),
      ),
    );
  }
}

/// Tarjeta que muestra el estado de la brujula y su orientacion.
class _CompassCard extends StatelessWidget {
  const _CompassCard({required this.heading});

  final double heading;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90,
      height: 90,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Positioned(top: 0, child: _CompassLabel('N')),
          const Positioned(bottom: 0, child: _CompassLabel('S')),
          const Positioned(left: 0, child: _CompassLabel('W')),
          const Positioned(right: 0, child: _CompassLabel('E')),
          Transform.rotate(
            angle: (-heading) * 3.1415926535897932 / 180,
            child: const Icon(
              Icons.navigation_rounded,
              color: Color(0xFF012D1D),
              size: 28,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompassLabel extends StatelessWidget {
  const _CompassLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w900,
        color: Color(0xFF012D1D),
      ),
    );
  }
}
