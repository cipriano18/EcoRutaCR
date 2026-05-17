import 'dart:math' as math;

import 'package:ecoruta/models/geo_edge.dart';
import 'package:ecoruta/models/geo_node.dart';
import 'package:ecoruta/models/route_profile.dart';

/// Resultado intermedio del mapeo de una respuesta OSM a grafo navegable.
class OsmGraphData {
  const OsmGraphData({
    required this.nodes,
    required this.edges,
    required this.rawWays,
  });

  final List<GeoNode> nodes;
  final List<GeoEdge> edges;
  final List<Map<String, dynamic>> rawWays;
}

/// Convierte la respuesta de Overpass en nodos y aristas de la app.
class OsmMapper {
  const OsmMapper();

  /// Transforma la carga cruda de OSM en una estructura apta para routing.
  OsmGraphData mapToGraph(
    Map<String, dynamic> payload, {
    required RouteProfile profile,
  }) {
    final rawElements = payload['elements'];
    if (rawElements is! List) {
      return const OsmGraphData(nodes: [], edges: [], rawWays: []);
    }

    final elements = rawElements.whereType<Map<String, dynamic>>().toList();
    final nodeMap = <int, GeoNode>{};
    final edges = <GeoEdge>[];
    final rawWays = <Map<String, dynamic>>[];

    for (final element in elements) {
      if (element['type'] != 'node') {
        continue;
      }

      final id = element['id'];
      final lat = element['lat'];
      final lon = element['lon'];
      if (id is! int || lat is! num || lon is! num) {
        continue;
      }

      nodeMap[id] = GeoNode(
        id: id,
        latitude: lat.toDouble(),
        longitude: lon.toDouble(),
        tags: _stringTags(element['tags']),
      );
    }

    for (final element in elements) {
      if (element['type'] != 'way') {
        continue;
      }

      rawWays.add(element);
      final wayId = element['id'];
      final nodeIds = element['nodes'];
      if (wayId is! int || nodeIds is! List) {
        continue;
      }

      final tags = _stringTags(element['tags']);
      final validNodeIds = nodeIds.whereType<int>().toList();

      for (var i = 0; i < validNodeIds.length - 1; i++) {
        final fromNode = nodeMap[validNodeIds[i]];
        final toNode = nodeMap[validNodeIds[i + 1]];
        if (fromNode == null || toNode == null) {
          continue;
        }

        final dist = _distanceInMeters(fromNode, toNode);

        edges.add(
          GeoEdge(
            id: '$wayId-${fromNode.id}-${toNode.id}',
            fromNodeId: fromNode.id,
            toNodeId: toNode.id,
            distanceMeters: dist,
            profile: profile,
            name: tags['name'],
            sourceWayId: wayId,
            tags: tags,
            geometry: [fromNode, toNode],
          ),
        );

        // Los caminos de OSM son bidireccionales salvo oneway=yes.
        final isOneway = tags['oneway'] == 'yes' || tags['oneway'] == '1';
        if (!isOneway) {
          edges.add(
            GeoEdge(
              id: '$wayId-${toNode.id}-${fromNode.id}',
              fromNodeId: toNode.id,
              toNodeId: fromNode.id,
              distanceMeters: dist,
              profile: profile,
              name: tags['name'],
              sourceWayId: wayId,
              tags: tags,
              geometry: [toNode, fromNode],
            ),
          );
        }
      }
    }

    return OsmGraphData(
      nodes: nodeMap.values.toList(growable: false),
      edges: edges,
      rawWays: rawWays,
    );
  }

  Map<String, String> _stringTags(dynamic tags) {
    if (tags is! Map) {
      return const {};
    }

    final mapped = <String, String>{};
    for (final entry in tags.entries) {
      final key = entry.key;
      final value = entry.value;
      if (key is String && value != null) {
        mapped[key] = value.toString();
      }
    }
    return mapped;
  }

  double _distanceInMeters(GeoNode from, GeoNode to) {
    const earthRadius = 6371000.0;
    final dLat = _degreesToRadians(to.latitude - from.latitude);
    final dLon = _degreesToRadians(to.longitude - from.longitude);
    final startLat = _degreesToRadians(from.latitude);
    final endLat = _degreesToRadians(to.latitude);

    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(startLat) *
            math.cos(endLat) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) => degrees * math.pi / 180;
}
