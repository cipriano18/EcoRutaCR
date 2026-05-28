import 'package:ecoruta/models/stored_route.dart';
import 'package:ecoruta/screens/explore/route_preview_screen.dart';
import 'package:ecoruta/services/routing/a_star_router.dart';
import 'package:ecoruta/services/saved_routes_service.dart';
import 'package:ecoruta/widgets/app_header.dart';
import 'package:ecoruta/widgets/confirm_dialog.dart';
import 'package:ecoruta/widgets/my_route_card.dart';
import 'package:ecoruta/widgets/save_route_sheet.dart';
import 'package:flutter/material.dart';

/// Pantalla que lista las rutas guardadas del usuario autenticado.
class MyRoutesScreen extends StatefulWidget {
  const MyRoutesScreen({super.key});

  @override
  State<MyRoutesScreen> createState() => _MyRoutesScreenState();
}

class _MyRoutesScreenState extends State<MyRoutesScreen> {
  static const primaryColor = Color(0xFF012D1D);
  static const surfaceColor = Color(0xFFF8F9FA);
  static const surfaceLow = Color(0xFFF3F4F5);
  static const surfaceLowest = Colors.white;
  static const textMuted = Color(0xFF5E6762);
  static const borderColor = Color(0xFFC1C8C2);

  static const _allFilter = 'Todas';
  static const List<String> _filters = [
    _allFilter,
    'Senderismo',
    'Ciclismo',
    'Running',
  ];

  static const _allPreferenceFilter = 'Todas';
  static const List<String> _preferenceFilters = [
    _allPreferenceFilter,
    'Mas cortas',
    'Mas desafiantes',
  ];

  static const _allVisibilityFilter = 'Todas';
  static const List<String> _visibilityFilters = [
    _allVisibilityFilter,
    'Públicas',
    'Privadas',
  ];

  final SavedRoutesService _savedRoutesService = SavedRoutesService();

  _MyRoutesTab _selectedTab = _MyRoutesTab.creations;
  String _selectedFilter = _allFilter;
  String _selectedPreferenceFilter = _allPreferenceFilter;
  String _selectedVisibilityFilter = _allVisibilityFilter;

  List<StoredRoute> _filterRoutes(List<StoredRoute> routes) {
    var filteredRoutes = routes;

    if (_selectedFilter != _allFilter) {
      filteredRoutes = filteredRoutes
          .where((route) => route.activityLabel == _selectedFilter)
          .toList(growable: false);
    }

    if (_selectedPreferenceFilter != _allPreferenceFilter) {
      filteredRoutes = filteredRoutes
          .where(
            (route) =>
                _labelForRoutingPreference(route.routingPreference) ==
                _selectedPreferenceFilter,
          )
          .toList(growable: false);
    }

    if (_selectedVisibilityFilter != _allVisibilityFilter) {
      filteredRoutes = filteredRoutes
          .where(
            (route) =>
                _labelForVisibility(route.visibility) ==
                _selectedVisibilityFilter,
          )
          .toList(growable: false);
    }

    return filteredRoutes;
  }

  List<StoredRoute> _sortCreatedRoutes(List<StoredRoute> routes) {
    final privateRoutes = routes
        .where((route) => !route.isPublic)
        .toList(growable: false);
    final publicRoutes = routes
        .where((route) => route.isPublic)
        .toList(growable: false);
    return [...privateRoutes, ...publicRoutes];
  }

  /// Elimina una ruta tras confirmar la intencion del usuario.
  Future<void> _removeRoute(StoredRoute route) async {
    final confirmed = await ConfirmDialog.mostrar(
      context,
      titulo: 'Eliminar ruta',
      mensaje: 'Quieres eliminar "${route.title}" de tu lista guardada?',
      textoConfirmar: 'Eliminar',
    );

    if (!confirmed || !mounted) return;

    try {
      await _savedRoutesService.deleteRoute(route.id);
    } on SavedRouteException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  Future<void> _removeSavedPublicRoute(StoredRoute route) async {
    final confirmed = await ConfirmDialog.mostrar(
      context,
      titulo: 'Quitar ruta guardada',
      mensaje: 'Quieres quitar "${route.title}" de tus rutas guardadas?',
      textoConfirmar: 'Quitar',
    );

    if (!confirmed || !mounted) return;

    try {
      await _savedRoutesService.deleteSavedPublicRoute(route.id);
    } on SavedRouteException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  Future<void> _editRoute(StoredRoute route) async {
    if (route.isPublic) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Las rutas publicas no se pueden editar.'),
        ),
      );
      return;
    }

