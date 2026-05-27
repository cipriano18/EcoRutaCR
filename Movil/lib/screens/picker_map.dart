import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:ecoruta/widgets/suggestion_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Define si el selector trabaja con dos puntos o solo con destino.
enum PointSelectionMode { dualPoint, singleDestination }

/// Pantalla para elegir puntos directamente sobre el mapa.
class PickerMapScreen extends StatefulWidget {
  const PickerMapScreen({
    super.key,
    required this.initialStartPoint,
    required this.initialDestinationPoint,
    required this.currentLocation,
    this.mode = PointSelectionMode.dualPoint,
  });

  final LatLng? initialStartPoint;
  final LatLng? initialDestinationPoint;
  final LatLng? currentLocation;
  final PointSelectionMode mode;

  @override
  State<PickerMapScreen> createState() => _PickerMapScreenState();
}

class _PickerMapScreenState extends State<PickerMapScreen>
    with SingleTickerProviderStateMixin {
  static const _primaryColor = Color(0xFF012D1D);
  static const _surfaceColor = Color(0xFFF8F9FA);
  static const _fallbackCenter = LatLng(9.9281, -84.0907);
  static const _nominatimUserAgent = 'EcoRutaCR/1.0';

  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  AnimationController? _cameraAnimationController;

  Timer? _debounce;
  List<_PlaceSuggestion> _suggestions = [];
  bool _isSearching = false;
  _SelectionTarget _activeTarget = _SelectionTarget.destination;

  late LatLng? _selectedStartPoint;
  late LatLng? _selectedDestinationPoint;
  String _startLabel = 'Ubicacion actual no disponible';
  String _destinationLabel = 'Pendiente de seleccionar';

  bool get _showsDualPoint => widget.mode == PointSelectionMode.dualPoint;

  @override
  void initState() {
    super.initState();
    _selectedStartPoint = _showsDualPoint
        ? widget.initialStartPoint ?? widget.currentLocation
        : widget.initialStartPoint;
    _selectedDestinationPoint = widget.initialDestinationPoint;
    _activeTarget = _showsDualPoint
        ? _SelectionTarget.start
        : _SelectionTarget.destination;

    if (_selectedStartPoint != null) {
      _startLabel = _formatCoordinates(_selectedStartPoint!);
    }
    if (_selectedDestinationPoint != null) {
      _destinationLabel = _formatCoordinates(_selectedDestinationPoint!);
    }
    _hydrateInitialLabels();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _cameraAnimationController?.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  /// Recupera etiquetas iniciales para no mostrar coordenadas cuando ya existen.
  Future<void> _hydrateInitialLabels() async {
    if (_showsDualPoint && _selectedStartPoint != null) {
      final startLabel = await _reverseGeocode(_selectedStartPoint!);
      if (!mounted) return;
      setState(() => _startLabel = startLabel);
    }

    if (_selectedDestinationPoint != null) {
      final destinationLabel = await _reverseGeocode(
        _selectedDestinationPoint!,
      );
      if (!mounted) return;
      setState(() => _destinationLabel = destinationLabel);
    }
  }

  @override
  Widget build(BuildContext context) {
    final center =
        _selectedDestinationPoint ??
        _selectedStartPoint ??
        widget.currentLocation ??
        _fallbackCenter;

    return Scaffold(
      backgroundColor: _surfaceColor,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: _surfaceColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          _showsDualPoint ? 'Seleccionar puntos' : 'Seleccionar destino',
          style: const TextStyle(
            color: _primaryColor,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: center,
              initialZoom: 13,
              onTap: (_, point) => _selectPoint(point),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.lab2_moviles',
              ),
              MarkerLayer(
                markers: [
                  if (_showsDualPoint && _selectedStartPoint != null)
                    Marker(
                      point: _selectedStartPoint!,
                      width: 44,
                      height: 44,
                      child: const _PointMarker(
                        color: _primaryColor,
                        icon: Icons.play_arrow_rounded,
                      ),
                    ),
                  if (_selectedDestinationPoint != null)
                    Marker(
                      point: _selectedDestinationPoint!,
                      width: 38,
                      height: 38,
                      child: const _PointMarker(
                        color: Color(0xFFFFB59F),
                        icon: Icons.flag_rounded,
                        iconColor: Color(0xFF721D00),
                      ),
                    ),
                ],
              ),
            ],
          ),
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Column(
              children: [
                Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  elevation: 4,
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    onChanged: _onSearchChanged,
                    onSubmitted: (_) => _searchAndCenter(),
                    decoration: InputDecoration(
                      hintText: 'Buscar lugar',
                      hintStyle: const TextStyle(color: Colors.grey),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: _primaryColor,
                      ),
                      suffixIcon: IconButton(
                        onPressed: _searchAndCenter,
                        icon: _isSearching
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(
                                Icons.travel_explore_rounded,
                                color: _primaryColor,
                              ),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                if (_suggestions.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  ..._suggestions
                      .take(3)
                      .map(
                        (suggestion) => SuggestionItem(
                          title: suggestion.title,
                          subtitle: suggestion.subtitle,
                          onTap: () => _moveMapToSuggestion(suggestion),
                        ),
                      ),
                ],
              ],
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.94),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _showsDualPoint
                                  ? (_activeTarget ==
                                            _SelectionTarget.destination
                                        ? 'Seleccionando destino'
                                        : 'Seleccionando inicio')
                                  : 'Seleccionando destino',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: _primaryColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _showsDualPoint
                                  ? 'Selecciona directamente inicio o destino.'
                                  : 'Selecciona un destino desde el mapa o el buscador.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (_showsDualPoint) ...[
                              _SelectionRow(
                                label: 'Inicio',
                                value: _startLabel,
                                selected:
                                    _activeTarget == _SelectionTarget.start,
                                onTap: () {
                                  setState(
                                    () =>
                                        _activeTarget = _SelectionTarget.start,
                                  );

                                  if (_selectedStartPoint != null) {
                                    _animateMapTo(
                                      _selectedStartPoint!,
                                      zoom: 17,
                                      duration: const Duration(
                                        milliseconds: 1400,
                                      ),
                                    );
                                  }
                                },
                              ),
                              const SizedBox(height: 10),
                            ],
                            _SelectionRow(
                              label: 'Destino',
                              value: _destinationLabel,
                              selected:
                                  _activeTarget == _SelectionTarget.destination,
                              onTap: _showsDualPoint
                                  ? () {
                                      setState(
                                        () => _activeTarget =
                                            _SelectionTarget.destination,
                                      );

                                      if (_selectedDestinationPoint != null) {
                                        _animateMapTo(
                                          _selectedDestinationPoint!,
                                          zoom: 17,
                                          duration: const Duration(
                                            milliseconds: 1400,
                                          ),
                                        );
                                      }
                                    }
                                  : null,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton.filled(
                        onPressed: _selectCurrentLocation,
                        style: IconButton.styleFrom(
                          backgroundColor: _primaryColor,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(40, 40),
                          padding: const EdgeInsets.all(8),
                        ),
                        icon: const Icon(Icons.my_location_rounded, size: 18),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _applySelection,
                    style: FilledButton.styleFrom(
                      backgroundColor: _primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: const Text(
                      'Aplicar',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    if (value.trim().isEmpty) {
      setState(() => _suggestions = []);
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 350), () {
      _searchPlaces(value);
    });
  }

  /// Busca sugerencias y recentra el mapa según el texto ingresado.
  Future<void> _searchAndCenter() async {
    if (_searchController.text.trim().isEmpty) return;
    final suggestions = await _searchPlaces(_searchController.text);
    if (!mounted || suggestions.isEmpty) return;
    _moveMapToSuggestion(suggestions.first);
  }

  /// Consulta lugares remotos para ayudar a posicionar la selección actual.
  Future<List<_PlaceSuggestion>> _searchPlaces(String query) async {
    setState(() => _isSearching = true);

    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'q': query,
        'format': 'jsonv2',
        'limit': '6',
        'addressdetails': '1',
      });
      final responseBody = await _getJson(uri);
      final List<dynamic> data = jsonDecode(responseBody) as List<dynamic>;

      final suggestions = data
          .map(
            (item) => _PlaceSuggestion.fromJson(item as Map<String, dynamic>),
          )
          .toList();

      suggestions.sort((a, b) {
        final importanceCompare = b.importance.compareTo(a.importance);
        if (importanceCompare != 0) return importanceCompare;
        if (widget.currentLocation == null) return 0;
        final distanceA = const Distance().as(
          LengthUnit.Meter,
          widget.currentLocation!,
          a.point,
        );
        final distanceB = const Distance().as(
          LengthUnit.Meter,
          widget.currentLocation!,
          b.point,
        );
        return distanceA.compareTo(distanceB);
      });

      if (!mounted) return suggestions;
      setState(() {
        _suggestions = suggestions.take(3).toList();
        _isSearching = false;
      });
      return suggestions;
    } catch (_) {
      if (mounted) {
        setState(() {
          _suggestions = [];
          _isSearching = false;
        });
      }
      return [];
    }
  }

  /// Aplica un punto al origen o destino activo y actualiza su etiqueta.
  Future<void> _selectPoint(LatLng point) async {
    _animateMapTo(
      point,
      zoom: 17,
      duration: const Duration(milliseconds: 1400),
    );

    final label = await _reverseGeocode(point);
    if (!mounted) return;

    setState(() {
      if (_showsDualPoint && _activeTarget == _SelectionTarget.start) {
        _selectedStartPoint = point;
        _startLabel = label;
      } else {
        _selectedDestinationPoint = point;
        _destinationLabel = label;
      }
    });
  }

  void _moveMapToSuggestion(_PlaceSuggestion suggestion) {
    _searchController.text = suggestion.title;
    _searchController.selection = TextSelection.fromPosition(
      TextPosition(offset: _searchController.text.length),
    );
    _searchFocusNode.unfocus();
    setState(() => _suggestions = []);
    _selectPoint(suggestion.point);
  }

  Future<void> _selectCurrentLocation() async {
    final current = widget.currentLocation;
    if (current == null) return;
    await _selectPoint(current);
  }

  /// Confirma la selección actual y devuelve el resultado a la pantalla previa.
  void _applySelection() {
    Navigator.of(context).pop(
      PointsSelectionResult(
        startPoint: _showsDualPoint ? _selectedStartPoint : null,
        destinationPoint: _selectedDestinationPoint,
        startLabel: _showsDualPoint ? _startLabel : '',
        destinationLabel: _destinationLabel,
      ),
    );
  }

  Future<String> _reverseGeocode(LatLng point) async {
    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
        'lat': point.latitude.toString(),
        'lon': point.longitude.toString(),
        'format': 'jsonv2',
      });
      final responseBody = await _getJson(uri);
      final data = jsonDecode(responseBody) as Map<String, dynamic>;
      final displayName = data['display_name'] as String?;
      if (displayName != null && displayName.trim().isNotEmpty) {
        final parts = displayName.split(',');
        if (parts.length >= 2) {
          return '${parts.first.trim()}, ${parts[1].trim()}';
        }
        return displayName.trim();
      }
    } catch (_) {
      // Fallback below.
    }
    return _formatCoordinates(point);
  }

  Future<String> _getJson(Uri uri) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(uri);
      request.headers.set(HttpHeaders.userAgentHeader, _nominatimUserAgent);
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException('Request failed', uri: uri);
      }
      return responseBody;
    } finally {
      client.close();
    }
  }

  String _formatCoordinates(LatLng point) {
    return '${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)}';
  }

  void _animateMapTo(
    LatLng target, {
    double zoom = 16,
    Duration duration = const Duration(milliseconds: 900),
  }) {
    try {
      final startCenter = _mapController.camera.center;
      final startZoom = _mapController.camera.zoom;

      _cameraAnimationController?.stop();
      _cameraAnimationController?.dispose();

      final controller = AnimationController(vsync: this, duration: duration);
      final curve = CurvedAnimation(
        parent: controller,
        curve: Curves.easeInOutCubic,
      );

      _cameraAnimationController = controller;
      controller.addListener(() {
        final t = curve.value;
        final animatedPoint = LatLng(
          ui.lerpDouble(startCenter.latitude, target.latitude, t)!,
          ui.lerpDouble(startCenter.longitude, target.longitude, t)!,
        );

        _mapController.move(animatedPoint, ui.lerpDouble(startZoom, zoom, t)!);
      });
      controller.forward();
    } catch (_) {
      _mapController.move(target, zoom);
    }
  }
}

