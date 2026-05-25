import 'package:ecoruta/services/health_inference.dart';

/// Representa el perfil persistido del usuario dentro de Firestore.
class UserModel {
  /// Identificador del usuario autenticado.
  final String uid;

  /// Correo asociado a la cuenta.
  final String email;

  /// Nombre completo mostrado en la app.
  final String fullName;

  /// Direccion o ubicacion de referencia del usuario.
  final String address;

  /// Avatar seleccionado dentro del catalogo local.
  final int avatarId;

  /// Actividad favorita elegida durante el registro.
  final String? favoriteActivity;
  final int? _completedRoutes;
  final num? _kmCounter;
  final DateTime? _streakStartedAt;
  final DateTime? _streakDeadlineAt;
  final double? _weightKg;
  final double? _heightCm;
  final DateTime? _birthDate;
  final double? _routesPerWeekAvg;
  final double? _kmPerWeekAvg;
  final double? _minutesPerWeekAvg;
  final double? _activityConsistencyScore;
  final double? _bmi;
  final String? _bmiCategory;
  final String? _activityLevel;
  final String? _wellnessStatus;
  final double? _wellnessScore;
  final DateTime? _inferenceUpdatedAt;
  final DateTime? _createdAt;
  final DateTime? _updatedAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.address,
    required this.avatarId,
    this.favoriteActivity,
    int? completedRoutes,
    num? kmCounter,
    DateTime? streakStartedAt,
    DateTime? streakDeadlineAt,
    double? weightKg,
    double? heightCm,
    DateTime? birthDate,
    double? routesPerWeekAvg,
    double? kmPerWeekAvg,
    double? minutesPerWeekAvg,
    double? activityConsistencyScore,
    double? bmi,
    String? bmiCategory,
    String? activityLevel,
    String? wellnessStatus,
    double? wellnessScore,
    DateTime? inferenceUpdatedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : _completedRoutes = completedRoutes,
       _kmCounter = kmCounter,
       _streakStartedAt = streakStartedAt,
       _streakDeadlineAt = streakDeadlineAt,
       _weightKg = weightKg,
       _heightCm = heightCm,
       _birthDate = birthDate,
       _routesPerWeekAvg = routesPerWeekAvg,
       _kmPerWeekAvg = kmPerWeekAvg,
       _minutesPerWeekAvg = minutesPerWeekAvg,
       _activityConsistencyScore = activityConsistencyScore,
       _bmi = bmi,
       _bmiCategory = bmiCategory,
       _activityLevel = activityLevel,
       _wellnessStatus = wellnessStatus,
       _wellnessScore = wellnessScore,
       _inferenceUpdatedAt = inferenceUpdatedAt,
       _createdAt = createdAt,
       _updatedAt = updatedAt;

  /// Cantidad de rutas completadas con valor por defecto seguro.
  int get completedRoutes => _completedRoutes ?? 0;

  /// Kilometros acumulados usados para rangos y progreso.
  num get kmCounter => _kmCounter ?? 0;

  /// Fecha de inicio de la racha semanal activa.
  DateTime? get streakStartedAt => _streakStartedAt;

  /// Fecha limite para conservar la racha actual.
  DateTime? get streakDeadlineAt => _streakDeadlineAt;

  double? get weightKg => _weightKg;
  double? get heightCm => _heightCm;
  DateTime? get birthDate => _birthDate;
  double? get routesPerWeekAvg => _routesPerWeekAvg;
  double? get kmPerWeekAvg => _kmPerWeekAvg;
  double? get minutesPerWeekAvg => _minutesPerWeekAvg;
  double? get activityConsistencyScore => _activityConsistencyScore;
  double? get bmi => _bmi;
  String? get bmiCategory => _bmiCategory;
  String? get activityLevel => _activityLevel;
  String? get wellnessStatus => _wellnessStatus;
  double? get wellnessScore => _wellnessScore;
  DateTime? get inferenceUpdatedAt => _inferenceUpdatedAt;
  DateTime? get createdAt => _createdAt;
  DateTime? get updatedAt => _updatedAt;

  /// Datos normalizados para correr el motor de inferencias localmente.
  UserHealthInput get healthInput => UserHealthInput(
    weightKg: _weightKg,
    heightCm: _heightCm,
    birthDate: _birthDate,
    favoriteActivity: favoriteActivity,
    completedRoutes: completedRoutes,
    kmCounter: kmCounter.toDouble(),
    routesPerWeekAvg: _routesPerWeekAvg,
    kmPerWeekAvg: _kmPerWeekAvg,
    minutesPerWeekAvg: _minutesPerWeekAvg,
    activityConsistencyScore: _activityConsistencyScore,
  );

  /// Resultado de inferencia usando datos existentes o derivando localmente.
  HealthInferenceResult get healthInference {
    final inferred = HealthInferenceEngine.evaluate(healthInput);
    return inferred.copyWith(
      bmi: _bmi ?? inferred.bmi,
      bmiCategory: _bmiCategory ?? inferred.bmiCategory,
      activityLevel: _activityLevel ?? inferred.activityLevel,
      wellnessStatus: _wellnessStatus ?? inferred.wellnessStatus,
      wellnessScore: _wellnessScore ?? inferred.wellnessScore,
    );
  }

