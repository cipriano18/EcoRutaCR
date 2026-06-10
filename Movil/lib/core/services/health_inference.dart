/// Entrada fuertemente tipada para inferencias de salud y actividad.
///
/// Normaliza datos de perfil y métricas de uso antes de enviarlos al
/// [HealthInferenceEngine].
class UserHealthInput {
  const UserHealthInput({
    this.weightKg,
    this.heightCm,
    this.birthDate,
    this.favoriteActivity,
    this.completedRoutes = 0,
    this.kmCounter = 0,
    this.routesPerWeekAvg,
    this.kmPerWeekAvg,
    this.minutesPerWeekAvg,

    this.lastRouteAt,
    this.activityConsistencyScore,
    this.favoriteRouteDistanceKm,
    this.favoriteRouteDurationMin,
  });

  /// Peso del usuario en kilogramos.
  final double? weightKg;

  /// Estatura del usuario en centímetros.
  final double? heightCm;

  /// Fecha de nacimiento usada para calcular edad.
  final DateTime? birthDate;

  /// Actividad preferida declarada en el perfil.
  final String? favoriteActivity;

  /// Cantidad histórica de rutas completadas.
  final int completedRoutes;

  /// Kilómetros acumulados por el usuario.
  final double kmCounter;

  /// Promedio de rutas completadas por semana.
  final double? routesPerWeekAvg;

  /// Promedio de kilómetros recorridos por semana.
  final double? kmPerWeekAvg;

  /// Promedio de minutos activos por semana.
  final double? minutesPerWeekAvg;

  /// Fecha de la última ruta registrada, si existe.
  final DateTime? lastRouteAt;

  /// Puntaje de consistencia de actividad en escala de 0 a 100.
  final double? activityConsistencyScore;

  /// Distancia típica de la ruta favorita del usuario.
  final double? favoriteRouteDistanceKm;

  /// Duración típica de la ruta favorita del usuario.
  final double? favoriteRouteDurationMin;

  /// Construye una entrada desde un documento de usuario de Firestore.
  ///
  /// Acepta valores nulos o formatos mixtos para mantener compatibilidad con
  /// documentos antiguos o datos parciales.
  factory UserHealthInput.fromUserMap(Map<String, dynamic> data) {
    return UserHealthInput(
      weightKg: _toDouble(data['weight_kg']),
      heightCm: _toDouble(data['height_cm']),
      birthDate: _parseDate(data['birth_date']),
      favoriteActivity: data['favoriteActivity']?.toString(),
      completedRoutes: (data['completed_routes'] as num?)?.toInt() ?? 0,
      kmCounter: _toDouble(data['km_counter']) ?? 0,
      routesPerWeekAvg: _toDouble(data['routes_per_week_avg']),
      kmPerWeekAvg: _toDouble(data['km_per_week_avg']),
      minutesPerWeekAvg: _toDouble(data['minutes_per_week_avg']),

      lastRouteAt: _parseDate(data['last_route_at']),
      activityConsistencyScore: _toDouble(data['activity_consistency_score']),
      favoriteRouteDistanceKm: _toDouble(data['favorite_route_distance_km']),
      favoriteRouteDurationMin: _toDouble(data['favorite_route_duration_min']),
    );
  }

  /// Convierte fechas de Firestore, Dart o texto ISO a [DateTime].
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
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  /// Convierte valores numéricos dinámicos a [double].
  static double? _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return null;
  }
}

/// Resultado derivado del motor de inferencias.
///
/// Agrupa métricas calculadas localmente para persistirlas o mostrarlas en el
/// perfil sin recalcularlas en cada pantalla.
class HealthInferenceResult {
  const HealthInferenceResult({
    this.bmi,
    this.bmiCategory,
    this.activityLevel,
    this.wellnessStatus,
    this.wellnessScore,
    this.ageYears,
  });

  /// Índice de masa corporal calculado desde peso y estatura.
  final double? bmi;

  /// Categoría textual derivada del [bmi].
  final String? bmiCategory;

  /// Nivel de actividad semanal estimado.
  final String? activityLevel;

  /// Estado general de bienestar derivado del puntaje.
  final String? wellnessStatus;

  /// Puntaje de bienestar en escala de 0 a 100.
  final double? wellnessScore;

  /// Edad calculada desde la fecha de nacimiento.
  final int? ageYears;

  /// Crea una copia conservando los valores existentes cuando el parámetro es nulo.
  HealthInferenceResult copyWith({
    double? bmi,
    String? bmiCategory,
    String? activityLevel,
    String? wellnessStatus,
    double? wellnessScore,
    int? ageYears,
  }) {
    return HealthInferenceResult(
      bmi: bmi ?? this.bmi,
      bmiCategory: bmiCategory ?? this.bmiCategory,
      activityLevel: activityLevel ?? this.activityLevel,
      wellnessStatus: wellnessStatus ?? this.wellnessStatus,
      wellnessScore: wellnessScore ?? this.wellnessScore,
      ageYears: ageYears ?? this.ageYears,
    );
  }

  /// Convierte el resultado en el parche completo usado por Firestore.
  Map<String, dynamic> toFirestorePatch({DateTime? inferredAt}) {
    return {
      'bmi': bmi,
      'bmi_category': bmiCategory,
      'activity_level': activityLevel,
      'wellness_status': wellnessStatus,
      'wellness_score': wellnessScore,
      'inference_updated_at': inferredAt ?? DateTime.now(),
    };
  }

