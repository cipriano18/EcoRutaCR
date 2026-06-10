import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:ecoruta/core/providers/location_provider.dart';
import 'package:ecoruta/features/routes/models/geo_node.dart';
import 'package:ecoruta/features/routes/models/guided_saved_route.dart';
import 'package:ecoruta/features/routes/models/route_profile.dart';
import 'package:ecoruta/features/routes/models/stored_route.dart';
import 'package:ecoruta/core/routes/main_shell.dart';
import 'package:ecoruta/features/profile/providers/user_provider.dart';
import 'package:ecoruta/core/services/auth_service.dart';
import 'package:ecoruta/features/routes/services/routing/a_star_router.dart';
import 'package:ecoruta/features/routes/services/routing/route_result.dart';
import 'package:ecoruta/features/routes/services/saved_routes_service.dart';
import 'package:ecoruta/core/widgets/app_header.dart';
import 'package:ecoruta/core/widgets/confirm_dialog.dart';
import 'package:ecoruta/features/map/widgets/finish_route_sheet.dart';
import 'package:ecoruta/features/map/widgets/guided_route_status_card.dart';
import 'package:ecoruta/features/map/widgets/route_metrics_panel.dart';
import 'package:ecoruta/features/map/widgets/start_route_sheet.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

const _kPrimaryColor = Color(0xFF012D1D);
const _kOrangeColor = Color(0xFFFF7043);

enum _MapMode {
  idle,
  freeRecording,
  guidedReadyToApproachStart,
  guidedActive,
  guidedReadyToFinish,
}

/// Pantalla de mapa en vivo con registro libre y seguimiento guiado.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => MapScreenState();
}

class MapScreenState extends State<MapScreen> {
  static const _elevationApiUserAgent = 'EcoRutaCR/1.0';
  static const LatLng _fallbackCenter = LatLng(9.9281, -84.0907);
  static const double _liveTrackingZoom = 17.5;
  static const double _guidedRangeMeters = 50;

  final MapController _mapController = MapController();
  final SavedRoutesService _savedRoutesService = SavedRoutesService();
  final Distance _distance = const Distance();
  final ValueNotifier<LatLng?> _currentPositionNotifier = ValueNotifier(null);
  final ValueNotifier<double?> _currentElevationNotifier = ValueNotifier(null);
  final ValueNotifier<double> _smoothedHeadingNotifier = ValueNotifier(0);

  StreamSubscription<CompassEvent>? _compassSubscription;
  Timer? _elevationRefreshTimer;
  Timer? _sessionTimer;
  LocationProvider? _locationProvider;
  Position? _lastSharedPosition;

  LatLng? _currentPosition;
  bool _loading = true;
  bool _savingRoute = false;
  bool _hasCompassSupport = false;
  bool _isCompassModeEnabled = false;
  double _heading = 0;
  double _smoothedHeading = 0;

  _MapMode _mode = _MapMode.idle;

  List<LatLng> _freeRoutePoints = const [];
  double _freeTrackedDistanceMeters = 0;
  double _freeTrackedElevationGainMeters = 0;
  Duration _freeTrackedDuration = Duration.zero;
  double? _freeLastTrackedAltitude;

  GuidedSavedRoute? _guidedRoute;
  List<LatLng> _guidedProgressPoints = const [];
  double _guidedTrackedDistanceMeters = 0;
  double _guidedTrackedElevationGainMeters = 0;
  Duration _guidedTrackedDuration = Duration.zero;
  double? _guidedLastTrackedAltitude;
  double? _distanceToGuidedStartMeters;
  double? _distanceToGuidedEndMeters;

  DateTime? _sessionStartedAt;

  bool get _hasFreeRecording => _mode == _MapMode.freeRecording;
  bool get _hasGuidedRoute => _guidedRoute != null;
  bool get _isGuidedRouteStarted =>
      _mode == _MapMode.guidedActive || _mode == _MapMode.guidedReadyToFinish;
  bool get _isWithinGuidedStartRange =>
      (_distanceToGuidedStartMeters ?? double.infinity) <= _guidedRangeMeters;
  bool get _isWithinGuidedEndRange =>
      (_distanceToGuidedEndMeters ?? double.infinity) <= _guidedRangeMeters;
  bool get _hideMapControls => _hasFreeRecording || _hasGuidedRoute;
  bool get hasBlockingActiveRoute => _hasFreeRecording || _hasGuidedRoute;

