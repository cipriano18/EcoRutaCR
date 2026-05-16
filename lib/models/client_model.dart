import 'package:cloud_firestore/cloud_firestore.dart';

class ClientModel {
  const ClientModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.favoriteActivity,
    required this.createdAt,
  });

  final String uid;
  final String name;
  final String email;
  final String favoriteActivity;
  final DateTime? createdAt;

  factory ClientModel.fromMap(Map<String, dynamic> map) {
    return ClientModel(
      uid: (map['uid'] as String?) ?? '',

      name: (map['name'] as String?) ??
          (map['fullName'] as String?) ??
          'Sin nombre',

      email: (map['email'] as String?) ?? '',

      favoriteActivity:
          (map['favoriteActivity'] as String?) ?? '',

      createdAt: _parseDate(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'favoriteActivity': favoriteActivity,
      'createdAt': createdAt,
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
}