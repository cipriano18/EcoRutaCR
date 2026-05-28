import 'dart:math' as math;

import 'package:ecoruta/models/route_profile.dart';
import 'package:ecoruta/models/stored_route.dart';
import 'package:ecoruta/screens/explore/route_preview_screen.dart';
import 'package:ecoruta/screens/picker_map.dart';
import 'package:ecoruta/services/saved_routes_service.dart';
import 'package:ecoruta/services/routing/route_result.dart';
import 'package:ecoruta/widgets/activity_type_card.dart';
import 'package:ecoruta/widgets/confirm_dialog.dart';
import 'package:ecoruta/widgets/points_preview.dart';
import 'package:ecoruta/widgets/route_result_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// Tab orientado a descubrir destinos y filtros de búsqueda.
class SearchTab extends StatefulWidget {
  const SearchTab({super.key});

  @override
  State<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab> {
  static const _primaryColor = Color(0xFF012D1D);
  static const _surfaceHighest = Color(0xFFE1E3E4);

  final MapController _mapController = MapController();
  final SavedRoutesService _savedRoutesService = SavedRoutesService();

  LatLng? _currentLocation;
  LatLng? _destinationPoint;
  String _destinationLabel = 'Pendiente de seleccionar';
  bool _isLoadingCurrentLocation = true;
  bool _isSearchingRoutes = false;
  bool _isMockSavingPublicRoute = false;
  bool _hasSearchedRoutes = false;
  String? _searchErrorMessage;
  List<_PublicRouteCardData> _publicRoutes = const [];

  int _selectedActivity = 0;
  double _radius = 25;

  @override
  void initState() {
    super.initState();
    _initCurrentLocation();
  }

  /// Intenta resolver la ubicación actual para centrar mejor la selección.
  Future<void> _initCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() => _isLoadingCurrentLocation = false);
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _isLoadingCurrentLocation = false;
      });
      _syncPreviewMap();
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingCurrentLocation = false);
    }
  }

  /// Abre el selector compartido en modo de solo destino.
  Future<void> _openDestinationPicker() async {
    final result = await Navigator.of(context).push<PointsSelectionResult>(
      MaterialPageRoute(
        builder: (_) => PickerMapScreen(
          initialStartPoint: null,
          initialDestinationPoint: _destinationPoint,
          currentLocation: _currentLocation,
          mode: PointSelectionMode.singleDestination,
        ),
      ),
    );

    if (result == null || !mounted) return;

    setState(() {
      _destinationPoint = result.destinationPoint;
      _destinationLabel = result.destinationLabel;
      _searchErrorMessage = null;
    });
    _syncPreviewMap();
  }

  /// Consulta rutas públicas dentro del radio elegido para el destino activo.
  Future<void> _searchPublicRoutes() async {
    if (_destinationPoint == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona un destino antes de buscar rutas.'),
        ),
      );
      return;
    }

    setState(() {
      _isSearchingRoutes = true;
      _hasSearchedRoutes = true;
      _searchErrorMessage = null;
    });

    try {
      final publicRoutes = await _savedRoutesService.fetchPublicRoutes();
      final creatorNames = await _savedRoutesService.fetchUserDisplayNames(
        publicRoutes.map((route) => route.ownerId),
      );
      final filteredRoutes = publicRoutes
          .where((route) {
            if (route.ownerId == _savedRoutesService.currentUserId) {
              return false;
            }

            if (route.activityProfile != _selectedProfile) {
              return false;
            }

            final distanceMeters = Geolocator.distanceBetween(
              _destinationPoint!.latitude,
              _destinationPoint!.longitude,
              route.endLat,
              route.endLon,
            );

            return distanceMeters <= _radius * 1000;
          })
          .toList(growable: true);
      filteredRoutes.sort((a, b) {
        final distanceToA = Geolocator.distanceBetween(
          _destinationPoint!.latitude,
          _destinationPoint!.longitude,
          a.endLat,
          a.endLon,
        );
        final distanceToB = Geolocator.distanceBetween(
          _destinationPoint!.latitude,
          _destinationPoint!.longitude,
          b.endLat,
          b.endLon,
        );
        return distanceToA.compareTo(distanceToB);
      });
      final filtered = filteredRoutes
          .map(
            (route) => _PublicRouteCardData(
              route: route,
              routeResult: route.toRouteResult(),
              creatorName:
                  creatorNames[route.ownerId]?.trim().isNotEmpty == true
                  ? creatorNames[route.ownerId]!
                  : 'usuario desconocido',
            ),
          )
          .toList(growable: false);

      if (!mounted) return;
      setState(() {
        _publicRoutes = filtered;
      });
    } on SavedRouteException catch (error) {
      if (!mounted) return;
      setState(() {
        _searchErrorMessage = error.message;
        _publicRoutes = const [];
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _searchErrorMessage =
            'No se pudieron consultar las rutas publicas en este momento.';
        _publicRoutes = const [];
      });
    } finally {
      if (mounted) {
        setState(() => _isSearchingRoutes = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final destinationPreviewLabel =
        _isLoadingCurrentLocation && _destinationPoint == null
        ? 'Cargando ubicacion actual...'
        : _destinationLabel;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      children: [
        _SectionLabel(text: 'Destino'),
        const SizedBox(height: 8),
        PointsPreview(
          mapController: _mapController,
          startPoint: null,
          destinationPoint: _destinationPoint,
          previewCenter: _currentLocation,
          startLabel: '',
          destinationLabel: destinationPreviewLabel,
          mode: PointsPreviewMode.singleDestination,
          actionLabel: 'Seleccionar destino',
          destinationRadiusKm: _destinationPoint != null ? _radius : null,
          onSelectPoints: _openDestinationPicker,
        ),
        const SizedBox(height: 28),
        _SectionLabel(text: 'Tipo de Actividad'),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ActivityTypeCard(
                icon: Icons.directions_bike_rounded,
                label: 'Ciclismo',
                selected: _selectedActivity == 0,
                onTap: () => setState(() => _selectedActivity = 0),
              ),
              const SizedBox(width: 14),
              ActivityTypeCard(
                icon: Icons.hiking_rounded,
                label: 'Senderismo',
                selected: _selectedActivity == 1,
                onTap: () => setState(() => _selectedActivity = 1),
              ),
              const SizedBox(width: 14),
              ActivityTypeCard(
                icon: Icons.directions_run_rounded,
                label: 'Running',
                selected: _selectedActivity == 2,
                onTap: () => setState(() => _selectedActivity = 2),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        const _HorizontalScrollHint(),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F5),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionLabel(text: 'Radio de Búsqueda'),
              const SizedBox(height: 4),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '${_radius.toInt()} ',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: _primaryColor,
                        letterSpacing: -1,
                      ),
                    ),
                    const TextSpan(
                      text: 'km',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: _primaryColor,
                  inactiveTrackColor: _surfaceHighest,
                  thumbColor: _primaryColor,
                  overlayColor: _primaryColor.withValues(alpha: 0.1),
                  trackHeight: 4,
                ),
                child: Slider(
                  value: _radius,
                  min: 1,
                  max: 100,
                  onChanged: (v) {
                    setState(() => _radius = v);
                    _syncPreviewMap();
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    '1 KM',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    '100 KM',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSearchingRoutes ? null : _searchPublicRoutes,
                  style: FilledButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isSearchingRoutes
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Buscar',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        _SectionLabel(text: 'Rutas Públicas Cercanas'),
        const SizedBox(height: 12),
        Text(
          _resultsSummaryText(),
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),
        if (_searchErrorMessage != null)
          _InfoCard(
            message: _searchErrorMessage!,
            icon: Icons.error_outline_rounded,
            iconColor: Colors.redAccent,
          )
        else if (!_hasSearchedRoutes)
          const _InfoCard(
            message:
                'Selecciona un destino, ajusta el radio y busca rutas publicas cercanas.',
            icon: Icons.travel_explore_rounded,
            iconColor: _primaryColor,
          )
        else if (_isSearchingRoutes)
          const _InfoCard(
            message: 'Buscando rutas publicas dentro del radio seleccionado...',
            icon: Icons.sync_rounded,
            iconColor: _primaryColor,
          )
        else if (_publicRoutes.isEmpty)
          const _InfoCard(
            message:
                'No se encontraron rutas publicas dentro del radio elegido para esta actividad.',
            icon: Icons.alt_route_rounded,
            iconColor: _primaryColor,
          )
        else
          ..._publicRoutes.map(
            (routeData) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: RouteResultCard(
                title: routeData.route.title,
                supportingText: 'Creada por ${routeData.creatorName}',
                distance: routeData.routeResult.formattedDistance,
                duration: routeData.routeResult.formattedDuration,
                elevationGain: routeData.routeResult.formattedElevationGain,
                accentColor: _accentForProfile(routeData.route.activityProfile),
                icon: _iconForProfile(routeData.route.activityProfile),
                badge: 'PUBLICA',
                isHighlighted: true,
                buttonText: 'Ver trazado',
                secondaryButtonText: 'Guardar',
                isSecondaryLoading: _isMockSavingPublicRoute,
                onSecondaryPressed: _isMockSavingPublicRoute
                    ? null
                    : () => _confirmSavePublicRoute(routeData),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => RoutePreviewScreen(
                        title: routeData.route.title,
                        route: routeData.routeResult,
                        profile: routeData.route.activityProfile,
                        preference: routeData.route.routingPreference,
                        startLabel: routeData.route.startLabel,
                        endLabel: routeData.route.endLabel,
                        allowSave: false,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }

  RouteProfile get _selectedProfile {
    switch (_selectedActivity) {
      case 0:
        return RouteProfile.cycling;
      case 2:
        return RouteProfile.running;
      case 1:
      default:
        return RouteProfile.hiking;
    }
  }

  String _resultsSummaryText() {
    if (!_hasSearchedRoutes) {
      return 'Todavia no has consultado rutas publicas para este destino';
    }
    if (_isSearchingRoutes) {
      return 'Consultando rutas de ${_selectedProfileLabel.toLowerCase()} cerca del destino seleccionado';
    }
    if (_searchErrorMessage != null) {
      return 'La consulta de rutas publicas no pudo completarse';
    }
    return 'Se encontraron ${_publicRoutes.length} rutas publicas de ${_selectedProfileLabel.toLowerCase()} dentro de ${_radius.toInt()} km';
  }

  Future<void> _confirmSavePublicRoute(_PublicRouteCardData routeData) async {
    final confirmed = await ConfirmDialog.mostrar(
      context,
      titulo: 'Guardar ruta publica',
      mensaje: 'Deseas guardar esta ruta creada por ${routeData.creatorName}?',
      textoConfirmar: 'Guardar',
    );

    if (!confirmed || !mounted) return;

    setState(() => _isMockSavingPublicRoute = true);
    try {
      await _savedRoutesService.savePublicRouteReference(
        route: routeData.route,
        creatorName: routeData.creatorName,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ruta guardada en la pestaña Guardadas.')),
      );
    } on SavedRouteException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) {
        setState(() => _isMockSavingPublicRoute = false);
      }
    }
  }

  String get _selectedProfileLabel {
    switch (_selectedProfile) {
      case RouteProfile.cycling:
        return 'Ciclismo';
      case RouteProfile.hiking:
        return 'Senderismo';
      case RouteProfile.running:
        return 'Running';
    }
  }

  Color _accentForProfile(RouteProfile profile) {
    switch (profile) {
      case RouteProfile.cycling:
        return const Color(0xFFAEEECB);
      case RouteProfile.hiking:
        return const Color(0xFFC1ECD4);
      case RouteProfile.running:
        return const Color(0xFFFFB59F);
    }
  }

  IconData _iconForProfile(RouteProfile profile) {
    switch (profile) {
      case RouteProfile.cycling:
        return Icons.directions_bike_rounded;
      case RouteProfile.hiking:
        return Icons.hiking_rounded;
      case RouteProfile.running:
        return Icons.directions_run_rounded;
    }
  }

  void _syncPreviewMap() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_destinationPoint != null) {
        _mapController.fitCamera(
          CameraFit.bounds(
            bounds: _boundsForRadius(_destinationPoint!, _radius),
            padding: const EdgeInsets.all(24),
          ),
        );
        return;
      }

      final center = _destinationPoint ?? _currentLocation;
      if (center != null) {
        _mapController.move(center, 11.5);
      }
    });
  }

  LatLngBounds _boundsForRadius(LatLng center, double radiusKm) {
    final latDelta = radiusKm / 111.0;
    final lonDelta =
        radiusKm /
        (111.0 *
            math.max(math.cos(center.latitude * math.pi / 180).abs(), 0.2));

    return LatLngBounds(
      LatLng(center.latitude - latDelta, center.longitude - lonDelta),
      LatLng(center.latitude + latDelta, center.longitude + lonDelta),
    );
  }
}

class _PublicRouteCardData {
  const _PublicRouteCardData({
    required this.route,
    required this.routeResult,
    required this.creatorName,
  });

  final StoredRoute route;
  final RouteResult routeResult;
  final String creatorName;
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w800,
        color: Color(0xFFFFB59F),
        letterSpacing: 2,
      ),
    );
  }
}

class _HorizontalScrollHint extends StatelessWidget {
  const _HorizontalScrollHint();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: const [
        Text(
          'Desliza para ver más',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Colors.grey,
          ),
        ),
        SizedBox(width: 6),
        Icon(Icons.arrow_forward_rounded, size: 14, color: Colors.grey),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.message,
    required this.icon,
    required this.iconColor,
  });

  final String message;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF191C1D),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
