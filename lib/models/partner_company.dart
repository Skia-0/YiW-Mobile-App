class PartnerCompany {
  final String companyName;
  final String? location;
  final String? sector;
  final String? businessProfile;
  final String? skillsNeeded;
  final String? contactName;
  final String? contactPhone;
  final String? contactEmail;
  final String? status;
  final int? youthSlots;
  final String? remarks;

  PartnerCompany({
    required this.companyName,
    this.location,
    this.sector,
    this.businessProfile,
    this.skillsNeeded,
    this.contactName,
    this.contactPhone,
    this.contactEmail,
    this.status,
    this.youthSlots,
    this.remarks,
  });

  factory PartnerCompany.fromJson(Map<String, dynamic> json) {
    return PartnerCompany(
      companyName: json['companyName'] ?? '',
      location: json['location'],
      sector: json['sector'],
      businessProfile: json['businessProfile'],
      skillsNeeded: json['skillsNeeded'],
      contactName: json['contactName'],
      contactPhone: json['contactPhone'],
      contactEmail: json['contactEmail'],
      status: json['status'],
      youthSlots: json['youthSlots'],
      remarks: json['remarks'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'companyName': companyName,
      'location': location,
      'sector': sector,
      'businessProfile': businessProfile,
      'skillsNeeded': skillsNeeded,
      'contactName': contactName,
      'contactPhone': contactPhone,
      'contactEmail': contactEmail,
      'status': status,
      'youthSlots': youthSlots,
      'remarks': remarks,
    };
  }

  PartnerCompany copyWith({
    String? companyName,
    String? location,
    String? sector,
    String? businessProfile,
    String? skillsNeeded,
    String? contactName,
    String? contactPhone,
    String? contactEmail,
    String? status,
    int? youthSlots,
    String? remarks,
  }) {
    return PartnerCompany(
      companyName: companyName ?? this.companyName,
      location: location ?? this.location,
      sector: sector ?? this.sector,
      businessProfile: businessProfile ?? this.businessProfile,
      skillsNeeded: skillsNeeded ?? this.skillsNeeded,
      contactName: contactName ?? this.contactName,
      contactPhone: contactPhone ?? this.contactPhone,
      contactEmail: contactEmail ?? this.contactEmail,
      status: status ?? this.status,
      youthSlots: youthSlots ?? this.youthSlots,
      remarks: remarks ?? this.remarks,
    );
  }
}