  /// Convierte solo las inferencias disponibles al crear o editar el perfil.
  ///
  /// Se limita a IMC porque las métricas de actividad aún no existen durante
  /// el registro inicial del usuario.
  Map<String, dynamic> toInitialFirestorePatch({DateTime? inferredAt}) {
    return {
      'bmi': bmi,
      'bmi_category': bmiCategory,
      'inference_updated_at': inferredAt ?? DateTime.now(),
    };
  }
}

/// Motor de inferencias de salud para usar localmente o como contrato compartido.
class HealthInferenceEngine {
  /// Evalúa [input] y retorna métricas derivadas de salud y actividad.
  static HealthInferenceResult evaluate(UserHealthInput input) {
    final bmi = _calculateBmi(input.weightKg, input.heightCm);
    final bmiCategory = _bmiCategoryFor(bmi);
    final activityLevel = _activityLevelFor(input);
    final wellnessScore = _wellnessScoreFor(
      bmiCategory: bmiCategory,
      activityLevel: activityLevel,
      consistencyScore: input.activityConsistencyScore,
    );
    final wellnessStatus = _wellnessStatusFor(wellnessScore);

    return HealthInferenceResult(
      bmi: bmi,
      bmiCategory: bmiCategory,
      activityLevel: activityLevel,
      wellnessStatus: wellnessStatus,
      wellnessScore: wellnessScore,
      ageYears: _ageFromBirthDate(input.birthDate),
    );
  }

  /// Calcula el índice de masa corporal usando peso en kg y estatura en cm.
  static double? _calculateBmi(double? weightKg, double? heightCm) {
    if (weightKg == null ||
        heightCm == null ||
        weightKg <= 0 ||
        heightCm <= 0) {
      return null;
    }

    final heightMeters = heightCm / 100;
    if (heightMeters <= 0) return null;
    return weightKg / (heightMeters * heightMeters);
  }

  /// Clasifica el IMC con rangos clínicos generales.
  static String? _bmiCategoryFor(double? bmi) {
    if (bmi == null) return null;
    if (bmi < 18.5) return 'underweight';
    if (bmi < 25) return 'normal';
    if (bmi < 30) return 'overweight';
    return 'obesity';
  }

  /// Estima el nivel de actividad semanal a partir de rutas, distancia y tiempo.
  static String? _activityLevelFor(UserHealthInput input) {
    final routes = input.routesPerWeekAvg;
    final kilometers = input.kmPerWeekAvg;
    final minutes = input.minutesPerWeekAvg;
    if (routes == null && kilometers == null && minutes == null) return null;

    var score = 0.0;
    var components = 0;

    // Cada métrica aporta una escala de 0 a 100. El promedio evita que un
    // único dato disponible domine por completo cuando faltan otros.
    if (routes != null) {
      components++;
      if (routes >= 4) {
        score += 100;
      } else if (routes >= 3) {
        score += 80;
      } else if (routes >= 2) {
        score += 60;
      } else if (routes >= 1) {
        score += 35;
      }
    }

    if (kilometers != null) {
      components++;
      if (kilometers >= 30) {
        score += 100;
      } else if (kilometers >= 20) {
        score += 80;
      } else if (kilometers >= 10) {
        score += 60;
      } else if (kilometers > 0) {
        score += 35;
      }
    }

    if (minutes != null) {
      components++;
      if (minutes >= 180) {
        score += 100;
      } else if (minutes >= 150) {
        score += 80;
      } else if (minutes >= 90) {
        score += 60;
      } else if (minutes > 0) {
        score += 35;
      }
    }

    final average = components == 0 ? 0 : score / components;
    if (average >= 85) return 'high';
    if (average >= 65) return 'good';
    if (average >= 40) return 'moderate';
    return 'low';
  }

  /// Promedia señales de IMC, actividad y consistencia en una escala de 0 a 100.
  static double? _wellnessScoreFor({
    required String? bmiCategory,
    required String? activityLevel,
    required double? consistencyScore,
  }) {
    final parts = <double>[];

    if (bmiCategory != null) {
      switch (bmiCategory) {
        case 'normal':
          parts.add(100);
          break;
        case 'overweight':
          parts.add(65);
          break;
        case 'underweight':
          parts.add(60);
          break;
        case 'obesity':
          parts.add(35);
          break;
      }
    }

    if (activityLevel != null) {
      switch (activityLevel) {
        case 'high':
          parts.add(100);
          break;
        case 'good':
          parts.add(80);
          break;
        case 'moderate':
          parts.add(60);
          break;
        case 'low':
          parts.add(30);
          break;
      }
    }

    if (consistencyScore != null) {
      // La consistencia puede venir de agregados externos; se limita para que
      // valores atípicos no rompan la escala del puntaje final.
      parts.add(consistencyScore.clamp(0, 100).toDouble());
    }

    if (parts.isEmpty) return null;
    return parts.reduce((a, b) => a + b) / parts.length;
  }

  /// Traduce el puntaje de bienestar a una etiqueta de estado.
  static String? _wellnessStatusFor(double? score) {
    if (score == null) return null;
    if (score >= 75) return 'saludable';
    if (score >= 50) return 'mejorable';
    return 'atencion';
  }

  /// Calcula la edad actual y descarta fechas de nacimiento futuras.
  static int? _ageFromBirthDate(DateTime? birthDate) {
    if (birthDate == null) return null;
    final now = DateTime.now();
    var age = now.year - birthDate.year;
    final birthdayReached =
        now.month > birthDate.month ||
        (now.month == birthDate.month && now.day >= birthDate.day);
    if (!birthdayReached) age--;
    return age < 0 ? null : age;
  }
}
