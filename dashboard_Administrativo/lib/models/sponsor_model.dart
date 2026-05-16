class Sponsor {
  const Sponsor({
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
  });

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

  Map<String, dynamic> toMap() {
    return {
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
    };
  }
}
