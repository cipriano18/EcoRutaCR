import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:ecoruta/features/routes/models/geo_edge.dart';
import 'package:ecoruta/features/routes/models/geo_node.dart';
import 'package:ecoruta/features/routes/models/route_profile.dart';
import 'package:ecoruta/features/routes/services/routing/route_result.dart';

/// Preferencia que ajusta el costo usado por el algoritmo de enrutamiento.
enum RoutingPreference { shortest, mostChallenging }

/// Resuelve rutas sobre el grafo de la app usando A* y heurísticas simples.
class AStarRouter {
  const AStarRouter();

  /// Busca una ruta entre [startId] y [goalId] usando el grafo entregado.
  ///
  /// Retorna `null` cuando no hay nodos válidos o el destino no es alcanzable.
  RouteResult? findRoute({
    required List<GeoNode> nodes,
    required List<GeoEdge> edges,
    required int startId,
    required int goalId,
    required RouteProfile profile,
    RoutingPreference preference = RoutingPreference.shortest,
  }) {
    final nodeMap = {for (final n in nodes) n.id: n};
    final startNode = nodeMap[startId];
    final goalNode = nodeMap[goalId];
    if (startNode == null || goalNode == null) return null;
    if (startId == goalId) {
      return RouteResult(
        path: [startNode],
        totalDistanceMeters: 0,
        estimatedDurationSeconds: 0,
      );
    }

    final adjacency = _buildAdjacency(edges);
    final gScore = <int, double>{startId: 0.0};
    final fScore = <int, double>{
      startId: _heuristic(startNode, goalNode, profile, preference),
    };
    final cameFrom = <int, GeoEdge>{};
    final closedSet = <int>{};
    final openQueue = PriorityQueue<_AStarEntry>((a, b) => a.f.compareTo(b.f))
      ..add(_AStarEntry(startId, fScore[startId]!));

    while (openQueue.isNotEmpty) {
      final currentEntry = openQueue.removeFirst();
      final current = currentEntry.id;

      if (closedSet.contains(current)) continue;
      if (currentEntry.f > (fScore[current] ?? double.infinity)) continue;
      closedSet.add(current);

      if (current == goalId) {
        return _reconstructPath(cameFrom, nodeMap, profile, current);
      }

      for (final edge in adjacency[current] ?? const <GeoEdge>[]) {
        final neighbor = edge.toNodeId;
        if (closedSet.contains(neighbor)) continue;

        final fromNode = nodeMap[current];
        final toNode = nodeMap[neighbor];
        if (fromNode == null || toNode == null) continue;

        final tentativeG =
            (gScore[current] ?? double.infinity) +
            _edgeSearchCost(edge, fromNode, toNode, profile, preference);

        if (tentativeG < (gScore[neighbor] ?? double.infinity)) {
          // A* solo actualiza el camino cuando encuentra un costo acumulado
          // menor para el nodo vecino.
          cameFrom[neighbor] = edge;
          gScore[neighbor] = tentativeG;
          final nextF =
              tentativeG + _heuristic(toNode, goalNode, profile, preference);
          fScore[neighbor] = nextF;
          openQueue.add(_AStarEntry(neighbor, nextF));
        }
      }
    }

    return null;
  }

  /// Busca el nodo más cercano dentro del componente principal del grafo.
  GeoNode? nearestNode(
    List<GeoNode> nodes,
    List<GeoEdge> edges,
    double latitude,
    double longitude,
  ) {
    if (nodes.isEmpty) return null;

    final candidates = _mainComponentNodes(nodes, edges);
    final pool = candidates.isEmpty ? nodes : candidates;

    GeoNode nearest = pool.first;
    double minDist = _haversine(
      nearest.latitude,
      nearest.longitude,
      latitude,
      longitude,
    );

    for (final node in pool.skip(1)) {
      final dist = _haversine(
        node.latitude,
        node.longitude,
        latitude,
        longitude,
      );
      if (dist < minDist) {
        minDist = dist;
        nearest = node;
      }
    }

    return nearest;
  }

  /// Retorna varios nodos cercanos para probar anclas de conexión válidas.
  List<GeoNode> nearestNodes(
    List<GeoNode> nodes,
    double latitude,
    double longitude, {
    int limit = 8,
  }) {
    if (nodes.isEmpty || limit <= 0) return const [];

    final sorted = [...nodes];
    sorted.sort(
      (a, b) => _haversine(
        a.latitude,
        a.longitude,
        latitude,
        longitude,
      ).compareTo(_haversine(b.latitude, b.longitude, latitude, longitude)),
    );
    return sorted.take(limit).toList(growable: false);
  }

  /// Retorna los nodos que pertenecen a la componente conexa más grande del grafo.
  List<GeoNode> mainComponentNodes(List<GeoNode> nodes, List<GeoEdge> edges) =>
      _mainComponentNodes(nodes, edges);

  List<GeoNode> _mainComponentNodes(List<GeoNode> nodes, List<GeoEdge> edges) {
    final adj = <int, List<int>>{};
    for (final e in edges) {
      adj.putIfAbsent(e.fromNodeId, () => []).add(e.toNodeId);
      adj.putIfAbsent(e.toNodeId, () => []).add(e.fromNodeId);
    }

    final nodeIds = {for (final n in nodes) n.id};
    final visited = <int>{};
    List<int> largest = [];

    for (final seed in nodeIds) {
      if (visited.contains(seed)) continue;
      final component = <int>[];
      final stack = [seed];
      while (stack.isNotEmpty) {
        final cur = stack.removeLast();
        if (visited.contains(cur)) continue;
        visited.add(cur);
        component.add(cur);
        for (final nb in adj[cur] ?? const <int>[]) {
          if (!visited.contains(nb)) stack.add(nb);
        }
      }
      // Se usa la componente más grande para evitar anclar rutas en islas
      // pequeñas del grafo que luego no conectan con el destino.
      if (component.length > largest.length) largest = component;
    }

    final largestSet = largest.toSet();
    return nodes.where((n) => largestSet.contains(n.id)).toList();
  }