  @override
  void initState() {
    super.initState();
    _startCompassTracking();
    _startElevationTimer();
  }

  @override
  void dispose() {
    _locationProvider?.removeListener(_handleSharedLocationChanged);
    _compassSubscription?.cancel();
    _elevationRefreshTimer?.cancel();
    _sessionTimer?.cancel();
    _currentPositionNotifier.dispose();
    _currentElevationNotifier.dispose();
    _smoothedHeadingNotifier.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final provider = context.read<LocationProvider>();
    if (identical(provider, _locationProvider)) return;

    _locationProvider?.removeListener(_handleSharedLocationChanged);
    _locationProvider = provider;
    _locationProvider!.addListener(_handleSharedLocationChanged);
    _locationProvider!.ensureInitialized();
    _handleSharedLocationChanged();
  }

  void _handleSharedLocationChanged() {
    if (!mounted) return;

    final provider = _locationProvider;
    if (provider == null) return;

    final sharedPosition = provider.currentPosition;
    final hadCurrentPosition = _currentPosition != null;

    setState(() {
      _loading = provider.isLoading && sharedPosition == null;
    });

    if (sharedPosition == null ||
        _samePosition(sharedPosition, _lastSharedPosition)) {
      return;
    }

    _lastSharedPosition = sharedPosition;

    final nextPosition = LatLng(
      sharedPosition.latitude,
      sharedPosition.longitude,
    );
    _currentPosition = nextPosition;
    _currentPositionNotifier.value = nextPosition;

    if (_hasFreeRecording) {
      _appendFreePoint(nextPosition, sharedPosition.altitude);
    }
    if (_hasGuidedRoute) {
      _updateGuidedRouteProximity(
        nextPosition,
        showFeedback: hadCurrentPosition,
      );
      if (_isGuidedRouteStarted) {
        _appendGuidedPoint(nextPosition, sharedPosition.altitude);
      }
    }

    if (!hadCurrentPosition) {
      _centerOnUser();
      _refreshElevation();
    }
    _syncLiveMapCamera();
  }

  bool _samePosition(Position? a, Position? b) {
    if (a == null || b == null) return false;
    return a.latitude == b.latitude &&
        a.longitude == b.longitude &&
        a.altitude == b.altitude;
  }

  /// Carga una ruta guardada para seguimiento guiado desde el shell principal.
  void loadGuidedSavedRoute(GuidedSavedRoute route) {
    if (hasBlockingActiveRoute) return;

    _sessionTimer?.cancel();
    _sessionStartedAt = null;

    final guidedPath = route.path;
    setState(() {
      _guidedRoute = route;
      _mode = _MapMode.guidedReadyToApproachStart;
      _guidedProgressPoints = const [];
      _guidedTrackedDistanceMeters = 0;
      _guidedTrackedElevationGainMeters = 0;
      _guidedTrackedDuration = Duration.zero;
      _guidedLastTrackedAltitude = null;
      _distanceToGuidedStartMeters = null;
      _distanceToGuidedEndMeters = null;
      _isCompassModeEnabled = _hasCompassSupport;
    });

    if (guidedPath.isNotEmpty) {
      _fitToRoute(guidedPath);
    }
    if (_currentPosition != null) {
      _updateGuidedRouteProximity(_currentPosition!, showFeedback: false);
      _syncLiveMapCamera(forceTrackingZoom: true);
    }
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

      _heading = sanitized;
      _smoothedHeading = smoothed;
      _smoothedHeadingNotifier.value = smoothed;

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

  Future<void> _refreshElevation() async {
    final currentPosition = _currentPosition;
    if (currentPosition == null) return;

    try {
      final elevation = await _fetchElevation(currentPosition);
      if (!mounted) return;
      _currentElevationNotifier.value = elevation;
    } catch (_) {
      // Conserva el ultimo valor valido si falla la red.
    }
  }

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

    final zoom = _cameraZoom();
    final rotation = _isCompassModeEnabled ? -_smoothedHeading : 0.0;
    _mapController.moveAndRotate(currentPosition, zoom, rotation);
  }

