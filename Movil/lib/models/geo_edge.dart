import 'package:ecoruta/models/geo_node.dart';
import 'package:ecoruta/models/route_profile.dart';

/// Representa una conexión dirigida entre dos nodos del grafo de rutas.
class GeoEdge {
  const GeoEdge({
    required this.id,
    required this.fromNodeId,
    required this.toNodeId,
    required this.distanceMeters,
    required this.profile,
    this.name,
    this.sourceWayId,
    this.tags = const {},
    this.geometry = const [],
  });

  /// Identificador único del tramo dentro del grafo.
  final String id;

  /// Nodo de origen desde el que inicia la arista.
  final int fromNodeId;

  /// Nodo destino al que apunta la arista.
  final int toNodeId;

  /// Distancia física estimada del tramo en metros.
  final double distanceMeters;

  /// Perfil para el que se generó esta arista.
  final RouteProfile profile;

  /// Nombre de la vía cuando OSM lo provee.
  final String? name;

  /// Referencia a la way original de OSM.
  final int? sourceWayId;

  /// Etiquetas crudas de OSM usadas para clasificar el tramo.
  final Map<String, String> tags;

  /// Geometría simplificada del segmento usada para dibujar la conexión.
  final List<GeoNode> geometry;
}
