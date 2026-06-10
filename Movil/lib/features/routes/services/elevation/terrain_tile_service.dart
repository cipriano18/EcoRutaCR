import 'dart:math' as math;

import 'package:ecoruta/features/routes/models/geo_node.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

/// Obtiene elevación desde AWS Terrain Tiles (Terrarium format).
///
/// Una ruta típica en Costa Rica cubre 1–4 tiles a zoom 13.
/// Sin rate limit, sin API key. Cada tile es ~30KB (256×256 PNG).
class TerrainTileService {
  TerrainTileService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  final _tileCache = <String, img.Image?>{};

  static const _zoom = 13;
  static const _tileSize = 256;
  static const _baseUrl =
      'https://s3.amazonaws.com/elevation-tiles-prod/terrarium';

  /// Enriquece [nodes] con elevación usando tiles que cubren el bbox dado.
  Future<List<GeoNode>> enrichWithElevation(
    List<GeoNode> nodes, {
    required double south,
    required double west,
    required double north,
    required double east,
  }) async {
    if (nodes.isEmpty) return nodes;

    await _prefetchTiles(south, west, north, east);

    return nodes.map((node) {
      final elevation = _elevationAt(node.latitude, node.longitude);
      if (elevation == null) return node;
      return GeoNode(
        id: node.id,
        latitude: node.latitude,
        longitude: node.longitude,
        elevation: elevation,
        tags: node.tags,
      );
    }).toList();
  }

  Future<void> _prefetchTiles(
    double south,
    double west,
    double north,
    double east,
  ) async {
    final xMin = _lonToTileX(west, _zoom);
    final xMax = _lonToTileX(east, _zoom);
    final yMin = _latToTileY(north, _zoom);
    final yMax = _latToTileY(south, _zoom);

    final futures = <Future<void>>[];
    for (var x = xMin; x <= xMax; x++) {
      for (var y = yMin; y <= yMax; y++) {
        final key = '$_zoom/$x/$y';
        if (!_tileCache.containsKey(key)) {
          // La caché almacena también fallos como null para no reintentar el
          // mismo tile durante una misma operación.
          futures.add(_downloadAndCache(x, y, key));
        }
      }
    }
    await Future.wait(futures);
  }

  /// Descarga un tile Terrarium y lo guarda decodificado en memoria.
  Future<void> _downloadAndCache(int x, int y, String key) async {
    final url = '$_baseUrl/$_zoom/$x/$y.png';
    try {
      final response = await _client
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        debugPrint('[TerrainTile] HTTP ${response.statusCode} para $key');
        _tileCache[key] = null;
        return;
      }
      _tileCache[key] = img.decodePng(response.bodyBytes);
    } catch (e) {
      debugPrint('[TerrainTile] Error descargando $key: $e');
      _tileCache[key] = null;
    }
  }

  /// Interpola la elevación del píxel Terrarium correspondiente a la coordenada.
  double? _elevationAt(double lat, double lon) {
    final x = _lonToTileX(lon, _zoom);
    final y = _latToTileY(lat, _zoom);
    final key = '$_zoom/$x/$y';
    final image = _tileCache[key];
    if (image == null) return null;

    final bounds = _tileBounds(x, y, _zoom);
    final px = ((lon - bounds.west) / (bounds.east - bounds.west) * _tileSize)
        .floor()
        .clamp(0, _tileSize - 1);
    final py =
        ((bounds.north - lat) / (bounds.north - bounds.south) * _tileSize)
            .floor()
            .clamp(0, _tileSize - 1);

    final pixel = image.getPixel(px, py);
    final r = pixel.r.toDouble();
    final g = pixel.g.toDouble();
    final b = pixel.b.toDouble();
    return r * 256.0 + g + b / 256.0 - 32768.0;
  }

  /// Convierte longitud a coordenada X de tile Web Mercator.
  int _lonToTileX(double lon, int z) =>
      ((lon + 180.0) / 360.0 * math.pow(2, z)).floor();

  /// Convierte latitud a coordenada Y de tile Web Mercator.
  int _latToTileY(double lat, int z) {
    final latRad = lat * math.pi / 180.0;
    return ((1.0 -
                math.log(math.tan(latRad) + 1.0 / math.cos(latRad)) / math.pi) /
            2.0 *
            math.pow(2, z))
        .floor();
  }

  /// Calcula los límites geográficos de un tile Web Mercator.
  _TileBounds _tileBounds(int x, int y, int z) {
    final n = math.pow(2, z).toDouble();
    final west = x / n * 360.0 - 180.0;
    final east = (x + 1) / n * 360.0 - 180.0;
    final north =
        math.atan(_sinh(math.pi * (1.0 - 2.0 * y / n))) * 180.0 / math.pi;
    final south =
        math.atan(_sinh(math.pi * (1.0 - 2.0 * (y + 1) / n))) * 180.0 / math.pi;
    return _TileBounds(north: north, south: south, west: west, east: east);
  }

  double _sinh(double x) => (math.exp(x) - math.exp(-x)) / 2.0;
}

/// Límites geográficos de un tile descargado.
class _TileBounds {
  const _TileBounds({
    required this.north,
    required this.south,
    required this.west,
    required this.east,
  });
  final double north, south, west, east;
}
