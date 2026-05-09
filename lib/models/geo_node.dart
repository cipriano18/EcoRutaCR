/// Representa un nodo geográfico del grafo de rutas.
class GeoNode {
  const GeoNode({
    required this.id,
    required this.latitude,
    required this.longitude,
    this.elevation,
    this.tags = const {},
  });

  /// Identificador único del nodo dentro del grafo.
  final int id;

  /// Latitud del punto.
  final double latitude;

  /// Longitud del punto.
  final double longitude;

  /// Elevación opcional enriquecida desde servicios externos.
  final double? elevation;

  /// Metadatos asociados al nodo cuando existen en OSM.
  final Map<String, String> tags;
}
