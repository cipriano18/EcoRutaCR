import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/admin_session_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminSessionProvider>(
      builder: (context, session, _) {
        if (session.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (session.isAuthenticated) {
          return DashboardScreen();
        }

        return LoginScreen();
      },
    );
  }
}