  Map<int, List<GeoEdge>> _buildAdjacency(List<GeoEdge> edges) {
    final map = <int, List<GeoEdge>>{};
    for (final edge in edges) {
      map.putIfAbsent(edge.fromNodeId, () => []).add(edge);
    }
    return map;
  }

  /// Calcula el costo de búsqueda de una arista según perfil y preferencia.
  double _edgeSearchCost(
    GeoEdge edge,
    GeoNode fromNode,
    GeoNode toNode,
    RouteProfile profile,
    RoutingPreference preference,
  ) {
    final highwayWeight = _highwayWeight(edge, profile, preference);

    switch (preference) {
      case RoutingPreference.shortest:
        return edge.distanceMeters * highwayWeight;
      case RoutingPreference.mostChallenging:
        return edge.distanceMeters * highwayWeight;
    }
  }

  double _highwayWeight(
    GeoEdge edge,
    RouteProfile profile,
    RoutingPreference preference,
  ) {
    final highway = edge.tags['highway'];

    switch (profile) {
      case RouteProfile.cycling:
        switch (highway) {
          case 'cycleway':
            return 0.82;
          case 'path':
          case 'track':
            return preference == RoutingPreference.mostChallenging ? 0.95 : 1.0;
          case 'living_street':
          case 'service':
          case 'residential':
          case 'unclassified':
            return 1.0;
          case 'tertiary':
          case 'tertiary_link':
            return 1.08;
          case 'secondary':
          case 'secondary_link':
            return 1.18;
          case 'primary':
          case 'primary_link':
            return 1.35;
          case 'trunk':
          case 'trunk_link':
            return 1.55;
          default:
            return 1.12;
        }
      case RouteProfile.running:
      case RouteProfile.hiking:
        return 1.0;
    }
  }

  double _edgeTravelTimeSeconds(GeoEdge edge, RouteProfile profile) {
    final baseSpeed = _baseSpeedMps(profile);
    if (baseSpeed <= 0) return double.infinity;
    return edge.distanceMeters / baseSpeed;
  }

  /// Velocidad base aproximada en metros por segundo para cada actividad.
  double _baseSpeedMps(RouteProfile profile) {
    switch (profile) {
      case RouteProfile.cycling:
        return 3.89;
      case RouteProfile.running:
        return 3.0;
      case RouteProfile.hiking:
        return 1.11;
    }
  }

  /// Estima el costo restante hasta el destino.
  double _heuristic(
    GeoNode from,
    GeoNode to,
    RouteProfile profile,
    RoutingPreference preference,
  ) {
    final distance = _haversine(
      from.latitude,
      from.longitude,
      to.latitude,
      to.longitude,
    );
    switch (preference) {
      case RoutingPreference.shortest:
        return distance;
      case RoutingPreference.mostChallenging:
        return distance;
    }
  }

  /// Calcula distancia geodésica aproximada en metros con Haversine.
  double _haversine(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371000.0;
    final dLat = _rad(lat2 - lat1);
    final dLon = _rad(lon2 - lon1);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_rad(lat1)) *
            math.cos(_rad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  double _rad(double deg) => deg * math.pi / 180;

  /// Reconstruye el camino final siguiendo las aristas guardadas en [cameFrom].
  RouteResult _reconstructPath(
    Map<int, GeoEdge> cameFrom,
    Map<int, GeoNode> nodeMap,
    RouteProfile profile,
    int current,
  ) {
    final path = <GeoNode>[];
    final pathEdges = <GeoEdge>[];
    var nodeId = current;

    while (cameFrom.containsKey(nodeId)) {
      path.add(nodeMap[nodeId]!);
      final edge = cameFrom[nodeId]!;
      pathEdges.add(edge);
      nodeId = edge.fromNodeId;
    }
    path.add(nodeMap[nodeId]!);

    final orderedPath = path.reversed.toList();
    final orderedEdges = pathEdges.reversed.toList();
    var totalDistanceMeters = 0.0;
    var estimatedDurationSeconds = 0.0;
    var elevationGainMeters = 0.0;

    for (var i = 0; i < orderedEdges.length; i++) {
      final edge = orderedEdges[i];
      final fromNode = orderedPath[i];
      final toNode = orderedPath[i + 1];

      totalDistanceMeters += edge.distanceMeters;
      estimatedDurationSeconds += _edgeTravelTimeSeconds(edge, profile);
      elevationGainMeters += _positiveElevationGain(fromNode, toNode);
    }

    return RouteResult(
      path: orderedPath,
      totalDistanceMeters: totalDistanceMeters,
      estimatedDurationSeconds: estimatedDurationSeconds.round(),
      elevationGainMeters: elevationGainMeters,
    );
  }

  /// Retorna únicamente el ascenso positivo entre dos nodos.
  double _positiveElevationGain(GeoNode fromNode, GeoNode toNode) {
    final fromElevation = fromNode.elevation;
    final toElevation = toNode.elevation;
    if (fromElevation == null || toElevation == null) return 0;
    final diff = toElevation - fromElevation;
    return diff > 0 ? diff : 0;
  }
}

/// Entrada priorizada dentro de la cola abierta de A*.
class _AStarEntry {
  const _AStarEntry(this.id, this.f);

  final int id;
  final double f;
}
