import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class SponsorLocationPickerPage extends StatefulWidget {
  const SponsorLocationPickerPage({
    this.initialLatitude,
    this.initialLongitude,
    super.key,
  });

  final double? initialLatitude;
  final double? initialLongitude;

  @override
  State<SponsorLocationPickerPage> createState() =>
      _SponsorLocationPickerPageState();
}

class _SponsorLocationPickerPageState extends State<SponsorLocationPickerPage> {
  static const LatLng defaultCenter = LatLng(9.7489, -83.7534);

  final _searchController = TextEditingController();
  final _mapController = MapController();

  bool _isSearching = false;
  String? _searchError;
  List<_LocationSearchResult> _results = const [];

  late LatLng _selectedPoint;
  late LatLng _mapCenter;

  @override
  void initState() {
    super.initState();
    final existingPoint = _currentPointFromWidget();
    _selectedPoint = existingPoint ?? defaultCenter;
    _mapCenter = existingPoint ?? defaultCenter;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('Seleccionar ubicación'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.icon(
              onPressed: () => Navigator.of(context).pop(_selectedPoint),
              icon: const Icon(Icons.check_circle_outline_rounded),
              label: const Text('Aplicar'),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 980;

            if (isCompact) {
              return Column(
                children: [
                  _SearchToolbar(
                    controller: _searchController,
                    isSearching: _isSearching,
                    searchError: _searchError,
                    onSearch: _searchLocations,
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _MapPanel(
                      mapController: _mapController,
                      selectedPoint: _selectedPoint,
                      mapCenter: _mapCenter,
                      onTap: _selectPointFromMap,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 180,
                    child: _ResultsPanel(
                      results: _results,
                      onSelect: _selectSearchResult,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SelectedLocationBar(
                    selectedPoint: _selectedPoint,
                    onReset: _resetSelection,
                  ),
                ],
              );
            }

            return Column(
              children: [
                _SearchToolbar(
                  controller: _searchController,
                  isSearching: _isSearching,
                  searchError: _searchError,
                  onSearch: _searchLocations,
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Row(
                    children: [
                      SizedBox(
                        width: 320,
                        child: _ResultsPanel(
                          results: _results,
                          onSelect: _selectSearchResult,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _MapPanel(
                          mapController: _mapController,
                          selectedPoint: _selectedPoint,
                          mapCenter: _mapCenter,
                          onTap: _selectPointFromMap,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SelectedLocationBar(
                  selectedPoint: _selectedPoint,
                  onReset: _resetSelection,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  LatLng? _currentPointFromWidget() {
    if (widget.initialLatitude == null || widget.initialLongitude == null) {
      return null;
    }
    return LatLng(widget.initialLatitude!, widget.initialLongitude!);
  }

  void _selectPointFromMap(LatLng point) {
    setState(() {
      _selectedPoint = point;
      _mapCenter = point;
    });
  }

  void _resetSelection() {
    setState(() {
      _selectedPoint = defaultCenter;
      _mapCenter = defaultCenter;
    });
    _mapController.move(defaultCenter, 7);
  }

  Future<void> _searchLocations() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _searchError = 'Escribe algo para buscar en el mapa.';
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _searchError = null;
    });

    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'q': query,
        'format': 'jsonv2',
        'limit': '6',
      });

      final response = await http.get(
        uri,
        headers: const {'Accept': 'application/json'},
      );

      if (response.statusCode != 200) {
        throw Exception('Búsqueda no disponible');
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! List) {
        throw Exception('Respuesta invalida');
      }

      final results = decoded
          .map((item) => _LocationSearchResult.fromMap(item))
          .whereType<_LocationSearchResult>()
          .toList();

      setState(() {
        _results = results;
        if (results.isEmpty) {
          _searchError = 'No encontramos resultados para esa búsqueda.';
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _searchError =
            'No se pudo buscar ahora mismo. Igual puedes tocar el mapa manualmente.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  void _selectSearchResult(_LocationSearchResult result) {
    final point = LatLng(result.latitude, result.longitude);
    setState(() {
      _selectedPoint = point;
      _mapCenter = point;
    });
    _mapController.move(point, 16);
  }
}

class _SearchToolbar extends StatelessWidget {
  const _SearchToolbar({
    required this.controller,
    required this.isSearching,
    required this.searchError,
    required this.onSearch,
  });

  final TextEditingController controller;
  final bool isSearching;
  final String? searchError;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: 'Buscar lugar, dirección o negocio',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
                onSubmitted: (_) => onSearch(),
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: isSearching ? null : onSearch,
              icon: const Icon(Icons.travel_explore_rounded),
              label: Text(isSearching ? 'Buscando...' : 'Buscar'),
            ),
          ],
        ),
        if (searchError != null) ...[
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              searchError!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFFE57373),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ResultsPanel extends StatelessWidget {
  const _ResultsPanel({required this.results, required this.onSelect});

  final List<_LocationSearchResult> results;
  final ValueChanged<_LocationSearchResult> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE7E8E9)),
      ),
      child: results.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Busca un lugar o toca el mapa para elegir la ubicación.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: results.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final result = results[index];
                return InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => onSelect(result),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE7E8E9)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          result.title,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          result.subtitle,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _MapPanel extends StatelessWidget {
  const _MapPanel({
    required this.mapController,
    required this.selectedPoint,
    required this.mapCenter,
    required this.onTap,
  });

  final MapController mapController;
  final LatLng selectedPoint;
  final LatLng mapCenter;
  final ValueChanged<LatLng> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE7E8E9)),
      ),
      clipBehavior: Clip.antiAlias,
      child: FlutterMap(
        mapController: mapController,
        options: MapOptions(
          initialCenter: mapCenter,
          initialZoom: 13,
          onTap: (tapPosition, point) => onTap(point),
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.ecoruta.admin.web',
          ),
          MarkerLayer(
            markers: [
              Marker(
                width: 54,
                height: 54,
                point: selectedPoint,
                child: const Icon(
                  Icons.location_on_rounded,
                  size: 46,
                  color: Color(0xFFFF7043),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SelectedLocationBar extends StatelessWidget {
  const _SelectedLocationBar({
    required this.selectedPoint,
    required this.onReset,
  });

  final LatLng selectedPoint;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F4F2),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Latitud: ${selectedPoint.latitude.toStringAsFixed(6)}   Longitud: ${selectedPoint.longitude.toStringAsFixed(6)}',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton(onPressed: onReset, child: const Text('Reiniciar')),
        ],
      ),
    );
  }
}

class _LocationSearchResult {
  const _LocationSearchResult({
    required this.title,
    required this.subtitle,
    required this.latitude,
    required this.longitude,
  });

  final String title;
  final String subtitle;
  final double latitude;
  final double longitude;

  static _LocationSearchResult? fromMap(dynamic map) {
    if (map is! Map<String, dynamic>) {
      return null;
    }

    final lat = double.tryParse('${map['lat'] ?? ''}');
    final lon = double.tryParse('${map['lon'] ?? ''}');
    final displayName = '${map['display_name'] ?? ''}'.trim();

    if (lat == null || lon == null || displayName.isEmpty) {
      return null;
    }

    final chunks = displayName
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();

    return _LocationSearchResult(
      title: chunks.isNotEmpty ? chunks.first : displayName,
      subtitle: chunks.length > 1 ? chunks.skip(1).join(', ') : displayName,
      latitude: lat,
      longitude: lon,
    );
  }
}
