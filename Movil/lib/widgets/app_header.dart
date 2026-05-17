import 'package:ecoruta/providers/user_provider.dart';
import 'package:ecoruta/navigation/main_shell.dart';
import 'package:ecoruta/screens/home/home_screen.dart';
import 'package:ecoruta/screens/profile/profile_screen.dart';
import 'package:ecoruta/services/auth_service.dart';
import 'package:ecoruta/widgets/avatar_image.dart';
import 'package:ecoruta/widgets/confirm_dialog.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// AppBar reutilizable con acceso rápido a cierre de sesión.
class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  const AppHeader({
    super.key,
    this.title = 'EcoRutaCR',
    this.bottom,
    this.backgroundColor,
  });

  static const _primaryColor = Color(0xFF012D1D);
  static const _primaryFixed = Color(0xFFC1ECD4);

  final String title;
  final PreferredSizeWidget? bottom;
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
      leading: PopupMenuButton<String>(
        icon: const Icon(Icons.menu_rounded, color: _primaryColor),
        onSelected: (value) async {
          if (value != 'logout') return;
          await _handleLogout(context);
        },
        itemBuilder: (context) => const [
          PopupMenuItem<String>(value: 'logout', child: Text('Cerrar sesión')),
        ],
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.eco_rounded, color: _primaryFixed, size: 22),
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