/// Resultado devuelto al cerrar el selector de puntos.
class PointsSelectionResult {
  const PointsSelectionResult({
    required this.startPoint,
    required this.destinationPoint,
    required this.startLabel,
    required this.destinationLabel,
  });

  final LatLng? startPoint;
  final LatLng? destinationPoint;
  final String startLabel;
  final String destinationLabel;
}

enum _SelectionTarget { start, destination }

class _SelectionRow extends StatelessWidget {
  const _SelectionRow({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String value;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEAF6EF) : const Color(0xFFF3F4F5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? const Color(0xFF2C694E) : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Color(0xFF012D1D),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PointMarker extends StatelessWidget {
  const _PointMarker({
    required this.color,
    required this.icon,
    this.iconColor = Colors.white,
  });

  final Color color;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.25), blurRadius: 12),
        ],
      ),
      child: Icon(icon, size: 16, color: iconColor),
    );
  }
}

class _PlaceSuggestion {
  const _PlaceSuggestion({
    required this.title,
    required this.subtitle,
    required this.point,
    required this.importance,
  });

  final String title;
  final String subtitle;
  final LatLng point;
  final double importance;

  factory _PlaceSuggestion.fromJson(Map<String, dynamic> json) {
    final displayName = (json['display_name'] as String? ?? '').trim();
    final parts = displayName.split(',');

    return _PlaceSuggestion(
      title: parts.isNotEmpty && parts.first.trim().isNotEmpty
          ? parts.first.trim()
          : 'Lugar encontrado',
      subtitle: parts.length > 1
          ? parts.skip(1).take(2).map((part) => part.trim()).join(', ')
          : 'Sin detalles',
      point: LatLng(
        double.parse(json['lat'] as String),
        double.parse(json['lon'] as String),
      ),
      importance: (json['importance'] as num?)?.toDouble() ?? 0,
    );
  }
}
