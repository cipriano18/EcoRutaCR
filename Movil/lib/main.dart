import 'package:ecoruta/core/providers/location_provider.dart';
import 'package:ecoruta/features/profile/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:ecoruta/core/routes/app_routes.dart';
import 'package:ecoruta/core/routes/screens/app_bootstrap_screen.dart';

/// Inicializa Firebase y registra los providers globales de la app.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
      ],
      child: const EcoRutaApp(),
    ),
  );
}

/// Widget raíz encargado de configurar tema y navegación principal.
class EcoRutaApp extends StatelessWidget {
  const EcoRutaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EcoRuta',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF012D1D),
          brightness: Brightness.light,
        ),
        fontFamily: 'Arial',
      ),
      home: const AppBootstrapScreen(),
      routes: AppRoutes.routes,
    );
  }
}
