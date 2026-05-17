import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecoruta/models/geo_node.dart';
import 'package:ecoruta/models/route_profile.dart';
import 'package:ecoruta/services/routing/a_star_router.dart';
import 'package:ecoruta/services/routing/route_result.dart';
import 'package:latlong2/latlong.dart';

/// Define el nivel de visibilidad con el que se comparte una ruta guardada.
enum StoredRouteVisibility { private, public }

/// Representa una ruta persistida en Firestore lista para reconstruirse.
class StoredRoute {
  const StoredRoute({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.description,
    required this.visibility,
    required this.activityProfile,
    required this.routingPreference,
    required this.startLabel,
    required this.startLat,
    required this.startLon,
    required this.endLabel,
    required this.endLat,
    required this.endLon,
    required this.polyline,
    required this.pointCount,
    required this.totalDistanceMeters,
    required this.estimatedDurationSeconds,
    required this.elevationGainMeters,
    required this.south,
    required this.west,
    required this.north,
    required this.east,
    required this.previewCenterLat,
    required this.previewCenterLon,
    this.createdAt,
    this.updatedAt,
  });

  /// Identificador del documento en Firestore.
  final String id;

  /// Usuario propietario de la ruta.
  final String ownerId;

  /// Título visible en la biblioteca de rutas.
  final String title;

  /// Descripción libre opcional.
  final String description;

  /// Visibilidad elegida por el usuario.
  final StoredRouteVisibility visibility;

  /// Perfil de actividad con el que se generó.
  final RouteProfile activityProfile;

  /// Preferencia de enrutamiento usada al guardar.
  final RoutingPreference routingPreference;

  /// Etiqueta legible del punto de origen.
  final String startLabel;

  /// Latitud del punto de inicio.
  final double startLat;

  /// Longitud del punto de inicio.
  final double startLon;

  /// Etiqueta legible del destino.
  final String endLabel;

  /// Latitud del punto final.
  final double endLat;

  /// Longitud del punto final.
  final double endLon;

  /// Geometría comprimida de la ruta en formato polyline.
  final String polyline;

  /// Cantidad de puntos codificados en la ruta.
  final int pointCount;

  /// Distancia total persistida en metros.
  final double totalDistanceMeters;

  /// Duración estimada persistida en segundos.
  final int estimatedDurationSeconds;

  /// Desnivel positivo acumulado de la ruta.
  final double elevationGainMeters;

  /// Borde sur del bounding box de la ruta.
  final double south;
  final double west;
  final double north;
  final double east;

  /// Centro aproximado usado para previsualizaciones rápidas.
  final double previewCenterLat;
  final double previewCenterLon;

  /// Fecha de creación del documento.
  final DateTime? createdAt;

  /// Fecha de última actualización.
  final DateTime? updatedAt;

  /// Etiqueta amigable del perfil para mostrar en UI.
  String get activityLabel {
    switch (activityProfile) {
      case RouteProfile.hiking:
        return 'Senderismo';
      case RouteProfile.cycling:
        return 'Ciclismo';
      case RouteProfile.running:
        return 'Running';
    }
  }

  /// Indica si la ruta está visible para otros usuarios.
  bool get isPublic => visibility == StoredRouteVisibility.public;

  /// Etiqueta legible del estado de visibilidad.
  String get visibilityLabel => isPublic ? 'Publica' : 'Privada';

  /// Decodifica la polyline guardada para redibujar la ruta.
  List<LatLng> get decodedLatLngs => _decodePolyline(polyline);

