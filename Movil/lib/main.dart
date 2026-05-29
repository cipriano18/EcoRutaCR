import 'package:ecoruta/firebase_options.dart';
import 'package:ecoruta/navigation/main_shell.dart';
import 'package:ecoruta/providers/user_provider.dart';
import 'package:ecoruta/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'routes/app_routes.dart';
import 'screens/home/home_screen.dart';

/// Inicializa Firebase y registra los providers globales de la app.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await AuthService().initializeRememberedSession();

  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => UserProvider())],
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
      home: FirebaseAuth.instance.currentUser == null
          ? const HomeScreen()
          : const MainShell(),
      routes: AppRoutes.routes,
    );
  }
}

