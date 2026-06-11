import 'package:ecoruta/features/profile/providers/user_provider.dart';
import 'package:ecoruta/features/routes/models/route_profile.dart';
import 'package:ecoruta/features/routes/models/stored_route.dart';
import 'package:ecoruta/features/routes/screens/route_preview_screen.dart';
import 'package:ecoruta/features/routes/services/recommendations_service.dart';
import 'package:ecoruta/features/routes/services/routing/route_result.dart';
import 'package:ecoruta/features/routes/services/saved_routes_service.dart';
import 'package:ecoruta/core/widgets/confirm_dialog.dart';
import 'package:ecoruta/core/widgets/suggestion_item.dart';
import 'package:ecoruta/features/routes/widgets/route_result_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class RecommendationsTab extends StatefulWidget {
  const RecommendationsTab({super.key});

  @override
  State<RecommendationsTab> createState() => _RecommendationsTabState();
}

class _RecommendationsTabState extends State<RecommendationsTab> {
  static const _primaryColor = Color(0xFF012D1D);
  static const _surfaceHighest = Color(0xFFE1E3E4);
  static const _textMuted = Color(0xFF414844);
  static const _borderSoft = Color(0xFFD8DDDA);

  final TextEditingController _searchController = TextEditingController();
  final RecommendationsService _recommendationsService =
      RecommendationsService();
  final SavedRoutesService _savedRoutesService = SavedRoutesService();

  String? _appliedZoneFilter;
  String _zoneQuery = '';
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  List<_RecommendationCardData> _recommendations = const [];

