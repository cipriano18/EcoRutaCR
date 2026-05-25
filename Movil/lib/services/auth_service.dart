import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecoruta/models/user_model.dart';
import 'package:ecoruta/services/health_inference.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Administra autenticación y perfil persistido del usuario en Firebase.
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
  }) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
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
      patch.addAll({
        'activity_level': healthInference.activityLevel,
        'wellness_status': healthInference.wellnessStatus,
        'wellness_score': healthInference.wellnessScore,
      });
    }

    await userDoc.update(patch);
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

  /// Elimina la cuenta autenticada y hace rollback del perfil si falla Auth.
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

    try {
      await user.delete();
    } catch (e) {
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

  DateTime? _readDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  double? _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return null;
  }

  DateTime _activityWindowStart(DateTime referenceTime) {
    final startOfWeek = DateTime(
      referenceTime.year,
      referenceTime.month,
      referenceTime.day,
    ).subtract(Duration(days: referenceTime.weekday - 1));
    return startOfWeek.subtract(const Duration(days: 28));
  }

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

class _CompletedRouteEvent {
  const _CompletedRouteEvent({
    required this.completedAt,
    required this.distanceKm,
    required this.durationMinutes,
  });

  final DateTime completedAt;
  final double distanceKm;
  final double durationMinutes;

  factory _CompletedRouteEvent.fromMap(Map<String, dynamic> data) {
    return _CompletedRouteEvent(
      completedAt: (data['completedAt'] as Timestamp).toDate(),
      distanceKm: (data['distanceKm'] as num?)?.toDouble() ?? 0,
      durationMinutes: (data['durationMinutes'] as num?)?.toDouble() ?? 0,
    );
  }
}

class _ActivityAggregates {
  const _ActivityAggregates({
    required this.routesPerWeekAverage,
    required this.kmPerWeekAverage,
    required this.minutesPerWeekAverage,
    required this.activityConsistencyScore,
  });

  final double routesPerWeekAverage;
  final double kmPerWeekAverage;
  final double minutesPerWeekAverage;
  final double activityConsistencyScore;
}

/// Estado local usado para precargar el formulario de inicio de sesión.
class RememberedLoginState {
  const RememberedLoginState({required this.rememberMe, required this.email});

  final bool rememberMe;
  final String email;
}
