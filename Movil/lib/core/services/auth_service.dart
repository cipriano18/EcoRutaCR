import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecoruta/features/profile/models/user_model.dart';
import 'package:ecoruta/core/services/health_inference.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Administra autenticación y perfil persistido del usuario en Firebase.
///
/// Coordina [FirebaseAuth], documentos privados de `users`, perfiles públicos
/// y preferencias locales relacionadas con el inicio de sesión.
class AuthService {
  static const _rememberMeKey = 'auth.remember_me';
  static const _rememberedEmailKey = 'auth.remembered_email';

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Aplica al arrancar la preferencia local que controla si la sesión se conserva.
  Future<void> initializeRememberedSession() async {
    final prefs = await SharedPreferences.getInstance();
    final shouldRemember = prefs.getBool(_rememberMeKey) ?? false;

    if (!shouldRemember && _auth.currentUser != null) {
      // Firebase puede restaurar sesión automáticamente. Si el usuario no pidió
      // recordarla, se cierra antes de resolver el flujo inicial.
      await _auth.signOut();
    }
  }

  /// Devuelve la configuración local usada por el checkbox de recordarme.
  Future<RememberedLoginState> getRememberedLoginState() async {
    final prefs = await SharedPreferences.getInstance();
    return RememberedLoginState(
      rememberMe: prefs.getBool(_rememberMeKey) ?? false,
      email: (prefs.getString(_rememberedEmailKey) ?? '').trim(),
    );
  }

  /// Persiste la preferencia de recordarme y el correo asociado al acceso.
  Future<void> saveRememberedLogin({
    required bool rememberMe,
    required String email,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_rememberMeKey, rememberMe);

    if (rememberMe) {
      await prefs.setString(_rememberedEmailKey, email.trim());
      return;
    }

    await prefs.remove(_rememberedEmailKey);
  }