  @override
  void initState() {
    super.initState();
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
          'Rutas sugeridas para ti según tu perfil y las rutas que ya has guardado.',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 28),
        _buildSearchControls(),
        if (zoneSuggestions.isNotEmpty) ...[
          const SizedBox(height: 10),
          ...zoneSuggestions.map(
            (zone) => SuggestionItem(
              title: zone,
              subtitle: 'Disponible en estas recomendaciones',
              onTap: () => _applyZoneFilter(zone),
            ),
          ),
        ],
        const SizedBox(height: 18),
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
            message: 'Consultando recomendaciones con IA...',
          )
        else if (visibleRecommendations.isEmpty)
          const _RecommendationsInfoCard(
            icon: Icons.route_rounded,
            message: 'No hay recomendaciones para mostrar.',
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

  Widget _buildSearchControls() {
    return Row(
      children: [
        Expanded(child: _buildSearchField()),
        const SizedBox(width: 12),
        _buildRefreshButton(),
      ],
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: (value) => setState(() => _zoneQuery = value),
      onSubmitted: _applyZoneFilter,
      decoration: InputDecoration(
        hintText: 'Filtrar por destino',
        hintStyle: const TextStyle(
          color: _textMuted,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: const Icon(Icons.location_on_rounded, color: _textMuted),
        suffixIcon: (_zoneQuery.isNotEmpty || _appliedZoneFilter != null)
            ? IconButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _zoneQuery = '';
                    _appliedZoneFilter = null;
                  });
                },
                icon: const Icon(Icons.close_rounded, color: _textMuted),
              )
            : null,
        filled: true,
        fillColor: _surfaceHighest,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 22,
          vertical: 20,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: const BorderSide(color: Colors.transparent),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: const BorderSide(color: _borderSoft),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: const BorderSide(color: _primaryColor, width: 1.8),
        ),
      ),
    );
  }

  Widget _buildRefreshButton() {
    return SizedBox(
      width: 58,
      height: 58,
      child: FilledButton(
        onPressed: _isLoading ? null : _reloadRecommendations,
        style: FilledButton.styleFrom(
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.autorenew_rounded),
      ),
    );
  }

  Future<void> _loadRecommendations() async {
    final user = context.read<UserProvider>().user;
    if (user == null) {
      setState(() {
        _errorMessage = 'No pudimos cargar las recomendaciones.';
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
              region: recommendation.region,
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
          _errorMessage = 'No pudimos mostrar las recomendaciones.';
        }
      });
    } on RecommendationsException catch (error) {
      if (!mounted) return;
      setState(() {
        debugPrint('Recommendations service failed: ${error.message}');
        _errorMessage = 'No pudimos cargar las recomendaciones.';
        _recommendations = const [];
      });
    } on SavedRouteException catch (error) {
      if (!mounted) return;
      setState(() {
        debugPrint(
          'Recommendations saved-route lookup failed: ${error.message}',
        );
        _errorMessage = 'No pudimos cargar las recomendaciones.';
        _recommendations = const [];
      });
    } catch (error) {
      debugPrint('RecommendationsTab load failed: $error');
      if (!mounted) return;
      setState(() {
        _errorMessage = 'No pudimos cargar las recomendaciones.';
        _recommendations = const [];
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _applyZoneFilter(String value) {
    final sanitized = value.trim();
    _searchController.value = TextEditingValue(
      text: sanitized,
      selection: TextSelection.collapsed(offset: sanitized.length),
    );
    setState(() {
      _zoneQuery = sanitized;
      _appliedZoneFilter = sanitized.isEmpty ? null : sanitized;
    });
  }

  void _reloadRecommendations() {
    _searchController.clear();
    setState(() {
      _zoneQuery = '';
      _appliedZoneFilter = null;
    });
    _loadRecommendations();
  }

  List<String> _filteredZoneSuggestions() {
    final query = _normalizeText(_zoneQuery);
    if (query.isEmpty) {
      return const [];
    }

    final applied = _normalizeText(_appliedZoneFilter ?? '');
    return _availableLocationTerms()
        .where(
          (term) =>
              _normalizeText(term).contains(query) &&
              _normalizeText(term) != applied,
        )
        .take(5)
        .toList(growable: false);
  }

  List<_RecommendationCardData> _filteredRecommendations() {
    final query = _normalizeText(_appliedZoneFilter ?? '');
    return _recommendations
        .where((route) => query.isEmpty || route.matchesLocationQuery(query))
        .toList(growable: false);
  }

  String _resultsSummary(int visibleCount) {
    if (_errorMessage != null) {
      return 'No se pudo completar la consulta de recomendaciones';
    }
    if (_isLoading) {
      return 'Consultando rutas recomendadas por IA';
    }
    return '$visibleCount recomendaciones';
  }

  List<String> _availableLocationTerms() {
    final terms = <String>{};
    for (final routeData in _recommendations) {
      for (final term in routeData.locationTerms) {
        final trimmed = term.trim();
        if (trimmed.isNotEmpty && _normalizeText(trimmed) != 'unknown') {
          terms.add(trimmed);
        }
      }
    }

    final sorted = terms.toList(growable: false)
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return sorted;
  }

  static String _normalizeText(String value) {
    final lowered = value
        .trim()
        .toLowerCase()
        .replaceAll('\u00E1', 'a')
        .replaceAll('\u00E9', 'e')
        .replaceAll('\u00ED', 'i')
        .replaceAll('\u00F3', 'o')
        .replaceAll('\u00FA', 'u')
        .replaceAll('\u00FC', 'u')
        .replaceAll('\u00F1', 'n');

    return lowered.replaceAll(RegExp(r'\s+'), ' ').trim();
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

class _RecommendationCardData {
  const _RecommendationCardData({
    required this.route,
    required this.routeResult,
    required this.creatorName,
    required this.score,
    required this.region,
  });

  final StoredRoute route;
  final RouteResult routeResult;
  final String creatorName;
  final double score;
  final String region;

  List<String> get locationTerms => [
    region,
    route.startLabel,
    route.endLabel,
  ].where((term) => term.trim().isNotEmpty).toList(growable: false);

  bool matchesLocationQuery(String query) {
    return locationTerms.any(
      (term) => _RecommendationsTabState._normalizeText(term).contains(query),
    );
  }

  String get matchScoreLabel {
    final normalized = ((score + 2) / 4).clamp(0, 1);
    return '${(normalized * 100).round()}%';
  }
}