  /// Calcula la cantidad de semanas activas de la racha vigente.
  int get streakWeeks {
    final startedAt = _streakStartedAt;
    final deadlineAt = _streakDeadlineAt;
    if (startedAt == null || deadlineAt == null) return 0;

    final now = DateTime.now();
    if (deadlineAt.isBefore(now)) return 0;

    return (now.difference(startedAt).inDays ~/ 7) + 1;
  }

  /// Reconstruye el modelo a partir del documento de Firestore.
  factory UserModel.fromMap(Map<String, dynamic> data) {
    final rawAvatarId = data['avatarId'];
    final rawCompletedRoutes = data['completed_routes'];
    final rawKmCounter = data['km_counter'];
    final rawStreakStartedAt = data['streak_started_at'];
    final rawStreakDeadlineAt = data['streak_deadline_at'];

    return UserModel(
      uid: (data['uid'] ?? '').toString(),
      email: (data['email'] ?? '').toString(),
      fullName: (data['fullName'] ?? 'Usuario').toString(),
      address: (data['address'] ?? '').toString(),
      avatarId: rawAvatarId is num ? rawAvatarId.toInt() : 0,
      favoriteActivity: data['favoriteActivity']?.toString(),
      completedRoutes: rawCompletedRoutes is num
          ? rawCompletedRoutes.toInt()
          : 0,
      kmCounter: rawKmCounter is num ? rawKmCounter : 0,
      streakStartedAt: _parseDate(rawStreakStartedAt),
      streakDeadlineAt: _parseDate(rawStreakDeadlineAt),
      weightKg: _toDouble(data['weight_kg']),
      heightCm: _toDouble(data['height_cm']),
      birthDate: _parseDate(data['birth_date']),
      routesPerWeekAvg: _toDouble(data['routes_per_week_avg']),
      kmPerWeekAvg: _toDouble(data['km_per_week_avg']),
      minutesPerWeekAvg: _toDouble(data['minutes_per_week_avg']),
      activityConsistencyScore: _toDouble(data['activity_consistency_score']),
      bmi: _toDouble(data['bmi']),
      bmiCategory: data['bmi_category']?.toString(),
      activityLevel: data['activity_level']?.toString(),
      wellnessStatus: data['wellness_status']?.toString(),
      wellnessScore: _toDouble(data['wellness_score']),
      inferenceUpdatedAt: _parseDate(data['inference_updated_at']),
      createdAt: _parseDate(data['createdAt']),
      updatedAt: _parseDate(data['updatedAt']),
    );
  }

  /// Crea una copia parcial para actualizar el estado sin mutar la instancia.
  UserModel copyWith({
    String? uid,
    String? email,
    String? fullName,
    String? address,
    int? avatarId,
    String? favoriteActivity,
    int? completedRoutes,
    num? kmCounter,
    DateTime? streakStartedAt,
    DateTime? streakDeadlineAt,
    double? weightKg,
    double? heightCm,
    DateTime? birthDate,
    double? routesPerWeekAvg,
    double? kmPerWeekAvg,
    double? minutesPerWeekAvg,
    double? activityConsistencyScore,
    double? bmi,
    String? bmiCategory,
    String? activityLevel,
    String? wellnessStatus,
    double? wellnessScore,
    DateTime? inferenceUpdatedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      address: address ?? this.address,
      avatarId: avatarId ?? this.avatarId,
      favoriteActivity: favoriteActivity ?? this.favoriteActivity,
      completedRoutes: completedRoutes ?? _completedRoutes,
      kmCounter: kmCounter ?? _kmCounter,
      streakStartedAt: streakStartedAt ?? _streakStartedAt,
      streakDeadlineAt: streakDeadlineAt ?? _streakDeadlineAt,
      weightKg: weightKg ?? _weightKg,
      heightCm: heightCm ?? _heightCm,
      birthDate: birthDate ?? _birthDate,
      routesPerWeekAvg: routesPerWeekAvg ?? _routesPerWeekAvg,
      kmPerWeekAvg: kmPerWeekAvg ?? _kmPerWeekAvg,
      minutesPerWeekAvg: minutesPerWeekAvg ?? _minutesPerWeekAvg,
      activityConsistencyScore:
          activityConsistencyScore ?? _activityConsistencyScore,
      bmi: bmi ?? _bmi,
      bmiCategory: bmiCategory ?? _bmiCategory,
      activityLevel: activityLevel ?? _activityLevel,
      wellnessStatus: wellnessStatus ?? _wellnessStatus,
      wellnessScore: wellnessScore ?? _wellnessScore,
      inferenceUpdatedAt: inferenceUpdatedAt ?? _inferenceUpdatedAt,
      createdAt: createdAt ?? _createdAt,
      updatedAt: updatedAt ?? _updatedAt,
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value.runtimeType.toString() == 'Timestamp') {
      try {
        return value.toDate() as DateTime;
      } catch (_) {
        return null;
      }
    }
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  static double? _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return null;
  }
}
