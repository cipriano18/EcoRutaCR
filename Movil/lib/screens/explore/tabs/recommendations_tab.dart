import 'package:ecoruta/data/costa_rica_locations.dart';
import 'package:ecoruta/models/route_profile.dart';
import 'package:ecoruta/models/stored_route.dart';
import 'package:ecoruta/providers/user_provider.dart';
import 'package:ecoruta/screens/explore/route_preview_screen.dart';
import 'package:ecoruta/services/recommendations_service.dart';
import 'package:ecoruta/services/routing/route_result.dart';
import 'package:ecoruta/services/saved_routes_service.dart';
import 'package:ecoruta/widgets/confirm_dialog.dart';
import 'package:ecoruta/widgets/route_result_card.dart';
import 'package:ecoruta/widgets/suggestion_item.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class RecommendationsTab extends StatefulWidget {
  const RecommendationsTab({super.key});

  @override
  State<RecommendationsTab> createState() => _RecommendationsTabState();
}

class _RecommendationsTabState extends State<RecommendationsTab> {
  static const _primaryColor = Color(0xFF012D1D);
  static const _surfaceHigh = Color(0xFFE7E8E9);
  static const _surfaceHighest = Color(0xFFE1E3E4);
  static const _tertiaryFixed = Color(0xFFFFB59F);
  static const _textMuted = Color(0xFF414844);

  final TextEditingController _searchController = TextEditingController();
  final RecommendationsService _recommendationsService =
      RecommendationsService();
  final SavedRoutesService _savedRoutesService = SavedRoutesService();

  String? _selectedZoneLabel;
  String _zoneQuery = '';
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  int _candidateCount = 0;
  int _savedRouteCount = 0;
  late final List<_ZoneOption> _allZones;
  List<_RecommendationCardData> _recommendations = const [];