  void _toggleCompassMode() {
    if (!_hasCompassSupport || _hideMapControls) return;
    setState(() => _isCompassModeEnabled = !_isCompassModeEnabled);
    _syncLiveMapCamera();
  }

  void _syncLiveMapCamera({bool forceTrackingZoom = false}) {
    final currentPosition = _currentPosition;
    if (currentPosition == null) return;

    final zoom = _cameraZoom(forceTrackingZoom: forceTrackingZoom);
    final rotation = _isCompassModeEnabled ? -_smoothedHeading : 0.0;
    _mapController.moveAndRotate(currentPosition, zoom, rotation);
  }

  double _cameraZoom({bool forceTrackingZoom = false}) {
    final currentZoom = _safeZoom();
    if (forceTrackingZoom || _hideMapControls) {
      return currentZoom < _liveTrackingZoom ? _liveTrackingZoom : currentZoom;
    }
    return currentZoom;
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

  Future<void> _onPrimaryActionPressed() async {
    if (_savingRoute) return;

    if (_hasGuidedRoute) {
      await _handleGuidedRoutePrimaryAction();
      return;
    }
    if (_hasFreeRecording) {
      await _showFinishSheet();
      return;
    }
    await _showStartOptionsSheet();
  }

  Future<void> _handleGuidedRoutePrimaryAction() async {
    switch (_mode) {
      case _MapMode.guidedReadyToApproachStart:
        _attemptStartGuidedRoute();
        return;
      case _MapMode.guidedActive:
      case _MapMode.guidedReadyToFinish:
        await _attemptFinishGuidedRoute();
        return;
      case _MapMode.idle:
      case _MapMode.freeRecording:
        return;
    }
  }

  Future<void> _showStartOptionsSheet() async {
    final action = await showModalBottomSheet<StartRouteAction>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (context) => StartRouteSheet(
        onActionSelected: (value) => Navigator.of(context).pop(value),
      ),
    );

    if (!mounted || action == null) return;

    if (action == StartRouteAction.live) {
      _startFreeRecording();
      return;
    }

    MainShell.navigateToTab(context, 2);
  }