    final editData = await showModalBottomSheet<SaveRouteFormResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SaveRouteSheet(
        initialTitle: route.title,
        initialDescription: route.description,
        startLabel: route.startLabel,
        endLabel: route.endLabel,
        titleText: 'Editar ruta',
        submitButtonText: 'Guardar cambios',
      ),
    );

    if (editData == null || !mounted) return;

    try {
      await _savedRoutesService.updateRouteDetails(
        routeId: route.id,
        title: editData.title,
        description: editData.description,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ruta actualizada correctamente.')),
      );
    } on SavedRouteException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudieron guardar los cambios de la ruta.'),
        ),
      );
    }
  }

  /// Abre la ruta guardada reconstruida desde Firestore.
  void _openRoute(StoredRoute route) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RoutePreviewScreen(
          title: route.title,
          route: route.toRouteResult(),
          startLabel: route.startLabel,
          endLabel: route.endLabel,
          enableStartAction: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: surfaceColor,
      appBar: const AppHeader(backgroundColor: surfaceColor),
      body: SafeArea(
        child: StreamBuilder<List<StoredRoute>>(
          stream: _selectedTab == _MyRoutesTab.saved
              ? _savedRoutesService.watchSavedPublicRoutes()
              : _savedRoutesService.watchUserRoutes(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
  print('ERROR CARGANDO MIS RUTAS: ${snapshot.error}');
  return _buildErrorState();
}
            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(color: primaryColor),
              );
            }

            final routes = snapshot.data ?? const <StoredRoute>[];
            final visibleRoutes = _selectedTab == _MyRoutesTab.saved
                ? _filterRoutes(routes)
                : _sortCreatedRoutes(_filterRoutes(routes));

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              children: [
                _buildHeader(savedRoutesCount: routes.length),
                const SizedBox(height: 24),
                _buildFilters(),
                const SizedBox(height: 20),
                if (visibleRoutes.isEmpty)
                  _selectedTab == _MyRoutesTab.saved
                      ? _buildSavedRoutesEmptyState()
                      : _buildEmptyState()
                else
                  ...visibleRoutes.map(
                    (route) => MyRouteCard(
                      route: route,
                      onOpen: () => _openRoute(route),
                      onDelete: _selectedTab == _MyRoutesTab.saved
                          ? () => _removeSavedPublicRoute(route)
                          : () => _removeRoute(route),
                      onEdit:
                          _selectedTab == _MyRoutesTab.saved || route.isPublic
                          ? null
                          : () => _editRoute(route),
                      creatorText: _selectedTab == _MyRoutesTab.saved
                          ? 'Creada por ${route.sourceOwnerName?.trim().isNotEmpty == true ? route.sourceOwnerName : 'usuario desconocido'}'
                          : 'Creada por ti',
                      showDeleteAction:
                          _selectedTab == _MyRoutesTab.saved || !route.isPublic,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader({required int savedRoutesCount}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mis rutas',
          style: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w900,
            color: primaryColor,
            letterSpacing: -0.9,
            height: 1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '$savedRoutesCount rutas totales en tu biblioteca',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildFilters() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: surfaceLow,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildMainTabButton(
                label: 'Mis creaciones',
                selected: _selectedTab == _MyRoutesTab.creations,
                onTap: () {
                  setState(() {
                    _selectedTab = _MyRoutesTab.creations;
                    _resetAllFilters();
                  });
                },
              ),
            ),

            const SizedBox(width: 8),

            Expanded(
              child: _buildMainTabButton(
                label: 'Guardadas',
                selected: _selectedTab == _MyRoutesTab.saved,
                onTap: () {
                  setState(() {
                    _selectedTab = _MyRoutesTab.saved;
                    _resetAllFilters();
                  });
                },
              ),
            ),
          ],
        ),
      ),

      const SizedBox(height: 18),

      Row(
        children: [
          Expanded(
            child: _buildHorizontalChips([
              _quickFilterChip(
                label: 'Todas',
                selected: _isQuickAllSelected,
                onTap: () {
                  setState(_resetAllFilters);
                },
              ),

              if (_selectedTab == _MyRoutesTab.creations)
                _quickFilterChip(
                  label: 'Privadas',
                  selected: _selectedVisibilityFilter == 'Privadas',
                  onTap: () {
                    setState(() {
                      _selectedVisibilityFilter = 'Privadas';
                    });
                  },
                ),
            ]),
          ),

          const SizedBox(width: 10),

          _buildMoreFiltersButton(),
        ],
      ),

      if (_activeExtraFilters.isNotEmpty) ...[
        const SizedBox(height: 12),

        Text(
          'Filtros activos: ${_activeExtraFilters.join(' | ')}',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: textMuted,
          ),
        ),
      ],
    ],
  );
}

  bool get _isQuickAllSelected =>
      _selectedFilter == _allFilter &&
      _selectedPreferenceFilter == _allPreferenceFilter &&
      _selectedVisibilityFilter == _allVisibilityFilter;

  List<String> get _activeExtraFilters {
    final filters = <String>[];

    if (_selectedFilter != _allFilter) {
      filters.add(_selectedFilter);
    }
    if (_selectedPreferenceFilter != _allPreferenceFilter) {
      filters.add(_selectedPreferenceFilter);
    }
    if (_selectedVisibilityFilter != _allVisibilityFilter &&
        _selectedVisibilityFilter != 'Privadas') {
      filters.add(_selectedVisibilityFilter);
    }

    return filters;
  }

  void _resetAllFilters() {
    _selectedFilter = _allFilter;
    _selectedPreferenceFilter = _allPreferenceFilter;
    _selectedVisibilityFilter = _allVisibilityFilter;
  }

  Widget _buildMainTabButton({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: selected ? surfaceLowest : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.06),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: selected ? primaryColor : textMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHorizontalChips(List<Widget> chips) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: chips),
    );
  }

  Widget _buildMoreFiltersButton() {
    final hasExtraFilters = _activeExtraFilters.isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _openMoreFiltersSheet,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: hasExtraFilters ? const Color(0xFFDAEBDD) : surfaceLowest,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: hasExtraFilters
                  ? const Color(0xFFB6D3BC)
                  : borderColor.withValues(alpha: 0.65),
            ),
          ),
          child: Icon(
            Icons.tune_rounded,
            color: hasExtraFilters ? primaryColor : textMuted,
          ),
        ),
      ),
    );
  }

  Future<void> _openMoreFiltersSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            void updateModalAndParent(VoidCallback update) {
              setState(update);
              setModalState(() {});
            }

            return Container(
              decoration: const BoxDecoration(
                color: surfaceLowest,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(
                        child: Container(
                          width: 42,
                          height: 5,
                          decoration: BoxDecoration(
                            color: borderColor,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Mas filtros',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: primaryColor,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              updateModalAndParent(_resetAllFilters);
                            },
                            child: const Text('Limpiar'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Ajusta actividad, tipo de ruta o visibilidad.',
                        style: TextStyle(
                          color: textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildSheetFilterSection(
                        title: 'Actividad',
                        chips: [
                          _buildSheetChip(
                            label: _allFilter,
                            selected: _selectedFilter == _allFilter,
                            icon: _iconForActivityFilter(_allFilter),
                            onTap: () {
                              updateModalAndParent(() {
                                _selectedFilter = _allFilter;
                              });
                            },
                          ),
                          ..._filters
                              .where((filter) => filter != _allFilter)
                              .map(
                                (filter) => _buildSheetChip(
                                  label: filter,
                                  selected: _selectedFilter == filter,
                                  icon: _iconForActivityFilter(filter),
                                  onTap: () {
                                    updateModalAndParent(() {
                                      _selectedFilter = filter;
                                    });
                                  },
                                ),
                              ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      _buildSheetFilterSection(
                        title: 'Tipo de ruta',
                        chips: _preferenceFilters
                            .map(
                              (filter) => _buildSheetChip(
                                label: filter,
                                selected: _selectedPreferenceFilter == filter,
                                icon: _iconForPreferenceFilter(filter),
                                onTap: () {
                                  updateModalAndParent(() {
                                    _selectedPreferenceFilter = filter;
                                  });
                                },
                              ),
                            )
                            .toList(growable: false),
                      ),
                      const SizedBox(height: 18),
                      _buildSheetFilterSection(
                        title: 'Visibilidad',
                        chips: _visibilityFilters
                            .map(
                              (filter) => _buildSheetChip(
                                label: filter,
                                selected: _selectedVisibilityFilter == filter,
                                icon: _iconForVisibilityFilter(filter),
                                onTap: () {
                                  updateModalAndParent(() {
                                    _selectedVisibilityFilter = filter;
                                  });
                                },
                              ),
                            )
                            .toList(growable: false),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Aplicar filtros'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSheetFilterSection({
    required String title,
    required List<Widget> chips,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: primaryColor,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(spacing: 10, runSpacing: 10, children: chips),
      ],
    );
  }

  Widget _quickFilterChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return _FilterChip(
      label: label,
      selected: selected,
      icon: label == 'Privadas' ? Icons.lock_rounded : Icons.explore_rounded,
      onTap: onTap,
    );
  }

  Widget _buildSheetChip({
    required String label,
    required bool selected,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return _FilterChip(
      label: label,
      selected: selected,
      icon: icon,
      onTap: onTap,
      usePadding: false,
    );
  }

  IconData _iconForActivityFilter(String text) {
    switch (text) {
      case 'Senderismo':
        return Icons.hiking_rounded;
      case 'Ciclismo':
        return Icons.directions_bike_rounded;
      case 'Running':
        return Icons.directions_run_rounded;
      case _allFilter:
      default:
        return Icons.explore_rounded;
    }
  }

  IconData _iconForPreferenceFilter(String text) {
    switch (text) {
      case 'Mas cortas':
        return Icons.straight_rounded;
      case 'Mas desafiantes':
        return Icons.landscape_rounded;
      case _allPreferenceFilter:
      default:
        return Icons.tune_rounded;
    }
  }

  IconData _iconForVisibilityFilter(String text) {
  switch (text) {
    case 'Públicas':
      return Icons.public_rounded;
    case 'Privadas':
      return Icons.lock_rounded;
    case _allVisibilityFilter:
    default:
      return Icons.visibility_rounded;
  }
}
  String _labelForRoutingPreference(RoutingPreference preference) {
    switch (preference) {
      case RoutingPreference.shortest:
        return 'Mas cortas';
      case RoutingPreference.mostChallenging:
        return 'Mas desafiantes';
    }
  }

 String _labelForVisibility(StoredRouteVisibility visibility) {
  switch (visibility) {
    case StoredRouteVisibility.public:
      return 'Públicas';
    case StoredRouteVisibility.private:
      return 'Privadas';
  }
}

  Widget _buildSavedRoutesEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: surfaceLowest,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: const Column(
        children: [
          Icon(Icons.bookmark_outline_rounded, size: 44, color: primaryColor),
          SizedBox(height: 14),
          Text(
            'Guardadas por ti',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: primaryColor,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Todavia no has guardado rutas publicas de otros usuarios desde Explorar.',
            textAlign: TextAlign.center,
            style: TextStyle(color: textMuted, height: 1.45),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: surfaceLowest,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: const Column(
        children: [
          Icon(Icons.map_outlined, size: 44, color: primaryColor),
          SizedBox(height: 14),
          Text(
            'No hay rutas para este filtro',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: primaryColor,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Ajusta los filtros o guarda una ruta desde Explorar para verla aqui.',
            textAlign: TextAlign.center,
            style: TextStyle(color: textMuted, height: 1.45),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: surfaceLowest,
            borderRadius: BorderRadius.circular(28),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: Colors.redAccent, size: 40),
              SizedBox(height: 10),
              Text(
                'No se pudieron cargar tus rutas guardadas.',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _MyRoutesTab { creations, saved }

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.icon,
    required this.onTap,
    this.usePadding = true,
  });

  final String label;
  final bool selected;
  final IconData icon;
  final VoidCallback onTap;
  final bool usePadding;

  @override
  Widget build(BuildContext context) {
    final foreground = selected
        ? _MyRoutesScreenState.primaryColor
        : _MyRoutesScreenState.textMuted;

    final chip = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFFDAEBDD)
                : _MyRoutesScreenState.surfaceLow,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? const Color(0xFFB6D3BC)
                  : _MyRoutesScreenState.borderColor.withValues(alpha: 0.65),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: foreground),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: foreground,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (!usePadding) return chip;

    return Padding(padding: const EdgeInsets.only(right: 10), child: chip);
  }
}
