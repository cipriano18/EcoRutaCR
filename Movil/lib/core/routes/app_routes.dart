import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:ecoruta/core/routes/main_shell.dart';
import 'package:ecoruta/features/routes/providers/explore_provider.dart';
import 'package:ecoruta/features/auth/screens/login_screen.dart';
import 'package:ecoruta/features/auth/screens/register_screen.dart';
import 'package:ecoruta/features/routes/screens/overpass_test_screen.dart';
import 'package:ecoruta/features/home/screens/home_screen.dart';

/// Centraliza las rutas nombradas y sus dependencias de arranque.
///
/// Mantiene los identificadores usados por [MaterialApp] en un único lugar
/// para evitar rutas literales dispersas por la aplicación.
class AppRoutes {
  /// Ruta de bienvenida de la aplicación.
  static const String home = '/home';

  /// Ruta de inicio de sesión.
  static const String login = '/login';

  /// Ruta de registro.
  static const String register = '/register';

  /// Ruta de pruebas manuales para Overpass.
  static const String overpassTest = '/overpass-test';

  /// Ruta del contenedor principal con navegación inferior.
  static const String shell = '/shell';

  /// Mapa de rutas que usa [MaterialApp] para resolver navegación.
  ///
  /// Las pantallas que requieren estado propio declaran aquí sus providers
  /// para que cada entrada del flujo reciba dependencias consistentes.
  static Map<String, WidgetBuilder> get routes => {
    home: (_) => const HomeScreen(),
    login: (_) => const LoginScreen(),
    register: (_) => const RegisterScreen(),
    shell: (_) => const MainShell(),
    overpassTest: (_) => ChangeNotifierProvider(
      create: (_) => ExploreProvider(),
      child: const OverpassTestScreen(),
    ),
  };
}
