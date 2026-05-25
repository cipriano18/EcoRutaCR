import 'package:ecoruta/data/costa_rica_locations.dart';
import 'package:ecoruta/widgets/suggestion_item.dart';
import 'package:flutter/material.dart';

/// Mockup de recomendaciones personalizadas basado en perfil y zona.
class RecommendationsTab extends StatefulWidget {
  const RecommendationsTab({super.key});

  @override
  State<RecommendationsTab> createState() => _RecommendationsTabState();
}

class _RecommendationsTabState extends State<RecommendationsTab> {
  static const _primaryColor = Color(0xFF012D1D);
  static const _surface = Color(0xFFF8F9FA);
  static const _surfaceHigh = Color(0xFFE7E8E9);
  static const _surfaceHighest = Color(0xFFE1E3E4);
  static const _surfaceLow = Color(0xFFF3F4F5);
  static const _tertiaryFixed = Color(0xFFFFB59F);
  static const _textMain = Color(0xFF191C1D);
  static const _textMuted = Color(0xFF414844);

  final TextEditingController _searchController = TextEditingController();

  String? _selectedZoneLabel;
  String _zoneQuery = '';

  late final List<_RecommendationRoute> _allRecommendations;
  late final List<_ZoneOption> _allZones;

  @override
  void initState() {
    super.initState();
    _allRecommendations = _buildMockRecommendations();
    _allZones = _buildZoneOptions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visibleRecommendations = _filteredRecommendations();
    final zoneSuggestions = _filteredZoneSuggestions();

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
      children: [
        const Text(
          'Recomendaciones',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w900,
            color: _primaryColor,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Mockup inicial de rutas recomendadas con filtro por zona.',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 22),
        _buildSearchField(),
        if (zoneSuggestions.isNotEmpty) ...[
          const SizedBox(height: 10),
          ...zoneSuggestions.map(
            (zone) => SuggestionItem(
              title: zone.title,
              subtitle: zone.subtitle,
              onTap: () => _selectZone(zone.label),
            ),
          ),
        ],
        const SizedBox(height: 28),
        _buildIntroPanel(),
        const SizedBox(height: 28),
        Text(
          _resultsSummary(visibleRecommendations.length),
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        if (visibleRecommendations.isEmpty)
          const _RecommendationsInfoCard(
            icon: Icons.filter_alt_off_rounded,
            message:
                'No hay rutas mock para esta zona. Prueba con otra busqueda.',
          )
        else
          ...visibleRecommendations.map(
            (route) => Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: _RecommendationCard(route: route),
            ),
          ),
      ],
    );
  }

  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: _surfaceHigh,
        borderRadius: BorderRadius.circular(18),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _zoneQuery = value),
        decoration: InputDecoration(
          hintText: 'Buscar por zona',
          prefixIcon: const Icon(Icons.location_on_rounded, color: _textMuted),
          suffixIcon: (_zoneQuery.isNotEmpty || _selectedZoneLabel != null)
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _zoneQuery = '';
                      _selectedZoneLabel = null;
                    });
                  },
                  icon: const Icon(Icons.close_rounded, color: _textMuted),
                )
              : null,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: _primaryColor, width: 1.8),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 18,
          ),
          fillColor: _surfaceHighest,
          filled: true,
        ),
      ),
    );
  }

  Widget _buildIntroPanel() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _tertiaryFixed.withValues(alpha: 0.24),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'IA PERSONALIZADA',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Color(0xFF852300),
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Rutas sugeridas',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: _primaryColor,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedZoneLabel == null
                ? 'Aqui puedes presentar recomendaciones generadas por tu modelo y mostrar rutas publicas destacadas debajo.'
                : 'Mostrando rutas mock cercanas a $_selectedZoneLabel para acotar mejor la zona.',
            style: const TextStyle(
              fontSize: 14,
              color: _textMuted,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          if (_selectedZoneLabel != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: _tertiaryFixed.withValues(alpha: 0.28),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.place_rounded,
                    size: 16,
                    color: _primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _selectedZoneLabel!,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _primaryColor,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _selectZone(String label) {
    _searchController.text = label;
    setState(() {
      _zoneQuery = label;
      _selectedZoneLabel = label;
    });
  }

  List<_ZoneOption> _filteredZoneSuggestions() {
    final query = _zoneQuery.trim().toLowerCase();
    if (query.isEmpty || _selectedZoneLabel == _zoneQuery) {
      return const [];
    }

    return _allZones
        .where((zone) => zone.searchText.contains(query))
        .take(5)
        .toList(growable: false);
  }

  List<_RecommendationRoute> _filteredRecommendations() {
    final query = (_selectedZoneLabel ?? _zoneQuery).trim().toLowerCase();
    return _allRecommendations
        .where((route) {
          return query.isEmpty || route.zoneSearchText.contains(query);
        })
        .toList(growable: false);
  }

  String _resultsSummary(int count) {
    final zoneText = _selectedZoneLabel == null
        ? 'sin zona definida'
        : _selectedZoneLabel!;
    return '$count rutas mock disponibles en $zoneText';
  }

  List<_ZoneOption> _buildZoneOptions() {
    return costaRicaLocations
        .expand(
          (province) => province.cantonDistricts.map(
            (entry) => _ZoneOption(
              label: '${entry.canton}, ${entry.district}',
              title: entry.displayLabel,
              subtitle: province.name,
            ),
          ),
        )
        .toList(growable: false);
  }

  List<_RecommendationRoute> _buildMockRecommendations() {
    return const [
      _RecommendationRoute(
        title: 'Senda del Bosque Nuboso',
        author: 'Carlos M.',
        zoneLabel: 'San Rafael, Heredia',
        activity: 'Senderismo',
        distanceKm: 12.4,
        elevationMeters: 450,
        durationMinutes: 200,
        difficulty: 'Intermedio',
        gradient: [Color(0xFF214235), Color(0xFF9DD0A5)],
      ),
      _RecommendationRoute(
        title: 'Circuito Volcan Arenal',
        author: 'Elena Ruiz',
        zoneLabel: 'La Fortuna, Alajuela',
        activity: 'Senderismo',
        distanceKm: 8.2,
        elevationMeters: 610,
        durationMinutes: 165,
        difficulty: 'Retador',
        gradient: [Color(0xFF5E2A17), Color(0xFFF0A36D)],
      ),
      _RecommendationRoute(
        title: 'Mirador del Pacifico',
        author: 'Marco V.',
        zoneLabel: 'Quepos, Puntarenas',
        activity: 'Running',
        distanceKm: 15,
        elevationMeters: 230,
        durationMinutes: 130,
        difficulty: 'Ritmo alto',
        gradient: [Color(0xFF005A77), Color(0xFF71D6E3)],
      ),
      _RecommendationRoute(
        title: 'Vuelta Urbana Escazu',
        author: 'Daniela P.',
        zoneLabel: 'Escazu, San Antonio',
        activity: 'Running',
        distanceKm: 6.8,
        elevationMeters: 120,
        durationMinutes: 50,
        difficulty: 'Ligero',
        gradient: [Color(0xFF28374E), Color(0xFF8AA7D7)],
      ),
      _RecommendationRoute(
        title: 'Ruta Verde de Belen',
        author: 'Rodo C.',
        zoneLabel: 'Belen, La Ribera',
        activity: 'Ciclismo',
        distanceKm: 18.6,
        elevationMeters: 180,
        durationMinutes: 72,
        difficulty: 'Fluido',
        gradient: [Color(0xFF174A3B), Color(0xFF57C798)],
      ),
      _RecommendationRoute(
        title: 'Ascenso Cartago Centro',
        author: 'Luis Fer',
        zoneLabel: 'Cartago, Occidental',
        activity: 'Ciclismo',
        distanceKm: 22,
        elevationMeters: 520,
        durationMinutes: 140,
        difficulty: 'Fuerza',
        gradient: [Color(0xFF3B2A17), Color(0xFFD2A56E)],
      ),
    ];
  }
}

class _RecommendationsInfoCard extends StatelessWidget {
  const _RecommendationsInfoCard({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: _RecommendationsTabState._primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _RecommendationsTabState._textMain,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({required this.route});

  final _RecommendationRoute route;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 170,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: route.gradient,
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 18,
                  right: 18,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.public_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'PUBLICA',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 18,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        route.zoneLabel,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        route.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.8,
                          height: 1.05,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'por ${route.author}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _RecommendationsTabState._textMuted,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _RecommendationsTabState._surfaceLow,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        route.difficulty,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: _RecommendationsTabState._primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _StatPill(
                      icon: Icons.route_rounded,
                      label: '${route.distanceKm.toStringAsFixed(1)} km',
                    ),
                    _StatPill(
                      icon: Icons.terrain_rounded,
                      label: '${route.elevationMeters} m',
                    ),
                    _StatPill(
                      icon: Icons.schedule_rounded,
                      label: route.formattedDuration,
                    ),
                    _StatPill(
                      icon: _activityIcon(route.activity),
                      label: route.activity,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.favorite_border_rounded),
                        label: const Text('Guardar'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor:
                              _RecommendationsTabState._primaryColor,
                          side: const BorderSide(
                            color: _RecommendationsTabState._primaryColor,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.auto_awesome_rounded),
                        label: const Text('Ver match'),
                        style: FilledButton.styleFrom(
                          backgroundColor:
                              _RecommendationsTabState._primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _activityIcon(String activity) {
    switch (activity) {
      case 'Ciclismo':
        return Icons.directions_bike_rounded;
      case 'Running':
        return Icons.directions_run_rounded;
      case 'Senderismo':
      default:
        return Icons.hiking_rounded;
    }
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _RecommendationsTabState._surface,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: _RecommendationsTabState._primaryColor),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _RecommendationsTabState._textMain,
            ),
          ),
        ],
      ),
    );
  }
}

class _ZoneOption {
  const _ZoneOption({
    required this.label,
    required this.title,
    required this.subtitle,
  });

  final String label;
  final String title;
  final String subtitle;

  String get searchText => '$label $title $subtitle'.toLowerCase();
}

class _RecommendationRoute {
  const _RecommendationRoute({
    required this.title,
    required this.author,
    required this.zoneLabel,
    required this.activity,
    required this.distanceKm,
    required this.elevationMeters,
    required this.durationMinutes,
    required this.difficulty,
    required this.gradient,
  });

  final String title;
  final String author;
  final String zoneLabel;
  final String activity;
  final double distanceKm;
  final int elevationMeters;
  final int durationMinutes;
  final String difficulty;
  final List<Color> gradient;

  String get zoneSearchText => zoneLabel.toLowerCase();

  String get formattedDuration {
    final hours = durationMinutes ~/ 60;
    final minutes = durationMinutes % 60;
    if (hours == 0) return '$minutes min';
    if (minutes == 0) return '${hours}h';
    return '${hours}h ${minutes}m';
  }
}
