import 'package:ecoruta/models/route_profile.dart';
import 'package:ecoruta/models/stored_route.dart';
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

  final String routeId;
  final String title;
  final RouteProfile activityProfile;
  final String startLabel;
  final LatLng startPoint;
  final String endLabel;
  final LatLng endPoint;
  final List<LatLng> path;
  final double totalDistanceMeters;
  final int estimatedDurationSeconds;
  final double elevationGainMeters;

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
