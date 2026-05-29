import 'package:ecoruta/models/route_profile.dart';
import 'package:ecoruta/navigation/main_shell.dart';
import 'package:ecoruta/screens/explore/route_preview_screen.dart';
import 'package:ecoruta/providers/explore_provider.dart';
import 'package:ecoruta/screens/picker_map.dart';
import 'package:ecoruta/services/routing/a_star_router.dart';
import 'package:ecoruta/services/routing/route_result.dart';
import 'package:ecoruta/services/saved_routes_service.dart';
import 'package:ecoruta/widgets/activity_type_card.dart';
import 'package:ecoruta/widgets/points_preview.dart';
import 'package:ecoruta/widgets/route_result_card.dart';
import 'package:ecoruta/widgets/save_route_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

/// Tab que genera rutas entre un origen y un destino elegidos por el usuario.
class GenerateTab extends StatefulWidget {
  const GenerateTab({super.key});

  @override
  State<GenerateTab> createState() => _GenerateTabState();
}

class _GenerateTabState extends State<GenerateTab> {
  static const _primaryColor = Color(0xFF012D1D);
  static const _primaryGlow = Color(0xFF1E6B4C);
  static const _secondaryContainer = Color(0xFFAEEECB);
  static const _tertiaryFixed = Color(0xFFFFB59F);

  final MapController _mapController = MapController();
  final SavedRoutesService _savedRoutesService = SavedRoutesService();

  RouteProfile _selectedProfile = RouteProfile.hiking;
  Map<RoutingPreference, RouteResult?> _generatedRoutes = const {};
  LatLng? _startPoint;
  LatLng? _destinationPoint;
  LatLng? _currentLocation;
  String _startLabel = 'Cargando ubicacion actual...';
  String _destinationLabel = 'Pendiente de seleccionar';
  bool _isLoadingCurrentLocation = true;
  bool _hasGenerated = false;
  bool _isSavingRoute = false;

  @override
  void initState() {
    super.initState();
    _initCurrentLocation();
  }

