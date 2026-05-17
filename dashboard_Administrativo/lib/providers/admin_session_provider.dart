import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/admin_model.dart';
import '../services/admin_auth_service.dart';

class AdminSessionProvider extends ChangeNotifier {
  AdminSessionProvider({AdminAuthService? authService})
    : _authService = authService ?? AdminAuthService() {
    _initialize();
  }

  final AdminAuthService _authService;
  StreamSubscription<User?>? _subscription;

  AdminModel? _admin;
  bool _isLoading = true;
  String? _errorMessage;

  AdminModel? get admin => _admin;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _admin != null;

  Future<void> _initialize() async {
    _isLoading = true;
    notifyListeners();

    _subscription = _authService.authStateChanges().listen(_handleAuthChanged);

    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      _admin = null;
      _isLoading = false;
      notifyListeners();
      return;
    }

    await _handleAuthChanged(currentUser);
  }

  Future<void> _handleAuthChanged(User? user) async {
    if (user != null) {
      _isLoading = true;
      notifyListeners();
    }

    if (user == null) {
      _admin = null;
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      _admin = await _authService.getCurrentAdminProfile();
      if (_admin == null) {
        _errorMessage = 'La cuenta autenticada no pertenece a admins.';
        await _authService.logout();
      }
    } catch (error, stackTrace) {
      debugPrint('AdminSessionProvider._handleAuthChanged error: $error');
      debugPrint('$stackTrace');
      _admin = null;
      _errorMessage = 'No se pudo cargar la sesion administrativa.';
    }

    _isLoading = false;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
