import 'dart:math' as math;
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../shared/sponsor_map_canvas.dart';

bool _isDarkMode(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark;

Color _pageBackground(BuildContext context) =>
    _isDarkMode(context) ? const Color(0xFF041710) : const Color(0xFFF8F9FA);

Color _chromeSurface(BuildContext context) =>
    _isDarkMode(context) ? const Color(0xFF0B261D) : Colors.white;

Color _panelSurface(BuildContext context) =>
    _isDarkMode(context) ? const Color(0xFF132F25) : const Color(0xFFF8F9FA);

Color _panelBorder(BuildContext context) =>
    _isDarkMode(context) ? const Color(0xFF1B4332) : const Color(0xFFE7E8E9);

Future<LatLng?> showSponsorLocationPickerDialog(
  BuildContext context, {
  double? initialLatitude,
  double? initialLongitude,
}) {
  final screenSize = MediaQuery.sizeOf(context);
  final inset = screenSize.width < 960 ? 12.0 : 28.0;
  final dialogWidth = math.min(screenSize.width - (inset * 2), 1180.0);
  final dialogHeight = math.min(screenSize.height - (inset * 2), 820.0);

  return showDialog<LatLng>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => Dialog(
      insetPadding: EdgeInsets.all(inset),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: dialogWidth,
        height: dialogHeight,
        child: SponsorLocationPickerView(
          initialLatitude: initialLatitude,
          initialLongitude: initialLongitude,
          mode: SponsorLocationPickerMode.dialog,
        ),
      ),
    ),
  );
}

enum SponsorLocationPickerMode { page, dialog, embedded }

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

class SponsorLocationPickerView extends StatefulWidget {
  const SponsorLocationPickerView({
    this.initialLatitude,
    this.initialLongitude,
    this.mode = SponsorLocationPickerMode.page,
    this.onPointApplied,
    this.onCloseRequested,
    super.key,
  });

  final double? initialLatitude;
  final double? initialLongitude;
  final SponsorLocationPickerMode mode;
  final ValueChanged<LatLng>? onPointApplied;
  final VoidCallback? onCloseRequested;

  @override
  State<SponsorLocationPickerView> createState() =>
      _SponsorLocationPickerViewState();
}

class _SponsorLocationPickerPageState extends State<SponsorLocationPickerPage> {
  @override
  Widget build(BuildContext context) => SponsorLocationPickerView(
    initialLatitude: widget.initialLatitude,
    initialLongitude: widget.initialLongitude,
    mode: SponsorLocationPickerMode.page,
  );
}

class _SponsorLocationPickerViewState extends State<SponsorLocationPickerView> {
  static const LatLng defaultCenter = LatLng(9.7489, -83.7534);
  final _searchController = TextEditingController();
  final MapController _mapController = MapController();
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
    final content = Padding(
      padding: const EdgeInsets.all(20),
      child: _buildResponsiveBody(),
    );

    if (widget.mode == SponsorLocationPickerMode.dialog) {
      return ColoredBox(
        color: _pageBackground(context),
        child: Column(
          children: [
            _PickerHeader(onClose: _handleClose, onApply: _handleApply),
            Expanded(child: content),
          ],
        ),
      );
    }

    if (widget.mode == SponsorLocationPickerMode.embedded) {
      return Container(
        decoration: BoxDecoration(
          color: _pageBackground(context),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _panelBorder(context)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            _PickerHeader(
              compact: true,
              onClose: _handleClose,
              onApply: _handleApply,
            ),
            Expanded(child: content),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: _pageBackground(context),
      appBar: _PickerHeader(onClose: _handleClose, onApply: _handleApply),
      body: content,
    );
  }

  void _handleApply() {
    if (widget.onPointApplied != null) {
      widget.onPointApplied!(_selectedPoint);
      return;
    }
    Navigator.of(context).pop(_selectedPoint);
  }

  void _handleClose() {
    if (widget.onCloseRequested != null) {
      widget.onCloseRequested!();
      return;
    }
    Navigator.of(context).pop();
  }

  Widget _buildResponsiveBody() {
    return LayoutBuilder(
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
      if (response.statusCode != 200) throw Exception('Busqueda no disponible');
      final decoded = jsonDecode(response.body);
      if (decoded is! List) throw Exception('Respuesta invalida');
      final results = decoded
          .map((item) => _LocationSearchResult.fromMap(item))
          .whereType<_LocationSearchResult>()
          .toList();
      setState(() {
        _results = results;
        if (results.isEmpty) {
          _searchError = 'No encontramos resultados para esa busqueda.';
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

class _PickerHeader extends StatelessWidget implements PreferredSizeWidget {
  const _PickerHeader({
    required this.onClose,
    required this.onApply,
    this.compact = false,
  });

  final VoidCallback onClose;
  final VoidCallback onApply;
  final bool compact;

  @override
  Size get preferredSize => Size.fromHeight(compact ? 64 : 76);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _chromeSurface(context),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: compact ? 64 : 76,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                const Expanded(
                  child: Text(
                    'Seleccionar ubicacion',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                ),
                FilledButton.icon(
                  onPressed: onApply,
                  icon: const Icon(Icons.check_circle_outline_rounded),
                  label: const Text('Aplicar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
  Widget build(BuildContext context) => Column(
    children: [
      Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Buscar lugar, direccion o negocio',
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

class _ResultsPanel extends StatelessWidget {
  const _ResultsPanel({required this.results, required this.onSelect});
  final List<_LocationSearchResult> results;
  final ValueChanged<_LocationSearchResult> onSelect;
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _panelSurface(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _panelBorder(context)),
      ),
      child: results.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Busca un lugar o toca el mapa para elegir la ubicacion.',
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
                      color: _chromeSurface(context),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: _panelBorder(context)),
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
  Widget build(BuildContext context) => SponsorMapCanvas(
    mapController: mapController,
    center: mapCenter,
    selectedPoint: selectedPoint,
    onTap: onTap,
  );
}

class _SelectedLocationBar extends StatelessWidget {
  const _SelectedLocationBar({
    required this.selectedPoint,
    required this.onReset,
  });
  final LatLng selectedPoint;
  final VoidCallback onReset;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: _panelSurface(context),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: _panelBorder(context)),
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
    if (map is! Map<String, dynamic>) return null;
    final lat = double.tryParse('${map['lat'] ?? ''}');
    final lon = double.tryParse('${map['lon'] ?? ''}');
    final displayName = '${map['display_name'] ?? ''}'.trim();
    if (lat == null || lon == null || displayName.isEmpty) return null;
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
