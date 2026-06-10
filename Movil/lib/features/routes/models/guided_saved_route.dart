import 'package:ecoruta/features/routes/models/route_profile.dart';
import 'package:ecoruta/features/routes/models/stored_route.dart';
import 'package:latlong2/latlong.dart';

/// Payload ligero para abrir una ruta guardada en modo guiado dentro del mapa.
class GuidedSavedRoute {
  const GuidedSavedRoute({
    required this.routeId,
    required this.title,
    required this.activityProfile,
    required this.startLabel,
    required this.startPoint,
    required this.endLabel,
    required this.endPoint,
    required this.path,
    required this.totalDistanceMeters,
    required this.estimatedDurationSeconds,
    required this.elevationGainMeters,
  });

  /// Identificador de la ruta persistida.
  final String routeId;

  /// Nombre visible de la ruta guiada.
  final String title;

  /// Actividad con la que fue creada la ruta.
  final RouteProfile activityProfile;

  /// Etiqueta del punto inicial.
  final String startLabel;

  /// Coordenada de inicio usada para validar proximidad.
  final LatLng startPoint;

  /// Etiqueta del punto final.
  final String endLabel;

  /// Coordenada de destino usada para validar finalización.
  final LatLng endPoint;

  /// Geometría completa que se dibuja como guía en el mapa.
  final List<LatLng> path;

  /// Distancia original de la ruta en metros.
  final double totalDistanceMeters;

  /// Duración estimada original en segundos.
  final int estimatedDurationSeconds;

  /// Desnivel positivo acumulado original en metros.
  final double elevationGainMeters;

  /// Construye el payload guiado desde una ruta persistida.
  factory GuidedSavedRoute.fromStoredRoute(StoredRoute route) {
    final decodedPath = route.decodedLatLngs;
    return GuidedSavedRoute(
      routeId: route.id,
      title: route.title,
      activityProfile: route.activityProfile,
      startLabel: route.startLabel,
      startPoint: LatLng(route.startLat, route.startLon),
      endLabel: route.endLabel,
      endPoint: LatLng(route.endLat, route.endLon),
      path: decodedPath,
      totalDistanceMeters: route.totalDistanceMeters,
      estimatedDurationSeconds: route.estimatedDurationSeconds,
      elevationGainMeters: route.elevationGainMeters,
    );
  }
}
