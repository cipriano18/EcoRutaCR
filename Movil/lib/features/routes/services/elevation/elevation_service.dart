import 'dart:convert';

import 'package:ecoruta/features/routes/models/geo_node.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Enriquece nodos geográficos con elevación usando proveedores HTTP.
class ElevationService {
  ElevationService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _openMeteoEndpoint = 'https://api.open-meteo.com/v1/elevation';
  static const _openTopoEndpoint = 'https://api.opentopodata.org/v1/srtm30m';
  static const _openElevEndpoint =
      'https://api.open-elevation.com/api/v1/lookup';

  // Open-Meteo: máximo 100 coordenadas por request según su API.
  static const _openMeteoBatch = 100;
  // Proveedores fallback: máximo 100 por batch según sus límites.
  static const _fallbackBatch = 100;
  // Si Open-Meteo falla, limitar el fallback para no tardar minutos.
  static const _fallbackSampleMax = 150;

  /// Retorna [nodes] con elevación cuando algún proveedor responde correctamente.
  Future<List<GeoNode>> enrichWithElevation(List<GeoNode> nodes) async {
    if (nodes.isEmpty) return nodes;

    final openMeteo = await _tryOpenMeteoAll(nodes);
    if (openMeteo != null) return openMeteo;

    final sample = _takeSample(nodes, _fallbackSampleMax);
    final enrichedSample = await _fetchAllFallback(sample);
    final byId = {for (final n in enrichedSample) n.id: n};
    // En fallback se enriquece una muestra para evitar llamadas excesivas. Los
    // nodos no muestreados conservan su estado original.
    return [for (final n in nodes) byId[n.id] ?? n];
  }

  /// Intenta enriquecer todos los nodos con Open-Meteo en lotes.
  Future<List<GeoNode>?> _tryOpenMeteoAll(List<GeoNode> nodes) async {
    final result = <GeoNode>[];

    for (var i = 0; i < nodes.length; i += _openMeteoBatch) {
      final end = (i + _openMeteoBatch).clamp(0, nodes.length);
      final batch = await _tryOpenMeteoBatch(nodes.sublist(i, end));
      // Cualquier fallo cancela el proveedor para evitar mezclar calidades.
      if (batch == null) return null;
      result.addAll(batch);
    }
    return result;
  }

  /// Solicita un lote a Open-Meteo y valida que la respuesta coincida en tamaño.
  Future<List<GeoNode>?> _tryOpenMeteoBatch(List<GeoNode> nodes) async {
    final lats = nodes.map((n) => n.latitude.toStringAsFixed(6)).join(',');
    final lons = nodes.map((n) => n.longitude.toStringAsFixed(6)).join(',');

    try {
      final uri = Uri.parse(
        '$_openMeteoEndpoint?latitude=$lats&longitude=$lons',
      );
      final response = await _client
          .get(uri)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        debugPrint(
          '[Elevación] Open-Meteo HTTP ${response.statusCode}: ${response.body.substring(0, response.body.length.clamp(0, 200))}',
        );
        return null;
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final results = decoded['elevation'];
      if (results is! List || results.length != nodes.length) {
        debugPrint(
          '[Elevación] Open-Meteo respuesta inesperada: keys=${decoded.keys}, elevation_count=${results is List ? results.length : "no-list"}, esperados=${nodes.length}',
        );
        return null;
      }

      return List.generate(nodes.length, (i) {
        final elev = results[i];
        return _copyWithElevation(
          nodes[i],
          elev is num ? elev.toDouble() : null,
        );
      });
    } catch (e) {
      debugPrint(
        '[Elevación] Open-Meteo excepción (batch ${nodes.length} nodos): $e',
      );
      return null;
    }
  }

  /// Ejecuta los proveedores fallback respetando una pausa entre lotes.
  Future<List<GeoNode>> _fetchAllFallback(List<GeoNode> nodes) async {
    final result = <GeoNode>[];

    for (var i = 0; i < nodes.length; i += _fallbackBatch) {
      final end = (i + _fallbackBatch).clamp(0, nodes.length);
      final batch = nodes.sublist(i, end);
      final enriched = await _fetchOneFallbackBatch(batch);
      result.addAll(enriched);
      if (end < nodes.length) {
        await Future.delayed(const Duration(milliseconds: 1100));
      }
    }
    return result;
  }

  /// Intenta los proveedores fallback en orden de preferencia.
  Future<List<GeoNode>> _fetchOneFallbackBatch(List<GeoNode> nodes) async {
    final openTopo = await _tryOpenTopoData(nodes);
    if (openTopo != null) return openTopo;

    final openElev = await _tryOpenElevation(nodes);
    if (openElev != null) return openElev;

    throw const ElevationException(
      'No se pudo obtener elevación: todos los proveedores fallaron.',
    );
  }

  /// Consulta OpenTopoData para un lote de nodos.
  Future<List<GeoNode>?> _tryOpenTopoData(List<GeoNode> nodes) async {
    final locations = nodes
        .map((n) => '${n.latitude},${n.longitude}')
        .join('|');

    try {
      final response = await _client
          .post(
            Uri.parse(_openTopoEndpoint),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'locations': locations}),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) return null;
      final results = (jsonDecode(response.body))['results'];
      if (results is! List || results.length != nodes.length) return null;

      return List.generate(nodes.length, (i) {
        final elev = results[i]['elevation'];
        return _copyWithElevation(
          nodes[i],
          elev is num ? elev.toDouble() : null,
        );
      });
    } catch (_) {
      return null;
    }
  }

  /// Consulta Open-Elevation para un lote de nodos.
  Future<List<GeoNode>?> _tryOpenElevation(List<GeoNode> nodes) async {
    final locations = nodes
        .map((n) => {'latitude': n.latitude, 'longitude': n.longitude})
        .toList();

    try {
      final response = await _client
          .post(
            Uri.parse(_openElevEndpoint),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'locations': locations}),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) return null;
      final results = (jsonDecode(response.body))['results'];
      if (results is! List || results.length != nodes.length) return null;

      return List.generate(nodes.length, (i) {
        final elev = results[i]['elevation'];
        return _copyWithElevation(
          nodes[i],
          elev is num ? elev.toDouble() : null,
        );
      });
    } catch (_) {
      return null;
    }
  }

  /// Toma una muestra uniforme para reducir carga en proveedores fallback.
  List<GeoNode> _takeSample(List<GeoNode> nodes, int maxCount) {
    if (nodes.length <= maxCount) return nodes;
    final step = nodes.length / maxCount;
    final sampled = <GeoNode>[];
    for (var i = 0.0; i < nodes.length; i += step) {
      sampled.add(nodes[i.toInt()]);
    }
    return sampled;
  }

  /// Copia un nodo conservando metadatos y reemplazando elevación.
  GeoNode _copyWithElevation(GeoNode node, double? elevation) {
    return GeoNode(
      id: node.id,
      latitude: node.latitude,
      longitude: node.longitude,
      elevation: elevation,
      tags: node.tags,
    );
  }
}

/// Error de dominio para fallos al obtener elevación.
class ElevationException implements Exception {
  const ElevationException(this.message);

  final String message;

  @override
  String toString() => 'ElevationException: $message';
}
