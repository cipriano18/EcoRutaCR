import 'package:ecoruta/models/geo_edge.dart';
import 'package:ecoruta/models/route_profile.dart';
import 'package:ecoruta/providers/explore_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

/// Herramienta visual para inspeccionar el grafo y respuestas de Overpass.
class OverpassTestScreen extends StatefulWidget {
  const OverpassTestScreen({super.key});

  @override
  State<OverpassTestScreen> createState() => _OverpassTestScreenState();
}

class _OverpassTestScreenState extends State<OverpassTestScreen> {
  static const _primaryColor = Color(0xFF012D1D);
  static const _primaryFixed = Color(0xFFC1ECD4);
  static const _surfaceHigh = Color(0xFFE7E8E9);
  static const _surfaceLow = Color(0xFFF3F4F5);

  final _startLatController = TextEditingController(text: '9.9281');
  final _startLngController = TextEditingController(text: '-84.0907');
  final _endLatController = TextEditingController(text: '10.1985');
  final _endLngController = TextEditingController(text: '-84.2337');

  RouteProfile _selectedProfile = RouteProfile.hiking;

  @override
  void dispose() {
    _startLatController.dispose();
    _startLngController.dispose();
    _endLatController.dispose();
    _endLngController.dispose();
    super.dispose();
  }

