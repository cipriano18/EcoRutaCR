import 'package:flutter/material.dart';

/// Modelo visual legado para representar tarjetas de rutas guardadas.
class SavedRouteItem {
  const SavedRouteItem({
    required this.id,
    required this.title,
    required this.location,
    required this.distance,
    required this.elevation,
    required this.time,
    required this.icon,
    required this.activityType,
  });

  /// Identificador local del elemento mostrado en UI.
  final String id;

  /// Título visible de la ruta.
  final String title;

  /// Descripción corta de ubicación.
  final String location;

  /// Distancia formateada para mostrar en tarjeta.
  final String distance;

  /// Desnivel formateado para mostrar en tarjeta.
  final String elevation;

  /// Tiempo estimado formateado para mostrar en tarjeta.
  final String time;

  /// Ícono asociado al tipo de actividad.
  final IconData icon;

  /// Etiqueta de actividad usada para filtrar en UI.
  final String activityType;
}
