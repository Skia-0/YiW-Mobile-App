class FocalPerson {
  final String fullName;
  final String phoneNumber;
  final String? email;
  final String zone;
  final DateTime visitDate;
  final List<String> visitTypes;

  FocalPerson({
    required this.fullName,
    required this.phoneNumber,
    this.email,
    required this.zone,
    required this.visitDate,
    this.visitTypes = const [],
  });

  factory FocalPerson.fromJson(Map<String, dynamic> json) {
    return FocalPerson(
      fullName: json['fullName'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      email: json['email'],
      zone: json['zone'] ?? '',
      visitDate: DateTime.parse(json['visitDate']),
      visitTypes: List<String>.from(json['visitTypes'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'email': email,
      'zone': zone,
      'visitDate': visitDate.toIso8601String(),
      'visitTypes': visitTypes,
    };
  }

  FocalPerson copyWith({
    String? fullName,
    String? phoneNumber,
    String? email,
    String? zone,
    DateTime? visitDate,
    List<String>? visitTypes,
  }) {
    return FocalPerson(
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      zone: zone ?? this.zone,
      visitDate: visitDate ?? this.visitDate,
      visitTypes: visitTypes ?? this.visitTypes,
    );
  }
}
