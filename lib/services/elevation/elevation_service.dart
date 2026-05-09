import 'dart:convert';

import 'package:ecoruta/models/geo_node.dart';
import 'package:http/http.dart' as http;

/// Administra consultas de elevación para enriquecer nodos geográficos.
class ElevationService {
  ElevationService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _endpoint = 'https://api.opentopodata.org/v1/srtm30m';
  static const _batchSize = 100;

  /// Enriquece nodos con elevación sin alterar el orden del recorrido.
  Future<List<GeoNode>> enrichWithElevation(List<GeoNode> nodes) async {
    if (nodes.isEmpty) return nodes;

    final result = <GeoNode>[];

    for (var i = 0; i < nodes.length; i += _batchSize) {
      final end = (i + _batchSize).clamp(0, nodes.length);
      final batch = nodes.sublist(i, end);
      final enriched = await _fetchBatch(batch);
      result.addAll(enriched);
    }

    return result;
  }

  Future<List<GeoNode>> _fetchBatch(List<GeoNode> nodes) async {
    final locations = nodes
        .map((n) => '${n.latitude},${n.longitude}')
        .join('|');

    try {
      final response = await _client
          .post(
            Uri.parse(_endpoint),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'locations': locations}),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) return nodes;

      final decoded = jsonDecode(response.body);
      final results = decoded['results'];
      if (results is! List || results.length != nodes.length) return nodes;

      return List.generate(nodes.length, (i) {
        final elevation = results[i]['elevation'];
        return GeoNode(
          id: nodes[i].id,
          latitude: nodes[i].latitude,
          longitude: nodes[i].longitude,
          elevation: elevation is num ? elevation.toDouble() : null,
          tags: nodes[i].tags,
        );
      });
    } catch (_) {
      return nodes;
    }
  }
}

/// Error semántico para fallas específicas del servicio de elevación.
class ElevationException implements Exception {
  const ElevationException(this.message);

  final String message;

  @override
  String toString() => 'ElevationException: $message';
}
