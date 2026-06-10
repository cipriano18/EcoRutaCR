import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:ecoruta/features/routes/models/guided_saved_route.dart';
import 'package:ecoruta/features/profile/providers/user_provider.dart';
import 'package:ecoruta/features/routes/screens/explore_screen.dart';
import 'package:ecoruta/features/map/screens/map_screen.dart';
import 'package:ecoruta/features/routes/screens/my_routes_screen.dart';
import 'package:ecoruta/features/profile/screens/profile_screen.dart';
import 'package:ecoruta/core/services/auth_service.dart';

/// Contenedor principal que mantiene la navegación inferior de la app.
///
/// Conserva las pantallas principales dentro de un [IndexedStack] para evitar
/// perder estado al cambiar entre mapa, exploración, rutas y perfil.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  static _MainShellState? _activeState;

  /// Permite cambiar de pestaña desde pantallas hijas sin exponer el estado.
  static bool navigateToTab(BuildContext context, int index) {
    final state =
        context.findAncestorStateOfType<_MainShellState>() ?? _activeState;
    if (state == null) return false;
    state._goToTab(index);
    return true;
  }

  /// Abre una ruta guardada en el mapa principal en modo guiado.
  static bool openGuidedSavedRoute(
    BuildContext context,
    GuidedSavedRoute route,
  ) {
    final state =
        context.findAncestorStateOfType<_MainShellState>() ?? _activeState;
    if (state == null) return false;
    return state._openGuidedSavedRoute(route);
  }

  /// Indica si el mapa ya tiene una ruta en proceso que impide cargar otra.
  static bool hasActiveTrackedRoute(BuildContext context) {
    final state =
        context.findAncestorStateOfType<_MainShellState>() ?? _activeState;
    return state?._hasActiveTrackedRoute ?? false;
  }

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  static const _primaryColor = Color(0xFF012D1D);

  final GlobalKey<MapScreenState> _mapScreenKey = GlobalKey<MapScreenState>();

  late final List<Widget> _screens;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    MainShell._activeState = this;
    _screens = [
      MapScreen(key: _mapScreenKey),
      const ExploreScreen(),
      const MyRoutesScreen(),
      const ProfileScreen(),
    ];
    _syncCurrentUserProfile();
  }

  @override
  void dispose() {
    if (identical(MainShell._activeState, this)) {
      MainShell._activeState = null;
    }
    super.dispose();
  }

  /// Sincroniza el perfil autenticado al entrar al shell principal.
  Future<void> _syncCurrentUserProfile() async {
    final userProfile = await AuthService().getCurrentUserProfile();
    if (!mounted || userProfile == null) return;

    Provider.of<UserProvider>(context, listen: false).setUser(userProfile);
  }

  /// Cambia la pestaña activa preservando el estado del resto de vistas.
  void _goToTab(int index) {
    if (_currentIndex == index) return;
    setState(() => _currentIndex = index);
  }

  bool get _hasActiveTrackedRoute =>
      _mapScreenKey.currentState?.hasBlockingActiveRoute ?? false;

  /// Carga [route] en el mapa si no hay una ruta activa que pueda perderse.
  bool _openGuidedSavedRoute(GuidedSavedRoute route) {
    if (_hasActiveTrackedRoute) {
      return false;
    }

    _goToTab(0);
    // La carga se difiere hasta el siguiente frame para asegurar que el mapa
    // ya esté visible y su estado pueda recibir la ruta guiada.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _mapScreenKey.currentState?.loadGuidedSavedRoute(route);
    });
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await SystemNavigator.pop();
      },
      child: Scaffold(
        body: IndexedStack(index: _currentIndex, children: _screens),
        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 32,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: 'Inicio',
                active: _currentIndex == 0,
                onTap: () => _goToTab(0),
                activeColor: _primaryColor,
              ),
              _NavItem(
                icon: Icons.explore_rounded,
                label: 'Explorar',
                active: _currentIndex == 1,
                onTap: () => _goToTab(1),
                activeColor: _primaryColor,
              ),
              _NavItem(
                icon: Icons.directions_run_rounded,
                label: 'Mis rutas',
                active: _currentIndex == 2,
                onTap: () => _goToTab(2),
                activeColor: _primaryColor,
              ),
              _NavItem(
                icon: Icons.person_rounded,
                label: 'Perfil',
                active: _currentIndex == 3,
                onTap: () => _goToTab(3),
                activeColor: _primaryColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Ítem visual reutilizable para la barra de navegación inferior.
class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
    required this.activeColor,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active
              ? activeColor.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24, color: active ? activeColor : Colors.grey),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: active ? activeColor : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
