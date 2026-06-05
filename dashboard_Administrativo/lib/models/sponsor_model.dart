class Sponsor {
  const Sponsor({
    this.id,
    required this.name,
    required this.logoUrl,
    required this.type,
    required this.contactEmail,
    required this.phone,
    required this.startDate,
    required this.endDate,
    required this.status,
    this.amountContributed,
    required this.paymentType,
    required this.isPhysicalBusiness,
    this.latitude,
    this.longitude,
    required this.category,
    required this.description,
    this.externalLink,
    this.priority,
    this.advertisementIds = const [],
    this.createdAt,
    this.updatedAt,
  });

  final String? id;
  final String name;
  final String logoUrl;
  final String type;
  final String contactEmail;
  final String phone;
  final DateTime startDate;
  final DateTime endDate;
  final String status;
  final double? amountContributed;
  final String paymentType;
  final bool isPhysicalBusiness;
  final double? latitude;
  final double? longitude;
  final String category;
  final String description;
  final String? externalLink;
  final int? priority;
  final List<String> advertisementIds;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory Sponsor.fromMap(Map<String, dynamic> map, {String? id}) {
    return Sponsor(
      id: id ?? (map['id'] as String?),
      name: (map['name'] as String?) ?? '',
      logoUrl: (map['logoUrl'] as String?) ?? '',
      type: (map['type'] as String?) ?? '',
      contactEmail: (map['contactEmail'] as String?) ?? '',
      phone: (map['phone'] as String?) ?? '',
      startDate: _parseDate(map['startDate']) ?? DateTime.now(),
      endDate: _parseDate(map['endDate']) ?? DateTime.now(),
      status: (map['status'] as String?) ?? '',
      amountContributed: (map['amountContributed'] as num?)?.toDouble(),
      paymentType: (map['paymentType'] as String?) ?? '',
      isPhysicalBusiness: (map['isPhysicalBusiness'] as bool?) ?? false,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      category: (map['category'] as String?) ?? '',
      description: (map['description'] as String?) ?? '',
      externalLink: map['externalLink'] as String?,
      priority: map['priority'] as int?,
      advertisementIds: ((map['advertisementIds'] as List?) ?? const [])
          .whereType<String>()
          .toList(),
      createdAt: _parseDate(map['createdAt']),
      updatedAt: _parseDate(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'logoUrl': logoUrl,
      'type': type,
      'contactEmail': contactEmail,
      'phone': phone,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'status': status,
      'amountContributed': amountContributed,
      'paymentType': paymentType,
      'isPhysicalBusiness': isPhysicalBusiness,
      'latitude': latitude,
      'longitude': longitude,
      'category': category,
      'description': description,
      'externalLink': externalLink,
      'priority': priority,
      'advertisementIds': advertisementIds,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
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
}
