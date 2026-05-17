import 'dart:math' as math;

import 'package:ecoruta/models/geo_edge.dart';
import 'package:ecoruta/models/geo_node.dart';
import 'package:ecoruta/models/route_profile.dart';
import 'package:ecoruta/services/elevation/elevation_service.dart';
import 'package:ecoruta/services/overpass/osm_mapper.dart';
import 'package:ecoruta/services/overpass/overpass_service.dart';
import 'package:ecoruta/services/routing/a_star_router.dart';
import 'package:ecoruta/services/routing/route_result.dart';
import 'package:flutter/foundation.dart';

/// Agrupa la selección de nodos ancla usada para una ruta candidata.
class _AnchorSelection {
  const _AnchorSelection({
    required this.startNode,
    required this.endNode,
    required this.previewRoute,
    required this.startDistanceMeters,
    required this.endDistanceMeters,
  });

  final GeoNode startNode;
  final GeoNode endNode;
  final RouteResult previewRoute;
  final double startDistanceMeters;
  final double endDistanceMeters;
}

/// Expone datos de diagnóstico útiles para depurar generación de rutas.
class RouteDebugInfo {
  const RouteDebugInfo({
    required this.requestedStartLat,
    required this.requestedStartLon,
    required this.requestedEndLat,
    required this.requestedEndLon,
    required this.graphNodeCount,
    required this.graphEdgeCount,
    required this.graphWayCount,
    required this.componentCount,
    required this.largestComponentNodeCount,
    required this.startCandidateCount,
    required this.endCandidateCount,
    this.selectedStartNode,
    this.selectedEndNode,
    this.selectedStartDistanceMeters,
    this.selectedEndDistanceMeters,
    this.shortestRouteNodeCount,
    this.shortestRouteDistanceMeters,
  });

  final double requestedStartLat;
  final double requestedStartLon;
  final double requestedEndLat;
  final double requestedEndLon;
  final int graphNodeCount;
  final int graphEdgeCount;
  final int graphWayCount;
  final int componentCount;
  final int largestComponentNodeCount;
  final int startCandidateCount;
  final int endCandidateCount;
  final GeoNode? selectedStartNode;
  final GeoNode? selectedEndNode;
  final double? selectedStartDistanceMeters;
  final double? selectedEndDistanceMeters;
  final int? shortestRouteNodeCount;
  final double? shortestRouteDistanceMeters;
}

/// Gestiona el estado del grafo, la carga remota y las rutas calculadas.
class ExploreProvider extends ChangeNotifier {
  ExploreProvider({
    OverpassService? overpassService,
    OsmMapper? osmMapper,
    AStarRouter? router,
    ElevationService? elevationService,
  }) : _overpassService = overpassService ?? OverpassService(),
       _osmMapper = osmMapper ?? const OsmMapper(),
       _router = router ?? const AStarRouter(),
       _elevationService = elevationService ?? ElevationService();

  final OverpassService _overpassService;
  final OsmMapper _osmMapper;
  final AStarRouter _router;
  final ElevationService _elevationService;

  RouteProfile _selectedProfile = RouteProfile.hiking;
  bool _isLoading = false;
  String? _errorMessage;
  List<GeoNode> _nodes = const [];
  List<GeoEdge> _edges = const [];
  List<Map<String, dynamic>> _rawWays = const [];
  Map<String, dynamic>? _lastPayload;
  Map<RoutingPreference, RouteResult?> _routes = const {};
  RouteDebugInfo? _debugInfo;

  RouteProfile get selectedProfile => _selectedProfile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<GeoNode> get nodes => _nodes;
  List<GeoEdge> get edges => _edges;
  List<Map<String, dynamic>> get rawWays => _rawWays;
  Map<String, dynamic>? get lastPayload => _lastPayload;
  Map<RoutingPreference, RouteResult?> get routes => _routes;
  RouteDebugInfo? get debugInfo => _debugInfo;

  /// Actualiza el perfil activo y notifica cuando cambia el contexto de búsqueda.
  void setProfile(RouteProfile profile) {
    if (_selectedProfile == profile) return;
    _selectedProfile = profile;
    notifyListeners();
  }

