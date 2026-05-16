import 'package:flutter/material.dart';

import '../navigation/auth_gate.dart';
import '../screens/auth/login_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';

class AppRoutes {
  static const String root = '/';
  static const String login = '/login';
  static const String dashboard = '/dashboard';

  static Map<String, WidgetBuilder> get routes {
    return {
      root: (_) => AuthGate(),
      login: (_) => LoginScreen(),
      dashboard: (_) => DashboardScreen(),
    };
  }
}
