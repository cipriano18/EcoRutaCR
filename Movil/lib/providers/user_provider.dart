import 'package:flutter/material.dart';
import 'package:ecoruta/models/user_model.dart';

/// Mantiene en memoria el perfil del usuario autenticado.
class UserProvider extends ChangeNotifier {
  UserModel? _user;

  /// Usuario actual disponible para la interfaz.
  UserModel? get user => _user;

  /// Actualiza el usuario global y notifica a los listeners dependientes.
  void setUser(UserModel user) {
    _user = user;
    notifyListeners();
  }

  /// Limpia la sesión local al cerrar sesión o reiniciar contexto.
  void clear() {
    _user = null;
    notifyListeners();
  }
}