  /// Descarga el grafo necesario y calcula rutas entre dos puntos dados.
  Future<void> generateRoutes({
    required double startLat,
    required double startLon,
    required double endLat,
    required double endLon,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    _routes = const {};
    _debugInfo = null;

    try {
      final straightLineDistanceMeters = _distanceBetween(
        startLat,
        startLon,
        endLat,
        endLon,
      );
      final bboxPadding = _bboxPaddingDegrees(
        startLat: startLat,
        endLat: endLat,
        distanceMeters: straightLineDistanceMeters,
      );
      final south = math.min(startLat, endLat) - bboxPadding.latitudeDelta;
      final north = math.max(startLat, endLat) + bboxPadding.latitudeDelta;
      final west = math.min(startLon, endLon) - bboxPadding.longitudeDelta;
      final east = math.max(startLon, endLon) + bboxPadding.longitudeDelta;

      final payload = await _overpassService.fetchRoutesInBoundingBox(
        south: south,
        west: west,
        north: north,
        east: east,
        profile: _selectedProfile,
      );

      final graph = _osmMapper.mapToGraph(payload, profile: _selectedProfile);
      _applyGraph(
        payload: payload,
        nodes: graph.nodes,
        edges: graph.edges,
        rawWays: graph.rawWays,
        notify: false,
      );

      final anchorResult = _selectConnectedAnchors(
        startLat: startLat,
        startLon: startLon,
        endLat: endLat,
        endLon: endLon,
      );
      final componentStats = _componentStats(_nodes, _edges);

      _debugInfo = RouteDebugInfo(
        requestedStartLat: startLat,
        requestedStartLon: startLon,
        requestedEndLat: endLat,
        requestedEndLon: endLon,
        graphNodeCount: _nodes.length,
        graphEdgeCount: _edges.length,
        graphWayCount: _rawWays.length,
        componentCount: componentStats.componentCount,
        largestComponentNodeCount: componentStats.largestComponentNodeCount,
        startCandidateCount: anchorResult.startCandidateCount,
        endCandidateCount: anchorResult.endCandidateCount,
        selectedStartNode: anchorResult.selection?.startNode,
        selectedEndNode: anchorResult.selection?.endNode,
        selectedStartDistanceMeters:
            anchorResult.selection?.startDistanceMeters,
        selectedEndDistanceMeters: anchorResult.selection?.endDistanceMeters,
        shortestRouteNodeCount:
            anchorResult.selection?.previewRoute.path.length,
        shortestRouteDistanceMeters:
            anchorResult.selection?.previewRoute.totalDistanceMeters,
      );

      if (anchorResult.selection == null) {
        _errorMessage = 'No se encontraron nodos en el area seleccionada.';
        notifyListeners();
        return;
      }
      final anchorSelection = anchorResult.selection!;
      final routeWithElevation = await _enrichRouteWithElevation(
        anchorSelection.previewRoute,
      );

      final rawResults = <RoutingPreference, RouteResult?>{
        RoutingPreference.shortest: routeWithElevation,
      };

      if (rawResults.values.every((result) => result == null)) {
        _errorMessage = 'No se pudo calcular una ruta entre los puntos.';
        return;
      }

      _routes = rawResults;
    } on OverpassException catch (error) {
      _errorMessage = error.message;
    } catch (error) {
      _errorMessage = 'Error al generar rutas: $error';
    } finally {
      _setLoading(false);
    }
  }

  /// Carga rutas manualmente dentro de un bounding box predefinido.
  Future<void> loadRoutesInBoundingBox({
    required double south,
    required double west,
    required double north,
    required double east,
    RouteProfile? profile,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final effectiveProfile = profile ?? _selectedProfile;
      final payload = await _overpassService.fetchRoutesInBoundingBox(
        south: south,
        west: west,
        north: north,
        east: east,
        profile: effectiveProfile,
      );

      _selectedProfile = effectiveProfile;
      _applyPayload(payload, effectiveProfile);
    } on OverpassException catch (error) {
      _errorMessage = error.message;
    } catch (error) {
      _errorMessage = 'No se pudieron cargar rutas desde Overpass: $error';
    } finally {
      _setLoading(false);
    }
  }

  /// Carga rutas alrededor de un punto con un radio específico.
  Future<void> loadRoutesAroundPoint({
    required double latitude,
    required double longitude,
    required int radiusMeters,
    RouteProfile? profile,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final effectiveProfile = profile ?? _selectedProfile;
      final payload = await _overpassService.fetchRoutesAroundPoint(
        latitude: latitude,
        longitude: longitude,
        radiusMeters: radiusMeters,
        profile: effectiveProfile,
      );

      _selectedProfile = effectiveProfile;
      _applyPayload(payload, effectiveProfile);
    } on OverpassException catch (error) {
      _errorMessage = error.message;
    } catch (error) {
      _errorMessage = 'No se pudieron cargar rutas desde Overpass: $error';
    } finally {
      _setLoading(false);
    }
  }

  /// Limpia el grafo y los resultados actuales para reiniciar la exploración.
  void clearData() {
    _errorMessage = null;
    _nodes = const [];
    _edges = const [];
    _rawWays = const [];
    _lastPayload = null;
    _routes = const {};
    _debugInfo = null;
    notifyListeners();
  }

  void _applyPayload(Map<String, dynamic> payload, RouteProfile profile) {
    final graph = _osmMapper.mapToGraph(payload, profile: profile);
    _applyGraph(
      payload: payload,
      nodes: graph.nodes,
      edges: graph.edges,
      rawWays: graph.rawWays,
    );
  }

  void _applyGraph({
    required Map<String, dynamic> payload,
    required List<GeoNode> nodes,
    required List<GeoEdge> edges,
    required List<Map<String, dynamic>> rawWays,
    bool notify = true,
  }) {
    _lastPayload = payload;
    _nodes = nodes;
    _edges = edges;
    _rawWays = rawWays;
    if (notify) {
      notifyListeners();
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  _AnchorSelectionResult _selectConnectedAnchors({
    required double startLat,
    required double startLon,
    required double endLat,
    required double endLon,
  }) {
    final startCandidates = _router.nearestNodes(_nodes, startLat, startLon);
    final endCandidates = _router.nearestNodes(_nodes, endLat, endLon);

    _AnchorSelection? bestSelection;
    double bestScore = double.infinity;

    for (final limit in const [3, 5, 8]) {
      final candidateScore = _bestAnchorSelection(
        startLat: startLat,
        startLon: startLon,
        endLat: endLat,
        endLon: endLon,
        startCandidates: startCandidates.take(limit).toList(growable: false),
        endCandidates: endCandidates.take(limit).toList(growable: false),
        currentBestScore: bestScore,
      );

      if (candidateScore.selection != null) {
        bestSelection = candidateScore.selection;
        bestScore = candidateScore.bestScore;
        break;
      }
    }

    return _AnchorSelectionResult(
      selection: bestSelection,
      startCandidateCount: startCandidates.length,
      endCandidateCount: endCandidates.length,
    );
  }

  _AnchorSelectionAttempt _bestAnchorSelection({
    required double startLat,
    required double startLon,
    required double endLat,
    required double endLon,
    required List<GeoNode> startCandidates,
    required List<GeoNode> endCandidates,
    required double currentBestScore,
  }) {
    _AnchorSelection? bestSelection;
    var bestScore = currentBestScore;

    for (final startCandidate in startCandidates) {
      final startDistance = _distanceBetween(
        startLat,
        startLon,
        startCandidate.latitude,
        startCandidate.longitude,
      );

      for (final endCandidate in endCandidates) {
        if (startCandidate.id == endCandidate.id) continue;

        final endDistance = _distanceBetween(
          endLat,
          endLon,
          endCandidate.latitude,
          endCandidate.longitude,
        );
        final anchorScore = startDistance + endDistance;
        if (anchorScore >= bestScore) continue;

        final previewRoute = _router.findRoute(
          nodes: _nodes,
          edges: _edges,
          startId: startCandidate.id,
          goalId: endCandidate.id,
          profile: _selectedProfile,
          preference: RoutingPreference.shortest,
        );
        if (previewRoute == null || previewRoute.isEmpty) continue;

        bestScore = anchorScore;
        bestSelection = _AnchorSelection(
          startNode: startCandidate,
          endNode: endCandidate,
          previewRoute: previewRoute,
          startDistanceMeters: startDistance,
          endDistanceMeters: endDistance,
        );
      }
    }

    return _AnchorSelectionAttempt(
      selection: bestSelection,
      bestScore: bestScore,
    );
  }

  Future<RouteResult> _enrichRouteWithElevation(RouteResult route) async {
    if (route.path.isEmpty) return route;
    final enrichedPath = await _elevationService.enrichWithElevation(
      route.path,
    );
    return route.withElevation(enrichedPath);
  }

  _BboxPadding _bboxPaddingDegrees({
    required double startLat,
    required double endLat,
    required double distanceMeters,
  }) {
    final paddingMeters = math.max(
      350.0,
      math.min(3000.0, distanceMeters * 0.18),
    );
    final referenceLat = (startLat + endLat) / 2;
    final latitudeDelta = paddingMeters / 111320.0;
    final cosLat = math.cos(_degreesToRadians(referenceLat)).abs();
    final longitudeDelta = paddingMeters / (111320.0 * math.max(cosLat, 0.2));

    return _BboxPadding(
      latitudeDelta: latitudeDelta,
      longitudeDelta: longitudeDelta,
    );
  }

  double _distanceBetween(double lat1, double lon1, double lat2, double lon2) {
    const radius = 6371000.0;
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return radius * c;
  }

  double _degreesToRadians(double degrees) => degrees * math.pi / 180;
}

class _AnchorSelectionResult {
  const _AnchorSelectionResult({
    required this.selection,
    required this.startCandidateCount,
    required this.endCandidateCount,
  });

  final _AnchorSelection? selection;
  final int startCandidateCount;
  final int endCandidateCount;
}

class _AnchorSelectionAttempt {
  const _AnchorSelectionAttempt({
    required this.selection,
    required this.bestScore,
  });

  final _AnchorSelection? selection;
  final double bestScore;
}

class _BboxPadding {
  const _BboxPadding({
    required this.latitudeDelta,
    required this.longitudeDelta,
  });

  final double latitudeDelta;
  final double longitudeDelta;
}

class _ComponentStats {
  const _ComponentStats({
    required this.componentCount,
    required this.largestComponentNodeCount,
  });

  final int componentCount;
  final int largestComponentNodeCount;
}

extension on ExploreProvider {
  _ComponentStats _componentStats(List<GeoNode> nodes, List<GeoEdge> edges) {
    if (nodes.isEmpty) {
      return const _ComponentStats(
        componentCount: 0,
        largestComponentNodeCount: 0,
      );
    }

    final adjacency = <int, Set<int>>{};
    for (final node in nodes) {
      adjacency[node.id] = <int>{};
    }
    for (final edge in edges) {
      adjacency.putIfAbsent(edge.fromNodeId, () => <int>{}).add(edge.toNodeId);
      adjacency.putIfAbsent(edge.toNodeId, () => <int>{}).add(edge.fromNodeId);
    }

    final visited = <int>{};
    var componentCount = 0;
    var largestComponentNodeCount = 0;

    for (final node in nodes) {
      if (visited.contains(node.id)) continue;
      componentCount++;
      var componentSize = 0;
      final stack = <int>[node.id];

      while (stack.isNotEmpty) {
        final current = stack.removeLast();
        if (!visited.add(current)) continue;
        componentSize++;
        for (final neighbor in adjacency[current] ?? const <int>{}) {
          if (!visited.contains(neighbor)) {
            stack.add(neighbor);
          }
        }
      }

      if (componentSize > largestComponentNodeCount) {
        largestComponentNodeCount = componentSize;
      }
    }

    return _ComponentStats(
      componentCount: componentCount,
      largestComponentNodeCount: largestComponentNodeCount,
    );
  }
}
