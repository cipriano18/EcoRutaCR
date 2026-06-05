import 'package:flutter/material.dart';

enum AdvertisementType { anuncio, local }

extension AdvertisementTypeLabel on AdvertisementType {
  String get label => this == AdvertisementType.anuncio ? 'Anuncio' : 'Local';
}

class AdvertisementDraft {
  const AdvertisementDraft({
    this.id,
    required this.type,
    required this.sponsorId,
    required this.sponsorName,
    required this.sponsorLogoUrl,
    this.sponsorExternalLink,
    required this.status,
    required this.imageUrl,
    required this.description,
    this.startDate,
    this.endDate,
    this.openingTime,
    this.closingTime,
    this.latitude,
    this.longitude,
    this.totalClicks = 0,
    this.createdByAdminId,
    this.createdAt,
    this.updatedAt,
  });

  final String? id;
  final AdvertisementType type;
  final String sponsorId;
  final String sponsorName;
  final String sponsorLogoUrl;
  final String? sponsorExternalLink;
  final String status;
  final String imageUrl;
  final String description;
  final DateTime? startDate;
  final DateTime? endDate;
  final TimeOfDay? openingTime;
  final TimeOfDay? closingTime;
  final double? latitude;
  final double? longitude;
  final int totalClicks;
  final String? createdByAdminId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory AdvertisementDraft.fromMap(Map<String, dynamic> map, {String? id}) {
    return AdvertisementDraft(
      id: id ?? map['id'] as String?,
      type: _parseType(map['type'] as String?),
      sponsorId: (map['sponsorId'] as String?) ?? '',
      sponsorName: (map['sponsorName'] as String?) ?? '',
      sponsorLogoUrl: (map['sponsorLogoUrl'] as String?) ?? '',
      sponsorExternalLink: map['sponsorExternalLink'] as String?,
      status: (map['status'] as String?) ?? '',
      imageUrl: (map['imageUrl'] as String?) ?? '',
      description: (map['description'] as String?) ?? '',
      startDate: _parseDate(map['startDate']),
      endDate: _parseDate(map['endDate']),
      openingTime: _parseTimeOfDay(map['openingTime']),
      closingTime: _parseTimeOfDay(map['closingTime']),
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      totalClicks: (map['totalClicks'] as num?)?.toInt() ?? 0,
      createdByAdminId: map['createdByAdminId'] as String?,
      createdAt: _parseDate(map['createdAt']),
      updatedAt: _parseDate(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'sponsorId': sponsorId,
      'sponsorName': sponsorName,
      'sponsorLogoUrl': sponsorLogoUrl,
      'sponsorExternalLink': sponsorExternalLink,
      'status': status,
      'imageUrl': imageUrl,
      'description': description,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'openingTime': _timeOfDayToString(openingTime),
      'closingTime': _timeOfDayToString(closingTime),
      'latitude': latitude,
      'longitude': longitude,
      'totalClicks': totalClicks,
      'createdByAdminId': createdByAdminId,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  static String? _timeOfDayToString(TimeOfDay? value) {
    if (value == null) return null;
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  static AdvertisementType _parseType(String? value) {
    return value == AdvertisementType.local.name
        ? AdvertisementType.local
        : AdvertisementType.anuncio;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    try {
      final dynamic toDate = value?.toDate();
      if (toDate is DateTime) return toDate;
    } catch (_) {}
    return null;
  }

  static TimeOfDay? _parseTimeOfDay(dynamic value) {
    if (value is! String || !value.contains(':')) return null;
    final parts = value.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }
}
