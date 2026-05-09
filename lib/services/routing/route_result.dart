import 'package:ecoruta/models/geo_node.dart';

/// Contiene el resultado final de una búsqueda de ruta.
class RouteResult {
  const RouteResult({
    required this.path,
    required this.totalDistanceMeters,
    required this.estimatedDurationSeconds,
    this.elevationGainMeters = 0,
  });

  /// Secuencia ordenada de nodos que componen la ruta.
  final List<GeoNode> path;

  /// Distancia total recorrida en metros.
  final double totalDistanceMeters;

  /// Duración estimada total en segundos.
  final int estimatedDurationSeconds;

  /// Desnivel positivo acumulado del recorrido.
  final double elevationGainMeters;

  /// Indica si la ruta no contiene nodos utilizables.
  bool get isEmpty => path.isEmpty;

  /// Distancia total lista para mostrar en la UI.
  String get formattedDistance {
    if (totalDistanceMeters >= 1000) {
      return '${(totalDistanceMeters / 1000).toStringAsFixed(1)} km';
    }
    return '${totalDistanceMeters.round()} m';
  }

  /// Duración estimada formateada para lectura humana.
  String get formattedDuration {
    final hours = estimatedDurationSeconds ~/ 3600;
    final minutes = (estimatedDurationSeconds % 3600) ~/ 60;
    if (hours > 0) {
      return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
    }
    return '${minutes}m';
  }

  /// Desnivel positivo formateado para tarjetas y detalles.
  String get formattedElevationGain => '+${elevationGainMeters.round()} m';

  /// Sustituye el camino por una versión enriquecida con elevación real.
  RouteResult withElevation(List<GeoNode> enrichedPath) {
    return RouteResult(
      path: enrichedPath,
      totalDistanceMeters: totalDistanceMeters,
      estimatedDurationSeconds: estimatedDurationSeconds,
      elevationGainMeters: _calculateElevationGain(enrichedPath),
    );
  }

  static double _calculateElevationGain(List<GeoNode> path) {
    double gain = 0;
    for (var i = 1; i < path.length; i++) {
      final prev = path[i - 1].elevation;
      final curr = path[i].elevation;
      if (prev != null && curr != null) {
        final diff = curr - prev;
        if (diff > 0) gain += diff;
      }
    }
    return gain;
  }
}