  /// Obtiene la ubicación actual para sugerir un punto de partida inicial.
  Future<void> _initCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        if (!mounted) return;
        setState(() {
          _isLoadingCurrentLocation = false;
          _startLabel = 'Ubicacion actual no disponible';
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      final currentPoint = LatLng(position.latitude, position.longitude);

      if (!mounted) return;
      setState(() {
        _currentLocation = currentPoint;
        _startPoint = currentPoint;
        _startLabel = _formatCoordinates(currentPoint);
        _isLoadingCurrentLocation = false;
      });
      _syncPreviewMap();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingCurrentLocation = false;
        _startLabel = 'Ubicacion actual no disponible';
      });
    }
  }

  /// Intercambia origen y destino para probar la ruta inversa rápidamente.
  void _swapLocations() {
    setState(() {
      final previousStartPoint = _startPoint;
      final previousStartLabel = _startLabel;
      _startPoint = _destinationPoint;
      _startLabel = _destinationLabel;
      _destinationPoint = previousStartPoint;
      _destinationLabel = previousStartLabel;
    });
    _syncPreviewMap();
  }

  /// Abre el selector de puntos para definir inicio y destino sobre el mapa.
  Future<void> _openPointsPicker() async {
    final result = await Navigator.of(context).push<PointsSelectionResult>(
      MaterialPageRoute(
        builder: (_) => PickerMapScreen(
          initialStartPoint: _startPoint,
          initialDestinationPoint: _destinationPoint,
          currentLocation: _currentLocation,
          mode: PointSelectionMode.dualPoint,
        ),
      ),
    );

    if (result == null || !mounted) return;

    setState(() {
      _startPoint = result.startPoint;
      _destinationPoint = result.destinationPoint;
      _startLabel = result.startLabel;
      _destinationLabel = result.destinationLabel;
    });
    _syncPreviewMap();
  }

  /// Valida entradas y solicita el cálculo de la ruta al provider.
  Future<void> _generateRoutes() async {
    if (_startPoint == null || _destinationPoint == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona un punto de inicio y un destino.'),
        ),
      );
      return;
    }

    final straightLineDistanceKm = _straightLineDistanceKm(
      _startPoint!,
      _destinationPoint!,
    );
    final maxDistanceKm = _selectedProfile.maxRecommendedDistanceKm;

    if (straightLineDistanceKm > maxDistanceKm) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _distanceLimitMessage(
              profile: _selectedProfile,
              maxDistanceKm: maxDistanceKm,
            ),
          ),
        ),
      );
      return;
    }

    final provider = context.read<ExploreProvider>();
    provider.setProfile(_selectedProfile);

    setState(() {
      _hasGenerated = true;
      _generatedRoutes = const {};
    });

    await provider.generateRoutes(
      startLat: _startPoint!.latitude,
      startLon: _startPoint!.longitude,
      endLat: _destinationPoint!.latitude,
      endLon: _destinationPoint!.longitude,
      preference: RoutingPreference.shortest,
    );

    final shortestRoute = provider.routes[RoutingPreference.shortest];

    await provider.generateRoutes(
      startLat: _startPoint!.latitude,
      startLon: _startPoint!.longitude,
      endLat: _destinationPoint!.latitude,
      endLon: _destinationPoint!.longitude,
      preference: RoutingPreference.mostChallenging,
    );

    final challengingRoute =
        provider.routes[RoutingPreference.mostChallenging];

    if (!mounted) return;
    setState(() {
      _generatedRoutes = {
        RoutingPreference.shortest: shortestRoute,
        RoutingPreference.mostChallenging: challengingRoute,
      };
    });
  }

  Future<void> _saveRoute({
    required RouteResult route,
    required RoutingPreference preference,
    required String title,
    required String startLabel,
    required String endLabel,
  }) async {
    final saveData = await showModalBottomSheet<SaveRouteFormResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SaveRouteSheet(
        initialTitle: title,
        startLabel: startLabel,
        endLabel: endLabel,
      ),
    );

    if (saveData == null || !mounted) return;

    setState(() => _isSavingRoute = true);

    try {
      await _savedRoutesService.saveRoute(
        title: saveData.title,
        description: saveData.description,
        visibility: saveData.visibility,
        activityProfile: _selectedProfile,
        routingPreference: preference,
        startLabel: startLabel,
        endLabel: endLabel,
        route: route,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Ruta guardada en Mis rutas.'),
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
      _resetGeneratedStateAfterSave();
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
        setState(() => _isSavingRoute = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final previewStartLabel = _isLoadingCurrentLocation
        ? 'Cargando ubicacion actual...'
        : _startLabel;

    return Consumer<ExploreProvider>(
      builder: (context, exploreProvider, _) {
        final shortestRoute = _generatedRoutes[RoutingPreference.shortest];
        final challengingRoute =
            _generatedRoutes[RoutingPreference.mostChallenging];

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          children: [
            PointsPreview(
              mapController: _mapController,
              startPoint: _startPoint,
              destinationPoint: _destinationPoint,
              startLabel: previewStartLabel,
              destinationLabel: _destinationLabel,
              mode: PointsPreviewMode.dualPoint,
              actionLabel: 'Seleccionar puntos',
              onSwap: _swapLocations,
              onSelectPoints: _openPointsPicker,
            ),

            const SizedBox(height: 24),
            const _SectionTitle(title: 'Tipo de actividad'),
            const SizedBox(height: 14),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ActivityTypeCard(
                    icon: Icons.directions_bike_rounded,
                    label: 'Ciclismo',
                    selected: _selectedProfile == RouteProfile.cycling,
                    onTap: () {
                      setState(() => _selectedProfile = RouteProfile.cycling);
                    },
                  ),
                  const SizedBox(width: 14),
                  ActivityTypeCard(
                    icon: Icons.hiking_rounded,
                    label: 'Senderismo',
                    selected: _selectedProfile == RouteProfile.hiking,
                    onTap: () {
                      setState(() => _selectedProfile = RouteProfile.hiking);
                    },
                  ),
                  const SizedBox(width: 14),
                  ActivityTypeCard(
                    icon: Icons.directions_run_rounded,
                    label: 'Running',
                    selected: _selectedProfile == RouteProfile.running,
                    onTap: () {
                      setState(() => _selectedProfile = RouteProfile.running);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            const _ScrollHint(),
            const SizedBox(height: 20),
            _AiActionButton(
              label: exploreProvider.isLoading
                  ? 'Generando rutas con IA...'
                  : 'Generar con IA',
              hint:
                  'Calcula una ruta corta y otra desafiante segun tu actividad.',
              icon: Icons.auto_awesome_rounded,
              isLoading: exploreProvider.isLoading,
              onPressed: exploreProvider.isLoading ? null : _generateRoutes,
              primaryColor: _primaryColor,
              glowColor: _primaryGlow,
            ),
            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    _secondaryContainer.withValues(alpha: 0.34),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: _secondaryContainer.withValues(alpha: 0.85),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: _primaryColor,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.psychology_alt_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'IA aplicada a tu recorrido',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: _primaryColor,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Elegimos dos estilos de ruta para ayudarte a comparar rapidez y reto sin cambiar de pantalla.',
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.4,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            const _SectionTitle(title: 'Rutas Generadas'),
            const SizedBox(height: 4),
            Text(
              _resultSummaryText(
                provider: exploreProvider,
                shortestRoute: shortestRoute,
                challengingRoute: challengingRoute,
              ),
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            const SizedBox(height: 8),
            if (exploreProvider.errorMessage != null &&
                _hasGenerated &&
                shortestRoute == null &&
                challengingRoute == null)
              _InfoCard(
                message: _friendlyNoRoutesMessage(),
                icon: Icons.error_outline_rounded,
                iconColor: Colors.redAccent,
              )
            else if (!_hasGenerated)
              _InfoCard(
                message:
                    'Selecciona la actividad, el origen y el destino para calcular rutas.',
                icon: Icons.route_rounded,
                iconColor: _primaryColor,
              )
            else if (exploreProvider.isLoading)
              _InfoCard(
                message: 'Calculando rutas...',
                icon: Icons.sync_rounded,
                iconColor: _primaryColor,
              )
            else if (shortestRoute == null && challengingRoute == null)
              _InfoCard(
                message: _friendlyNoRoutesMessage(),
                icon: Icons.alt_route_rounded,
                iconColor: _primaryColor,
              )
            else ...[
              if (shortestRoute != null)
                _buildRouteCard(
                  route: shortestRoute,
                  preference: RoutingPreference.shortest,
                  previewStartLabel: previewStartLabel,
                ),
              if (shortestRoute != null && challengingRoute != null)
                const SizedBox(height: 16),
              if (challengingRoute != null)
                _buildRouteCard(
                  route: challengingRoute,
                  preference: RoutingPreference.mostChallenging,
                  previewStartLabel: previewStartLabel,
                ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildRouteCard({
    required RouteResult route,
    required RoutingPreference preference,
    required String previewStartLabel,
  }) {
    return RouteResultCard(
      title: _titleForRoute(_selectedProfile, preference),
      distance: route.formattedDistance,
      duration: route.formattedDuration,
      elevationGain: route.formattedElevationGain,
      accentColor: _accentForPreference(preference),
      icon: _iconForPreference(preference),
      isHighlighted: false,
      buttonText: 'Ver trazado',
      secondaryButtonText: 'Guardar ruta',
      isSecondaryLoading: _isSavingRoute,
      onSecondaryPressed: _isSavingRoute
          ? null
          : () => _saveRoute(
              route: route,
              preference: preference,
              title: _titleForRoute(_selectedProfile, preference),
              startLabel: previewStartLabel,
              endLabel: _destinationLabel,
            ),
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => RoutePreviewScreen(
              title: _titleForRoute(_selectedProfile, preference),
              route: route,
              profile: _selectedProfile,
              preference: preference,
              startLabel: previewStartLabel,
              endLabel: _destinationLabel,
              allowSave: false,
            ),
          ),
        );
      },
    );
  }

  String _resultSummaryText({
    required ExploreProvider provider,
    required RouteResult? shortestRoute,
    required RouteResult? challengingRoute,
  }) {
    if (!_hasGenerated) {
      return 'Aun no se han generado sugerencias';
    }
    if (provider.isLoading) {
      return 'Calculando rutas para ${_activityLabel(_selectedProfile).toLowerCase()}';
    }
    if (provider.errorMessage != null &&
        shortestRoute == null &&
        challengingRoute == null) {
      return _friendlyNoRoutesMessage();
    }
    if (shortestRoute == null && challengingRoute == null) {
      return _friendlyNoRoutesMessage();
    }
    final totalRoutes = [
      shortestRoute,
      challengingRoute,
    ].whereType<RouteResult>().length;
    return 'Se generaron $totalRoutes rutas para ${_activityLabel(_selectedProfile).toLowerCase()}';
  }

  String _friendlyNoRoutesMessage() {
    return 'No hay rutas para ${_activityLabel(_selectedProfile).toLowerCase()} entre los dos puntos seleccionados.';
  }

  String _activityLabel(RouteProfile profile) {
    switch (profile) {
      case RouteProfile.cycling:
        return 'Ciclismo';
      case RouteProfile.hiking:
        return 'Senderismo';
      case RouteProfile.running:
        return 'Running';
    }
  }

  String _titleForRoute(RouteProfile profile, RoutingPreference preference) {
    final activity = _activityLabel(profile);
    switch (preference) {
      case RoutingPreference.shortest:
        return '$activity - Ruta más corta';
      case RoutingPreference.mostChallenging:
        return '$activity - Ruta más desafiante';
    }
  }

  Color _accentForPreference(RoutingPreference preference) {
    switch (preference) {
      case RoutingPreference.shortest:
        return _secondaryContainer;
      case RoutingPreference.mostChallenging:
        return _tertiaryFixed;
    }
  }

  IconData _iconForPreference(RoutingPreference preference) {
    switch (preference) {
      case RoutingPreference.shortest:
        return Icons.straighten_rounded;
      case RoutingPreference.mostChallenging:
        return Icons.terrain_rounded;
    }
  }

  String _formatCoordinates(LatLng point) {
    return '${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)}';
  }

  double _straightLineDistanceKm(LatLng start, LatLng end) {
    final distanceMeters = Geolocator.distanceBetween(
      start.latitude,
      start.longitude,
      end.latitude,
      end.longitude,
    );
    return distanceMeters / 1000;
  }

  String _distanceLimitMessage({
    required RouteProfile profile,
    required double maxDistanceKm,
  }) {
    final activity = _activityLabel(profile).toLowerCase();
    return 'Para $activity, el origen y destino no deben superar ${maxDistanceKm.toStringAsFixed(0)} km en linea recta.';
  }

  void _resetGeneratedStateAfterSave() {
    if (!mounted) return;

    setState(() {
      _generatedRoutes = const {};
      _hasGenerated = false;
      _destinationPoint = null;
      _destinationLabel = 'Pendiente de seleccionar';

      if (_currentLocation != null) {
        _startPoint = _currentLocation;
        _startLabel = _formatCoordinates(_currentLocation!);
      } else {
        _startPoint = null;
        _startLabel = 'Ubicacion actual no disponible';
      }
    });
    _syncPreviewMap();
  }

  void _syncPreviewMap() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final center = _startPoint != null && _destinationPoint != null
          ? LatLng(
              (_startPoint!.latitude + _destinationPoint!.latitude) / 2,
              (_startPoint!.longitude + _destinationPoint!.longitude) / 2,
            )
          : _startPoint ?? _destinationPoint;

      if (center != null) {
        _mapController.move(center, 11.5);
      }
    });
  }
}

/// Título reutilizable de sección dentro del tab de generación.
class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w800,
        color: Color(0xFF012D1D),
        letterSpacing: -0.6,
      ),
    );
  }
}

/// Pista visual para listas horizontales desplazables.
class _ScrollHint extends StatelessWidget {
  const _ScrollHint();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: const [
        Text(
          'Desliza para ver mas',
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

/// Tarjeta informativa para estados vacíos, carga o error.
class _AiActionButton extends StatelessWidget {
  const _AiActionButton({
    required this.label,
    required this.hint,
    required this.icon,
    required this.isLoading,
    required this.onPressed,
    required this.primaryColor,
    required this.glowColor,
  });

  final String label;
  final String hint;
  final IconData icon;
  final bool isLoading;
  final VoidCallback? onPressed;
  final Color primaryColor;
  final Color glowColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: glowColor.withValues(alpha: 0.22),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [primaryColor, glowColor],
            ),
          ),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onPressed,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isLoading)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    )
                  else
                    Icon(icon, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          hint,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12.5,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
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
