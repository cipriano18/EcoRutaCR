import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../navigation/main_shell.dart';
import '../providers/explore_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/explore/overpass_test_screen.dart';
import '../screens/home/home_screen.dart';

/// Centraliza las rutas nombradas y sus dependencias de arranque.
class AppRoutes {
  /// Ruta de bienvenida de la aplicación.
  static const String home = '/';

  /// Ruta de inicio de sesión.
  static const String login = '/login';

  /// Ruta de registro.
  static const String register = '/register';

  /// Ruta de pruebas manuales para Overpass.
  static const String overpassTest = '/overpass-test';

  /// Ruta del contenedor principal con navegación inferior.
  static const String shell = '/shell';

  /// Mapa de rutas que usa [MaterialApp] para resolver navegación.
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
