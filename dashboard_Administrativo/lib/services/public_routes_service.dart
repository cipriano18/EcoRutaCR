import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class PublicRouteAdminModel {
  const PublicRouteAdminModel({
    required this.id,
    required this.title,
    required this.description,
    required this.activityProfile,
    required this.originLabel,
    required this.destinationLabel,
    required this.distanceMeters,
    required this.estimatedDurationSeconds,
    required this.elevationGainMeters,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String description;
  final String activityProfile;
  final String originLabel;
  final String destinationLabel;
  final num distanceMeters;
  final int estimatedDurationSeconds;
  final num elevationGainMeters;
  final DateTime? createdAt;

  factory PublicRouteAdminModel.fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return PublicRouteAdminModel(
      id: doc.id,
      title: _readString(data, ['title', 'name', 'routeName']) ?? 'Ruta sin titulo',
      description: _readString(data, ['description']) ?? 'Sin descripcion',
      activityProfile:
          _readString(data, ['activityProfile', 'activityType']) ?? 'hiking',
      originLabel: _readNestedLabel(data['start']) ?? 'Origen no disponible',
      destinationLabel: _readNestedLabel(data['end']) ?? 'Destino no disponible',
      distanceMeters: _readNum(data['totalDistanceMeters']) ?? 0,
      estimatedDurationSeconds:
          _readInt(data['estimatedDurationSeconds']) ?? 0,
      elevationGainMeters: _readNum(data['elevationGainMeters']) ?? 0,
      createdAt: _readDate(data['createdAt']),
    );
  }

  static String? _readString(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }

  static String? _readNestedLabel(dynamic value) {
    if (value is Map<String, dynamic>) {
      final label = value['label'];
      if (label is String && label.trim().isNotEmpty) {
        return label.trim();
      }
    }
    return null;
  }

  static num? _readNum(dynamic value) {
    if (value is num) {
      return value;
    }
    return null;
  }

  static int? _readInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return null;
  }

  static DateTime? _readDate(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    return null;
  }
}

class PublicRoutesService {
  PublicRoutesService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<PublicRouteAdminModel>> streamPublicRoutes() {
    debugPrint(
      'PublicRoutesService.streamPublicRoutes: leyendo routes con visibility=public.',
    );

    return _firestore
        .collection('routes')
        .where('visibility', isEqualTo: 'public')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          debugPrint(
            'PublicRoutesService.streamPublicRoutes: ${snapshot.docs.length} rutas públicas recibidas.',
          );
          return snapshot.docs
              .map(PublicRouteAdminModel.fromDocument)
              .toList();
        });
  }

  Future<void> updateRouteBasicInfo({
    required String routeId,
    required String title,
    required String description,
  }) async {
    debugPrint(
      'PublicRoutesService.updateRouteBasicInfo: actualizando routeId=$routeId.',
    );

    await _firestore.collection('routes').doc(routeId).update({
      'title': title.trim(),
      'description': description.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteRoute({required String routeId}) async {
    debugPrint('PublicRoutesService.deleteRoute: eliminando routeId=$routeId.');
    await _firestore.collection('routes').doc(routeId).delete();
  }
}