  /// Reconstruye un [RouteResult] ligero sin depender del grafo original.
  RouteResult toRouteResult() {
    final path = decodedLatLngs
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
      totalDistanceMeters: totalDistanceMeters,
      estimatedDurationSeconds: estimatedDurationSeconds,
      elevationGainMeters: elevationGainMeters,
    );
  }

  /// Serializa la entidad al formato esperado por Firestore.
  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'title': title,
      'description': description,
      'visibility': visibility.name,
      'activityProfile': activityProfile.label,
      'routingPreference': routingPreference.name,
      'start': {'label': startLabel, 'lat': startLat, 'lon': startLon},
      'end': {'label': endLabel, 'lat': endLat, 'lon': endLon},
      'polyline': polyline,
      'pointCount': pointCount,
      'totalDistanceMeters': totalDistanceMeters,
      'estimatedDurationSeconds': estimatedDurationSeconds,
      'elevationGainMeters': elevationGainMeters,
      'boundingBox': {
        'south': south,
        'west': west,
        'north': north,
        'east': east,
      },
      'preview': {'centerLat': previewCenterLat, 'centerLon': previewCenterLon},
      'createdAt': createdAt == null ? null : Timestamp.fromDate(createdAt!),
      'updatedAt': updatedAt == null ? null : Timestamp.fromDate(updatedAt!),
    };
  }

  /// Reconstruye una ruta guardada desde un documento de Firestore.
  factory StoredRoute.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    final start = _mapValue(data['start']);
    final end = _mapValue(data['end']);
    final boundingBox = _mapValue(data['boundingBox']);
    final preview = _mapValue(data['preview']);

    return StoredRoute(
      id: doc.id,
      ownerId: (data['ownerId'] as String? ?? '').trim(),
      title: (data['title'] as String? ?? 'Ruta guardada').trim(),
      description: (data['description'] as String? ?? '').trim(),
      visibility: _visibilityFromString(data['visibility'] as String?),
      activityProfile: _routeProfileFromString(
        data['activityProfile'] as String?,
      ),
      routingPreference: _routingPreferenceFromString(
        data['routingPreference'] as String?,
      ),
      startLabel: (start['label'] as String? ?? 'Origen').trim(),
      startLat: _toDouble(start['lat']),
      startLon: _toDouble(start['lon']),
      endLabel: (end['label'] as String? ?? 'Destino').trim(),
      endLat: _toDouble(end['lat']),
      endLon: _toDouble(end['lon']),
      polyline: (data['polyline'] as String? ?? '').trim(),
      pointCount: (data['pointCount'] as num?)?.toInt() ?? 0,
      totalDistanceMeters: _toDouble(data['totalDistanceMeters']),
      estimatedDurationSeconds:
          (data['estimatedDurationSeconds'] as num?)?.toInt() ?? 0,
      elevationGainMeters: _toDouble(data['elevationGainMeters']),
      south: _toDouble(boundingBox['south']),
      west: _toDouble(boundingBox['west']),
      north: _toDouble(boundingBox['north']),
      east: _toDouble(boundingBox['east']),
      previewCenterLat: _toDouble(preview['centerLat']),
      previewCenterLon: _toDouble(preview['centerLon']),
      createdAt: _timestampToDateTime(data['createdAt']),
      updatedAt: _timestampToDateTime(data['updatedAt']),
    );
  }

  /// Codifica la ruta como polyline para reducir el tamaño del documento.
  static String encodePath(List<GeoNode> path) {
    if (path.isEmpty) return '';

    final result = StringBuffer();
    var lastLat = 0;
    var lastLon = 0;

    for (final node in path) {
      final lat = (node.latitude * 1e5).round();
      final lon = (node.longitude * 1e5).round();

      _encodeSignedValue(lat - lastLat, result);
      _encodeSignedValue(lon - lastLon, result);

      lastLat = lat;
      lastLon = lon;
    }

    return result.toString();
  }

  static List<LatLng> _decodePolyline(String encoded) {
    if (encoded.isEmpty) return const [];

    final points = <LatLng>[];
    var index = 0;
    var lat = 0;
    var lon = 0;

    while (index < encoded.length) {
      lat += _decodeValue(encoded, index);
      index = _nextDecodeIndex;
      lon += _decodeValue(encoded, index);
      index = _nextDecodeIndex;
      points.add(LatLng(lat / 1e5, lon / 1e5));
    }

    return points;
  }

  static void _encodeSignedValue(int value, StringBuffer buffer) {
    var chunk = value < 0 ? ~(value << 1) : value << 1;
    while (chunk >= 0x20) {
      buffer.writeCharCode((0x20 | (chunk & 0x1f)) + 63);
      chunk >>= 5;
    }
    buffer.writeCharCode(chunk + 63);
  }

  static int _nextDecodeIndex = 0;

  static int _decodeValue(String encoded, int startIndex) {
    var result = 0;
    var shift = 0;
    int byte;
    var index = startIndex;

    do {
      byte = encoded.codeUnitAt(index) - 63;
      result |= (byte & 0x1f) << shift;
      shift += 5;
      index++;
    } while (byte >= 0x20);

    _nextDecodeIndex = index;
    return (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
  }

  static Map<String, dynamic> _mapValue(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), val));
    }
    return const <String, dynamic>{};
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return 0;
  }

  static DateTime? _timestampToDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  static StoredRouteVisibility _visibilityFromString(String? value) {
    switch (value) {
      case 'public':
        return StoredRouteVisibility.public;
      case 'private':
      default:
        return StoredRouteVisibility.private;
    }
  }

  static RouteProfile _routeProfileFromString(String? value) {
    switch (value) {
      case 'cycling':
        return RouteProfile.cycling;
      case 'running':
        return RouteProfile.running;
      case 'hiking':
      default:
        return RouteProfile.hiking;
    }
  }

  static RoutingPreference _routingPreferenceFromString(String? value) {
    switch (value) {
      case 'fastest':
        return RoutingPreference.fastest;
      case 'mostChallenging':
        return RoutingPreference.mostChallenging;
      case 'shortest':
      default:
        return RoutingPreference.shortest;
    }
  }
}