  /// Inicia sesión con correo y contraseña normalizados.
  Future<UserCredential> login({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
    await _syncPublicProfileFromPrivateDoc(credential.user?.uid);
    return credential;
  }

  /// Registra un usuario nuevo y crea su perfil base en Firestore.
  Future<UserCredential> register({
    required String fullName,
    required String email,
    required String address,
    required String password,
    required int avatarId,
    required String favoriteActivity,
    required double weightKg,
    required int heightCm,
    required DateTime birthDate,
  }) async {
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );

    final user = userCredential.user;

    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-null',
        message: 'No se pudo crear el usuario',
      );
    }

    final inferredAt = DateTime.now();
    final healthInference = HealthInferenceEngine.evaluate(
      UserHealthInput(
        weightKg: weightKg,
        heightCm: heightCm.toDouble(),
        birthDate: birthDate,
        favoriteActivity: favoriteActivity.trim(),
        completedRoutes: 0,
        kmCounter: 0,
      ),
    );

    // El documento privado conserva datos sensibles y métricas completas del
    // perfil. El documento público se sincroniza aparte con campos mínimos.
    await _firestore.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'email': email.trim(),
      'fullName': fullName.trim(),
      'address': address.trim(),
      'avatarId': avatarId,
      'favoriteActivity': favoriteActivity.trim(),
      'weight_kg': weightKg,
      'height_cm': heightCm,
      'birth_date': Timestamp.fromDate(birthDate),
      'completed_routes': 0,
      'km_counter': 0,
      'streak_started_at': null,
      'streak_deadline_at': null,
      'routes_per_week_avg': null,
      'km_per_week_avg': null,
      'minutes_per_week_avg': null,
      'activity_consistency_score': null,
      'activity_level': null,
      'wellness_status': null,
      'wellness_score': null,
      ...healthInference.toInitialFirestorePatch(inferredAt: inferredAt),

      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _syncPublicUserProfile(
      uid: user.uid,
      fullName: fullName.trim(),
      avatarId: avatarId,
      favoriteActivity: favoriteActivity.trim(),
      isCreate: true,
    );

    return userCredential;
  }

  /// Obtiene el documento crudo de un usuario por UID.
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.data();
  }

  /// Recupera y normaliza el perfil del usuario autenticado.
  Future<UserModel?> getCurrentUserProfile() async {
    final user = _auth.currentUser;

    if (user == null) return null;

    final doc = await _firestore.collection('users').doc(user.uid).get();

    if (!doc.exists || doc.data() == null) return null;

    final data = Map<String, dynamic>.from(doc.data()!);
    await _syncPublicProfileFromPrivateDoc(user.uid, currentData: data);
    final syncedData = await _resetExpiredStreakIfNeeded(
      uid: user.uid,
      data: data,
    );
    return UserModel.fromMap(syncedData);
  }

  /// Actualiza únicamente el avatar elegido por el usuario.
  Future<void> updateAvatar(int avatarId) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-null',
        message: 'No hay un usuario autenticado',
      );
    }

    await _firestore.collection('users').doc(user.uid).update({
      'avatarId': avatarId,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    final snapshot = await _firestore.collection('users').doc(user.uid).get();
    final data = snapshot.data() ?? const <String, dynamic>{};
    // El avatar también vive en el perfil público para que otras pantallas lo
    // puedan mostrar sin leer el documento privado del usuario.
    await _syncPublicUserProfile(
      uid: user.uid,
      fullName: (data['fullName'] as String? ?? 'Usuario').trim(),
      avatarId: avatarId,
      favoriteActivity: (data['favoriteActivity'] as String? ?? '').trim(),
    );
  }

  /// Actualiza los campos editables del perfil.
  Future<void> updateProfile({
    required String fullName,
    required String address,
    required String favoriteActivity,
    double? weightKg,
    double? heightCm,
    DateTime? birthDate,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-null',
        message: 'No hay un usuario autenticado',
      );
    }

    final userDoc = _firestore.collection('users').doc(user.uid);

    final snapshot = await userDoc.get();

    final currentData = Map<String, dynamic>.from(snapshot.data() ?? {});

    // Se mezclan los valores editados con el estado actual para recalcular
    // inferencias sin perder métricas de actividad ya persistidas.
    final nextHealthInput = UserHealthInput.fromUserMap({
      ...currentData,
      'weight_kg': weightKg,
      'height_cm': heightCm,
      'birth_date': birthDate,
      'favoriteActivity': favoriteActivity.trim(),
    });

    final healthInference = HealthInferenceEngine.evaluate(nextHealthInput);

    final patch = <String, dynamic>{
      'fullName': fullName.trim(),
      'address': address.trim(),
      'favoriteActivity': favoriteActivity.trim(),

      'weight_kg': weightKg,
      'height_cm': heightCm,

      'birth_date': birthDate == null ? null : Timestamp.fromDate(birthDate),

      ...healthInference.toInitialFirestorePatch(),

      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (healthInference.activityLevel != null &&
        nextHealthInput.activityConsistencyScore != null) {
      // Las inferencias de actividad solo se actualizan cuando existen
      // agregados suficientes para no sobrescribirlas con datos parciales.
      patch.addAll({
        'activity_level': healthInference.activityLevel,
        'wellness_status': healthInference.wellnessStatus,
        'wellness_score': healthInference.wellnessScore,
      });
    }

    await userDoc.update(patch);
    final currentAvatarId = (currentData['avatarId'] as num?)?.toInt() ?? 0;
    await _syncPublicUserProfile(
      uid: user.uid,
      fullName: fullName.trim(),
      avatarId: currentAvatarId,
      favoriteActivity: favoriteActivity.trim(),
    );
  }

  /// Reautentica al usuario antes de cambiar su contraseña.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;

    if (user == null || user.email == null) {
      throw FirebaseAuthException(
        code: 'user-null',
        message: 'No hay un usuario autenticado',
      );
    }

    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword.trim(),
    );

    await user.reauthenticateWithCredential(credential);
    await user.updatePassword(newPassword.trim());
  }

  /// Elimina la cuenta autenticada y restaura el perfil si falla Auth.
  Future<void> deleteCurrentAccount({required String currentPassword}) async {
    final user = _auth.currentUser;

    if (user == null || user.email == null) {
      throw FirebaseAuthException(
        code: 'user-null',
        message: 'No hay un usuario autenticado',
      );
    }

    final uid = user.uid;
    final normalizedPassword = currentPassword.trim();

    if (normalizedPassword.isEmpty) {
      throw FirebaseAuthException(
        code: 'missing-password',
        message: 'Debes confirmar tu contraseña actual',
      );
    }

    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: normalizedPassword,
    );
    await user.reauthenticateWithCredential(credential);

    final userDocRef = _firestore.collection('users').doc(uid);
    final userDocSnapshot = await userDocRef.get();
    final backupData = userDocSnapshot.data();

    await userDocRef.delete();
    await _firestore.collection('public_user_profiles').doc(uid).delete();

    try {
      await user.delete();
    } catch (e) {
      // Firebase Auth puede rechazar la eliminación aunque Firestore ya haya
      // borrado datos. Se restaura el documento privado para no dejar la cuenta
      // autenticada sin perfil asociado.
      if (backupData != null) {
        await userDocRef.set(backupData);
      }
      rethrow;
    }
  }

  /// Registra el cumplimiento semanal de una ruta para mantener la racha.
  Future<UserModel?> registerWeeklyRouteCompletion({
    required double distanceKm,
    required double durationMinutes,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-null',
        message: 'No hay un usuario autenticado',
      );
    }

    final userDoc = _firestore.collection('users').doc(user.uid);
    final snapshot = await userDoc.get();
    final data = Map<String, dynamic>.from(snapshot.data() ?? {});
    final now = DateTime.now();

    final startedAt = _readDate(data['streak_started_at']);
    final deadlineAt = _readDate(data['streak_deadline_at']);
    final hasActiveStreak = deadlineAt != null && !deadlineAt.isBefore(now);
    final nextDeadline = now.add(const Duration(days: 7));
    final eventsCollection = userDoc.collection('completed_route_events');
    final eventDoc = eventsCollection.doc();
    final windowStart = _activityWindowStart(now);
    final recentEventsSnapshot = await eventsCollection
        .where(
          'completedAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(windowStart),
        )
        .get();
    final recentEvents = [
      for (final doc in recentEventsSnapshot.docs)
        _CompletedRouteEvent.fromMap(doc.data()),
      _CompletedRouteEvent(
        completedAt: now,
        distanceKm: distanceKm,
        durationMinutes: durationMinutes,
      ),
    ];
    // Los agregados incluyen el evento actual antes de persistir el batch para
    // que el perfil actualizado refleje inmediatamente la ruta completada.
    final aggregates = _computeActivityAggregates(
      events: recentEvents,
      referenceTime: now,
    );
    final nextCompletedRoutes =
        ((data['completed_routes'] as num?)?.toInt() ?? 0) + 1;
    final nextKmCounter =
        ((data['km_counter'] as num?)?.toDouble() ?? 0) + distanceKm;
    final healthInference = HealthInferenceEngine.evaluate(
      UserHealthInput(
        weightKg: _toDouble(data['weight_kg']),
        heightCm: _toDouble(data['height_cm']),
        birthDate: _readDate(data['birth_date']),
        favoriteActivity: data['favoriteActivity']?.toString(),
        completedRoutes: nextCompletedRoutes,
        kmCounter: nextKmCounter,
        routesPerWeekAvg: aggregates.routesPerWeekAverage,
        kmPerWeekAvg: aggregates.kmPerWeekAverage,
        minutesPerWeekAvg: aggregates.minutesPerWeekAverage,
        activityConsistencyScore: aggregates.activityConsistencyScore,
      ),
    );

    final batch = _firestore.batch();
    batch.set(eventDoc, {
      'completedAt': Timestamp.fromDate(now),
      'distanceKm': distanceKm,
      'durationMinutes': durationMinutes,
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.set(userDoc, {
      // Si la racha expiró, se reinicia desde la ruta actual. Si sigue activa,
      // se conserva su fecha original y se extiende el vencimiento.
      'streak_started_at': hasActiveStreak ? startedAt ?? now : now,
      'streak_deadline_at': nextDeadline,

      'completed_routes': nextCompletedRoutes,
      'km_counter': nextKmCounter,
      'routes_per_week_avg': aggregates.routesPerWeekAverage,
      'km_per_week_avg': aggregates.kmPerWeekAverage,
      'minutes_per_week_avg': aggregates.minutesPerWeekAverage,
      'activity_consistency_score': aggregates.activityConsistencyScore,
      ...healthInference.toFirestorePatch(inferredAt: now),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await batch.commit();

    final refreshed = await userDoc.get();
    if (!refreshed.exists || refreshed.data() == null) return null;
    return UserModel.fromMap(refreshed.data()!);
  }

  /// Limpia rachas vencidas al cargar el perfil y retorna datos normalizados.
  Future<Map<String, dynamic>> _resetExpiredStreakIfNeeded({
    required String uid,
    required Map<String, dynamic> data,
  }) async {
    final deadlineAt = _readDate(data['streak_deadline_at']);
    if (deadlineAt == null || !deadlineAt.isBefore(DateTime.now())) {
      return data;
    }

    await _firestore.collection('users').doc(uid).set({
      'streak_started_at': null,
      'streak_deadline_at': null,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final normalized = Map<String, dynamic>.from(data);
    normalized['streak_started_at'] = null;
    normalized['streak_deadline_at'] = null;
    return normalized;
  }

  /// Lee fechas provenientes de Firestore, Dart o texto ISO.
  DateTime? _readDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  /// Convierte valores numéricos dinámicos a [double].
  double? _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return null;
  }

  /// Sincroniza el documento público mínimo usado por vistas compartidas.
  Future<void> _syncPublicUserProfile({
    required String uid,
    required String fullName,
    required int avatarId,
    required String favoriteActivity,
    bool isCreate = false,
  }) {
    final payload = <String, dynamic>{
      'uid': uid,
      'fullName': fullName,
      'avatarId': avatarId,
      'favoriteActivity': favoriteActivity,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (isCreate) {
      payload['createdAt'] = FieldValue.serverTimestamp();
    }
    return _firestore
        .collection('public_user_profiles')
        .doc(uid)
        .set(payload, SetOptions(merge: true));
  }

  /// Reconstruye el perfil público desde el documento privado del usuario.
  Future<void> _syncPublicProfileFromPrivateDoc(
    String? uid, {
    Map<String, dynamic>? currentData,
  }) async {
    if (uid == null || uid.isEmpty) return;

    final data =
        currentData ??
        (await _firestore.collection('users').doc(uid).get()).data() ??
        const <String, dynamic>{};
    if (data.isEmpty) return;

    final fullName = (data['fullName'] as String? ?? '').trim();
    if (fullName.isEmpty) return;

    await _syncPublicUserProfile(
      uid: uid,
      fullName: fullName,
      avatarId: (data['avatarId'] as num?)?.toInt() ?? 0,
      favoriteActivity: (data['favoriteActivity'] as String? ?? '').trim(),
    );
  }

  /// Retorna el inicio de la ventana usada para promedios de actividad.
  DateTime _activityWindowStart(DateTime referenceTime) {
    final startOfWeek = DateTime(
      referenceTime.year,
      referenceTime.month,
      referenceTime.day,
    ).subtract(Duration(days: referenceTime.weekday - 1));
    return startOfWeek.subtract(const Duration(days: 28));
  }

  /// Calcula promedios semanales y consistencia de actividad reciente.
  _ActivityAggregates _computeActivityAggregates({
    required List<_CompletedRouteEvent> events,
    required DateTime referenceTime,
  }) {
    final windowStart = _activityWindowStart(referenceTime);
    final relevantEvents = events
        .where((event) => !event.completedAt.isBefore(windowStart))
        .toList(growable: false);

    const trackedWeeks = 5.0;
    var totalDistanceKm = 0.0;
    var totalDurationMinutes = 0.0;
    final activeWeeks = <String>{};

    for (final event in relevantEvents) {
      totalDistanceKm += event.distanceKm;
      totalDurationMinutes += event.durationMinutes;
      final weekStart = DateTime(
        event.completedAt.year,
        event.completedAt.month,
        event.completedAt.day,
      ).subtract(Duration(days: event.completedAt.weekday - 1));
      // Se agrupa por inicio de semana para medir consistencia, no cantidad
      // exacta de rutas. Varias rutas en la misma semana cuentan una vez.
      activeWeeks.add(weekStart.toIso8601String());
    }

    return _ActivityAggregates(
      routesPerWeekAverage: relevantEvents.length / trackedWeeks,
      kmPerWeekAverage: totalDistanceKm / trackedWeeks,
      minutesPerWeekAverage: totalDurationMinutes / trackedWeeks,
      activityConsistencyScore: (activeWeeks.length / trackedWeeks) * 100,
    );
  }

  /// Cierra la sesión activa en Firebase Auth.
  Future<void> logout({bool clearRememberedLogin = true}) async {
    await _auth.signOut();
    if (clearRememberedLogin) {
      await saveRememberedLogin(rememberMe: false, email: '');
    }
  }
}

/// Evento interno usado para calcular métricas recientes de rutas completadas.
class _CompletedRouteEvent {
  const _CompletedRouteEvent({
    required this.completedAt,
    required this.distanceKm,
    required this.durationMinutes,
  });

  final DateTime completedAt;
  final double distanceKm;
  final double durationMinutes;

  /// Reconstruye un evento desde el subdocumento de Firestore.
  factory _CompletedRouteEvent.fromMap(Map<String, dynamic> data) {
    // TODO: validar el tipo de completedAt antes de convertirlo desde Firestore.
    return _CompletedRouteEvent(
      completedAt: (data['completedAt'] as Timestamp).toDate(),
      distanceKm: (data['distanceKm'] as num?)?.toDouble() ?? 0,
      durationMinutes: (data['durationMinutes'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// Agregados semanales derivados de los eventos recientes de rutas.
class _ActivityAggregates {
  const _ActivityAggregates({
    required this.routesPerWeekAverage,
    required this.kmPerWeekAverage,
    required this.minutesPerWeekAverage,
    required this.activityConsistencyScore,
  });

  /// Promedio de rutas por semana dentro de la ventana analizada.
  final double routesPerWeekAverage;

  /// Promedio de kilómetros por semana dentro de la ventana analizada.
  final double kmPerWeekAverage;

  /// Promedio de minutos activos por semana dentro de la ventana analizada.
  final double minutesPerWeekAverage;

  /// Porcentaje de semanas con al menos una ruta completada.
  final double activityConsistencyScore;
}

/// Estado local usado para precargar el formulario de inicio de sesión.
class RememberedLoginState {
  const RememberedLoginState({required this.rememberMe, required this.email});

  /// Indica si la sesión debe restaurarse en el siguiente arranque.
  final bool rememberMe;

  /// Correo normalizado que se precarga en el formulario de acceso.
  final String email;
}
