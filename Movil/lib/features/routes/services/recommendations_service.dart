import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Cliente HTTP para consultar recomendaciones personalizadas de rutas.
class RecommendationsService {
  RecommendationsService({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _baseUrl = baseUrl ?? _resolveBaseUrl();

  final http.Client _client;
  final String _baseUrl;

  /// Solicita las mejores recomendaciones para [userId].
  Future<RecommendationsResponse> fetchRecommendations({
    required String userId,
    int topK = 8,
  }) async {
    final uri = Uri.parse(
      '$_baseUrl/recommendations/$userId',
    ).replace(queryParameters: {'top_k': '$topK'});

    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      throw RecommendationsException(_extractErrorMessage(response.body));
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const RecommendationsException(
        'La respuesta del servicio de recomendaciones no es valida.',
      );
    }

    final items = decoded['topRecommendations'];
    if (items is! List) {
      throw const RecommendationsException(
        'El servicio no devolvio un listado de recomendaciones.',
      );
    }

    return RecommendationsResponse(
      userId: decoded['userId']?.toString() ?? userId,
      candidateCount: _toInt(decoded['candidateCount']),
      savedRouteCount: _toInt(decoded['savedRouteCount']),
      recommendations: items
          .whereType<Map>()
          .map(
            (item) => RecommendationItem.fromJson(
              item.map((key, value) => MapEntry(key.toString(), value)),
            ),
          )
          .toList(growable: false),
    );
  }

  /// Resuelve la URL base según plataforma o variable de compilación.
  static String _resolveBaseUrl() {
    const fromEnvironment = String.fromEnvironment(
      'RECOMMENDATION_API_BASE_URL',
      defaultValue: '',
    );
    if (fromEnvironment.isNotEmpty) {
      return fromEnvironment;
    }

    if (kIsWeb) {
      return 'http://127.0.0.1:8000';
    }

    // Android emulador usa 10.0.2.2 para acceder al host local.
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:8000';
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        return 'http://127.0.0.1:8000';
      case TargetPlatform.fuchsia:
        return 'http://127.0.0.1:8000';
    }
  }

  /// Convierte contadores dinámicos del backend a entero.
  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return 0;
  }

  /// Extrae un mensaje de error legible desde la respuesta del backend.
  static String _extractErrorMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final detail = decoded['detail']?.toString();
        if (detail != null && detail.trim().isNotEmpty) {
          return detail;
        }
      }
    } catch (_) {}

    return 'No se pudieron cargar las recomendaciones.';
  }
}

/// Respuesta agregada del servicio de recomendaciones.
class RecommendationsResponse {
  const RecommendationsResponse({
    required this.userId,
    required this.candidateCount,
    required this.savedRouteCount,
    required this.recommendations,
  });

  /// Usuario para el que se calcularon las recomendaciones.
  final String userId;

  /// Cantidad de rutas candidatas evaluadas por el backend.
  final int candidateCount;

  /// Cantidad de rutas guardadas usadas como señal de preferencia.
  final int savedRouteCount;

  /// Lista ordenada de recomendaciones.
  final List<RecommendationItem> recommendations;
}

/// Ruta recomendada por el backend de inteligencia.
class RecommendationItem {
  const RecommendationItem({
    required this.routeId,
    required this.ownerId,
    required this.activityProfile,
    required this.region,
    required this.distanceKm,
    required this.durationMin,
    required this.elevationGainMeters,
    required this.score,
  });

  /// Identificador de la ruta recomendada.
  final String routeId;

  /// Usuario propietario de la ruta recomendada.
  final String ownerId;

  /// Perfil de actividad asociado a la recomendación.
  final String activityProfile;

  /// Región inferida o etiquetada de la ruta.
  final String region;

  /// Distancia estimada en kilómetros.
  final double distanceKm;

  /// Duración estimada en minutos.
  final double durationMin;

  /// Desnivel positivo acumulado en metros.
  final double elevationGainMeters;

  /// Puntaje de relevancia calculado por el backend.
  final double score;

  /// Reconstruye un item desde JSON tolerando campos ausentes.
  factory RecommendationItem.fromJson(Map<String, dynamic> json) {
    return RecommendationItem(
      routeId: json['routeId']?.toString() ?? '',
      ownerId: json['ownerId']?.toString() ?? '',
      activityProfile: json['activityProfile']?.toString() ?? '',
      region: json['region']?.toString() ?? '',
      distanceKm: _toDouble(json['distanceKm']),
      durationMin: _toDouble(json['durationMin']),
      elevationGainMeters: _toDouble(json['elevationGainMeters']),
      score: _toDouble(json['score']),
    );
  }

  /// Convierte valores numéricos dinámicos a [double].
  static double _toDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return 0;
  }
}

/// Error de dominio para fallos del servicio de recomendaciones.
class RecommendationsException implements Exception {
  const RecommendationsException(this.message);

  final String message;
}
