import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'navigation/auth_gate.dart';
import 'providers/admin_session_provider.dart';
import 'routes/app_routes.dart';
import 'services/admin_auth_service.dart';
import 'theme/app_theme.dart';
import 'services/admin_service.dart';
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    runApp(const EcoRutaAdminApp());
  } catch (error) {
    runApp(
      StartupErrorApp(message: 'No se pudo inicializar Firebase.\n$error'),
    );
  }
}

class EcoRutaAdminApp extends StatelessWidget {
  const EcoRutaAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(create: (_) => AdminAuthService()),
        ChangeNotifierProvider(create: (_) => AdminSessionProvider()),
        Provider(
  create: (_) => AdminService(),
),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'EcoRuta Admin',
        theme: AppTheme.lightTheme,
        initialRoute: AppRoutes.root,
        routes: AppRoutes.routes,
        onUnknownRoute: (_) =>
            MaterialPageRoute<void>(builder: (_) => AuthGate()),
      ),
    );
  }
}

class StartupErrorApp extends StatelessWidget {
  const StartupErrorApp({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 56,
                    color: Colors.redAccent,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Error de arranque',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  Text(message, textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