  void _startFreeRecording() {
    final startPoint = _currentPosition;
    if (startPoint == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Necesitamos tu ubicacion actual para iniciar la ruta.',
          ),
        ),
      );
      return;
    }

    _cancelGuidedRoute(clearOnly: true);
    _startSessionTimer();

    setState(() {
      _mode = _MapMode.freeRecording;
      _freeRoutePoints = [startPoint];
      _freeTrackedDistanceMeters = 0;
      _freeTrackedElevationGainMeters = 0;
      _freeTrackedDuration = Duration.zero;
      _freeLastTrackedAltitude = null;
      _isCompassModeEnabled = _hasCompassSupport;
    });
    _syncLiveMapCamera(forceTrackingZoom: true);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Registro en vivo iniciado. La ruta se trazara en el mapa.',
        ),
      ),
    );
  }

  void _attemptStartGuidedRoute() {
    final route = _guidedRoute;
    if (route == null) return;

    if (!_isWithinGuidedStartRange) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Aproximese un poco mas para poder comenzar la ruta. Te faltan ${_formatMeters(_distanceToGuidedStartMeters)}.',
          ),
        ),
      );
      return;
    }

    final currentPosition = _currentPosition ?? route.startPoint;
    _startSessionTimer();
    setState(() {
      _mode = _isWithinGuidedEndRange
          ? _MapMode.guidedReadyToFinish
          : _MapMode.guidedActive;
      _guidedProgressPoints = [currentPosition];
      _guidedTrackedDistanceMeters = 0;
      _guidedTrackedElevationGainMeters = 0;
      _guidedTrackedDuration = Duration.zero;
      _guidedLastTrackedAltitude = null;
      _isCompassModeEnabled = _hasCompassSupport;
    });
    _syncLiveMapCamera(forceTrackingZoom: true);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Ruta "${route.title}" iniciada. Sigue el trazado hasta el destino.',
        ),
      ),
    );
  }

  Future<void> _attemptFinishGuidedRoute() async {
    final route = _guidedRoute;
    if (route == null) return;

    if (!_isWithinGuidedEndRange) {
      final shouldEndWithoutCompletion = await ConfirmDialog.mostrar(
        context,
        titulo: 'Terminar sin completar',
        mensaje:
            'Todavia no estas cerca del destino. Si terminas ahora, esta sesion no se registrara como ruta completada en tu perfil.',
        textoConfirmar: 'Terminar de todos modos',
      );
      if (!shouldEndWithoutCompletion || !mounted) return;
      _cancelGuidedRoute(clearOnly: true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'La sesion se cerro sin marcarse como ruta completada.',
          ),
        ),
      );
      return;
    }

    if (_guidedProgressPoints.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Necesitamos mas recorrido registrado antes de completar la ruta.',
          ),
        ),
      );
      return;
    }

    setState(() => _savingRoute = true);
    final finishedAt = DateTime.now();
    final startedAt = _sessionStartedAt ?? finishedAt;

    try {
      await _savedRoutesService.saveRouteCompletionSession(
        sourceRoute: route,
        startedAt: startedAt,
        finishedAt: finishedAt,
        completionDistanceMeters: _guidedTrackedDistanceMeters,
        completionDurationSeconds: _guidedTrackedDuration.inSeconds,
        elevationGainMeters: _guidedTrackedElevationGainMeters,
        recordedPath: _guidedProgressPoints,
      );
      final refreshedUser = await AuthService().registerWeeklyRouteCompletion(
        distanceKm: _guidedTrackedDistanceMeters / 1000,
        durationMinutes: _guidedTrackedDuration.inSeconds / 60,
      );

      if (!mounted) return;
      if (refreshedUser != null) {
        Provider.of<UserProvider>(
          context,
          listen: false,
        ).setUser(refreshedUser);
      }
      _cancelGuidedRoute(clearOnly: true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Completaste "${route.title}". La ruta quedo marcada como completada en tu perfil.',
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
          content: Text('No se pudo guardar la sesión de esta ruta.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _savingRoute = false);
      }
    }
  }

  Future<void> _cancelGuidedRoute({bool clearOnly = false}) async {
    if (!clearOnly && _guidedRoute != null) {
      final confirmed = await ConfirmDialog.mostrar(
        context,
        titulo: 'Cancelar seguimiento',
        mensaje:
            'Si cancelas este seguimiento, la ruta guiada se cerrara sin marcarse como completada.',
        textoConfirmar: 'Cancelar seguimiento',
      );
      if (!confirmed || !mounted) return;
    }

    _sessionTimer?.cancel();
    _sessionStartedAt = null;
    setState(() {
      _guidedRoute = null;
      _guidedProgressPoints = const [];
      _guidedTrackedDistanceMeters = 0;
      _guidedTrackedElevationGainMeters = 0;
      _guidedTrackedDuration = Duration.zero;
      _guidedLastTrackedAltitude = null;
      _distanceToGuidedStartMeters = null;
      _distanceToGuidedEndMeters = null;
      if (_mode != _MapMode.freeRecording) {
        _mode = _MapMode.idle;
      }
      if (!_hasFreeRecording) {
        _isCompassModeEnabled = false;
      }
    });

    if (!clearOnly && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seguimiento guiado cancelado.')),
      );
    }
  }

  void _startSessionTimer() {
    _sessionTimer?.cancel();
    _sessionStartedAt = DateTime.now();
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final startedAt = _sessionStartedAt;
      if (!mounted || startedAt == null) return;
      final elapsed = DateTime.now().difference(startedAt);
      setState(() {
        if (_hasFreeRecording) {
          _freeTrackedDuration = elapsed;
        } else if (_isGuidedRouteStarted) {
          _guidedTrackedDuration = elapsed;
        }
      });
    });
  }

  void _appendFreePoint(LatLng point, double altitude) {
    final points = _freeRoutePoints;
    if (points.isEmpty) {
      setState(() {
        _freeRoutePoints = [point];
        _freeLastTrackedAltitude = _isValidAltitude(altitude) ? altitude : null;
      });
      return;
    }

    final previous = points.last;
    final segmentDistance = _distance.as(LengthUnit.Meter, previous, point);
    if (segmentDistance < 3) return;

    var nextElevationGain = _freeTrackedElevationGainMeters;
    if (_isValidAltitude(altitude)) {
      final lastAltitude = _freeLastTrackedAltitude;
      if (lastAltitude != null) {
        final delta = altitude - lastAltitude;
        if (delta > 0) nextElevationGain += delta;
      }
    }

    setState(() {
      _freeRoutePoints = [...points, point];
      _freeTrackedDistanceMeters += segmentDistance;
      _freeTrackedElevationGainMeters = nextElevationGain;
      if (_isValidAltitude(altitude)) {
        _freeLastTrackedAltitude = altitude;
      }
    });
  }

  void _appendGuidedPoint(LatLng point, double altitude) {
    final points = _guidedProgressPoints;
    if (points.isEmpty) {
      setState(() {
        _guidedProgressPoints = [point];
        _guidedLastTrackedAltitude = _isValidAltitude(altitude)
            ? altitude
            : null;
      });
      return;
    }

    final previous = points.last;
    final segmentDistance = _distance.as(LengthUnit.Meter, previous, point);
    if (segmentDistance < 3) return;

    var nextElevationGain = _guidedTrackedElevationGainMeters;
    if (_isValidAltitude(altitude)) {
      final lastAltitude = _guidedLastTrackedAltitude;
      if (lastAltitude != null) {
        final delta = altitude - lastAltitude;
        if (delta > 0) nextElevationGain += delta;
      }
    }

    setState(() {
      _guidedProgressPoints = [...points, point];
      _guidedTrackedDistanceMeters += segmentDistance;
      _guidedTrackedElevationGainMeters = nextElevationGain;
      if (_isValidAltitude(altitude)) {
        _guidedLastTrackedAltitude = altitude;
      }
    });
  }

  void _updateGuidedRouteProximity(
    LatLng position, {
    required bool showFeedback,
  }) {
    final route = _guidedRoute;
    if (route == null) return;

    final previousStartDistance = _distanceToGuidedStartMeters;
    final previousEndDistance = _distanceToGuidedEndMeters;
    final startDistance = _distance.as(
      LengthUnit.Meter,
      position,
      route.startPoint,
    );
    final endDistance = _distance.as(
      LengthUnit.Meter,
      position,
      route.endPoint,
    );

    var nextMode = _mode;
    if (_mode == _MapMode.guidedActive && endDistance <= _guidedRangeMeters) {
      nextMode = _MapMode.guidedReadyToFinish;
    } else if (_mode == _MapMode.guidedReadyToFinish &&
        endDistance > _guidedRangeMeters) {
      nextMode = _MapMode.guidedActive;
    }

    setState(() {
      _distanceToGuidedStartMeters = startDistance;
      _distanceToGuidedEndMeters = endDistance;
      _mode = nextMode;
    });

    if (!showFeedback) return;
    if (_mode == _MapMode.guidedReadyToApproachStart &&
        (previousStartDistance == null ||
            previousStartDistance > _guidedRangeMeters) &&
        startDistance <= _guidedRangeMeters) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ya estas cerca del inicio. Puedes comenzar la ruta.'),
        ),
      );
    }
    if ((previousEndDistance == null ||
            previousEndDistance > _guidedRangeMeters) &&
        endDistance <= _guidedRangeMeters &&
        (_mode == _MapMode.guidedReadyToFinish ||
            _mode == _MapMode.guidedActive)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Ya llegaste al rango del destino. Puedes terminar la ruta.',
          ),
        ),
      );
    }
  }

  bool _isValidAltitude(double altitude) {
    return !altitude.isNaN && !altitude.isInfinite && altitude.abs() < 12000;
  }

  Future<void> _showFinishSheet() async {
    final result = await showModalBottomSheet<FinishRouteSheetResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      showDragHandle: true,
      builder: (context) {
        return FinishRouteSheet(
          initialTitle: _defaultRouteTitle(),
          initialActivity: RouteActivityOption.hiking,
          initialVisibility: RouteVisibilityOption.private,
          onSave: (draft) =>
              Navigator.of(context).pop(FinishRouteSheetResult.save(draft)),
          onDiscard: () =>
              Navigator.of(context).pop(const FinishRouteSheetResult.discard()),
        );
      },
    );

    if (!mounted || result == null) return;

    if (result.discarded) {
      _resetFreeRecordingState();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('La ruta fue descartada.')));
      return;
    }

    final draft = result.draft;
    if (draft == null) return;
    await _persistFinishedRoute(draft);
  }

  Future<void> _persistFinishedRoute(FinishRouteDraft draft) async {
    if (_freeRoutePoints.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Recorre unos metros antes de guardar la ruta.'),
        ),
      );
      return;
    }

    setState(() => _savingRoute = true);

    try {
      await _savedRoutesService.saveRoute(
        title: draft.title,
        description: '',
        visibility: _mapVisibility(draft.visibility),
        activityProfile: _mapActivity(draft.activity),
        routingPreference: RoutingPreference.shortest,
        startLabel: _buildPointLabel(_freeRoutePoints.first, 'Inicio'),
        endLabel: _buildPointLabel(_freeRoutePoints.last, 'Fin'),
        route: _buildFreeRouteResult(),
      );

      if (!mounted) return;
      _resetFreeRecordingState();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ruta guardada en Mis rutas.')),
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
          content: Text('No se pudo guardar la ruta en este momento.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _savingRoute = false);
      }
    }
  }

  RouteResult _buildFreeRouteResult() {
    final path = _freeRoutePoints
        .asMap()
        .entries
        .map(
          (entry) => GeoNode(
            id: entry.key,
            latitude: entry.value.latitude,
            longitude: entry.value.longitude,
          ),
        )
        .toList(growable: false);

    return RouteResult(
      path: path,
      totalDistanceMeters: _freeTrackedDistanceMeters,
      estimatedDurationSeconds: _freeTrackedDuration.inSeconds,
      elevationGainMeters: _freeTrackedElevationGainMeters,
    );
  }

  String _buildPointLabel(LatLng point, String prefix) {
    final lat = point.latitude.toStringAsFixed(5);
    final lon = point.longitude.toStringAsFixed(5);
    return '$prefix ($lat, $lon)';
  }

  RouteProfile _mapActivity(RouteActivityOption activity) {
    switch (activity) {
      case RouteActivityOption.cycling:
        return RouteProfile.cycling;
      case RouteActivityOption.running:
        return RouteProfile.running;
      case RouteActivityOption.hiking:
        return RouteProfile.hiking;
    }
  }

  StoredRouteVisibility _mapVisibility(RouteVisibilityOption visibility) {
    switch (visibility) {
      case RouteVisibilityOption.public:
        return StoredRouteVisibility.public;
      case RouteVisibilityOption.private:
        return StoredRouteVisibility.private;
    }
  }

  String _defaultRouteTitle() {
    final now = DateTime.now();
    final date =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
    return 'Ruta del $date';
  }

  void _resetFreeRecordingState() {
    _sessionTimer?.cancel();
    _sessionStartedAt = null;
    setState(() {
      _mode = _hasGuidedRoute
          ? _MapMode.guidedReadyToApproachStart
          : _MapMode.idle;
      _freeRoutePoints = const [];
      _freeTrackedDistanceMeters = 0;
      _freeTrackedElevationGainMeters = 0;
      _freeTrackedDuration = Duration.zero;
      _freeLastTrackedAltitude = null;
      if (!_hasGuidedRoute) {
        _isCompassModeEnabled = false;
      }
    });
  }

  void _fitToRoute(List<LatLng> points) {
    if (points.isEmpty) return;
    final bounds = LatLngBounds.fromPoints(points);
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.fromLTRB(40, 120, 40, 200),
      ),
    );
  }

  String _formatMeters(double? meters) {
    if (meters == null) return '-- m';
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
    return '${meters.round()} m';
  }

  String get _primaryButtonLabel {
    if (_hasGuidedRoute) {
      if (_mode == _MapMode.guidedReadyToApproachStart) {
        return 'Comenzar ruta';
      }
      return 'Terminar ruta';
    }
    return _hasFreeRecording ? 'Terminar Registro' : 'Iniciar Registro';
  }

  String get _guidedStatusTitle {
    switch (_mode) {
      case _MapMode.guidedReadyToApproachStart:
        return _isWithinGuidedStartRange
            ? 'Listo para comenzar'
            : 'Acercate al inicio';
      case _MapMode.guidedReadyToFinish:
        return 'Listo para terminar';
      case _MapMode.guidedActive:
        return 'Sigue hasta el destino';
      case _MapMode.idle:
      case _MapMode.freeRecording:
        return '';
    }
  }

  String get _guidedStatusMessage {
    final route = _guidedRoute;
    if (route == null) return '';
    switch (_mode) {
      case _MapMode.guidedReadyToApproachStart:
        return _isWithinGuidedStartRange
            ? 'Ya estas dentro del rango de inicio. Pulsa comenzar para registrar esta ejecucion.'
            : 'Ve hasta ${route.startLabel} para habilitar el comienzo de esta ruta guardada.';
      case _MapMode.guidedActive:
        return 'La ruta ya esta en progreso. Sigue el trazado y acercate a ${route.endLabel} para poder finalizar.';
      case _MapMode.guidedReadyToFinish:
        return 'Ya estas cerca del destino. Pulsa terminar para guardar esta ejecucion como una sesion completada.';
      case _MapMode.idle:
      case _MapMode.freeRecording:
        return '';
    }
  }

  String get _guidedDistanceLabel {
    if (_mode == _MapMode.guidedReadyToApproachStart) {
      return _formatMeters(_distanceToGuidedStartMeters);
    }
    return _formatMeters(_distanceToGuidedEndMeters);
  }

  bool get _guidedPrimaryReady {
    if (_mode == _MapMode.guidedReadyToApproachStart) {
      return _isWithinGuidedStartRange;
    }
    return _isWithinGuidedEndRange;
  }

  @override
  Widget build(BuildContext context) {
    final guidedRoute = _guidedRoute;
    final guidedPath = guidedRoute?.path ?? const <LatLng>[];

    return Scaffold(
      appBar: const AppHeader(),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentPositionNotifier.value ?? _fallbackCenter,
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
              if (guidedPath.length >= 2)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: guidedPath,
                      strokeWidth: 5,
                      color: _kPrimaryColor.withValues(alpha: 0.7),
                    ),
                  ],
                ),
              if (_freeRoutePoints.length >= 2)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _freeRoutePoints,
                      strokeWidth: 6,
                      color: _kOrangeColor,
                    ),
                  ],
                ),
              if (_guidedProgressPoints.length >= 2)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _guidedProgressPoints,
                      strokeWidth: 6,
                      color: _kOrangeColor,
                    ),
                  ],
                ),
              if (guidedRoute != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: guidedRoute.startPoint,
                      width: 82,
                      height: 92,
                      child: _GuidedRouteMarker(
                        icon: Icons.trip_origin_rounded,
                        color: _mode == _MapMode.guidedReadyToApproachStart
                            ? (_isWithinGuidedStartRange
                                  ? _kPrimaryColor
                                  : _kOrangeColor)
                            : _kPrimaryColor,
                        label: 'Inicio',
                      ),
                    ),
                    Marker(
                      point: guidedRoute.endPoint,
                      width: 82,
                      height: 92,
                      child: _GuidedRouteMarker(
                        icon: Icons.flag_rounded,
                        color:
                            (_mode == _MapMode.guidedActive ||
                                _mode == _MapMode.guidedReadyToFinish)
                            ? (_isWithinGuidedEndRange
                                  ? _kPrimaryColor
                                  : _kOrangeColor)
                            : _kOrangeColor,
                        label: 'Destino',
                      ),
                    ),
                  ],
                ),
              _LivePositionMarkerLayer(
                positionListenable: _currentPositionNotifier,
                headingListenable: _smoothedHeadingNotifier,
                primaryColor: _kPrimaryColor,
              ),
            ],
          ),
          if (_loading) const Center(child: CircularProgressIndicator()),
          if (!_hideMapControls)
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
            child: ValueListenableBuilder<double>(
              valueListenable: _smoothedHeadingNotifier,
              builder: (_, heading, _) => _CompassCard(heading: heading),
            ),
          ),
          if (!_hideMapControls)
            Positioned(
              right: 10,
              top: 30,
              child: ValueListenableBuilder<double?>(
                valueListenable: _currentElevationNotifier,
                builder: (_, elevation, _) => _ElevationCard(
                  elevation: elevation,
                  accentColor: _kOrangeColor,
                ),
              ),
            ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 24,
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (guidedRoute != null && !_isGuidedRouteStarted) ...[
                    GuidedRouteStatusCard(
                      title: _guidedStatusTitle,
                      message: _guidedStatusMessage,
                      distanceLabel: _guidedDistanceLabel,
                      isReady: _guidedPrimaryReady,
                      secondaryLabel:
                          '${guidedRoute.startLabel} -> ${guidedRoute.endLabel}',
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (_hasFreeRecording) ...[
                    RouteMetricsPanel(
                      distanceMeters: _freeTrackedDistanceMeters,
                      duration: _freeTrackedDuration,
                      elevationGainMeters: _freeTrackedElevationGainMeters,
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (_isGuidedRouteStarted) ...[
                    RouteMetricsPanel(
                      distanceMeters: _guidedTrackedDistanceMeters,
                      duration: _guidedTrackedDuration,
                      elevationGainMeters: _guidedTrackedElevationGainMeters,
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (guidedRoute != null && !_isGuidedRouteStarted) ...[
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _savingRoute
                            ? null
                            : () => _cancelGuidedRoute(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _kPrimaryColor,
                          backgroundColor: Colors.white,
                          side: BorderSide(
                            color: _kPrimaryColor.withValues(alpha: 0.18),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text('Cancelar seguimiento'),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _onPrimaryActionPressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: guidedRoute != null
                            ? (_guidedPrimaryReady
                                  ? _kPrimaryColor
                                  : _kOrangeColor)
                            : _hasFreeRecording
                            ? _kOrangeColor
                            : _kPrimaryColor,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      icon: _savingRoute
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(
                              guidedRoute != null
                                  ? (_mode ==
                                            _MapMode.guidedReadyToApproachStart
                                        ? Icons.play_arrow_rounded
                                        : Icons.flag_rounded)
                                  : _hasFreeRecording
                                  ? Icons.check_circle_rounded
                                  : Icons.fiber_manual_record_rounded,
                            ),
                      label: Text(
                        _primaryButtonLabel,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LivePositionMarkerLayer extends StatelessWidget {
  const _LivePositionMarkerLayer({
    required this.positionListenable,
    required this.headingListenable,
    required this.primaryColor,
  });

  final ValueListenable<LatLng?> positionListenable;
  final ValueListenable<double> headingListenable;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<LatLng?>(
      valueListenable: positionListenable,
      builder: (_, position, _) {
        if (position == null) {
          return const SizedBox.shrink();
        }

        return ValueListenableBuilder<double>(
          valueListenable: headingListenable,
          builder: (_, heading, _) {
            return MarkerLayer(
              markers: [
                Marker(
                  point: position,
                  width: 40,
                  height: 40,
                  child: Transform.rotate(
                    angle: heading * 3.1415926535897932 / 180,
                    child: Container(
                      decoration: BoxDecoration(
                        color: primaryColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withValues(alpha: 0.4),
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
            );
          },
        );
      },
    );
  }
}

class _GuidedRouteMarker extends StatelessWidget {
  const _GuidedRouteMarker({
    required this.icon,
    required this.color,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 12,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ],
    );
  }
}

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
            'ELEVACIÓN',
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