  /// Ejecuta una prueba completa de descarga y construcción del grafo.
  Future<void> _runOverpassTest() async {
    final startLat = double.tryParse(_startLatController.text.trim());
    final startLng = double.tryParse(_startLngController.text.trim());
    final endLat = double.tryParse(_endLatController.text.trim());
    final endLng = double.tryParse(_endLngController.text.trim());

    if (startLat == null ||
        startLng == null ||
        endLat == null ||
        endLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa coordenadas válidas para inicio y destino.'),
        ),
      );
      return;
    }

    final provider = context.read<ExploreProvider>();
    provider.setProfile(_selectedProfile);
    await provider.generateRoutes(
      startLat: startLat,
      startLon: startLng,
      endLat: endLat,
      endLon: endLng,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ExploreProvider>(
      builder: (context, exploreProvider, _) {
        final startPoint = LatLng(
          double.tryParse(_startLatController.text.trim()) ?? 9.9281,
          double.tryParse(_startLngController.text.trim()) ?? -84.0907,
        );
        final endPoint = LatLng(
          double.tryParse(_endLatController.text.trim()) ?? 10.1985,
          double.tryParse(_endLngController.text.trim()) ?? -84.2337,
        );

        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FA),
          appBar: AppBar(
            backgroundColor: const Color(0xFFF8F9FA),
            title: const Text(
              'Test Visual Overpass',
              style: TextStyle(
                color: _primaryColor,
                fontWeight: FontWeight.w800,
              ),
            ),
            iconTheme: const IconThemeData(color: _primaryColor),
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildControlsCard(),
              const SizedBox(height: 20),
              _MapPreviewCard(
                startPoint: startPoint,
                endPoint: endPoint,
                edges: exploreProvider.edges,
              ),
              const SizedBox(height: 20),
              _buildSummaryCard(exploreProvider),
              const SizedBox(height: 20),
              _buildDiagnosticsCard(exploreProvider),
              const SizedBox(height: 20),
              _buildWaysList(exploreProvider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildControlsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Configurar consulta',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: _primaryColor,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Esto consulta Overpass dentro del bounding box formado entre inicio y destino.',
            style: TextStyle(fontSize: 13, color: Colors.grey, height: 1.4),
          ),
          const SizedBox(height: 18),
          DropdownButtonFormField<RouteProfile>(
            initialValue: _selectedProfile,
            decoration: _inputDecoration('Perfil'),
            items: const [
              DropdownMenuItem(
                value: RouteProfile.hiking,
                child: Text('Senderismo'),
              ),
              DropdownMenuItem(
                value: RouteProfile.cycling,
                child: Text('Ciclismo'),
              ),
              DropdownMenuItem(
                value: RouteProfile.running,
                child: Text('Running'),
              ),
            ],
            onChanged: (value) {
              if (value == null) {
                return;
              }
              setState(() => _selectedProfile = value);
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _startLatController,
                  keyboardType: const TextInputType.numberWithOptions(
                    signed: true,
                    decimal: true,
                  ),
                  decoration: _inputDecoration('Inicio lat'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _startLngController,
                  keyboardType: const TextInputType.numberWithOptions(
                    signed: true,
                    decimal: true,
                  ),
                  decoration: _inputDecoration('Inicio lng'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _endLatController,
                  keyboardType: const TextInputType.numberWithOptions(
                    signed: true,
                    decimal: true,
                  ),
                  decoration: _inputDecoration('Destino lat'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _endLngController,
                  keyboardType: const TextInputType.numberWithOptions(
                    signed: true,
                    decimal: true,
                  ),
                  decoration: _inputDecoration('Destino lng'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _runOverpassTest,
              style: FilledButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text(
                'Consultar Overpass',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(ExploreProvider exploreProvider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _surfaceHigh),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resumen del resultado',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: _primaryColor,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _StatChip(
                label: 'Perfil',
                value: exploreProvider.selectedProfile.label,
                backgroundColor: _primaryFixed,
                foregroundColor: _primaryColor,
              ),
              _StatChip(
                label: 'Nodos',
                value: '${exploreProvider.nodes.length}',
                backgroundColor: _surfaceLow,
                foregroundColor: _primaryColor,
              ),
              _StatChip(
                label: 'Aristas',
                value: '${exploreProvider.edges.length}',
                backgroundColor: _surfaceLow,
                foregroundColor: _primaryColor,
              ),
              _StatChip(
                label: 'Ways',
                value: '${exploreProvider.rawWays.length}',
                backgroundColor: _surfaceLow,
                foregroundColor: _primaryColor,
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (exploreProvider.isLoading)
            const Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.2),
                ),
                SizedBox(width: 10),
                Text('Consultando...'),
              ],
            )
          else if (exploreProvider.errorMessage != null)
            Text(
              exploreProvider.errorMessage!,
              style: const TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.w600,
              ),
            )
          else
            Text(
              exploreProvider.rawWays.isEmpty
                  ? 'Todavía no hay datos cargados.'
                  : 'Consulta exitosa. Ya puedes inspeccionar geometrías y ways devueltos.',
              style: const TextStyle(
                fontSize: 13,
                color: Colors.grey,
                height: 1.45,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWaysList(ExploreProvider exploreProvider) {
    final previewWays = exploreProvider.rawWays.take(8).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _surfaceHigh),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Preview de ways filtrados',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: _primaryColor,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Se muestran los primeros resultados crudos útiles para validar si el filtro está trayendo senderos o rutas ciclables reales.',
            style: TextStyle(fontSize: 13, color: Colors.grey, height: 1.4),
          ),
          const SizedBox(height: 16),
          if (previewWays.isEmpty)
            const Text(
              'Aún no hay ways para mostrar.',
              style: TextStyle(color: Colors.grey),
            )
          else
            ...previewWays.map((way) {
              final tags =
                  (way['tags'] as Map?)?.map(
                    (key, value) => MapEntry(key.toString(), value.toString()),
                  ) ??
                  <String, String>{};

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _surfaceLow,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tags['name'] ?? 'Way ${way['id']}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: _primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _MiniTag(label: 'highway', value: tags['highway']),
                        _MiniTag(label: 'route', value: tags['route']),
                        _MiniTag(label: 'bicycle', value: tags['bicycle']),
                        _MiniTag(label: 'foot', value: tags['foot']),
                        _MiniTag(label: 'surface', value: tags['surface']),
                      ],
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildDiagnosticsCard(ExploreProvider exploreProvider) {
    final debugInfo = exploreProvider.debugInfo;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _surfaceHigh),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Diagnostico de nodos',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: _primaryColor,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Muestra que nodos candidatos encontro cerca del inicio y destino, y cuales eligio para rutear.',
            style: TextStyle(fontSize: 13, color: Colors.grey, height: 1.4),
          ),
          const SizedBox(height: 16),
          if (debugInfo == null)
            const Text(
              'Ejecuta una consulta para ver el diagnostico del anclaje al grafo.',
              style: TextStyle(color: Colors.grey),
            )
          else ...[
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _StatChip(
                  label: 'Cand. inicio',
                  value: '${debugInfo.startCandidateCount}',
                  backgroundColor: _surfaceLow,
                  foregroundColor: _primaryColor,
                ),
                _StatChip(
                  label: 'Cand. destino',
                  value: '${debugInfo.endCandidateCount}',
                  backgroundColor: _surfaceLow,
                  foregroundColor: _primaryColor,
                ),
                _StatChip(
                  label: 'Ruta base',
                  value: debugInfo.shortestRouteNodeCount == null
                      ? 'sin ruta'
                      : '${debugInfo.shortestRouteNodeCount} nodos',
                  backgroundColor: _primaryFixed,
                  foregroundColor: _primaryColor,
                ),
                _StatChip(
                  label: 'Componentes',
                  value: '${debugInfo.componentCount}',
                  backgroundColor: _surfaceLow,
                  foregroundColor: _primaryColor,
                ),
                _StatChip(
                  label: 'Mayor componente',
                  value: '${debugInfo.largestComponentNodeCount} nodos',
                  backgroundColor: _surfaceLow,
                  foregroundColor: _primaryColor,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _DebugLine(
              label: 'Inicio solicitado',
              value:
                  '${debugInfo.requestedStartLat.toStringAsFixed(5)}, ${debugInfo.requestedStartLon.toStringAsFixed(5)}',
            ),
            _DebugLine(
              label: 'Destino solicitado',
              value:
                  '${debugInfo.requestedEndLat.toStringAsFixed(5)}, ${debugInfo.requestedEndLon.toStringAsFixed(5)}',
            ),
            _DebugLine(
              label: 'Ways utiles',
              value: '${debugInfo.graphWayCount}',
            ),
            _DebugLine(
              label: 'Nodos del grafo',
              value: '${debugInfo.graphNodeCount}',
            ),
            _DebugLine(
              label: 'Aristas del grafo',
              value: '${debugInfo.graphEdgeCount}',
            ),
            _DebugLine(
              label: 'Nodo inicio elegido',
              value: _nodeLabel(debugInfo.selectedStartNode),
            ),
            _DebugLine(
              label: 'Nodo destino elegido',
              value: _nodeLabel(debugInfo.selectedEndNode),
            ),
            _DebugLine(
              label: 'Distancia al inicio',
              value: debugInfo.selectedStartDistanceMeters == null
                  ? 'sin dato'
                  : '${debugInfo.selectedStartDistanceMeters!.round()} m',
            ),
            _DebugLine(
              label: 'Distancia al destino',
              value: debugInfo.selectedEndDistanceMeters == null
                  ? 'sin dato'
                  : '${debugInfo.selectedEndDistanceMeters!.round()} m',
            ),
            _DebugLine(
              label: 'Distancia de ruta corta',
              value: debugInfo.shortestRouteDistanceMeters == null
                  ? 'sin ruta'
                  : '${debugInfo.shortestRouteDistanceMeters!.round()} m',
            ),
          ],
        ],
      ),
    );
  }

  String _nodeLabel(dynamic node) {
    if (node == null) return 'sin nodo';
    return '#${node.id} (${node.latitude.toStringAsFixed(5)}, ${node.longitude.toStringAsFixed(5)})';
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: _surfaceLow,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}

/// Fila compacta para mostrar datos de diagnóstico clave-valor.
class _DebugLine extends StatelessWidget {
  const _DebugLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: Colors.grey,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF012D1D),
            ),
          ),
        ],
      ),
    );
  }
}