  @override
  void initState() {
    super.initState();
    _allZones = _buildZoneOptions();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadRecommendations();
      }
    });
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
          'Rutas sugeridas por el modelo segun tu perfil y las rutas publicas que has guardado.',
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
        if (_errorMessage != null)
          _RecommendationsInfoCard(
            icon: Icons.error_outline_rounded,
            message: _errorMessage!,
            actionLabel: 'Reintentar',
            onAction: _loadRecommendations,
          )
        else if (_isLoading)
          const _RecommendationsInfoCard(
            icon: Icons.sync_rounded,
            message: 'Consultando recomendaciones del modelo...',
          )
        else if (visibleRecommendations.isEmpty)
          const _RecommendationsInfoCard(
            icon: Icons.route_rounded,
            message:
                'Todavia no hay recomendaciones disponibles para esta zona o para tu perfil actual.',
          )
        else
          ...visibleRecommendations.map(
            (routeData) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: RouteResultCard(
                title: routeData.route.title,
                supportingText:
                    'Creada por ${routeData.creatorName} | match ${routeData.matchScoreLabel}',
                distance: routeData.routeResult.formattedDistance,
                duration: routeData.routeResult.formattedDuration,
                elevationGain: routeData.routeResult.formattedElevationGain,
                accentColor: _accentForProfile(routeData.route.activityProfile),
                icon: _iconForProfile(routeData.route.activityProfile),
                badge: 'IA',
                isHighlighted: true,
                buttonText: 'Ver trazado',
                secondaryButtonText: 'Guardar',
                isSecondaryLoading: _isSaving,
                onSecondaryPressed: _isSaving
                    ? null
                    : () => _confirmSave(routeData),
                onPressed: () => _openPreview(routeData),
              ),
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
              'TWO-TOWER',
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
            'Rutas sugeridas para ti',
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
                ? 'El modelo prioriza tus rutas publicas guardadas y tu perfil para rankear nuevas opciones.'
                : 'Mostrando sugerencias filtradas por $_selectedZoneLabel.',
            style: const TextStyle(
              fontSize: 14,
              color: _textMuted,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _SummaryChip(
                icon: Icons.analytics_rounded,
                label: '$_candidateCount candidatas',
              ),
              _SummaryChip(
                icon: Icons.bookmark_rounded,
                label: '$_savedRouteCount guardadas',
              ),
              if (_selectedZoneLabel != null)
                _SummaryChip(
                  icon: Icons.place_rounded,
                  label: _selectedZoneLabel!,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _loadRecommendations() async {
    final user = context.read<UserProvider>().user;
    if (user == null) {
      setState(() {
        _errorMessage =
            'No se encontro el usuario autenticado para consultar recomendaciones.';
        _recommendations = const [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _recommendationsService.fetchRecommendations(
        userId: user.uid,
        topK: 12,
      );
      if (!mounted) return;
      setState(() {
        _candidateCount = response.candidateCount;
        _savedRouteCount = response.savedRouteCount;
      });

      final publicRoutes = await _savedRoutesService.fetchPublicRoutes();
      final byId = {
        for (final route in publicRoutes)
          if (route.ownerId != user.uid) route.id: route,
      };
      final creatorNames = await _savedRoutesService.fetchUserDisplayNames(
        byId.values.map((route) => route.ownerId),
      );

      final visible = <_RecommendationCardData>[];
      for (final recommendation in response.recommendations) {
        final route = byId[recommendation.routeId];
        if (route == null) {
          debugPrint(
            'Recommendation skipped: route ${recommendation.routeId} not found in Firestore public routes.',
          );
          continue;
        }

        try {
          visible.add(
            _RecommendationCardData(
              route: route,
              routeResult: route.toRouteResult(),
              creatorName:
                  creatorNames[route.ownerId]?.trim().isNotEmpty == true
                  ? creatorNames[route.ownerId]!
                  : 'usuario desconocido',
              score: recommendation.score,
            ),
          );
        } catch (error, stackTrace) {
          debugPrint(
            'Recommendation skipped for route ${route.id}: $error\n$stackTrace',
          );
        }
      }

      if (!mounted) return;
      setState(() {
        _recommendations = visible;
        if (response.recommendations.isNotEmpty && visible.isEmpty) {
          _errorMessage =
              'El modelo devolvio rutas, pero ninguna pudo renderizarse correctamente en la app.';
        }
      });
    } on RecommendationsException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.message;
        _recommendations = const [];
      });
    } on SavedRouteException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.message;
        _recommendations = const [];
      });
    } catch (error) {
      debugPrint('RecommendationsTab load failed: $error');
      if (!mounted) return;
      setState(() {
        _errorMessage = 'No se pudieron cargar las recomendaciones: $error';
        _recommendations = const [];
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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

  List<_RecommendationCardData> _filteredRecommendations() {
    final query = (_selectedZoneLabel ?? _zoneQuery).trim().toLowerCase();
    return _recommendations
        .where(
          (route) =>
              query.isEmpty ||
              route.route.startLabel.toLowerCase().contains(query) ||
              route.route.endLabel.toLowerCase().contains(query),
        )
        .toList(growable: false);
  }

  String _resultsSummary(int visibleCount) {
    if (_errorMessage != null) {
      return 'No se pudo completar la consulta del modelo';
    }
    if (_isLoading) {
      return 'Consultando rutas recomendadas por IA';
    }
    final zoneText = _selectedZoneLabel == null
        ? 'sin filtro de zona'
        : _selectedZoneLabel!;
    return '$visibleCount recomendaciones visibles en $zoneText';
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

  Future<void> _confirmSave(_RecommendationCardData routeData) async {
    final confirmed = await ConfirmDialog.mostrar(
      context,
      titulo: 'Guardar ruta publica',
      mensaje: 'Deseas guardar esta ruta creada por ${routeData.creatorName}?',
      textoConfirmar: 'Guardar',
    );

    if (!confirmed || !mounted) return;

    setState(() => _isSaving = true);
    try {
      await _savedRoutesService.savePublicRouteReference(
        route: routeData.route,
        creatorName: routeData.creatorName,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ruta guardada en la pestaña Guardadas.')),
      );
    } on SavedRouteException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _openPreview(_RecommendationCardData routeData) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RoutePreviewScreen(
          title: routeData.route.title,
          route: routeData.routeResult,
          profile: routeData.route.activityProfile,
          preference: routeData.route.routingPreference,
          startLabel: routeData.route.startLabel,
          endLabel: routeData.route.endLabel,
          allowSave: false,
        ),
      ),
    );
  }

  Color _accentForProfile(RouteProfile profile) {
    switch (profile) {
      case RouteProfile.cycling:
        return const Color(0xFFAEEECB);
      case RouteProfile.hiking:
        return const Color(0xFFC1ECD4);
      case RouteProfile.running:
        return const Color(0xFFFFB59F);
    }
  }

  IconData _iconForProfile(RouteProfile profile) {
    switch (profile) {
      case RouteProfile.cycling:
        return Icons.directions_bike_rounded;
      case RouteProfile.hiking:
        return Icons.hiking_rounded;
      case RouteProfile.running:
        return Icons.directions_run_rounded;
    }
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _RecommendationsTabState._tertiaryFixed.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(width: 2),
          Icon(icon, size: 16, color: _RecommendationsTabState._primaryColor),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _RecommendationsTabState._primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecommendationsInfoCard extends StatelessWidget {
  const _RecommendationsInfoCard({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: _RecommendationsTabState._primaryColor),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF191C1D),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(actionLabel!),
              ),
            ),
          ],
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

class _RecommendationCardData {
  const _RecommendationCardData({
    required this.route,
    required this.routeResult,
    required this.creatorName,
    required this.score,
  });

  final StoredRoute route;
  final RouteResult routeResult;
  final String creatorName;
  final double score;

  String get matchScoreLabel {
    final normalized = ((score + 2) / 4).clamp(0, 1);
    return '${(normalized * 100).round()}%';
  }
}
