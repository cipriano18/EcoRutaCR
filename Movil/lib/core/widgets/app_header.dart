import 'package:ecoruta/core/routes/main_shell.dart';
import 'package:ecoruta/features/profile/providers/user_provider.dart';
import 'package:ecoruta/features/home/screens/home_screen.dart';
import 'package:ecoruta/features/profile/screens/profile_screen.dart';
import 'package:ecoruta/core/services/auth_service.dart';
import 'package:ecoruta/core/widgets/avatar_image.dart';
import 'package:ecoruta/core/widgets/confirm_dialog.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// AppBar reutilizable con acceso rápido a perfil y cierre de sesión.
///
/// Implementa [PreferredSizeWidget] para integrarse directamente en
/// [Scaffold.appBar] y permitir contenido inferior opcional mediante [bottom].
class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  const AppHeader({
    super.key,
    this.title = 'EcoRutaCR',
    this.bottom,
    this.backgroundColor,
  });

  static const _primaryColor = Color(0xFF012D1D);
  static const _primaryFixed = Color(0xFFC1ECD4);
  static const _surfaceColor = Color(0xFFF8F9FA);
  static const _textMuted = Color(0xFF5E6762);

  /// Título mostrado en el centro del encabezado.
  final String title;

  /// Widget inferior opcional, como pestañas o filtros.
  final PreferredSizeWidget? bottom;

  /// Color de fondo del encabezado; usa blanco translúcido si es nulo.
  final Color? backgroundColor;

  /// Cierra sesión y redirige al flujo público de la aplicación.
  Future<void> _handleLogout(BuildContext context) async {
    final shouldLogout = await ConfirmDialog.mostrar(
      context,
      titulo: 'Cerrar sesion',
      mensaje:
          'Estas seguro de que quieres cerrar tu sesion actual en EcoRuta?',
      textoConfirmar: 'Cerrar sesion',
    );

    if (!shouldLogout || !context.mounted) return;

    await AuthService().logout();

    if (!context.mounted) return;

    // El perfil en memoria se limpia antes de reconstruir el flujo público
    // para evitar que widgets posteriores lean datos de una sesión cerrada.
    Provider.of<UserProvider>(context, listen: false).clear();

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (_) => false,
    );
  }

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: backgroundColor ?? Colors.white.withValues(alpha: 0.92),
      elevation: 0,
      scrolledUnderElevation: 0,
      leadingWidth: 72,
      leading: PopupMenuButton<String>(
        tooltip: 'Abrir menu',
        color: Colors.white,
        surfaceTintColor: Colors.white,
        shadowColor: Colors.black.withValues(alpha: 0.12),
        elevation: 14,
        offset: const Offset(8, 12),
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        icon: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: _surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _primaryColor.withValues(alpha: 0.08)),
          ),
          child: const Icon(Icons.menu_rounded, color: _primaryColor),
        ),
        onSelected: (value) async {
          if (value != 'logout') return;
          await _handleLogout(context);
        },
        itemBuilder: (context) => [
          const PopupMenuItem<String>(
            enabled: false,
            padding: EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'OPCIONES',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: _textMuted,
                    letterSpacing: 1.2,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Gestiona tu sesion actual',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _primaryColor,
                  ),
                ),
              ],
            ),
          ),
          const PopupMenuDivider(height: 1),
          PopupMenuItem<String>(
            value: 'logout',
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3EE),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.logout_rounded,
                    color: Color(0xFFBA1A1A),
                    size: 18,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Cerrar sesion',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFBA1A1A),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/images/logo/logo verde.png',
            width: 24,
            height: 24,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 6),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: _primaryColor,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
      centerTitle: true,
      bottom: bottom,
      actions: [
        Consumer<UserProvider>(
          builder: (context, userProvider, _) {
            final avatarId = userProvider.user?.avatarId ?? 0;

            return Padding(
              padding: const EdgeInsets.only(right: 16),
              child: GestureDetector(
                onTap: () {
                  final didNavigateInShell = MainShell.navigateToTab(
                    context,
                    3,
                  );
                  if (didNavigateInShell) return;

                  // Cuando el encabezado vive fuera de [MainShell], el perfil
                  // se abre con navegación normal como alternativa.
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  );
                },
                child: Container(
                  width: 36,
                  height: 36,
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _primaryColor.withValues(alpha: 0.08),
                    border: Border.all(
                      color: _primaryColor.withValues(alpha: 0.14),
                    ),
                  ),
                  child: AvatarImage(
                    avatarId: avatarId,
                    size: 32,
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