/// Vista rápida del grafo y la ruta calculada sobre el mapa.
class _MapPreviewCard extends StatelessWidget {
  const _MapPreviewCard({
    required this.startPoint,
    required this.endPoint,
    required this.edges,
  });

  static const _primaryColor = Color(0xFF012D1D);
  static const _orangeColor = Color(0xFFFF7043);

  final LatLng startPoint;
  final LatLng endPoint;
  final List<GeoEdge> edges;

  @override
  Widget build(BuildContext context) {
    final center = LatLng(
      (startPoint.latitude + endPoint.latitude) / 2,
      (startPoint.longitude + endPoint.longitude) / 2,
    );

    return Container(
      height: 340,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          FlutterMap(
            options: MapOptions(initialCenter: center, initialZoom: 10.5),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.lab2_moviles',
              ),
              PolylineLayer(
                polylines: [
                  ...edges.map(
                    (edge) => Polyline(
                      points: edge.geometry
                          .map((node) => LatLng(node.latitude, node.longitude))
                          .toList(growable: false),
                      color: _primaryColor.withValues(alpha: 0.7),
                      strokeWidth: 3,
                    ),
                  ),
                  Polyline(
                    points: [startPoint, endPoint],
                    color: _orangeColor,
                    strokeWidth: 3,
                    pattern: StrokePattern.dashed(segments: const [8, 8]),
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: startPoint,
                    width: 44,
                    height: 44,
                    child: const _PointMarker(
                      icon: Icons.play_arrow_rounded,
                      color: _primaryColor,
                    ),
                  ),
                  Marker(
                    point: endPoint,
                    width: 44,
                    height: 44,
                    child: const _PointMarker(
                      icon: Icons.flag_rounded,
                      color: _orangeColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            left: 16,
            top: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Segmentos cargados: ${edges.length}',
                style: const TextStyle(
                  color: _primaryColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Marcador simple usado en el mapa de pruebas.
class _PointMarker extends StatelessWidget {
  const _PointMarker({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.22),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 18),
    );
  }
}

/// Chip visual para estadísticas resumidas del grafo.
class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final String label;
  final String value;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: foregroundColor.withValues(alpha: 0.7),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: foregroundColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// Etiqueta compacta para representar tags de OSM.
class _MiniTag extends StatelessWidget {
  const _MiniTag({required this.label, required this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    if (value == null || value!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        '$label=$value',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Color(0xFF012D1D),
        ),
      ),
    );
  }
}
