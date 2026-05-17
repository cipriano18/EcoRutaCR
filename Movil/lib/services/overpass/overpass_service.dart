import 'dart:async';
import 'dart:convert';

import 'package:ecoruta/models/route_profile.dart';
import 'package:http/http.dart' as http;

/// Administra la construcción y ejecución de consultas contra Overpass.
class OverpassService {
  OverpassService({http.Client? client, String? endpoint})
    : _client = client ?? http.Client(),
      _endpoint = endpoint ?? 'https://overpass-api.de/api/interpreter';

  final http.Client _client;
  final String _endpoint;

  /// Ejecuta una consulta cruda y valida el formato básico de la respuesta.
  Future<Map<String, dynamic>> executeRawQuery(String query) async {
    final response = await _client
        .post(
          Uri.parse(_endpoint),
          headers: const {
            'Content-Type': 'application/x-www-form-urlencoded',
            'User-Agent': 'EcoRutaCR/1.0',
          },
          body: {'data': query},
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw OverpassException(
        'Overpass respondió con código ${response.statusCode}.',
      );
    }

    final dynamic decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const OverpassException(
        'La respuesta de Overpass no tiene el formato esperado.',
      );
    }

    return decoded;
  }

  /// Descarga datos OSM dentro de un bounding box para el perfil indicado.
  Future<Map<String, dynamic>> fetchRoutesInBoundingBox({
    required double south,
    required double west,
    required double north,
    required double east,
    required RouteProfile profile,
  }) {
    final query = buildBoundingBoxQuery(
      south: south,
      west: west,
      north: north,
      east: east,
      profile: profile,
    );

    return executeRawQuery(query);
  }

  /// Descarga datos OSM alrededor de un punto y radio dados.
  Future<Map<String, dynamic>> fetchRoutesAroundPoint({
    required double latitude,
    required double longitude,
    required int radiusMeters,
    required RouteProfile profile,
  }) {
    final query = buildAroundPointQuery(
      latitude: latitude,
      longitude: longitude,
      radiusMeters: radiusMeters,
      profile: profile,
    );

    return executeRawQuery(query);
  }

  /// Construye una consulta Overpass basada en un bounding box.
  String buildBoundingBoxQuery({
    required double south,
    required double west,
    required double north,
    required double east,
    required RouteProfile profile,
  }) {
    final bbox = '($south,$west,$north,$east)';
    return '''
[out:json][timeout:25];
(
  ${_buildRelationQuery(profile, bbox)}
  ${_buildWayQuery(profile, bbox)}
);
out body;
>;
out skel qt;
''';
  }

  /// Construye una consulta Overpass centrada en un punto.
  String buildAroundPointQuery({
    required double latitude,
    required double longitude,
    required int radiusMeters,
    required RouteProfile profile,
  }) {
    final around = '(around:$radiusMeters,$latitude,$longitude)';
    return '''
[out:json][timeout:25];
(
  ${_buildRelationQuery(profile, around)}
  ${_buildWayQuery(profile, around)}
);
out body;
>;
out skel qt;
''';
  }

  String _buildRelationQuery(RouteProfile profile, String areaSelector) {
    final buffer = StringBuffer();
    for (final routeValue in profile.routeValues) {
      buffer.writeln('relation["route"="$routeValue"]$areaSelector;');
    }
    return buffer.toString();
  }

  String _buildWayQuery(RouteProfile profile, String areaSelector) {
    final buffer = StringBuffer();
    final accessFilter = _accessFilter(profile);

    for (final highwayValue in profile.highwayValues) {
      buffer.writeln(
        'way["highway"="$highwayValue"]$accessFilter$areaSelector;',
      );
    }

    switch (profile) {
      case RouteProfile.hiking:
        buffer.writeln(
          'way["foot"]["foot"!="no"]${_baseExclusionFilter()}$areaSelector;',
        );
        break;
      case RouteProfile.cycling:
        buffer.writeln(
          'way["bicycle"]["bicycle"!="no"]${_baseExclusionFilter()}$areaSelector;',
        );
        buffer.writeln(
          'way["cycleway"]${_baseExclusionFilter()}$areaSelector;',
        );
        break;
      case RouteProfile.running:
        buffer.writeln(
          'way["foot"]["foot"!="no"]${_baseExclusionFilter()}$areaSelector;',
        );
        break;
    }

    return buffer.toString();
  }

  String _accessFilter(RouteProfile profile) {
    final buffer = StringBuffer(_baseExclusionFilter());
    switch (profile) {
      case RouteProfile.hiking:
      case RouteProfile.running:
        buffer.write('["foot"!="no"]');
        break;
      case RouteProfile.cycling:
        buffer.write('["bicycle"!="no"]');
        break;
    }
    return buffer.toString();
  }

  String _baseExclusionFilter() {
    return '["access"!="private"]["access"!="no"]["motorroad"!="yes"]["area"!="yes"]';
  }
}

/// Representa fallas controladas al interactuar con Overpass.
class OverpassException implements Exception {
  const OverpassException(this.message);

  final String message;

  @override
  String toString() => 'OverpassException: $message';
}
