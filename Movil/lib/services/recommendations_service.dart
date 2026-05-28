import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class RecommendationsService {
  RecommendationsService({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _baseUrl = baseUrl ?? _resolveBaseUrl();

  final http.Client _client;
  final String _baseUrl;

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

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return 0;
  }

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

class RecommendationsResponse {
  const RecommendationsResponse({
    required this.userId,
    required this.candidateCount,
    required this.savedRouteCount,
    required this.recommendations,
  });

  final String userId;
  final int candidateCount;
  final int savedRouteCount;
  final List<RecommendationItem> recommendations;
}

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

  final String routeId;
  final String ownerId;
  final String activityProfile;
  final String region;
  final double distanceKm;
  final double durationMin;
  final double elevationGainMeters;
  final double score;

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

  static double _toDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return 0;
  }
}

class RecommendationsException implements Exception {
  const RecommendationsException(this.message);

  final String message;
}
