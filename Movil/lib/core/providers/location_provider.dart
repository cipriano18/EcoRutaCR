import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// Fuente global de ubicación compartida entre las pantallas de la app.
///
/// Encapsula permisos, lectura inicial y suscripción continua para que las
/// vistas no dependan directamente de [Geolocator].
class LocationProvider extends ChangeNotifier {
  Position? _currentPosition;
  LocationPermission? _permission;
  StreamSubscription<Position>? _positionSubscription;
  Future<void>? _initializationFuture;
  bool _isLoading = false;

  Position? get currentPosition => _currentPosition;
  LatLng? get currentLatLng => _currentPosition == null
      ? null
      : LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
  LocationPermission? get permission => _permission;
  bool get isLoading => _isLoading;

  /// Indica si el permiso actual permite consultar ubicación.
  bool get hasPermission {
    final permission = _permission;
    return permission != null &&
        permission != LocationPermission.denied &&
        permission != LocationPermission.deniedForever;
  }

  /// Solicita permisos si hace falta y activa el seguimiento de ubicación.
  ///
  /// Reutiliza una inicialización pendiente para evitar múltiples solicitudes
  /// de permisos o lecturas simultáneas desde distintas pantallas.
  Future<void> ensureInitialized({bool requestPermission = true}) {
    final pending = _initializationFuture;
    if (pending != null) return pending;

    final future = _initialize(requestPermission: requestPermission);
    _initializationFuture = future.whenComplete(() {
      _initializationFuture = null;
    });
    return _initializationFuture!;
  }

  Future<void> _initialize({required bool requestPermission}) async {
    _setLoading(true);

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Si el servicio del dispositivo está apagado, se conserva el estado
        // del permiso pero se detiene cualquier stream activo.
        _permission = await Geolocator.checkPermission();
        await _stopTracking();
        _currentPosition = null;
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied && requestPermission) {
        permission = await Geolocator.requestPermission();
      }
      _permission = permission;

      if (!hasPermission) {
        // Sin permiso no debe quedar una posición antigua expuesta como si
        // todavía fuera válida para navegación o cálculo de rutas.
        await _stopTracking();
        _currentPosition = null;
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
        ),
      );
      _currentPosition = position;
      _startTracking();
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  void _startTracking() {
    if (_positionSubscription != null) return;

    // El filtro de 1 metro favorece navegación activa con actualizaciones
    // frecuentes sin recrear la suscripción en cada reconstrucción.
    _positionSubscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.bestForNavigation,
            distanceFilter: 1,
          ),
        ).listen((position) {
          _currentPosition = position;
          notifyListeners();
        });
  }

  Future<void> _stopTracking() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  void _setLoading(bool value) {
    if (_isLoading == value) return;
    _isLoading = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }
}
