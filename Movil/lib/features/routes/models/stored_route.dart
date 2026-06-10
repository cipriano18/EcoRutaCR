import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecoruta/features/routes/models/geo_node.dart';
import 'package:ecoruta/features/routes/models/route_profile.dart';
import 'package:ecoruta/features/routes/services/routing/a_star_router.dart';
import 'package:ecoruta/features/routes/services/routing/route_result.dart';
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
    this.sourceRouteId,
    this.savedByUserId,
    this.sourceOwnerId,
    this.sourceOwnerName,
    this.savedAt,
    this.sourceRouteCreatedAt,
    this.sourceRouteUpdatedAt,
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

  /// Borde oeste del bounding box de la ruta.
  final double west;

  /// Borde norte del bounding box de la ruta.
  final double north;

  /// Borde este del bounding box de la ruta.
  final double east;

  /// Latitud del centro aproximado usado para previsualizaciones rápidas.
  final double previewCenterLat;

  /// Longitud del centro aproximado usado para previsualizaciones rápidas.
  final double previewCenterLon;

  /// Identificador de la ruta pública original cuando esta fue guardada.
  final String? sourceRouteId;

  /// Usuario que guardó la ruta pública como referencia personal.
  final String? savedByUserId;

  /// Propietario original de la ruta pública guardada.
  final String? sourceOwnerId;

  /// Nombre visible del autor original al momento de guardar.
  final String? sourceOwnerName;

  /// Fecha en la que el usuario guardó esta ruta pública.
  final DateTime? savedAt;

  /// Fecha original de creación de la ruta fuente.
  final DateTime? sourceRouteCreatedAt;

  /// Fecha original de actualización de la ruta fuente.
  final DateTime? sourceRouteUpdatedAt;

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

  /// Indica si este documento representa una referencia guardada de una ruta pública.
  bool get isSavedPublicRoute => sourceRouteId?.isNotEmpty == true;

  /// Etiqueta legible del estado de visibilidad.
  String get visibilityLabel => isPublic ? 'Pública' : 'Privada';

  /// Decodifica la polyline guardada para redibujar la ruta.
  List<LatLng> get decodedLatLngs => _decodePolyline(polyline);

  /// Reconstruye un [RouteResult] ligero sin depender del grafo original.
  RouteResult toRouteResult() {
    // La polyline puede venir de documentos antiguos o externos. Se filtran
    // coordenadas inválidas antes de construir nodos consumidos por el mapa.
    final validPoints = decodedLatLngs
        .where((point) {
          return point.latitude >= -90 &&
              point.latitude <= 90 &&
              point.longitude >= -180 &&
              point.longitude <= 180;
        })
        .toList(growable: false);

    final path = validPoints
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
      if (sourceRouteId != null) 'sourceRouteId': sourceRouteId,
      if (savedByUserId != null) 'savedByUserId': savedByUserId,
      if (sourceOwnerId != null) 'sourceOwnerId': sourceOwnerId,
      if (sourceOwnerName != null) 'sourceOwnerName': sourceOwnerName,
      'savedAt': savedAt == null ? null : Timestamp.fromDate(savedAt!),
      'sourceRouteCreatedAt': sourceRouteCreatedAt == null
          ? null
          : Timestamp.fromDate(sourceRouteCreatedAt!),
      'sourceRouteUpdatedAt': sourceRouteUpdatedAt == null
          ? null
          : Timestamp.fromDate(sourceRouteUpdatedAt!),
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
      polyline: (data['polyline'] as String? ?? '')
          .replaceAll(RegExp(r'\s+'), '')
          .trim(),
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
      sourceRouteId: (data['sourceRouteId'] as String?)?.trim(),
      savedByUserId: (data['savedByUserId'] as String?)?.trim(),
      sourceOwnerId: (data['sourceOwnerId'] as String?)?.trim(),
      sourceOwnerName: (data['sourceOwnerName'] as String?)?.trim(),
      savedAt: _timestampToDateTime(data['savedAt']),
      sourceRouteCreatedAt: _timestampToDateTime(data['sourceRouteCreatedAt']),
      sourceRouteUpdatedAt: _timestampToDateTime(data['sourceRouteUpdatedAt']),
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
      final latResult = _decodeValue(encoded, index);
      lat += latResult.value;
      index = latResult.nextIndex;

      if (index >= encoded.length) break;

      final lonResult = _decodeValue(encoded, index);
      lon += lonResult.value;
      index = lonResult.nextIndex;

      final point = LatLng(lat / 1e5, lon / 1e5);

      // Se descartan coordenadas fuera de rango para tolerar payloads
      // incompletos sin romper la reconstrucción del resto de la ruta.
      if (point.latitude >= -90 &&
          point.latitude <= 90 &&
          point.longitude >= -180 &&
          point.longitude <= 180) {
        points.add(point);
      }
    }

    return points;
  }

  static void _encodeSignedValue(int value, StringBuffer buffer) {
    var chunk = value < 0 ? ((-value) << 1) - 1 : value << 1;

    while (chunk >= 0x20) {
      buffer.writeCharCode((0x20 | (chunk & 0x1f)) + 63);
      chunk >>= 5;
    }

    buffer.writeCharCode(chunk + 63);
  }

  /// Decodifica un valor firmado desde [encoded] usando el índice actual.
  static _DecodedValue _decodeValue(String encoded, int startIndex) {
    var result = 0;
    var shift = 0;
    var index = startIndex;

    while (index < encoded.length) {
      final byte = encoded.codeUnitAt(index) - 63;
      index++;

      result |= (byte & 0x1f) << shift;
      shift += 5;

      if (byte < 0x20) {
        final value = (result & 1) != 0 ? -((result >> 1) + 1) : (result >> 1);

        return _DecodedValue(value, index);
      }
    }

    return _DecodedValue(0, index);
  }

  /// Normaliza mapas provenientes de Firestore o estructuras dinámicas.
  static Map<String, dynamic> _mapValue(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), val));
    }
    return const <String, dynamic>{};
  }

  /// Convierte valores numéricos dinámicos a [double] con cero como respaldo.
  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return 0;
  }

  /// Convierte fechas de Firestore o Dart a [DateTime].
  static DateTime? _timestampToDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  /// Interpreta la visibilidad guardada en Firestore.
  static StoredRouteVisibility _visibilityFromString(String? value) {
    switch (value) {
      case 'public':
        return StoredRouteVisibility.public;
      case 'private':
      default:
        return StoredRouteVisibility.private;
    }
  }

  /// Interpreta el perfil de actividad guardado en Firestore.
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

  /// Interpreta la preferencia de enrutamiento guardada en Firestore.
  static RoutingPreference _routingPreferenceFromString(String? value) {
    switch (value) {
      case 'mostChallenging':
        return RoutingPreference.mostChallenging;
      case 'shortest':
      default:
        return RoutingPreference.shortest;
    }
  }
}

/// Resultado parcial de decodificar un componente de polyline.
class _DecodedValue {
  const _DecodedValue(this.value, this.nextIndex);

  final int value;
  final int nextIndex;
}
