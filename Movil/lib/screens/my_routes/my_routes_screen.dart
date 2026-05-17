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
    'Más cortas',
    'Más rapidas',
    'Más desafiantes',
  ];
  static const _allVisibilityFilter = 'Todas';
  static const List<String> _visibilityFilters = [
    _allVisibilityFilter,
    'Publicas',
    'Privadas',
  ];

  final SavedRoutesService _savedRoutesService = SavedRoutesService();

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

  /// Elimina una ruta tras confirmar la intención del usuario.
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
          stream: _savedRoutesService.watchUserRoutes(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _buildErrorState();
            }

            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(color: primaryColor),
              );
            }

            final routes = snapshot.data ?? const <StoredRoute>[];
            final visibleRoutes = _filterRoutes(routes);

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              children: [
                _buildHeader(savedRoutesCount: routes.length),
                const SizedBox(height: 24),
                _buildFilters(),
                const SizedBox(height: 20),
                if (visibleRoutes.isEmpty)
                  _buildEmptyState()
                else
                  ...visibleRoutes.map(
                    (route) => MyRouteCard(
                      route: route,
                      onOpen: () => _openRoute(route),
                      onDelete: () => _removeRoute(route),
                      onEdit: route.isPublic ? null : () => _editRoute(route),
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
          'MI BIBLIOTECA',
          style: TextStyle(
            fontSize: 12,
            letterSpacing: 2,
            fontWeight: FontWeight.w800,
            color: Colors.orange,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Mis rutas',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: primaryColor,
              ),
            ),
            Text(
              '$savedRoutesCount Guardadas',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        const Text(
          'Revive tus rutas guardadas y decide si compartirlas o mantenerlas privadas.',
          style: TextStyle(color: Colors.black54),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filtrar rutas',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          _buildFilterSection(
            title: 'Actividad',
            chips: _filters
                .map(
                  (filter) =>
                      _filterChip(filter, selected: _selectedFilter == filter),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 16),
          _buildFilterSection(
            title: 'Tipo de ruta',
            chips: _preferenceFilters
                .map(
                  (filter) => _preferenceFilterChip(
                    filter,
                    selected: _selectedPreferenceFilter == filter,
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 16),
          _buildFilterSection(
            title: 'Visibilidad',
            chips: _visibilityFilters
                .map(
                  (filter) => _visibilityFilterChip(
                    filter,
                    selected: _selectedVisibilityFilter == filter,
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 6),
          const Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Desliza para ver mas',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(width: 6),
                Icon(Icons.arrow_forward_rounded, size: 14, color: Colors.grey),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection({
    required String title,
    required List<Widget> chips,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: primaryColor,
          ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: chips),
        ),
      ],
    );
  }

  Widget _filterChip(String text, {bool selected = false}) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedFilter = text;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? primaryColor : surfaceLow,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            text,
            style: TextStyle(
              color: selected ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _preferenceFilterChip(String text, {bool selected = false}) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedPreferenceFilter = text;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? primaryColor : surfaceLow,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            text,
            style: TextStyle(
              color: selected ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _visibilityFilterChip(String text, {bool selected = false}) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedVisibilityFilter = text;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? primaryColor : surfaceLow,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            text,
            style: TextStyle(
              color: selected ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  String _labelForRoutingPreference(RoutingPreference preference) {
    switch (preference) {
      case RoutingPreference.shortest:
        return 'Más cortas';
      case RoutingPreference.fastest:
        return 'Más rapidas';
      case RoutingPreference.mostChallenging:
        return 'Más desafiantes';
    }
  }

  String _labelForVisibility(StoredRouteVisibility visibility) {
    switch (visibility) {
      case StoredRouteVisibility.public:
        return 'Publicas';
      case StoredRouteVisibility.private:
        return 'Privadas';
    }
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Column(
        children: [
          Icon(Icons.map_outlined, size: 44, color: Color(0xFF012D1D)),
          SizedBox(height: 12),
          Text(
            'No hay rutas para este filtro',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: primaryColor,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Guarda una ruta desde Explorar para verla aqui.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54, height: 1.4),
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
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
