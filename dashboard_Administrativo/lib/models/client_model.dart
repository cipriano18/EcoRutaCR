import 'package:cloud_firestore/cloud_firestore.dart';

class ClientModel {
  const ClientModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.address,
    required this.favoriteActivity,
    required this.completedRoutes,
    required this.kilometers,
    required this.streakDeadlineAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String uid;
  final String name;
  final String email;
  final String address;
  final String favoriteActivity;
  final int completedRoutes;
  final double kilometers;
  final DateTime? streakDeadlineAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory ClientModel.fromMap(Map<String, dynamic> map) {
    return ClientModel(
      uid: (map['uid'] as String?) ?? (map['id'] as String?) ?? '',

      name: (map['name'] as String?) ??
          (map['fullName'] as String?) ??
          'Sin nombre',

      email: (map['email'] as String?) ?? '',

      address: (map['address'] as String?) ?? '',

      favoriteActivity:
          (map['favoriteActivity'] as String?) ?? '',

      completedRoutes: _readInt(map['completed_routes']),

      kilometers: _readDouble(map['km_counter']),

      streakDeadlineAt: _parseDate(map['streak_deadline_at']),

      createdAt: _parseDate(map['createdAt']),

      updatedAt: _parseDate(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'address': address,
      'favoriteActivity': favoriteActivity,
      'completed_routes': completedRoutes,
      'km_counter': kilometers,
      'streak_deadline_at': streakDeadlineAt,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return null;
  }

  static int _readInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return 0;
  }

  static double _readDouble(dynamic value) {
    if (value is double) {
      return value;
    }
    if (value is num) {
      return value.toDouble();
    }
    return 0;
  }
}
